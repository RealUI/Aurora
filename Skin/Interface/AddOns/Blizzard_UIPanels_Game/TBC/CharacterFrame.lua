local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals select ipairs type

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

function private.AddOns.Blizzard_CharacterFrame()
    local CharacterFrame = _G.CharacterFrame
    if not CharacterFrame then return end

    ---------------------
    -- CharacterFrame  --
    ---------------------
    -- FIRST: hide all existing Blizzard textures on CharacterFrame
    -- (portrait is the only texture defined directly on CharacterFrame in the XML)
    local portrait = _G.CharacterFramePortrait
    if portrait then
        portrait:Hide()
    end

    -- THEN: apply Aurora flat backdrop (creates new bg/border textures that must not be hidden)
    Base.SetBackdrop(CharacterFrame, Color.frame, Util.GetFrameAlpha())

    ---------------------
    -- PaperDollFrame  --
    ---------------------
    -- Hide the 4 large background art textures (BORDER layer: UI-Character-CharacterTab-*)
    -- These are the main visual background of the character panel.
    local PaperDollFrame = _G.PaperDollFrame
    if PaperDollFrame then
        for i = 1, PaperDollFrame:GetNumRegions() do
            local region = select(i, PaperDollFrame:GetRegions())
            if region and region.GetObjectType and region:GetObjectType() == "Texture" then
                region:Hide()
            end
        end
    end

    ---------------------
    -- Close Button    --
    ---------------------
    local closeButton = _G.CharacterFrameCloseButton
    if closeButton then
        Skin.UIPanelCloseButton(closeButton)
    end

    ---------------------
    -- Tabs            --
    ---------------------
    for i = 1, 5 do
        local tab = _G["CharacterFrameTab" .. i]
        if tab then
            local name = tab:GetName()
            -- Hide all 6 tab art textures (inactive + active states)
            local textures = {"Left", "Middle", "Right", "LeftDisabled", "MiddleDisabled", "RightDisabled"}
            for _, suffix in ipairs(textures) do
                local tex = _G[name .. suffix]
                if tex then
                    tex:SetTexture("")
                    tex:Hide()
                end
            end
            -- Hide the highlight texture
            local hl = _G[name .. "HighlightTexture"]
            if hl then hl:SetTexture("") end

            -- Apply flat backdrop
            Base.SetBackdrop(tab, Color.button)
            Base.SetHighlight(tab)
        end
    end

    ---------------------
    -- Equipment Slots --
    ---------------------
    -- Slot buttons use PaperDollItemSlotButtonTemplate which inherits ItemButtonTemplate.
    -- They have a NormalTexture (UI-Quickslot2 - the round border), icon texture, and cooldown.
    local slotNames = {
        "CharacterHeadSlot",
        "CharacterNeckSlot",
        "CharacterShoulderSlot",
        "CharacterBackSlot",
        "CharacterChestSlot",
        "CharacterShirtSlot",
        "CharacterTabardSlot",
        "CharacterWristSlot",
        "CharacterHandsSlot",
        "CharacterWaistSlot",
        "CharacterLegsSlot",
        "CharacterFeetSlot",
        "CharacterFinger0Slot",
        "CharacterFinger1Slot",
        "CharacterTrinket0Slot",
        "CharacterTrinket1Slot",
        "CharacterMainHandSlot",
        "CharacterSecondaryHandSlot",
        "CharacterRangedSlot",
    }
    for _, slotName in ipairs(slotNames) do
        local slot = _G[slotName]
        if slot then
            -- Hide the round NormalTexture border (UI-Quickslot2)
            local normalTex = slot:GetNormalTexture()
            if normalTex then
                normalTex:SetTexture("")
            end
            -- Crop the icon
            local icon = _G[slotName .. "IconTexture"] or slot.icon
            if icon then
                Base.CropIcon(icon, slot)
            end
            -- Hide the pushed texture glow
            local pushedTex = slot:GetPushedTexture()
            if pushedTex then
                pushedTex:SetTexture("")
            end
        end
    end

    -- Ammo slot uses a different template with Background/Overlay AmmoSlot textures
    local ammoSlot = _G.CharacterAmmoSlot
    if ammoSlot then
        local normalTex = ammoSlot:GetNormalTexture()
        if normalTex then
            normalTex:SetTexture("")
        end
        local icon = _G.CharacterAmmoSlotIconTexture or ammoSlot.icon
        if icon then
            Base.CropIcon(icon, ammoSlot)
        end
        -- Hide the AmmoSlot background/overlay textures
        for i = 1, ammoSlot:GetNumRegions() do
            local region = select(i, ammoSlot:GetRegions())
            if region and region.GetObjectType and region:GetObjectType() == "Texture" then
                local tex = region:GetTexture()
                if tex and type(tex) == "string" and tex:lower():find("ammoslot") then
                    region:SetAlpha(0)
                end
            end
        end
    end

    ---------------------
    -- Stat Backgrounds --
    ---------------------
    -- These are BACKGROUND layer textures on the stat frame area (UI-Character-StatBackground)
    local statBackgrounds = {
        "PlayerStatLeftTop",
        "PlayerStatLeftMiddle",
        "PlayerStatLeftBottom",
        "PlayerStatRightTop",
        "PlayerStatRightMiddle",
        "PlayerStatRightBottom",
    }
    for _, bgName in ipairs(statBackgrounds) do
        local bg = _G[bgName]
        if bg then
            bg:SetAlpha(0)
        end
    end

    ---------------------
    -- Stat Dropdowns  --
    ---------------------
    if _G.PlayerStatFrameLeftDropDown then
        Skin.UIDropDownMenuTemplate(_G.PlayerStatFrameLeftDropDown)
    end
    if _G.PlayerStatFrameRightDropDown then
        Skin.UIDropDownMenuTemplate(_G.PlayerStatFrameRightDropDown)
    end

    -- Title dropdown (WowStyle1DropdownTemplate on TBC)
    if _G.PlayerTitleDropdown then
        if Skin.DropdownButton then
            Skin.DropdownButton(_G.PlayerTitleDropdown)
        end
    end

    ---------------------
    -- Model Frame     --
    ---------------------
    -- Set model frame background to a flat dark color
    local modelFrame = _G.CharacterModelFrame
    if modelFrame then
        -- Hide the slot background art textures around the model
        -- These are virtual textures instantiated from CharacterFrame.xml:
        -- Char-LeftSlot, Char-RightSlot, Char-BottomSlot, Char-Inner-*, Char-Corner-*, Char-Slot-*
        for i = 1, modelFrame:GetNumRegions() do
            local region = select(i, modelFrame:GetRegions())
            if region and region.GetObjectType and region:GetObjectType() == "Texture" then
                region:SetAlpha(0)
            end
        end
    end

    ---------------------
    -- Resistance Frame --
    ---------------------
    -- Resistance icons have BACKGROUND textures; leave the icons but could style them
    -- (leaving as-is for now since they're small functional icons)
end
