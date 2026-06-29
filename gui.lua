local _, private = ...

-- [[ Lua Globals ]]
-- luacheck: globals next ipairs
local wago = private.wago
local GetAddOnMetadata = _G.C_AddOns and _G.C_AddOns.GetAddOnMetadata

-- [[ Core ]]
local Aurora = private.Aurora
local Base, Skin = Aurora.Base, Aurora.Skin
local Util = Aurora.Util
local Config = private.Config
local Analytics = private.Analytics
local Compatibility = private.Compatibility
local Integration = private.Integration
local _, C = _G.unpack(Aurora)

-- [[ Splash screen ]]

local splash = _G.CreateFrame("Frame", "AuroraSplashScreen", _G.UIParent)
splash:SetPoint("CENTER")
splash:SetSize(400, 300)
splash:Hide()

do
local text = [[
Thank you for using Aurora!


Type |cff00a0ff/aurora|r at any time to access Aurora's options.

There, you can customize the addon's appearance and behavior.

You can also turn off optional features such as bags and tooltips if they conflict with your other addons.

|cffffcc00Tip:|r Use |cff00a0ff/aurora help|r to see all available commands.


Enjoy!
]]
    local title = splash:CreateFontString(nil, "ARTWORK", "GameFont_Gigantic")
    title:SetTextColor(1, 1, 1)
    title:SetPoint("TOP", 0, -25)
    title:SetText("Aurora " .. GetAddOnMetadata("Aurora", "Version"))

    local body = splash:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    body:SetPoint("TOP", title, "BOTTOM", 0, -20)
    body:SetWidth(360)
    body:SetJustifyH("CENTER")
    body:SetText(text)

    local okayButton = _G.CreateFrame("Button", nil, splash, "UIPanelButtonTemplate")
    okayButton:SetSize(128, 25)
    okayButton:SetPoint("BOTTOM", 0, 10)
    okayButton:SetText("Got it")
    okayButton:SetScript("OnClick", function()
        splash:Hide()
        _G.AuroraConfig.acknowledgedSplashScreen = true

        -- Show helpful message
        _G.print("|cff00a0ffAurora:|r Type |cffffffff/aurora|r to open configuration, or |cffffffff/aurora help|r for commands.")
    end)

    splash.okayButton = okayButton
    splash.closeButton = _G.CreateFrame("Button", nil, splash, "UIPanelCloseButton")
end

-- [[ Options UI ]]

-- these variables are loaded on init and updated only on gui.okay. Calling gui.cancel resets the saved vars to these
local old = {}
local checkboxes = {}

local function updateFrames()
    local r, g, b = Aurora.Color.frame:GetRGB()
    local a = _G.AuroraConfig.alpha

    Util.SetFrameAlpha(a)
    for i = 1, #C.frames do
        C.frames[i]:SetBackdropColor(r, g, b, a)
    end
end

-- function to copy table contents and inner table
local function copyTable(source, target)
    for key, value in next, source do
        if _G.type(value) == "table" then
            target[key] = {}
            for k, v in next, value do
                target[key][k] = value[k]
            end
        else
            target[key] = value
        end
    end
end

local function addSubCategory(parent, name)
    local header = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    header:SetText(name)

    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetSize(450, 1)
    line:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
    line:SetColorTexture(1, 1, 1, .2) -- static: not a theme color

    return header
end

local createToggleBox do
    local function toggle(self)
        _G.AuroraConfig[self.value] = self:GetChecked()
        wago:Switch(self.value, self:GetChecked())

        -- Track configuration change via Analytics module
        Analytics.trackConfigChange(self.value, self:GetChecked())
    end

    function createToggleBox(parent, value, text)
        local checkbutton = _G.CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
        checkbutton.Text:SetText(text)
        checkbutton.value = value

        _G.tinsert(checkboxes, checkbutton)

        checkbutton:SetScript("OnClick", toggle)
        return checkbutton
    end
end

local createColorSwatch do
    local info, swatch = {}
    function info.swatchFunc()
        local r, g, b = _G.ColorPickerFrame:GetColorRGB()
        local value = _G.AuroraConfig[swatch.value]
        if swatch.class then
            value = _G.CUSTOM_CLASS_COLORS[swatch.class]
            value:SetRGB(r, g, b)
            _G.CUSTOM_CLASS_COLORS:NotifyChanges()
        else
            value.r, value.g, value.b = r, g, b
            private.updateHighlightColor()
            swatch:SetBackdropColor(r, g, b)
        end
    end

    function info.cancelFunc(restore)
        local value = _G.AuroraConfig[swatch.value]
        if swatch.class then
            value = _G.CUSTOM_CLASS_COLORS[swatch.class]
        end
        value.r, value.g, value.b = restore.r, restore.g, restore.b
        swatch:SetBackdropColor(restore.r, restore.g, restore.b)

        if swatch.class then
            _G.CUSTOM_CLASS_COLORS:NotifyChanges()
        else
            private.updateHighlightColor()
        end
    end

    local function OnClick(self)
        local value = _G.AuroraConfig[self.value]
        if self.class then
            value = _G.CUSTOM_CLASS_COLORS[self.class]
        end
        swatch = self
        info.r, info.g, info.b = value.r, value.g, value.b
        _G.ColorPickerFrame:SetupColorPickerAndShow(info)
    end

    local frameColor = Aurora.Color.frame
    function createColorSwatch(parent, value, text)
        local button = _G.CreateFrame("Button", nil, parent)
        button:SetScript("OnClick", OnClick)
        button:SetSize(16, 16)
        button._auroraPaletteOptOut = true  -- color is set to class/custom colors dynamically
        Base.SetBackdrop(button, frameColor, 1)
        button.value = value

        if text then
            button:SetNormalFontObject("GameFontHighlight")
            button:SetText(text)
            button:GetFontString():SetPoint("LEFT", button, "RIGHT", 10, 0)
        end

        return button
    end
