local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color = Aurora.Color

--do --[[ FrameXML\MainMenuBarBagButtons.lua ]]
--end

do --[[ FrameXML\MainMenuBarBagButtons.xml ]]
    function Skin.BagSlotButtonTemplate(ItemButton)
        Skin.FrameTypeItemButton(ItemButton)
        Base.CropIcon(ItemButton.SlotHighlightTexture)
    end

    -- Camelot's bag slots cannot take Skin.FrameTypeItemButton.
    --
    -- BaseBagSlotButtonMixin:UpdateTextures (Camelot\MainMenuBarBagButtons.lua:9)
    -- runs on every BAG_UPDATE and does `self:GetNormalTexture():SetPoint(...)`
    -- unconditionally. FrameTypeItemButton ends with Button:ClearNormalTexture(),
    -- after which GetNormalTexture() returns nil -- so skinning these the retail
    -- way arms an error inside Blizzard's own code on the next bag change.
    -- Alpha the texture instead: UpdateTextures re-sets its atlas, point and
    -- size, but never its alpha, so the hide survives.
    --
    -- The same call re-atlases the icon (SetAtlas carries its own texcoords, so
    -- it undoes Base.CropIcon), the pushed and highlight textures and
    -- SlotHighlightTexture. Re-apply from a per-button hook -- per button, not
    -- on the mixin table, because Mixin() copies methods at frame creation.
    function Skin.CamelotBagSlotButtonTemplate(ItemButton)
        if not ItemButton or private.IsSkinned(ItemButton) then return end
        private.SetSkinned(ItemButton, true)

        Base.SetBackdrop(ItemButton, Color.black, Color.frame.a)
        ItemButton._auroraIconBorder = ItemButton
        local bg = ItemButton:GetBackdropTexture("bg")

        if ItemButton.Count then
            ItemButton.Count:SetPoint("BOTTOMRIGHT", -2, 2)
        end

        local function Restyle()
            local normal = ItemButton:GetNormalTexture()
            if normal then normal:SetAlpha(0) end

            local pushed = ItemButton:GetPushedTexture()
            if pushed then pushed:SetAlpha(0) end

            -- ui-hud-actionbar-iconframe-bags, ADD-blended at .4. It reads as a
            -- gold wash over Aurora's backdrop, so square it to the icon rather
            -- than leaving it standing off the border.
            local highlight = ItemButton:GetHighlightTexture()
            if highlight then highlight:SetAllPoints(bg) end
            if ItemButton.SlotHighlightTexture then
                ItemButton.SlotHighlightTexture:SetAllPoints(bg)
            end

            -- The keyring and backpack draw their glyph through icon via
            -- bagAtlas/bagIcon, so the icon is the affordance and is kept --
            -- the same call the era skin makes for its KeyRingButton.
            if ItemButton.icon then
                Base.CropIcon(ItemButton.icon)
                ItemButton.icon:SetPoint("TOPLEFT", bg, 1, -1)
                ItemButton.icon:SetPoint("BOTTOMRIGHT", bg, -1, 1)
            end
        end

        Restyle()
        if ItemButton.UpdateTextures then
            _G.hooksecurefunc(ItemButton, "UpdateTextures", Restyle)
        end
    end
end

