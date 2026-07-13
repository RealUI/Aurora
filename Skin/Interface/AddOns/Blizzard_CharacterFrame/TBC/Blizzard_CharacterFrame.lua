local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Base, Skin = Aurora.Base, Aurora.Skin
local Util = Aurora.Util

--[[ TBC (anniversary 2.5.6) character frame. Same 384x512 sheet skeleton
    as era, but the stat pane is REBUILT: PlayerStatFrameLeft/Right1-6 text
    rows selected by modern WowStyle1 dropdowns (PlayerStatFrameLeft/
    RightDropdown + PlayerTitleDropdown), plus MagicResFrame1-5 resistance
    icons (kept — informational). Evidence: wow-ui-source-anniversary/
    Interface/AddOns/Blizzard_CharacterFrame/TBC/*.xml. Do NOT share with
    the Vanilla file (per spec).
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

    Skin.FrameTypeFrame(CharacterFrame)
    -- Art bounds of the classic 384x512 sheet (tune in game if needed)
    CharacterFrame:SetBackdropOption("offsets", {
        left = 10,
        right = 30,
        top = 0,
        bottom = 75,
    })

    _G.CharacterFramePortrait:SetAlpha(0)
    Skin.UIPanelCloseButton(_G.CharacterFrameCloseButton)

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

    -- Quadrant sheet art is unnamed textures on the tab panel
    Util.HideFrameTextures(PaperDollFrame)

    -- Modern stat/title dropdowns
    if PaperDollFrame.TitleDropdown then
        Skin.DropdownButton(PaperDollFrame.TitleDropdown)
    end
    local attributes = PaperDollFrame.Attributes
    if attributes then
        Util.HideFrameTextures(attributes)
        if attributes.LeftPlayerStatDropdown then
            Skin.DropdownButton(attributes.LeftPlayerStatDropdown)
        end
        if attributes.RightPlayerStatDropdown then
            Skin.DropdownButton(attributes.RightPlayerStatDropdown)
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