end

local createSlider do
    local numSliders = 0
    local function OnValueChanged(self, value)
        _G.AuroraConfig[self.value] = value
        wago:SetCounter(self.value, value)

        -- Track configuration change via Analytics module
        Analytics.trackConfigChange(self.value, value)

        if self.update then
            self.update()
        end
    end

    function createSlider(parent, value, text)
        numSliders = numSliders + 1
        local slider = _G.CreateFrame("Slider", "AuroraOptionsSlider"..numSliders, parent, "OptionsSliderTemplate")
        slider:SetMinMaxValues(0, 1)
        slider:SetValueStep(0.1)
        slider.value = value

        if text then
            _G[slider:GetName().."Text"]:SetText(text)
        end

        if _G.BlizzardOptionsPanel_Slider_Enable then
            _G.BlizzardOptionsPanel_Slider_Enable(slider)
        end


        slider:SetScript("OnValueChanged", OnValueChanged)
        return slider
    end
end

local createButton do
    function createButton(parent, func, text)
        local button = _G.CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        button:SetText(text)

        button:SetScript("OnClick", function(dialog)
            func()
        end)
        return button
    end
end


-- create frames/widgets
local gui = _G.CreateFrame("Frame", "AuroraOptions", _G.UIParent)
gui.name = "Aurora"

-- add the settings canvas to the addons settings
local category, _ = _G.Settings.RegisterCanvasLayoutCategory(gui, "Aurora", "Aurora")
Aurora.category = category
_G.Settings.RegisterAddOnCategory(category)

-- Create subcategory panels
local featuresPanel = _G.CreateFrame("Frame", "AuroraOptionsFeatures", _G.UIParent)
featuresPanel.name = "Features"
featuresPanel.parent = "Aurora"

local appearancePanel = _G.CreateFrame("Frame", "AuroraOptionsAppearance", _G.UIParent)
appearancePanel.name = "Appearance"
appearancePanel.parent = "Aurora"

local privacyPanel = _G.CreateFrame("Frame", "AuroraOptionsPrivacy", _G.UIParent)
privacyPanel.name = "Privacy"
privacyPanel.parent = "Aurora"

-- Register subcategories
_G.Settings.RegisterCanvasLayoutSubcategory(category, featuresPanel, "Features")
_G.Settings.RegisterCanvasLayoutSubcategory(category, appearancePanel, "Appearance")
_G.Settings.RegisterCanvasLayoutSubcategory(category, privacyPanel, "Privacy")

--[[ Main Panel ]]--
local title = gui:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -26)
title:SetText("Aurora " .. GetAddOnMetadata("Aurora", "Version"))

local mainDesc = gui:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
mainDesc:SetPoint("TOPLEFT", 16, -80)
mainDesc:SetWidth(600)
mainDesc:SetJustifyH("LEFT")
mainDesc:SetText([[
Thank you for using Aurora!

Aurora themes the default World of Warcraft interface with a sleek, modern appearance.

Use the subcategories on the left to configure:
  • |cff00a0ffFeatures|r - Enable/disable themed UI components
  • |cff00a0ffAppearance|r - Customize colors, fonts, and visual style
  • |cff00a0ffPrivacy|r - Manage analytics and data sharing

Type |cffffffff/aurora help|r in chat for available commands.
]])

local line = gui:CreateTexture(nil, "ARTWORK")
line:SetSize(600, 1)
line:SetPoint("TOPLEFT", mainDesc, "BOTTOMLEFT", 0, -30)
line:SetColorTexture(1, 1, 1, .2) -- static: not a theme color

local credits = gui:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
credits:SetText([[
Aurora by Lightsword @ Argent Dawn - EU / Haleth on wowinterface.com

Maintained by Gethe (2016-2023) and Hanshi/arnvid (2023-)
]])
credits:SetPoint("TOP", line, "BOTTOM", 0, -20)

local helpText = gui:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
helpText:SetPoint("BOTTOMLEFT", 20, 10)
helpText:SetText("|cff00a0ffTip:|r Type |cffffffff/aurora help|r for commands, or |cffffffff/aurora status|r for system info.")

--[[ Features Panel ]]--
local featuresTitle = featuresPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
featuresTitle:SetPoint("TOP", 0, -26)
featuresTitle:SetText("Features")

local featuresDesc = featuresPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
featuresDesc:SetPoint("TOPLEFT", 16, -60)
featuresDesc:SetWidth(600)
featuresDesc:SetJustifyH("LEFT")
featuresDesc:SetText("Enable or disable Aurora theming for specific UI components. Disable features that conflict with other addons.")

local bagsBox = createToggleBox(featuresPanel, "bags", "Bags")
bagsBox:SetPoint("TOPLEFT", featuresDesc, "BOTTOMLEFT", 0, -20)
bagsBox:SetScript("OnEnter", function(self)
    _G.GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    _G.GameTooltip:SetText("Bags Theming", 1, 1, 1)
    _G.GameTooltip:AddLine("Apply Aurora's theme to bag frames.", nil, nil, nil, true)
    _G.GameTooltip:AddLine("Disable if using bag addons like Bagnon or AdiBags.", 0.7, 0.7, 0.7, true)
    _G.GameTooltip:Show()
end)
bagsBox:SetScript("OnLeave", function(self)
    _G.GameTooltip:Hide()
end)

