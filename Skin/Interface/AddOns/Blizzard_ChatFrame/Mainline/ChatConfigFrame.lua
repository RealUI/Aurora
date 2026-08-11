local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals _G ipairs type select

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

do --[[ FrameXML\ChatConfigFrame.lua ]]
    function Hook.ChatConfig_CreateCheckboxes(frame, checkBoxTable, checkBoxTemplate, title)
        local checkBoxNameString = frame:GetName().."Checkbox"
        for index, value in ipairs(checkBoxTable) do
            local checkBoxName = checkBoxNameString..index
            Util.SkinOnce(_G[checkBoxName], Skin[checkBoxTemplate])
        end
    end
    function Hook.ChatConfig_CreateTieredCheckboxes(frame, checkBoxTable, checkBoxTemplate, subCheckBoxTemplate, columns, spacing)
        local checkBoxNameString = frame:GetName().."Checkbox"

        for index, value in ipairs(checkBoxTable) do
            local checkBoxName = checkBoxNameString..index
            Skin[checkBoxTemplate](_G[checkBoxName])

            if value.subTypes then
                local subCheckBoxNameString = checkBoxName.."_"
                for i, v in ipairs(value.subTypes) do
                    Skin[subCheckBoxTemplate](_G[subCheckBoxNameString..i])
                end
            end
        end
    end
    function Hook.ChatConfig_CreateColorSwatches(frame, swatchTable, swatchTemplate, title)
        local nameString = frame:GetName().."Swatch"

        -- Guard the template lookup: 12.1 introduced
        -- ChatConfigAdditionalColorSwatchTemplate (Discord colors) — an
        -- unknown template here must degrade to stock, not nil-call.
        local skinFunc = Skin[swatchTemplate]
        if not skinFunc then return end
        for index, value in ipairs(swatchTable) do
            local swatchName = nameString..index
            skinFunc(_G[swatchName])
        end
    end
end

do --[[ FrameXML\ChatConfigFrame.xml ]]
    Skin.ConfigCategoryButtonTemplate = private.nop
    function Skin.ConfigFilterButtonTemplate(Button)
        Skin.ConfigCategoryButtonTemplate(Button)
    end
    function Skin.ChatConfigBoxTemplate(Frame)
        Util.HideNineSlice(Frame)
    end
    function Skin.ChatConfigBorderBoxTemplate(Frame)
        Skin.TooltipBorderBackdropTemplate(Frame)
        Frame.NineSlice:SetBackdropBorderColor(Color.button)
        Frame.NineSlice:SetBackdropOption("offsets", {
            left = 3,
            right = 2,
            top = 2,
            bottom = 2,
        })
    end
    function Skin.ChatConfigBoxWithHeaderTemplate(Frame)
        Skin.ChatConfigBoxTemplate(Frame)
    end
    function Skin.WideChatConfigBoxWithHeaderAndClassColorsTemplate(Frame)
        Skin.ChatConfigBoxWithHeaderTemplate(Frame)
    end

    function Skin.ChatConfigBaseCheckButtonTemplate(CheckButton)
        Skin.UICheckButtonTemplate(CheckButton) -- BlizzWTF: Doesn't use the template
    end
    function Skin.ChatConfigCheckButtonTemplate(CheckButton)
        Skin.ChatConfigBaseCheckButtonTemplate(CheckButton)
    end
    function Skin.ChatConfigSmallCheckButtonTemplate(CheckButton)
        Skin.ChatConfigBaseCheckButtonTemplate(CheckButton)
    end

    function Skin.ChatConfigCheckboxTemplate(Frame)
        Skin.ChatConfigBorderBoxTemplate(Frame)
        Skin.ChatConfigCheckButtonTemplate(Frame.CheckButton)
    end
    function Skin.ChatConfigCheckboxSmallTemplate(Frame)
        Skin.ChatConfigCheckboxTemplate(Frame)
    end
    function Skin.ChatConfigCheckboxWithSwatchTemplate(Frame)
        Skin.ChatConfigCheckboxTemplate(Frame)
        Skin.ColorSwatchTemplate(Frame.ColorSwatch)
    end
    function Skin.ChatConfigWideCheckboxWithSwatchTemplate(Frame)
        Skin.ChatConfigCheckboxWithSwatchTemplate(Frame)
    end
    function Skin.MovableChatConfigWideCheckboxWithSwatchTemplate(Frame)
        Skin.ChatConfigWideCheckboxWithSwatchTemplate(Frame)
        Frame.ArtOverlay.GrayedOut:SetPoint("TOPLEFT")
    end
    function Skin.ChatConfigSwatchTemplate(Frame)
        Skin.ChatConfigBorderBoxTemplate(Frame)
        Skin.ColorSwatchTemplate(_G[Frame:GetName().."ColorSwatch"])
    end
    function Skin.ChatConfigAdditionalColorSwatchTemplate(Frame)
        -- 12.1 Discord colors box: structurally identical to
        -- ChatConfigSwatchTemplate (only the OnClick handler differs)
        Skin.ChatConfigSwatchTemplate(Frame)
    end
    function Skin.ChatConfigTabTemplate(Button)
        Button.Left:Hide()
        Button.Right:Hide()
        Button.Middle:Hide()

        Button.Text:SetHeight(0)
        Button.Text:SetPoint("LEFT", 0, -5)
        Button.Text:SetPoint("RIGHT", 0, -5)
        Button:GetHighlightTexture():Hide()
    end
    function Skin.ChatWindowTab(Button)
        Skin.ChatTabArtTemplate(Button)
    end


    -- not a template
    function Skin.ChatConfigMoveFilter(Button, direction)
        Skin.FrameTypeButton(Button)
        Button:SetBackdropOption("offsets", {
            left = 6,
            right = 6,
            top = 7,
            bottom = 7,
        })

        local bg = Button:GetBackdropTexture("bg")
        local arrow = Button:CreateTexture(nil, "ARTWORK")
        arrow:SetPoint("TOPLEFT", bg, 2, -4)
        arrow:SetSize(10, 5)

        Base.SetTexture(arrow, "arrow"..direction)
        Button._auroraTextures = {arrow}
    end
