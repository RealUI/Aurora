local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals select

--[[ Core ]]
local Aurora = private.Aurora
local Hook, Skin = Aurora.Hook, Aurora.Skin

-- Template functions and the shared panes live in Skin\shared\PaperDollFrame.lua
-- (D3.1). Only the entry function differs between flavors: the anchors and the
-- slot layout.

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

    private.SharedSkins.PaperDollPanes()

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