local banksBox = createToggleBox(featuresPanel, "banks", "Bank")
banksBox:SetPoint("TOPLEFT", bagsBox, "BOTTOMLEFT", 0, -15)
banksBox:SetScript("OnEnter", function(self)
    _G.GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    _G.GameTooltip:SetText("Bank Theming", 1, 1, 1)
    _G.GameTooltip:AddLine("Apply Aurora's theme to the Bank frame.", nil, nil, nil, true)
    _G.GameTooltip:AddLine("Disable if using a bank replacement addon.", 0.7, 0.7, 0.7, true)
    _G.GameTooltip:Show()
end)
banksBox:SetScript("OnLeave", function(self)
    _G.GameTooltip:Hide()
end)

local lootBox = createToggleBox(featuresPanel, "loot", "Loot")
lootBox:SetPoint("TOPLEFT", banksBox, "BOTTOMLEFT", 0, -15)

local mainmenubarBox = createToggleBox(featuresPanel, "mainmenubar", "Main Menu Bar")
mainmenubarBox:SetPoint("TOPLEFT", lootBox, "BOTTOMLEFT", 0, -15)

local chatBubbleBox = createToggleBox(featuresPanel, "chatBubbles", "Chat bubbles")
chatBubbleBox:SetPoint("TOPLEFT", mainmenubarBox, "BOTTOMLEFT", 0, -15)

local chatBubbleNamesBox = createToggleBox(featuresPanel, "chatBubbleNames", "Show names")
chatBubbleNamesBox:SetPoint("TOPLEFT", chatBubbleBox, "BOTTOMRIGHT", -3, 3)
chatBubbleNamesBox:SetSize(20, 20)

chatBubbleBox:SetScript("OnClick", function(dialog)
    if dialog:GetChecked() then
        _G.AuroraConfig.chatBubbles = true
        chatBubbleNamesBox:Enable()
    else
        _G.AuroraConfig.chatBubbles = false
        chatBubbleNamesBox:Disable()
    end
end)

local chatBox = createToggleBox(featuresPanel, "chat", "Chat Frames")
chatBox:SetPoint("TOPLEFT", chatBubbleBox, "BOTTOMLEFT", 0, -15)

local tooltipsBox = createToggleBox(featuresPanel, "tooltips", "Tooltips")
tooltipsBox:SetPoint("TOPLEFT", chatBox, "BOTTOMLEFT", 0, -15)
tooltipsBox:SetScript("OnEnter", function(self)
    _G.GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    _G.GameTooltip:SetText("Tooltip Theming", 1, 1, 1)
    _G.GameTooltip:AddLine("Apply Aurora's theme to tooltips.", nil, nil, nil, true)
    _G.GameTooltip:AddLine("Disable if using tooltip addons like TipTac.", 0.7, 0.7, 0.7, true)
    _G.GameTooltip:Show()
end)
tooltipsBox:SetScript("OnLeave", function(self)
    _G.GameTooltip:Hide()
end)

local characterSheetBox = createToggleBox(featuresPanel, "characterSheet", "Character Sheet")
characterSheetBox:SetPoint("TOPLEFT", tooltipsBox, "BOTTOMLEFT", 0, -15)
characterSheetBox:SetScript("OnEnter", function(self)
    _G.GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    _G.GameTooltip:SetText("Character Sheet Theming", 1, 1, 1)
    _G.GameTooltip:AddLine("Apply Aurora's theme to the character sheet.", nil, nil, nil, true)
    _G.GameTooltip:AddLine("Disable when using addons like ChonkyCharacterSheet that replace the character sheet.", 0.7, 0.7, 0.7, true)
    _G.GameTooltip:Show()
end)
characterSheetBox:SetScript("OnLeave", function(self)
    _G.GameTooltip:Hide()
end)

local objectiveTrackerBox = createToggleBox(featuresPanel, "objectiveTracker", "Objective Tracker")
objectiveTrackerBox:SetPoint("TOPLEFT", characterSheetBox, "BOTTOMLEFT", 0, -15)
objectiveTrackerBox:SetScript("OnEnter", function(self)
    _G.GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    _G.GameTooltip:SetText("Objective Tracker Theming", 1, 1, 1)
    _G.GameTooltip:AddLine("Apply Aurora's theme to the objective/quest tracker.", nil, nil, nil, true)
    _G.GameTooltip:AddLine("Disabling restores Blizzard's default tracker appearance.", 0.7, 0.7, 0.7, true)
    _G.GameTooltip:Show()
end)
objectiveTrackerBox:SetScript("OnLeave", function(self)
    _G.GameTooltip:Hide()
end)

local featuresNote = featuresPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
featuresNote:SetPoint("TOPLEFT", objectiveTrackerBox, "BOTTOMLEFT", 0, -30)
featuresNote:SetWidth(600)
featuresNote:SetJustifyH("LEFT")
featuresNote:SetTextColor(1, 0.82, 0)
featuresNote:SetText("Note: Changes to these settings require a UI reload to take effect.")

local featuresReloadButton = createButton(featuresPanel, _G.C_UI.Reload, _G.RELOADUI)
featuresReloadButton:SetPoint("TOPLEFT", featuresNote, "BOTTOMLEFT", 0, -15)
featuresReloadButton:SetWidth(120)

--[[ Appearance Panel ]]--
local appearanceTitle = appearancePanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
appearanceTitle:SetPoint("TOP", 0, -26)
appearanceTitle:SetText("Appearance")

-- Scroll frame to accommodate all appearance options
local appearanceScroll = _G.CreateFrame("ScrollFrame", "AuroraAppearanceScroll", appearancePanel, "UIPanelScrollFrameTemplate")
appearanceScroll:SetPoint("TOPLEFT", 0, -50)
appearanceScroll:SetPoint("BOTTOMRIGHT", -26, 10)

local appearanceChild = _G.CreateFrame("Frame", "AuroraAppearanceScrollChild", appearanceScroll)
appearanceChild:SetWidth(600)
appearanceScroll:SetScrollChild(appearanceChild)