end

function private.FrameXML.ChatConfigFrame()
    _G.hooksecurefunc("ChatConfig_CreateCheckboxes", Hook.ChatConfig_CreateCheckboxes)
    _G.hooksecurefunc("ChatConfig_CreateTieredCheckboxes", Hook.ChatConfig_CreateTieredCheckboxes)
    _G.hooksecurefunc("ChatConfig_CreateColorSwatches", Hook.ChatConfig_CreateColorSwatches)

    local ChatConfigFrame = _G.ChatConfigFrame
    Skin.DialogBorderTemplate(ChatConfigFrame.Border)
    Skin.DialogHeaderTemplate(ChatConfigFrame.Header)

    Skin.ChatConfigBoxTemplate(_G.ChatConfigCategoryFrame)
    Skin.ConfigCategoryButtonTemplate(_G.ChatConfigCategoryFrameButton1)
    Skin.ConfigCategoryButtonTemplate(_G.ChatConfigCategoryFrameButton2)
    Skin.ConfigCategoryButtonTemplate(_G.ChatConfigCategoryFrameButton3)
    Skin.ConfigCategoryButtonTemplate(_G.ChatConfigCategoryFrameButton4)
    Skin.ConfigCategoryButtonTemplate(_G.ChatConfigCategoryFrameButton5)
    Skin.ConfigCategoryButtonTemplate(_G.ChatConfigCategoryFrameButton6)
    Skin.ConfigCategoryButtonTemplate(_G.ChatConfigCategoryFrameButton7)
    Util.WrapPoolAcquire(ChatConfigFrame.ChatTabManager and ChatConfigFrame.ChatTabManager.tabPool, "ChatWindowTab")
    Skin.ChatConfigBoxTemplate(_G.ChatConfigBackgroundFrame)

    local divider = _G.ChatConfigFrame:CreateTexture()
    divider:SetPoint("TOPLEFT", _G.ChatConfigCategoryFrame, "TOPRIGHT")
    divider:SetPoint("BOTTOMRIGHT", _G.ChatConfigBackgroundFrame, "BOTTOMLEFT", 0, 60)
    divider:SetColorTexture(1, 1, 1, .2) -- static: not a theme color

    Skin.WideChatConfigBoxWithHeaderAndClassColorsTemplate(_G.ChatConfigChatSettingsLeft)
    Skin.WideChatConfigBoxWithHeaderAndClassColorsTemplate(_G.ChatConfigChannelSettingsLeft)
    Skin.ChatConfigBoxWithHeaderTemplate(_G.ChatConfigOtherSettingsCombat)
    Skin.ChatConfigBoxWithHeaderTemplate(_G.ChatConfigOtherSettingsPVP)
    if _G.ChatConfigOtherSettingsAdditionalColors then -- 12.1 Discord colors
        Skin.ChatConfigBoxWithHeaderTemplate(_G.ChatConfigOtherSettingsAdditionalColors)
    end
    Skin.ChatConfigBoxWithHeaderTemplate(_G.ChatConfigOtherSettingsSystem)
    Skin.ChatConfigBoxWithHeaderTemplate(_G.ChatConfigOtherSettingsCreature)

    -------------------------
    -- Combat Log Settings --
    -------------------------
    local Filters = _G.ChatConfigCombatSettings.Filters
    Skin.ChatConfigBoxTemplate(_G.ChatConfigCombatSettingsFilters)
    Skin.WowScrollBoxList(Filters.ScrollBox)
    Skin.MinimalScrollBar(Filters.ScrollBar)
    Skin.UIPanelButtonTemplate(_G.ChatConfigCombatSettingsFiltersDeleteButton)
    Skin.UIPanelButtonTemplate(_G.ChatConfigCombatSettingsFiltersAddFilterButton)
    _G.ChatConfigCombatSettingsFiltersAddFilterButton:SetPoint("RIGHT", _G.ChatConfigCombatSettingsFiltersDeleteButton, "LEFT", -5, 0)
    Skin.UIPanelButtonTemplate(_G.ChatConfigCombatSettingsFiltersCopyFilterButton)
    _G.ChatConfigCombatSettingsFiltersCopyFilterButton:SetPoint("RIGHT", _G.ChatConfigCombatSettingsFiltersAddFilterButton, "LEFT", -5, 0)
    Skin.ChatConfigMoveFilter(_G.ChatConfigMoveFilterUpButton, "Up")
    Skin.ChatConfigMoveFilter(_G.ChatConfigMoveFilterDownButton, "Down")
    _G.ChatConfigMoveFilterDownButton:SetPoint("LEFT", _G.ChatConfigMoveFilterUpButton, "RIGHT", -5, 0)

    -- MessageSources --
    Skin.ChatConfigBoxWithHeaderTemplate(_G.CombatConfigMessageSourcesDoneBy)
    Skin.ChatConfigBoxWithHeaderTemplate(_G.CombatConfigMessageSourcesDoneTo)

    -- MessageTypes --

    -- Colors --
    Skin.ChatConfigBoxWithHeaderTemplate(_G.CombatConfigColorsUnitColors)
    Util.HideNineSlice(_G.CombatConfigColorsHighlighting)
    Skin.ChatConfigSmallCheckButtonTemplate(_G.CombatConfigColorsHighlightingLine)
    Skin.ChatConfigSmallCheckButtonTemplate(_G.CombatConfigColorsHighlightingAbility)
    Skin.ChatConfigSmallCheckButtonTemplate(_G.CombatConfigColorsHighlightingDamage)
    Skin.ChatConfigSmallCheckButtonTemplate(_G.CombatConfigColorsHighlightingSchool)

    Util.HideNineSlice(_G.CombatConfigColorsColorizeUnitName)
    Skin.ChatConfigCheckButtonTemplate(_G.CombatConfigColorsColorizeUnitNameCheck)

    Util.HideNineSlice(_G.CombatConfigColorsColorizeSpellNames)
    Skin.ChatConfigCheckButtonTemplate(_G.CombatConfigColorsColorizeSpellNamesCheck)
    Skin.ChatConfigSmallCheckButtonTemplate(_G.CombatConfigColorsColorizeSpellNamesSchoolColoring)
    Skin.ColorSwatchTemplate(_G.CombatConfigColorsColorizeSpellNamesColorSwatch)

    Util.HideNineSlice(_G.CombatConfigColorsColorizeDamageNumber)
    Skin.ChatConfigCheckButtonTemplate(_G.CombatConfigColorsColorizeDamageNumberCheck)
    Skin.ChatConfigSmallCheckButtonTemplate(_G.CombatConfigColorsColorizeDamageNumberSchoolColoring)
    Skin.ColorSwatchTemplate(_G.CombatConfigColorsColorizeDamageNumberColorSwatch)

    Util.HideNineSlice(_G.CombatConfigColorsColorizeDamageSchool)
    Skin.ChatConfigCheckButtonTemplate(_G.CombatConfigColorsColorizeDamageSchoolCheck)

    Util.HideNineSlice(_G.CombatConfigColorsColorizeEntireLine)
    Skin.ChatConfigCheckButtonTemplate(_G.CombatConfigColorsColorizeEntireLineCheck)
    Skin.UIRadioButtonTemplate(_G.CombatConfigColorsColorizeEntireLineBySource)
    Skin.UIRadioButtonTemplate(_G.CombatConfigColorsColorizeEntireLineByTarget)

    -- Formatting --
    Skin.ChatConfigCheckButtonTemplate(_G.CombatConfigFormattingShowTimeStamp)
    Skin.ChatConfigCheckButtonTemplate(_G.CombatConfigFormattingShowBraces)
    Skin.ChatConfigSmallCheckButtonTemplate(_G.CombatConfigFormattingUnitNames)
    Skin.ChatConfigSmallCheckButtonTemplate(_G.CombatConfigFormattingSpellNames)
    Skin.ChatConfigSmallCheckButtonTemplate(_G.CombatConfigFormattingItemNames)
    Skin.ChatConfigCheckButtonTemplate(_G.CombatConfigFormattingFullText)

    -- Settings --
    Skin.InputBoxTemplate(_G.CombatConfigSettingsNameEditBox)
    Skin.UIPanelButtonTemplate(_G.CombatConfigSettingsSaveButton)
    Skin.ChatConfigCheckButtonTemplate(_G.CombatConfigSettingsShowQuickButton)
    Skin.ChatConfigSmallCheckButtonTemplate(_G.CombatConfigSettingsSolo)
    Skin.ChatConfigSmallCheckButtonTemplate(_G.CombatConfigSettingsParty)
    Skin.ChatConfigSmallCheckButtonTemplate(_G.CombatConfigSettingsRaid)

    for index, value in ipairs(_G.COMBAT_CONFIG_TABS) do
        Skin.ChatConfigTabTemplate(_G[_G.CHAT_CONFIG_COMBAT_TAB_NAME..index])
    end

    Skin.UIPanelButtonTemplate(ChatConfigFrame.DefaultButton)
    ChatConfigFrame.DefaultButton:SetPoint("BOTTOMLEFT", 10, 10)
    Skin.UIPanelButtonTemplate(ChatConfigFrame.RedockButton)
    ChatConfigFrame.RedockButton:SetPoint("BOTTOMLEFT", ChatConfigFrame.DefaultButton, "BOTTOMRIGHT", 5, 0)

    Skin.UIPanelButtonTemplate(_G.CombatLogDefaultButton)
    Skin.UIPanelButtonTemplate(_G.TextToSpeechDefaultButton)
    Skin.UICheckButtonTemplate(_G.TextToSpeechCharacterSpecificButton)
    _G.TextToSpeechCharacterSpecificButton:SetPoint("BOTTOMLEFT", _G.TextToSpeechDefaultButton, "BOTTOMRIGHT", 5, 0)

    --Skin.UIPanelButtonTemplate(_G.ChatConfigFrameCancelButton) -- BlizzWTF: Not used?
    Skin.UIPanelButtonTemplate(_G.ChatConfigFrameOkayButton)
    _G.ChatConfigFrameOkayButton:ClearAllPoints()
    _G.ChatConfigFrameOkayButton:SetPoint("BOTTOMRIGHT", -10, 10)
end
