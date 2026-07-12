local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals select ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin

--[[ Classic Era CharacterFrame + PaperDollFrame + PetPaperDollFrame.
    Evidence: wow-ui-source-era/Interface/AddOns/Blizzard_CharacterFrame/
    Vanilla/CharacterFrame.xml (root L141: plain 384x512 frame, no template),
    Vanilla/PaperDollFrame.xml, Vanilla/PetPaperDollFrame.xml.
    The big sheet art (UI-Character-CharacterTab-* / UI-Character-General-* /
    UI-PetPaperDollFrame-*) is four UNNAMED textures layered on each tab
    panel, so those are hidden by region iteration. Stat backgrounds are
    named globals. Item slots are PaperDollItemSlotButtonTemplate
    (= ItemButtonTemplate; skinned via Skin.FrameTypeItemButton, quality
    borders via the shared SetItemButtonQuality hook).
    Blizzard_CharacterFrame is LoadFirst, hence private.FrameXML dispatch.
]]

-- Hide every Texture region directly attached to a frame (used for the
-- unnamed character-sheet quadrant art); leaves FontStrings alone.
local function HideFrameTextures(Frame)
    for i = 1, select("#", Frame:GetRegions()) do
        local region = select(i, Frame:GetRegions())
        if region:IsObjectType("Texture") then
            region:SetTexture("")
        end
    end
end

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

local statBackgrounds = {
    "PlayerStatBackgroundTop", "PlayerStatBackgroundMiddle", "PlayerStatBackgroundBottom",
    "MeleeAttackBackgroundTop", "MeleeAttackBackgroundMiddle", "MeleeAttackBackgroundBottom",
    "RangedAttackBackgroundTop", "RangedAttackBackgroundMiddle", "RangedAttackBackgroundBottom",
}

function private.FrameXML.CharacterFrame()
    local CharacterFrame = _G.CharacterFrame

    Skin.FrameTypeFrame(CharacterFrame)
    -- Art bounds of the classic 384x512 sheet (right/bottom bands are empty;
    -- from the frame's HitRectInsets and tab anchors). Tune in game if needed.
    CharacterFrame:SetBackdropOption("offsets", {
        left = 10,
        right = 30,
        top = 0,
        bottom = 75,
    })

    _G.CharacterFramePortrait:SetAlpha(0)
    Skin.UIPanelCloseButton(_G.CharacterFrameCloseButton)

    -- The tab scripts cap the tab at GetParent().maxTabWidth or 88; with the
    -- skinned side padding (2*17) the widest tab ("Reputation") needs ~99px.
    CharacterFrame.maxTabWidth = 110

    for i = 1, 5 do
        local tab = _G["CharacterFrameTab"..i]
        if tab then
            Skin.CharacterFrameTabButtonTemplate(tab)
        end
    end
end

function private.FrameXML.PaperDollFrame()
    local PaperDollFrame = _G.PaperDollFrame

    -- The four unnamed UI-Character-CharacterTab-* quadrants
    HideFrameTextures(PaperDollFrame)

    for _, name in ipairs(statBackgrounds) do
        local texture = _G[name]
        if texture then
            texture:SetTexture("")
        end
    end

    for _, name in ipairs(itemSlots) do
        local slot = _G[name]
        if slot then
            Skin.FrameTypeItemButton(slot)
        end
    end

    -- Ammo slot is a bespoke button (not ItemButtonTemplate)
    local AmmoSlot = _G.CharacterAmmoSlot
    if AmmoSlot then
        Base.CropIcon(_G.CharacterAmmoSlotIconTexture)
        AmmoSlot:ClearNormalTexture()
    end
end

function private.FrameXML.PetPaperDollFrame()
    local PetPaperDollFrame = _G.PetPaperDollFrame
    if not PetPaperDollFrame then return end

    -- UI-Character-General-Top* / UI-PetPaperDollFrame-Bot* quadrants
    HideFrameTextures(PetPaperDollFrame)
end