local appearanceDesc = appearanceChild:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
appearanceDesc:SetPoint("TOPLEFT", 16, 0)
appearanceDesc:SetWidth(600)
appearanceDesc:SetJustifyH("LEFT")
appearanceDesc:SetText("Customize the visual appearance of Aurora's themed interface.")

local fontBox = createToggleBox(appearanceChild, "fonts", "Replace default game fonts")
fontBox:SetPoint("TOPLEFT", appearanceDesc, "BOTTOMLEFT", 0, -20)

local buttonsHaveGradientBox = createToggleBox(appearanceChild, "buttonsHaveGradient", "Gradient button style")
buttonsHaveGradientBox:SetPoint("TOPLEFT", fontBox, "BOTTOMLEFT", 0, -15)

local talentArtBgBox = createToggleBox(appearanceChild, "talentArtBackground", "Talent artistic background")
talentArtBgBox:SetPoint("TOPLEFT", buttonsHaveGradientBox, "BOTTOMLEFT", 0, -15)
talentArtBgBox:SetScript("OnEnter", function(self)
    _G.GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    _G.GameTooltip:SetText("Talent Artistic Background", 1, 1, 1)
    _G.GameTooltip:AddLine("Show Blizzard's class-specific artwork behind the talent tree.", nil, nil, nil, true)
    _G.GameTooltip:AddLine("Requires UI reload to take effect.", 0.7, 0.7, 0.7, true)
    _G.GameTooltip:Show()
end)
talentArtBgBox:SetScript("OnLeave", function(self)
    _G.GameTooltip:Hide()
end)

local heroTalentsAnchorBox = createToggleBox(appearanceChild, "heroTalentsCustomAnchor", "Hero talents custom position")
heroTalentsAnchorBox:SetPoint("TOPLEFT", talentArtBgBox, "BOTTOMLEFT", 0, -15)
heroTalentsAnchorBox:SetScript("OnEnter", function(self)
    _G.GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    _G.GameTooltip:SetText("Hero Talents Custom Position", 1, 1, 1)
    _G.GameTooltip:AddLine("Use Aurora's alternate anchor for HeroTalentsContainer inside the Talents frame.", nil, nil, nil, true)
    _G.GameTooltip:AddLine("Disabled keeps Blizzard's default position.", 0.7, 0.7, 0.7, true)
    _G.GameTooltip:AddLine("Requires UI reload to take effect.", 0.7, 0.7, 0.7, true)
    _G.GameTooltip:Show()
end)
heroTalentsAnchorBox:SetScript("OnLeave", function(self)
    _G.GameTooltip:Hide()
end)

local heroTalentsAnchorPresets = {
    { key = "default", label = "Balanced (50, -4)" },
    { key = "topcenter", label = "Top Centered (0, -4)" },
    { key = "centercenter", label = "Center Centered (0, 0)" },
    { key = "left", label = "Shift Left (30, -4)" },
    { key = "lower", label = "Lowered (50, -28)" },
    { key = "compact", label = "Compact (38, -18)" },
}

local heroTalentsAnchorPresetLabel = appearanceChild:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
heroTalentsAnchorPresetLabel:SetPoint("TOPLEFT", heroTalentsAnchorBox, "BOTTOMLEFT", 20, -8)
heroTalentsAnchorPresetLabel:SetText("Hero talents anchor preset")

local heroTalentsAnchorPresetDropdown = _G.CreateFrame("Frame", "AuroraHeroTalentsAnchorPresetDropdown", appearanceChild, "UIDropDownMenuTemplate")
heroTalentsAnchorPresetDropdown:SetPoint("TOPLEFT", heroTalentsAnchorPresetLabel, "BOTTOMLEFT", -16, -4)
_G.UIDropDownMenu_SetWidth(heroTalentsAnchorPresetDropdown, 210)

_G.UIDropDownMenu_Initialize(heroTalentsAnchorPresetDropdown, function(self, level)
    local currentPreset = (_G.AuroraConfig and _G.AuroraConfig.heroTalentsAnchorPreset) or "default"
    for _, preset in ipairs(heroTalentsAnchorPresets) do
        local info = _G.UIDropDownMenu_CreateInfo()
        info.text = preset.label
        info.value = preset.key
        info.checked = (currentPreset == preset.key)
        info.disabled = not (_G.AuroraConfig and _G.AuroraConfig.heroTalentsCustomAnchor)
        info.func = function(buttonSelf)
            if _G.AuroraConfig then
                _G.AuroraConfig.heroTalentsAnchorPreset = buttonSelf.value
            end
            _G.UIDropDownMenu_SetSelectedValue(heroTalentsAnchorPresetDropdown, buttonSelf.value)
        end
        _G.UIDropDownMenu_AddButton(info, level)
    end
end)

local alphaSlider = createSlider(appearanceChild, "alpha", "Backdrop opacity *")
alphaSlider:SetPoint("TOPLEFT", heroTalentsAnchorPresetDropdown, "BOTTOMLEFT", 16, -25)
alphaSlider.update = updateFrames
alphaSlider:SetScript("OnEnter", function(self)
    _G.GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    _G.GameTooltip:SetText("Backdrop Opacity", 1, 1, 1)
    _G.GameTooltip:AddLine("Control the transparency of themed UI elements.", nil, nil, nil, true)
    _G.GameTooltip:AddLine("Lower values make frames more transparent.", 0.7, 0.7, 0.7, true)
    _G.GameTooltip:AddLine("Changes apply immediately without reload.", 0.5, 1, 0.5, true)
    _G.GameTooltip:Show()
end)
alphaSlider:SetScript("OnLeave", function(self)
    _G.GameTooltip:Hide()
end)