-- BagsBar and the gamepad bar, both Camelot-only.
local function SkinForeverBagBar()
    -- CharacterReagentBag0Slot and KeyRingButton are new here; the four
    -- CharacterBagNSlot buttons come from
    -- Mainline\MainMenuBarBagButtonTemplates.xml, which Camelot still loads
    -- ([AllowLoadGameType mainline], with no camelot exclusion).
    for _, name in ipairs({
        "MainMenuBarBackpackButton",
        "CharacterBag0Slot", "CharacterBag1Slot", "CharacterBag2Slot", "CharacterBag3Slot",
        "CharacterReagentBag0Slot", "KeyRingButton",
    }) do
        Skin.CamelotBagSlotButtonTemplate(_G[name])
    end

    -- UI-HUD-ActionBar-Frame, the gold plate behind the row.
    local BagsBar = _G.BagsBar
    if BagsBar and BagsBar.BorderArt then
        BagsBar.BorderArt:SetAlpha(0)
    end

    -- Gamepad duplicate of the same row, parented to ContainerFrameCombinedBags
    -- and only shown with a controller attached. Skinned defensively so it is
    -- not a second unskinned surface the moment someone plugs one in.
    local GamepadBagBar = _G.GamepadBagBar
    if GamepadBagBar then
        for _, button in ipairs(GamepadBagBar.BagButtonArray or {}) do
            Skin.CamelotBagSlotButtonTemplate(button)
        end

        -- Its KeyRingButton is a plain CheckButton with UI-Button-KeyRing art,
        -- not an ItemButton, so it takes the button treatment instead.
        local KeyRing = GamepadBagBar.KeyRingButton
        if KeyRing and not private.IsSkinned(KeyRing) then
            private.SetSkinned(KeyRing, true)
            Skin.FrameTypeButton(KeyRing)
        end
    end
end

-- Registered as an AddOns entry, not a FrameXML one.
--
-- private.FrameXML entries all run once, in fileOrder, at Aurora's own
-- ADDON_LOADED. Blizzard_MainMenuBarBagButtons loads *after* Aurora, so every
-- `if frame then` guard below saw nil and the whole skin quietly did nothing --
-- measured in-game on 69913: BagsBar.BorderArt and the backpack's normal
-- texture were both still at alpha 1 with the frames present. private.AddOns
-- entries fire on that addon's own ADDON_LOADED and get the catch-up passes in
-- Skin\init.lua, so they cannot run early.
--
-- The name had to change too: the dispatch is private.AddOns[addonName], and
-- this was registered as "MainMenuBarBagButtons" without the Blizzard_ prefix.
--
-- The Classic file still registers under FrameXML deliberately -- its bag bar
-- is skinned correctly today, so its timing works and is left alone.
function private.AddOns.Blizzard_MainMenuBarBagButtons()
    if private.disabled.mainmenubar then return end

    -- Camelot restores the whole vanilla bag row -- reagent bag, keyring and a
    -- BagsBar that lays itself out (BagsBarMixin: isHorizontal, bagPadding,
    -- useDividers). The retail body below both re-anchors the four slots, which
    -- fights that layout, and clears their normal textures, which breaks
    -- UpdateTextures. Neither applies here.
    --
    -- This branch is reached at all only because CharacterBag0Slot still exists
    -- on Forever: the 12.0.5 bail-out below does not fire, so until now the
    -- retail path was running against Camelot's bar.
    if private.isForever then
        SkinForeverBagBar()
        return
    end

    -- 12.0.5: BagSlotButtonTemplate and CharacterBag*Slot frames removed from Mainline XML
    if not _G.CharacterBag0Slot then return end
    -- Skin.FrameTypeItemButton(_G.MainMenuBarBackpackButton)
    -- Base.CropIcon(_G.MainMenuBarBackpackButton.SlotHighlightTexture)
    Skin.BagSlotButtonTemplate(_G.CharacterBag0Slot)
    Skin.BagSlotButtonTemplate(_G.CharacterBag1Slot)
    Skin.BagSlotButtonTemplate(_G.CharacterBag2Slot)
    Skin.BagSlotButtonTemplate(_G.CharacterBag3Slot)
    _G.CharacterBag0Slot:SetPoint("RIGHT", _G.MainMenuBarBackpackButton, "LEFT", -4, -5)
    _G.CharacterBag1Slot:SetPoint("RIGHT", _G.CharacterBag0Slot, "LEFT", -4, 0)
    _G.CharacterBag2Slot:SetPoint("RIGHT", _G.CharacterBag1Slot, "LEFT", -4, 0)
    _G.CharacterBag3Slot:SetPoint("RIGHT", _G.CharacterBag2Slot, "LEFT", -4, 0)
end
