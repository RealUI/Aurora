local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs select

--[[ Core ]]
local Aurora = private.Aurora
local Base, Skin = Aurora.Base, Aurora.Skin
local Util = Aurora.Util

--[[ Mists (5.5.4) character frame — the CATA design (TOC gametype
    'cata, mists' loads Cata\*.xml): ButtonFrameTemplate root, 4 tabs,
    expandable right inset with the CharacterStatsPane category groups,
    Cata paperdoll with sidebar tabs and the equipment manager.
    Evidence: wow-ui-source-classic/Interface/AddOns/Blizzard_CharacterFrame/
    Cata/*.xml. First pass: gear manager popup, equipment flyouts and the
    titles pane are iteration items.
]]

local itemSlots = {
    "CharacterHeadSlot", "CharacterNeckSlot", "CharacterShoulderSlot",
    "CharacterBackSlot", "CharacterChestSlot", "CharacterShirtSlot",
    "CharacterTabardSlot", "CharacterWristSlot", "CharacterHandsSlot",
    "CharacterWaistSlot", "CharacterLegsSlot", "CharacterFeetSlot",
    "CharacterFinger0Slot", "CharacterFinger1Slot",
    "CharacterTrinket0Slot", "CharacterTrinket1Slot",
    "CharacterMainHandSlot", "CharacterSecondaryHandSlot",
    "CharacterRangedSlot",
}

function private.FrameXML.CharacterFrame()
    local CharacterFrame = _G.CharacterFrame

    Util.HideFrameTextures(CharacterFrame, true)
    Skin.ButtonFrameTemplate(CharacterFrame)

    CharacterFrame.maxTabWidth = 110
    for i = 1, 4 do
        local tab = _G["CharacterFrameTab"..i]
        if tab then
            Skin.CharacterFrameTabButtonTemplate(tab)
        end
    end

    if CharacterFrame.InsetRight then
        Skin.InsetFrameTemplate(CharacterFrame.InsetRight)
    end

    -- Expandable stats pane: category headers carry toolbar/sort art
    if _G.CharacterStatsPane then
        Util.HideFrameTextures(_G.CharacterStatsPane)
        for i = 1, 7 do
            local category = _G["CharacterStatsPaneCategory"..i]
            if category then
                Util.HideFrameTextures(category)
                local toolbar = _G["CharacterStatsPaneCategory"..i.."Toolbar"]
                if toolbar then
                    Util.HideFrameTextures(toolbar)
                end
            end
        end
    end
end

function private.FrameXML.PaperDollFrame()
    local PaperDollFrame = _G.PaperDollFrame
    if not PaperDollFrame then return end

    Util.HideFrameTextures(PaperDollFrame, true)

    for _, name in ipairs(itemSlots) do
        local slot = _G[name]
        if slot then
            -- Cata slots carry extra plate/frame art beyond the generic
            -- item button (same as TBC inspect slots) — sweep every
            -- non-icon, non-state texture BEFORE the backdrop
            local iconTexture = _G[name.."IconTexture"]
            local pushed = slot:GetPushedTexture()
            local highlight = slot:GetHighlightTexture()
            for j = 1, select("#", slot:GetRegions()) do
                local region = select(j, slot:GetRegions())
                if region:IsObjectType("Texture") and region ~= iconTexture
                    and region ~= pushed and region ~= highlight then
                    region:SetAlpha(0)
                end
            end

            Skin.FrameTypeItemButton(slot)
        end
    end

    -- Sidebar tabs (stats/titles/equipment): strip the tab plate art,
    -- keep the icons
    for i = 1, 3 do
        local tab = _G["PaperDollSidebarTab"..i]
        if tab then
            if tab.TabBg then
                tab.TabBg:SetAlpha(0)
            end
            if tab.Hider then
                tab.Hider:SetAlpha(0)
            end
        end
    end

    -- Ammo slot exists on some classic builds only
    local AmmoSlot = _G.CharacterAmmoSlot
    if AmmoSlot then
        if _G.CharacterAmmoSlotIconTexture then
            Base.CropIcon(_G.CharacterAmmoSlotIconTexture)
        end
        AmmoSlot:SetNormalTexture("")
    end
end

function private.FrameXML.PetPaperDollFrame()
    local PetPaperDollFrame = _G.PetPaperDollFrame
    if not PetPaperDollFrame then return end

    Util.HideFrameTextures(PetPaperDollFrame)
end