local colorHeader = addSubCategory(appearanceChild, "Colors")
colorHeader:SetPoint("TOPLEFT", alphaSlider, "BOTTOMLEFT", 0, -50)

-- 7.1: Ordered mode-name list for deterministic radio button order
local colorModeOrder = {"Normal", "HDR", "Deuteranopia", "Protanopia", "Tritanopia"}

-- 7.2: Color mode radio button group
local Color = Aurora.Color
local colorModeRadios = {}

local function UpdateColorModeRadios()
    local current = _G.AuroraConfig and _G.AuroraConfig.colorMode or "Normal"
    for _, radio in ipairs(colorModeRadios) do
        radio:SetChecked(radio.modeKey == current)
    end
end

local function OnColorModeRadioClick(self)
    Color.SetMode(self.modeKey)
    UpdateColorModeRadios()
end

local lastModeAnchor = colorHeader
for i, modeName in ipairs(colorModeOrder) do
    local radio = _G.CreateFrame("CheckButton", "AuroraColorMode" .. i, appearanceChild, "UIRadioButtonTemplate")
    radio:SetPoint("TOPLEFT", lastModeAnchor, "BOTTOMLEFT", i == 1 and 10 or 0, i == 1 and -15 or -8)
    radio.modeKey = modeName
    radio:SetScript("OnClick", OnColorModeRadioClick)

    local label = radio:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("LEFT", radio, "RIGHT", 5, 0)
    label:SetText(modeName)

    _G.tinsert(colorModeRadios, radio)
    lastModeAnchor = radio
end

-- 7.3: Info note shown when colorMode == "HDR" and customHighlight.enabled == true
local hdrInfoNote = appearanceChild:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
hdrInfoNote:SetPoint("TOPLEFT", lastModeAnchor, "BOTTOMLEFT", 22, -4)
hdrInfoNote:SetWidth(500)
hdrInfoNote:SetJustifyH("LEFT")
hdrInfoNote:SetTextColor(1, 0.82, 0)
hdrInfoNote:SetText("HDR class color boost is inactive while a custom highlight color is set.")
hdrInfoNote:Hide()

-- 7.4: Update info note visibility based on current config state
local function UpdateHdrInfoNote()
    local config = _G.AuroraConfig
    if config and config.colorMode == "HDR"
        and config.customHighlight and config.customHighlight.enabled then
        hdrInfoNote:Show()
    else
        hdrInfoNote:Hide()
    end
end

-- Wire into CONFIG_CHANGED via Integration event system
Integration.RegisterEventHandler("CONFIG_CHANGED", "GUI_ColorMode", function(key, value)
    if key == "colorMode" then
        UpdateColorModeRadios()
        UpdateHdrInfoNote()
    end
end)

local highlightBox = createToggleBox(appearanceChild, "customHighlight", "Custom highlight color")
highlightBox:SetPoint("TOPLEFT", lastModeAnchor, "BOTTOMLEFT", -10, -20)

local highlightButton = createColorSwatch(appearanceChild, "customHighlight")
highlightButton:SetPoint("LEFT", highlightBox, "RIGHT", 150, 0)

highlightBox:SetScript("OnClick", function(dialog)
    local isChecked = dialog:GetChecked()
    _G.AuroraConfig.customHighlight.enabled = isChecked
    wago:Switch(dialog.value, isChecked)

    -- Track configuration change via Analytics module
    Analytics.trackConfigChange(dialog.value, _G.AuroraConfig.customHighlight)

    if isChecked then
        highlightButton:Enable()
        highlightButton:SetAlpha(1)
    else
        highlightButton:Disable()
        highlightButton:SetAlpha(.7)
    end
    private.updateHighlightColor()
    UpdateHdrInfoNote()
end)

local classColorsHeader = addSubCategory(appearanceChild, "Class Colors")
classColorsHeader:SetPoint("TOPLEFT", highlightBox, "BOTTOMLEFT", -10, -50)

local classColors = {}
for i, classToken in ipairs(_G.CLASS_SORT_ORDER) do
    local classColor = createColorSwatch(appearanceChild, "customClassColors", classToken)
    classColor.class = classToken
    classColors[i] = classColor

    if i == 1 then
        classColor:SetPoint("TOPLEFT", classColorsHeader, "BOTTOMLEFT", 10, -20)
    elseif i % 4 == 1 then
        classColor:SetPoint("TOPLEFT", classColors[i - 4], "BOTTOMLEFT", 0, -10)
    else
        classColor:SetPoint("LEFT", classColors[i - 1], "RIGHT", 120, 0)
    end
end

