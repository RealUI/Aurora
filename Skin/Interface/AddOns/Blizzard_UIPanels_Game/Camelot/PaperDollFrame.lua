local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals next

--[[ Core ]]
local Aurora = private.Aurora
local Hook, Skin = Aurora.Hook, Aurora.Skin

-- Template functions and the shared panes live in Skin\shared\PaperDollFrame.lua
-- (D3.1). What differs on Camelot:
--
--  * anchors -- CharacterFrame.Inset / .InsetRight do not exist; the content
--    and side panes are LeftPaneHost / RightPaneHost (T2.0.1).
--  * PaperDollInnerBorder* (nine textures) and CharacterModelFrameBackgroundOverlay
--    are gone -- Camelot's PaperDollFrame.xml replaces the Mainline one outright.
--  * PaperDollSidebarTabs has no DecorLeft/DecorRight.
--
-- Slot positions are deliberately left as Blizzard lays them out. The Mainline
-- skin re-anchors all eighteen to CharacterFrame.Inset because Aurora reshapes
-- that frame; here the panes keep Blizzard's own geometry, and forcing retail
-- offsets onto a 398-wide LeftPaneHost would be guesswork. Revisit once the
-- panel has been looked at in-game.

function private.FrameXML.PaperDollFrame()
    _G.hooksecurefunc("PaperDollFrame_SetLevel", Hook.PaperDollFrame_SetLevel)

    local CharacterFrame = _G.CharacterFrame
    local leftPane = CharacterFrame.LeftPaneHost
    local rightPane = CharacterFrame.RightPaneHost

    -- Class art behind the model, as on retail but bounded by the left pane.
    local bg = CharacterFrame.NineSlice and CharacterFrame.NineSlice:GetBackdropTexture("bg")
    if bg and leftPane then
        local classBG = _G.PaperDollFrame:CreateTexture(nil, "BORDER")
        classBG:SetAtlas("dressingroom-background-" .. private.charClass.token)
        classBG:SetPoint("TOPLEFT", bg)
        classBG:SetPoint("BOTTOM", bg)
        classBG:SetPoint("RIGHT", leftPane, 4, 0)

        local settings = private.CLASS_BACKGROUND_SETTINGS[private.charClass.token]
            or private.CLASS_BACKGROUND_SETTINGS["DEFAULT"]
        classBG:SetDesaturation(settings.desaturation)
        classBG:SetAlpha(settings.alpha)
    end

    local SidebarTabs = _G.PaperDollSidebarTabs
    if SidebarTabs then
        if rightPane then
            SidebarTabs:ClearAllPoints()
            SidebarTabs:SetPoint("BOTTOM", rightPane, "TOP", 0, -3)
        end
        -- Camelot drops the decorative end caps.
        if SidebarTabs.DecorLeft then SidebarTabs.DecorLeft:Hide() end
        if SidebarTabs.DecorRight then SidebarTabs.DecorRight:Hide() end
    end

    private.SharedSkins.PaperDollPanes()

    if leftPane then
        _G.CharacterModelScene:SetPoint("TOPLEFT", leftPane, 45, -10)
        _G.CharacterModelScene:SetPoint("BOTTOMRIGHT", leftPane, -45, 30)
    end

    -- Corner art around the model: still present on Camelot.
    for _, corner in next, {"TopLeft", "TopRight", "BotLeft", "BotRight"} do
        local texture = _G["CharacterModelFrameBackground" .. corner]
        if texture then texture:Hide() end
    end

    -- CharacterModelFrameBackgroundOverlay and the nine PaperDollInnerBorder*
    -- textures belong to Mainline\PaperDollFrame.xml, which Camelot excludes.
    if _G.CharacterModelFrameBackgroundOverlay then
        _G.CharacterModelFrameBackgroundOverlay:Hide()
    end

    ------------------------------------------------------------------
    -- Equipment slots: skinned in place, not re-anchored (see header).
    ------------------------------------------------------------------
    local EquipmentSlots = {
        "CharacterHeadSlot", "CharacterNeckSlot", "CharacterShoulderSlot", "CharacterBackSlot",
        "CharacterChestSlot", "CharacterShirtSlot", "CharacterTabardSlot", "CharacterWristSlot",
        "CharacterHandsSlot", "CharacterWaistSlot", "CharacterLegsSlot", "CharacterFeetSlot",
        "CharacterFinger0Slot", "CharacterFinger1Slot", "CharacterTrinket0Slot", "CharacterTrinket1Slot",
    }

    local slotsPerSide = 8
    for i = 1, #EquipmentSlots do
        local button = _G[EquipmentSlots[i]]
        if button then
            local isLeftSide = button.IsLeftSide or i <= slotsPerSide
            if isLeftSide then
                Skin.PaperDollItemSlotButtonLeftTemplate(button)
            else
                Skin.PaperDollItemSlotButtonRightTemplate(button)
            end
        end
    end

    for _, name in next, {"CharacterMainHandSlot", "CharacterSecondaryHandSlot"} do
        local button = _G[name]
        if button then
            Skin.PaperDollItemSlotButtonBottomTemplate(button)
        end
    end
end
