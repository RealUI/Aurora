local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals select

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

-- Hides every Texture region on the frame except the ones passed in `keep`.
-- The spell template's gold ring is an unnamed OVERLAY texture, so it can only
-- be reached by iteration. Base.StripBlizzardTextures is not usable here — it
-- would blank the spell Icon along with the decoration.
local function HideDecorativeTextures(frame, keep)
    if not frame or not frame.GetNumRegions then return end

    for i = 1, frame:GetNumRegions() do
        local region = select(i, frame:GetRegions())
        if region and region.GetObjectType and region:GetObjectType() == "Texture"
        and region ~= keep then
            region:SetAlpha(0)
        end
    end
end

do --[[ AddOns\Blizzard_TieredEntranceTraits.lua ]]
    Hook.TieredEntranceTraitsContainerMixin = {}

    -- Update re-shows ThemeOverlay and tints it from the tree's theme colour;
    -- SetPressed swaps its atlas. Re-hide it after both.
    function Hook.TieredEntranceTraitsContainerMixin:Update(numTraits, traitTreeID, spells)
        if self.ThemeOverlay then
            self.ThemeOverlay:SetAlpha(0)
        end
    end

    function Hook.TieredEntranceTraitsContainerMixin:SetPressed(pressed)
        if self.ThemeOverlay then
            self.ThemeOverlay:SetAlpha(0)
        end
    end

    -- UpdateAlignment re-applies a themed atlas to the flyout arrow whenever
    -- the container flips sides, so the replacement has to happen after it.
    function Hook.TieredEntranceTraitsContainerMixin:UpdateAlignment()
        if self.Arrow then
            Base.SetTexture(self.Arrow, self.isOnLeftSide and "arrowRight" or "arrowLeft")
        end
    end

    Hook.TieredEntranceTraitsListMixin = {}

    -- Blizzard's OnLoad creates the spell frame pool; wrap it so icons are
    -- skinned as they are acquired rather than on every SetSpells call.
    function Hook.TieredEntranceTraitsListMixin:OnLoad()
        Skin.TieredEntranceTraitsList(self)

        if self.framePool then
            Util.WrapPoolAcquire(self.framePool, Skin.TieredEntranceTraitSpellTemplate)
        end
    end
end

do --[[ AddOns\Blizzard_TieredEntranceTraits.xml ]]
    function Skin.TieredEntranceTraitSpellTemplate(Frame)
        -- The icon is masked into a circle by IconMask. Drop the mask first:
        -- Base.CropIcon's SetTexCoord is a no-op on a masked texture (the
        -- client errors, and CropIcon swallows it via pcall).
        if Frame.IconMask and Frame.Icon then
            Frame.Icon:RemoveMaskTexture(Frame.IconMask)
            Frame.IconMask:Hide()
        end

        HideDecorativeTextures(Frame, Frame.Icon)
        Base.CropIcon(Frame.Icon, Frame)
    end

    function Skin.TieredEntranceTraitsList(Frame)
        if not Frame then return end

        -- TalentFrameGridTemplate derives from TalentFrameBaseTemplate, so the
        -- SharedTalentUI OnLoad hook has already stripped Blizzard's art and
        -- applied the frame backdrop. Only the flyout's own art is left.
        if Frame.Background then
            Frame.Background:SetAlpha(0)
        end

        -- Also wrap here, not just from the OnLoad hook. `mixin=` copies the
        -- mixin's functions onto the frame when it is created, so if the
        -- instance in ScenarioObjectiveTracker.xml was built before our hook
        -- was installed, its OnLoad carries the unhooked copy. WrapPoolAcquire
        -- is a no-op on an already-wrapped pool.
        if Frame.framePool then
            Util.WrapPoolAcquire(Frame.framePool, Skin.TieredEntranceTraitSpellTemplate)
        end
    end

    function Skin.TieredEntranceTraitsContainer(Button)
        Skin.FrameTypeButton(Button)
        Button:SetButtonColor(Color.button)

        if Button.ThemeOverlay then
            Button.ThemeOverlay:SetAlpha(0)
        end

        Skin.TieredEntranceTraitsList(Button.List)
    end
end

function private.AddOns.Blizzard_TieredEntranceTraits()
    ----====####################====----
    --   Blizzard_TieredEntranceTraits --
    ----====####################====----
    -- The templates in this addon are virtual; the only instance is
    -- ScenarioObjectiveTracker.TieredEntranceTraitsBlock.Container, which the
    -- Blizzard_ObjectiveTracker skin skins directly (as it does MawBuffs).
    -- Only the shared mixin hooks are installed here.

    if _G.TieredEntranceTraitsContainerMixin then
        Util.Mixin(_G.TieredEntranceTraitsContainerMixin, Hook.TieredEntranceTraitsContainerMixin)
    end

    if _G.TieredEntranceTraitsListMixin then
        Util.Mixin(_G.TieredEntranceTraitsListMixin, Hook.TieredEntranceTraitsListMixin)
    end
end
