local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color = Aurora.Color

do --[[ Classic\MainMenuBarBagButtons.xml ]]
    -- The flat (Mainline) Blizzard_MainMenuBarBagButtons.lua defines
    -- Skin.BagSlotButtonTemplate, but that file is [MAINLINE ONLY] and is not
    -- loaded for TBC (see AddOns_TBC.xml), so we define a TBC-aware version here.
    --
    -- CharacterBag0Slot-CharacterBag3Slot inherit ItemButtonTemplate (they have
    -- the `icon` and `Count` parentKeys), so Skin.FrameTypeItemButton handles
    -- them. KeyRingButton is a plain CheckButton with bespoke key-ring art and a
    -- mixin (KeyringMixin) that rotates its Normal/Pushed/Highlight textures via
    -- GetNormalTexture()/etc. We must NOT clear those textures (that would make
    -- GetNormalTexture() return nil and break KeyringMixin:UpdateOrientation), so
    -- we Hide() them instead and apply a flat backdrop directly.
    function Skin.BagSlotButtonTemplate(ItemButton)
        if not ItemButton then return end

        if ItemButton.icon and ItemButton.Count then
            Skin.FrameTypeItemButton(ItemButton)

            -- SlotHighlightTexture is a Mainline-only field; crop it if present.
            if ItemButton.SlotHighlightTexture then
                Base.CropIcon(ItemButton.SlotHighlightTexture)
            end
        else
            local normal = ItemButton.GetNormalTexture and ItemButton:GetNormalTexture()
            if normal then normal:Hide() end

            local pushed = ItemButton.GetPushedTexture and ItemButton:GetPushedTexture()
            if pushed then pushed:Hide() end

            local highlight = ItemButton.GetHighlightTexture and ItemButton:GetHighlightTexture()
            if highlight then highlight:Hide() end

            Base.SetBackdrop(ItemButton, Color.black, Color.frame.a)
        end
    end
end

function private.AddOns.Blizzard_MainMenuBarBagButtons()
    if private.disabled.mainmenubar then return end

    -- Skin the four character bag slots (each inherits BagSlotButtonTemplate).
    for i = 0, 3 do
        local slot = _G["CharacterBag"..i.."Slot"]
        if slot then
            Skin.BagSlotButtonTemplate(slot)
        end
    end

    -- KeyRingButton is TBC-only; it does not exist in Mainline.
    local KeyRingButton = _G.KeyRingButton
    if KeyRingButton then
        Skin.BagSlotButtonTemplate(KeyRingButton)
    end

    -- Reposition the first bag slot to the left of the backpack button, using
    -- the right-to-left spacing convention (-4px horizontal offset).
    local CharacterBag0Slot = _G.CharacterBag0Slot
    local MainMenuBarBackpackButton = _G.MainMenuBarBackpackButton
    if CharacterBag0Slot and MainMenuBarBackpackButton then
        CharacterBag0Slot:SetPoint("RIGHT", MainMenuBarBackpackButton, "LEFT", -4, 0)
    end
end