local resetButton = createButton(appearanceChild, function()
    private.classColorsReset(_G.CUSTOM_CLASS_COLORS, _G.RAID_CLASS_COLORS)
end, _G.RESET)
-- Position reset button below the last row of class colors
local lastRowStart = classColors[#classColors - (#classColors % 4)]
resetButton:SetPoint("TOPLEFT", lastRowStart, "BOTTOMLEFT", 0, -15)
resetButton:SetWidth(100)

local appearanceNote = appearanceChild:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
appearanceNote:SetPoint("TOPLEFT", resetButton, "BOTTOMLEFT", 0, -20)
appearanceNote:SetWidth(600)
appearanceNote:SetJustifyH("LEFT")
appearanceNote:SetText("* Does not require a Reload UI.")

-- Set scroll child height to fit all content
appearanceChild:SetHeight(900)

--[[ Privacy Panel ]]--
local privacyTitle = privacyPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
privacyTitle:SetPoint("TOP", 0, -26)
privacyTitle:SetText("Privacy & Analytics")

local privacyDesc = privacyPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
privacyDesc:SetPoint("TOPLEFT", 16, -60)
privacyDesc:SetWidth(600)
privacyDesc:SetJustifyH("LEFT")
privacyDesc:SetText("Manage data collection and analytics preferences.")

local analyticsHeader = addSubCategory(privacyPanel, "Wago Analytics")
analyticsHeader:SetPoint("TOPLEFT", privacyDesc, "BOTTOMLEFT", 0, -20)

local analyticsBox = createToggleBox(privacyPanel, "hasAnalytics", "Share anonymous usage data with Wago")
analyticsBox:SetPoint("TOPLEFT", analyticsHeader, "BOTTOMLEFT", 10, -20)

analyticsBox:SetScript("OnClick", function(dialog)
    local isChecked = dialog:GetChecked()
    _G.AuroraConfig.hasAnalytics = isChecked

    -- Enable or disable analytics based on user choice
    if isChecked then
        Analytics.enable(_G.AuroraConfig)
    else
        Analytics.disable(_G.AuroraConfig)
    end
end)

local analyticsHelp = privacyPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
analyticsHelp:SetPoint("TOPLEFT", analyticsBox, "BOTTOMLEFT", 25, -5)
analyticsHelp:SetWidth(550)
analyticsHelp:SetJustifyH("LEFT")
analyticsHelp:SetText([[Aurora uses Wago Analytics to collect anonymous usage statistics to help improve the addon.

|cff00ff00What is collected:|r
  • Which Aurora features you enable/disable
  • UI customization preferences (colors, opacity, etc.)
  • Addon version and game version

|cffff8800What is NOT collected:|r
  • Character names, realm names, or account information
  • Chat messages or any personal data
  • Gameplay data or combat logs

Data is sent to Wago's analytics service and helps the developers understand which features are most used and identify potential issues. You can opt out at any time by unchecking the box above.]])

-- Compatibility status display
local compatHeader = addSubCategory(privacyPanel, "Compatibility Status")
compatHeader:SetPoint("TOPLEFT", analyticsHelp, "BOTTOMLEFT", -10, -30)

local compatStatus = privacyPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
compatStatus:SetPoint("TOPLEFT", compatHeader, "BOTTOMLEFT", 10, -15)
compatStatus:SetWidth(550)
compatStatus:SetJustifyH("LEFT")

local function updateCompatibilityStatus()
    local status = Compatibility.getStatus()
    if status.hasIssues then
        local text = ""
        if #status.conflicts > 0 then
            text = text .. "|cffffcc00" .. #status.conflicts .. " potential conflict(s) detected.|r "
        end
        if #status.missingDependencies > 0 then
            text = text .. "|cffffcc00" .. #status.missingDependencies .. " missing dependenc(ies).|r "
        end
        if status.safeMode then
            text = text .. "\n|cffff0000Safe mode is active.|r"
        end
        compatStatus:SetText(text)
    else
        compatStatus:SetText("|cff00ff00No compatibility issues detected.|r")
    end
end

local privacyLine = privacyPanel:CreateTexture(nil, "ARTWORK")
privacyLine:SetSize(600, 1)
privacyLine:SetPoint("TOPLEFT", compatStatus, "BOTTOMLEFT", 0, -30)
privacyLine:SetColorTexture(1, 1, 1, .2) -- static: not a theme color

local privacyReloadButton = createButton(privacyPanel, _G.C_UI.Reload, _G.RELOADUI)
privacyReloadButton:SetPoint("TOPLEFT", privacyLine, "BOTTOMLEFT", 0, -20)
privacyReloadButton:SetWidth(120)
privacyReloadButton:SetScript("OnEnter", function(self)
    _G.GameTooltip:SetOwner(self, "ANCHOR_TOP")
    _G.GameTooltip:SetText("Reload UI", 1, 1, 1)
    _G.GameTooltip:AddLine("Reload the user interface to apply changes that require it.", nil, nil, nil, true)
    _G.GameTooltip:AddLine("Most Aurora settings apply immediately.", 0.7, 0.7, 0.7, true)
    _G.GameTooltip:Show()
end)
privacyReloadButton:SetScript("OnLeave", function(self)
    _G.GameTooltip:Hide()
end)

--[[ Performance Panel ]]--
local performancePanel = _G.CreateFrame("Frame", "AuroraOptionsPerformance", _G.UIParent)
performancePanel.name = "Performance"
performancePanel.parent = "Aurora"
_G.Settings.RegisterCanvasLayoutSubcategory(category, performancePanel, "Performance")

local perfTitle = performancePanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
perfTitle:SetPoint("TOP", 0, -26)
perfTitle:SetText("Performance")

local perfDesc = performancePanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
perfDesc:SetPoint("TOPLEFT", 16, -60)
perfDesc:SetWidth(600)
perfDesc:SetJustifyH("LEFT")
perfDesc:SetText("Configure garbage collection behavior to reduce microstutter. Changes apply immediately.")

local gcHeader = addSubCategory(performancePanel, "Garbage Collection Mode")
gcHeader:SetPoint("TOPLEFT", perfDesc, "BOTTOMLEFT", 0, -20)

local gcModes = {
    { key = "smooth",  label = "Smooth (recommended)", desc = "Frequent small GC passes. Reduces large stutter spikes at the cost of ~1-2% average CPU." },
    { key = "default", label = "Default", desc = "Standard Lua GC behavior. May cause occasional 30-80ms pauses at high addon memory." },
    { key = "combat",  label = "Combat Pause", desc = "Disables GC during combat entirely. Zero in-combat GC stutter, but memory grows unchecked. Risky above 500MB." },
}

local gcRadioButtons = {}
local function UpdateGCRadios()
    local current = _G.AuroraConfig and _G.AuroraConfig.gcMode or "smooth"
    for _, radio in ipairs(gcRadioButtons) do
        radio:SetChecked(radio.gcKey == current)
    end
end

local function OnGCRadioClick(self)
    if _G.AuroraConfig then
        _G.AuroraConfig.gcMode = self.gcKey
    end
    if _G.Aurora and _G.Aurora.ApplyGCMode then
        _G.Aurora.ApplyGCMode(self.gcKey)
    end
    UpdateGCRadios()
end

local lastAnchor = gcHeader
for i, mode in ipairs(gcModes) do
    local radio = _G.CreateFrame("CheckButton", "AuroraGCMode" .. i, performancePanel, "UIRadioButtonTemplate")
    radio:SetPoint("TOPLEFT", lastAnchor, "BOTTOMLEFT", i == 1 and 10 or 0, i == 1 and -15 or -8)
    radio.gcKey = mode.key
    radio:SetScript("OnClick", OnGCRadioClick)

    local label = radio:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("LEFT", radio, "RIGHT", 5, 0)
    label:SetText(mode.label)

    local desc = performancePanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", radio, "BOTTOMLEFT", 22, -2)
    desc:SetWidth(550)
    desc:SetJustifyH("LEFT")
    desc:SetTextColor(0.7, 0.7, 0.7)
    desc:SetText(mode.desc)

    _G.tinsert(gcRadioButtons, radio)
    lastAnchor = desc
end

local gcMemInfo = performancePanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
gcMemInfo:SetPoint("TOPLEFT", lastAnchor, "BOTTOMLEFT", -32, -20)
gcMemInfo:SetWidth(550)
gcMemInfo:SetJustifyH("LEFT")

local function UpdateGCMemInfo()
    local mem = _G.collectgarbage("count")
    gcMemInfo:SetText(("Current addon memory: |cffffffff%.1f MB|r"):format(mem / 1024))
end

local gcNote = performancePanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
gcNote:SetPoint("TOPLEFT", gcMemInfo, "BOTTOMLEFT", 0, -10)
gcNote:SetWidth(550)
gcNote:SetJustifyH("LEFT")
gcNote:SetTextColor(1, 0.82, 0)
gcNote:SetText("Note: If you use many addons (500MB+), 'Smooth' is recommended. 'Combat Pause' can cause a large stutter when combat ends as all deferred garbage is collected at once. Changes apply immediately without reload.")

performancePanel.refresh = function()
    UpdateGCRadios()
    UpdateGCMemInfo()
end

--[[ Refresh and callbacks ]]--
gui.refresh = function()
    --print("gui refresh")

    -- Safely refresh with error handling
    local success, err = pcall(function()
        alphaSlider:SetValue(_G.AuroraConfig.alpha)

        local currentHeroPreset = _G.AuroraConfig.heroTalentsAnchorPreset or "default"
        _G.UIDropDownMenu_SetSelectedValue(heroTalentsAnchorPresetDropdown, currentHeroPreset)
        _G.UIDropDownMenu_SetText(heroTalentsAnchorPresetDropdown, nil)
        for _, preset in ipairs(heroTalentsAnchorPresets) do
            if preset.key == currentHeroPreset then
                _G.UIDropDownMenu_SetText(heroTalentsAnchorPresetDropdown, preset.label)
                break
            end
        end

        local presetEnabled = _G.AuroraConfig.heroTalentsCustomAnchor == true
        heroTalentsAnchorPresetDropdown:SetAlpha(presetEnabled and 1 or 0.6)
        heroTalentsAnchorPresetLabel:SetAlpha(presetEnabled and 1 or 0.6)

        for i = 1, #checkboxes do
            checkboxes[i]:SetChecked(_G.AuroraConfig[checkboxes[i].value] == true)
        end

        local customHighlight = _G.AuroraConfig.customHighlight
        highlightBox:SetChecked(_G.AuroraConfig.customHighlight.enabled == true)
        highlightButton:SetBackdropColor(customHighlight.r, customHighlight.g, customHighlight.b)
        if not highlightBox:GetChecked() then
            highlightButton:Disable()
            highlightButton:SetAlpha(.7)
        end

        for i, classColor in ipairs(classColors) do
            local color = _G.AuroraConfig.customClassColors[classColor.class]
            local className = _G.LOCALIZED_CLASS_NAMES_MALE[classColor.class]
            classColor:SetFormattedText("|c%s%s|r", color.colorStr, className)
            classColor:SetBackdropColor(color.r, color.g, color.b)
        end

        -- Update color mode radios and HDR info note
        UpdateColorModeRadios()
        UpdateHdrInfoNote()

        -- Update compatibility status
        updateCompatibilityStatus()

        -- Update performance panel
        UpdateGCRadios()
        UpdateGCMemInfo()
    end)

    if not success then
        _G.print("|cffff0000Aurora:|r Failed to refresh configuration interface.")
        _G.print("|cff00a0ffError:|r " .. tostring(err))

        -- Log error if integration is available
        if Integration then
            Integration.HandleError("GUI", err, {phase = "refresh", recoverable = false})
        end
    end
end

-- Copy refresh to all panels
featuresPanel.refresh = gui.refresh
appearancePanel.refresh = gui.refresh
privacyPanel.refresh = gui.refresh

gui.okay = function()
    copyTable(_G.AuroraConfig, old)
end

gui.cancel = function()
    copyTable(old, _G.AuroraConfig)

    updateFrames()
    gui.refresh()
end

gui.default = function()
    -- Use Config.reset to properly reset configuration with error handling
    local success, err = pcall(function()
        Config.reset(true) -- preserve splash screen acknowledgment

        updateFrames()
        gui.refresh()
    end)

    if not success then
        _G.print("|cffff0000Aurora:|r Failed to reset configuration to defaults.")
        _G.print("|cff00a0ffError:|r " .. tostring(err))
        _G.print("|cff00a0ffTip:|r Try reloading your UI with /reload")

        -- Log error if integration is available
        if Integration then
            Integration.HandleError("GUI", err, {phase = "reset", recoverable = true})
        end
    else
        _G.print("|cff00a0ffAurora:|r Configuration reset to defaults.")
    end
end

function private.SetupGUI()
    -- Validate configuration before setting up GUI
    if _G.AuroraConfig then
        local valid, errors = Config.validateConfig(_G.AuroraConfig)
        if not valid then
            _G.print("|cffffcc00Aurora:|r Configuration validation found issues:")
            for _, err in pairs(errors) do
                _G.print("  |cffff0000-|r " .. err.error)
            end
            _G.print("|cff00a0ffTip:|r Configuration will be sanitized automatically.")

            -- Sanitize invalid values
            for _, err in pairs(errors) do
                _G.AuroraConfig[err.key] = Config.sanitizeValue(err.key, _G.AuroraConfig[err.key])
            end
        end
    end

    -- fill 'old' table
    copyTable(_G.AuroraConfig, old)

    if not splash._auroraSkinned then
        Base.SetBackdrop(splash)
        local r, g, b = Aurora.Color.frame:GetRGB()
        splash:SetBackdropColor(r, g, b, 0.9)
        Skin.UIPanelButtonTemplate(splash.okayButton)
        Skin.UIPanelCloseButton(splash.closeButton)
        splash._auroraSkinned = true
    end

    Skin.OptionsSliderTemplate(alphaSlider)
    for i = 1, #checkboxes do
        Skin.UICheckButtonTemplate(checkboxes[i])
    end

    Skin.UIPanelButtonTemplate(featuresReloadButton)
    Skin.UIPanelButtonTemplate(privacyReloadButton)
    Skin.UIPanelButtonTemplate(resetButton)

    gui.refresh()
end

-- easy slash command
private.commands = {}
_G.SLASH_AURORA1 = "/aurora"
_G.SlashCmdList.AURORA = function(msg, editBox)
    private.debug("/aurora", msg)

    -- Check for combat lockdown with user-friendly message
    if _G.InCombatLockdown() then
        _G.print("|cffff0000Aurora:|r Cannot open configuration during combat.")
        _G.print("|cff00a0ffTip:|r Try again after leaving combat.")
        return
    end

    if msg == "debug" then
        local debugger = private.debugger
        if debugger then
            if debugger:Lines() == 0 then
                debugger:AddLine("Nothing to report.")
                debugger:Display()
                debugger:Clear()
                return
            end
            debugger:Display()
        else
            _G.print("|cffff0000Aurora:|r LibTextDump is not available.")
            _G.print("|cff00a0ffTip:|r Install LibTextDump to enable debug output.")
        end
    elseif msg == "help" then
        _G.print("|cff00a0ffAurora Commands:|r")
        _G.print("  |cffffffff/aurora|r - Open configuration panel")
        _G.print("  |cffffffff/aurora help|r - Show this help message")
        _G.print("  |cffffffff/aurora debug|r - Display debug information")
        _G.print("  |cffffffff/aurora status|r - Show system status")
        _G.print("  |cffffffff/aurora reset|r - Reset configuration to defaults and reload UI")
    elseif msg == "reset" then
        -- Reset configuration to defaults and reload UI
        _G.print("|cff00a0ffAurora:|r Resetting configuration to defaults...")
        Config.reset(false) -- Don't preserve splash screen acknowledgment
        _G.print("|cff00ff00Aurora:|r Configuration reset complete.")
        _G.print("|cffffcc00Please type |r|cffffffff/reload|r|cffffcc00 to apply changes.|r")
    elseif msg == "status" then
        -- Display system status
        _G.print("|cff00a0ffAurora System Status:|r")

        -- Configuration status
        if _G.AuroraConfig then
            _G.print("  |cff00ff00Configuration:|r Loaded")
            local needsRecovery, reason = Config.needsRecovery(_G.AuroraConfig)
            if needsRecovery then
                _G.print("    |cffffcc00Warning:|r " .. reason)
            end
        else
            _G.print("  |cffff0000Configuration:|r Not loaded")
        end

        -- Compatibility status
        if Compatibility then
            local status = Compatibility.getStatus()
            if status.hasIssues then
                _G.print("  |cffffcc00Compatibility:|r " .. #status.conflicts .. " conflict(s), " .. #status.missingDependencies .. " missing dependenc(ies)")
            else
                _G.print("  |cff00ff00Compatibility:|r No issues")
            end
        end

        -- Analytics status
        if Analytics then
            if Analytics.hasConsent() then
                _G.print("  |cff00ff00Analytics:|r Enabled (with consent)")
            else
                _G.print("  |cffccccccAnalytics:|r Disabled")
            end
        end

        -- Integration status
        if Integration then
            local intStatus = Integration.GetStatus()
            _G.print("  |cff00ff00Integration:|r " .. intStatus.errorCount .. " error(s) logged")
        end
    elseif private.commands[msg] then
        private.commands[msg]()
    elseif msg == "" then
        -- Open settings panel with error handling
        local success, err = pcall(function()
            _G.Settings.OpenToCategory(Aurora.category:GetID())
        end)

        if not success then
            _G.print("|cffff0000Aurora:|r Failed to open configuration panel.")
            _G.print("|cff00a0ffError:|r " .. tostring(err))
            _G.print("|cff00a0ffTip:|r Try reloading your UI with /reload")
        end
    else
        -- Invalid command with helpful suggestion
        _G.print("|cffff0000Aurora:|r Unknown command '" .. msg .. "'.")
        _G.print("|cff00a0ffTip:|r Type |cffffffff/aurora help|r for available commands.")
    end
end
