local _, private = ...
if private.shouldSkip() then return end
-- ERA-ONLY: anniversary's bag bar is managed by the modern BagsBar layout
-- (scaled/positioned by its container) — era-shaped skinning mangles it;
-- stock there, matching retail Aurora precedent for modern bars
if not private.isVanilla then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin

--[[ Classic-family bag bar (era/TBC/Mists; retail resolves Mainline/).
    Evidence: wow-ui-source-*/Interface/AddOns/Blizzard_MainMenuBarBagButtons/
    Classic/MainMenuBarBagButtons.xml — MainMenuBarBackpackButton
    (ItemButtonTemplate) + CharacterBag0-3Slot (BagSlotButtonTemplate) with
    the round UI-Quickslot2 ring as $parentNormalTexture and a CheckButton
    CheckedTexture instead of retail's SlotHighlightTexture. The KeyRingButton
    latch keeps its own art (it IS the affordance).
]]

do --[[ Classic\MainMenuBarBagButtons.xml ]]
    function Skin.BagSlotButtonTemplate(ItemButton)
        Skin.FrameTypeItemButton(ItemButton)

        local ring = _G[ItemButton:GetName().."NormalTexture"]
        if ring then
            ring:SetAlpha(0)
        end
        Base.CropIcon(ItemButton:GetHighlightTexture())
        if ItemButton.GetCheckedTexture and ItemButton:GetCheckedTexture() then
            Base.CropIcon(ItemButton:GetCheckedTexture())
        end
    end
end

function private.FrameXML.MainMenuBarBagButtons()
    if private.disabled.mainmenubar then return end

    Skin.BagSlotButtonTemplate(_G.MainMenuBarBackpackButton)
    for _, name in ipairs({"CharacterBag0Slot", "CharacterBag1Slot", "CharacterBag2Slot", "CharacterBag3Slot"}) do
        local button = _G[name]
        if button then
            Skin.BagSlotButtonTemplate(button)
        end
    end
end
