local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals select

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color = Aurora.Color

do --[[ FrameXML\PaperDollFrame.lua ]]
    do --[[ PaperDollFrame.lua ]]
        function Hook.PaperDollFrame_SetLevel()
            local classLocale, classColor = private.charClass.locale, _G.CUSTOM_CLASS_COLORS[private.charClass.token]

            local level = _G.UnitLevel("player")
            local effectiveLevel = _G.UnitEffectiveLevel("player")

            if ( effectiveLevel ~= level ) then
                level = _G.EFFECTIVE_LEVEL_FORMAT:format(effectiveLevel, level)
            end

            local _, specName = _G.C_SpecializationInfo.GetSpecializationInfo(_G.C_SpecializationInfo.GetSpecialization(), nil, nil, nil, _G.UnitSex("player"))
            if specName and specName ~= "" then
                _G.CharacterLevelText:SetFormattedText(_G.PLAYER_LEVEL, level, classColor.colorStr, specName, classLocale)
            end

            local showTrialCap = false
            if _G.GameLimitedMode_IsActive() then
                local rLevel = _G.GetRestrictedAccountData()
                if _G.UnitLevel("player") >= rLevel then
                    showTrialCap = true
                end
            end
            if showTrialCap then
                _G.CharacterLevelText:SetPoint("CENTER", _G.CharacterFrame.TitleContainer, "TOP", 0, -36)
            else
                --_G.CharacterTrialLevelErrorText:Show()
                _G.CharacterLevelText:SetPoint("CENTER", _G.CharacterFrame.TitleContainer, "BOTTOM", 0, -4)
            end
        end
    end
end

do --[[ FrameXML\PaperDollFrame.xml ]]
    do --[[ AzeritePaperDollItemOverlay.xml ]]
        function Skin.PaperDollAzeriteItemOverlayTemplate(Frame)
            Frame.RankFrame.Label:SetPoint("CENTER", Frame.RankFrame.Texture, 0, 0)
        end
    end
    do --[[ PaperDollFrame.xml ]]
        function Skin.PaperDollItemSlotButtonTemplate(ItemButton)
            Skin.FrameTypeItemButton(ItemButton)
            Skin.PaperDollAzeriteItemOverlayTemplate(ItemButton)
            _G[ItemButton:GetName().."Frame"]:Hide()

            if ItemButton.verticalFlyout then
                ItemButton.popoutButton:SetPoint("TOP", ItemButton, "BOTTOM")
                ItemButton.popoutButton:SetSize(38, 8)
                Skin.EquipmentFlyoutPopoutButtonTemplate(ItemButton.popoutButton)
                Base.SetTexture(ItemButton.popoutButton._auroraArrow, "arrowDown")
            else
                ItemButton.popoutButton:SetPoint("LEFT", ItemButton, "RIGHT")
                ItemButton.popoutButton:SetSize(8, 38)
                Skin.EquipmentFlyoutPopoutButtonTemplate(ItemButton.popoutButton)
            end
        end
        function Skin.PaperDollItemSlotButtonLeftTemplate(ItemButton)
            Skin.PaperDollItemSlotButtonTemplate(ItemButton)
        end
        function Skin.PaperDollItemSlotButtonRightTemplate(ItemButton)
            Skin.PaperDollItemSlotButtonTemplate(ItemButton)
        end
        function Skin.PaperDollItemSlotButtonBottomTemplate(ItemButton)
            Skin.PaperDollItemSlotButtonTemplate(ItemButton)
        end
        function Skin.PlayerTitleButtonTemplate(Button)
            Button.BgTop:SetTexture("")
            Button.BgBottom:SetTexture("")
            Button.BgMiddle:SetTexture("")

            Button.SelectedBar:SetColorTexture(1, 1, 0, 0.3) -- static: not a theme color
            Button:GetHighlightTexture():SetColorTexture(0, 0, 1, 0.2) -- static: not a theme color
        end
        function Skin.GearSetButtonTemplate(Button)
            Button.BgTop:SetTexture("")
            Button.BgBottom:SetTexture("")
            Button.BgMiddle:SetTexture("")

            Button.HighlightBar:SetColorTexture(0, 0, 1, 0.3) -- static: not a theme color
            Button.SelectedBar:SetColorTexture(1, 1, 0, 0.3) -- static: not a theme color

            Base.CropIcon(Button.icon, Button)
        end
        function Skin.GearSetPopupButtonTemplate(CheckButton)
            Skin.SimplePopupButtonTemplate(CheckButton)
            Base.CropIcon(_G[CheckButton:GetName().."Icon"])
            Base.CropIcon(CheckButton:GetHighlightTexture())
            Base.CropIcon(CheckButton:GetCheckedTexture())
        end
        function Skin.PaperDollSidebarTabTemplate(Button)
            Button.TabBg:SetAlpha(0)
            Button.Hider:SetTexture("")

            Button.Icon:ClearAllPoints()
            Button.Icon:SetPoint("TOPLEFT", 1, -1)
            Button.Icon:SetPoint("BOTTOMRIGHT", -1, 1)

            Button.Highlight:SetTexture("")

            Base.SetBackdrop(Button, Color.button)
            Base.SetHighlight(Button)
        end

        function Skin.MagicResistanceFrameTemplate(Frame)
            Frame:SetSize(20, 20)
            local icon = Frame:GetRegions()
            Frame._icon = icon
            Base.CropIcon(icon, Frame)
        end
    end
end

function private.FrameXML.PaperDollFrame()
    _G.hooksecurefunc("PaperDollFrame_SetLevel", Hook.PaperDollFrame_SetLevel)

    local CharacterFrame = _G.CharacterFrame
    local bg = CharacterFrame.NineSlice:GetBackdropTexture("bg")
    local classBG = _G.PaperDollFrame:CreateTexture(nil, "BORDER")
    classBG:SetAtlas("dressingroom-background-"..private.charClass.token)
    classBG:SetPoint("TOPLEFT", bg)
    classBG:SetPoint("BOTTOM", bg)
    classBG:SetPoint("RIGHT", CharacterFrame.Inset, 4, 0)

    local settings = private.CLASS_BACKGROUND_SETTINGS[private.charClass.token] or private.CLASS_BACKGROUND_SETTINGS["DEFAULT"];
    classBG:SetDesaturation(settings.desaturation)
    classBG:SetAlpha(settings.alpha)

    _G.PaperDollSidebarTabs:ClearAllPoints()
    _G.PaperDollSidebarTabs:SetPoint("BOTTOM", CharacterFrame.InsetRight, "TOP", 0, -3)
    _G.PaperDollSidebarTabs.DecorLeft:Hide()
    _G.PaperDollSidebarTabs.DecorRight:Hide()

    for i = 1, #_G.PAPERDOLL_SIDEBARS do
        local tab = _G["PaperDollSidebarTab"..i]
        Skin.PaperDollSidebarTabTemplate(tab)
    end


    local TitleManagerPane = _G.PaperDollFrame.TitleManagerPane
    Skin.WowScrollBoxList(TitleManagerPane.ScrollBox)
    Skin.MinimalScrollBar(TitleManagerPane.ScrollBar)


    local EquipmentManagerPane = _G.PaperDollFrame.EquipmentManagerPane
    Skin.WowScrollBoxList(EquipmentManagerPane.ScrollBox)
    Skin.MinimalScrollBar(EquipmentManagerPane.ScrollBar)

    Skin.UIPanelButtonTemplate(EquipmentManagerPane.EquipSet)
    Skin.UIPanelButtonTemplate(EquipmentManagerPane.SaveSet)


    _G.CharacterModelScene:SetPoint("TOPLEFT", CharacterFrame.Inset, 45, -10)
    _G.CharacterModelScene:SetPoint("BOTTOMRIGHT", CharacterFrame.Inset, -45, 30)

    _G.CharacterModelFrameBackgroundTopLeft:Hide()
    _G.CharacterModelFrameBackgroundTopRight:Hide()
    _G.CharacterModelFrameBackgroundBotLeft:Hide()
    _G.CharacterModelFrameBackgroundBotRight:Hide()

    _G.CharacterModelFrameBackgroundOverlay:Hide()

    _G.PaperDollInnerBorderTopLeft:Hide()
    _G.PaperDollInnerBorderTopRight:Hide()
    _G.PaperDollInnerBorderBottomLeft:Hide()
    _G.PaperDollInnerBorderBottomRight:Hide()
    _G.PaperDollInnerBorderLeft:Hide()
    _G.PaperDollInnerBorderRight:Hide()
    _G.PaperDollInnerBorderTop:Hide()
    _G.PaperDollInnerBorderBottom:Hide()
    _G.PaperDollInnerBorderBottom2:Hide()


    local EquipmentSlots = {
        "CharacterHeadSlot", "CharacterNeckSlot", "CharacterShoulderSlot", "CharacterBackSlot", "CharacterChestSlot", "CharacterShirtSlot", "CharacterTabardSlot", "CharacterWristSlot",
        "CharacterHandsSlot", "CharacterWaistSlot", "CharacterLegsSlot", "CharacterFeetSlot", "CharacterFinger0Slot", "CharacterFinger1Slot", "CharacterTrinket0Slot", "CharacterTrinket1Slot"
    }
    local WeaponSlots = {
        "CharacterMainHandSlot", "CharacterSecondaryHandSlot"
    }

    local slotsPerSide, prevSlot = 8
    for i = 1, #EquipmentSlots do
        local button = _G[EquipmentSlots[i]]
        button:ClearAllPoints()
        local isLeftSide = button.IsLeftSide or i <= slotsPerSide

        if i % slotsPerSide == 1 then
            if isLeftSide then
                button:SetPoint("TOPLEFT", CharacterFrame.Inset, 4, -11)
            else
                button:SetPoint("TOPRIGHT", CharacterFrame.Inset, -4, -11)
            end
        else
            button:SetPoint("TOPLEFT", prevSlot, "BOTTOMLEFT", 0, -6)
        end

        if isLeftSide then
            Skin.PaperDollItemSlotButtonLeftTemplate(button)
        elseif isLeftSide == false then
            Skin.PaperDollItemSlotButtonRightTemplate(button)
        end

        prevSlot = button
    end

    for i = 1, #WeaponSlots do
        local button = _G[WeaponSlots[i]]

        if i == 1 then
            -- main hand
            button:SetPoint("BOTTOMLEFT", 130, 8)
        end

        _G.select(button:GetNumRegions(), button:GetRegions()):Hide()
        Skin.PaperDollItemSlotButtonBottomTemplate(button)
    end
end
