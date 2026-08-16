local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base, Hook = Aurora.Base, Aurora.Hook
local Util = Aurora.Util

-- Shared helper: skin a single tray item frame
local function SkinTrayItem(frame)
    if not frame or private.IsSkinned(frame) then return end

    -- Crop the spell icon texture
    if frame.Icon then
        Base.CropIcon(frame.Icon)
    end

    -- Strip any decorative border textures from the tray item
    Base.StripBlizzardTextures(frame)

    private.SetSkinned(frame, true)
end

do --[[ AddOns\Blizzard_SpellDiminishUI.lua ]]
    -- Hook InitializeTrayItemPool to wrap the pool after creation,
    -- so every acquired tray item is automatically skinned.
    Hook.SpellDiminishStatusTrayMixin = {}
    function Hook.SpellDiminishStatusTrayMixin:InitializeTrayItemPool()
        if self.trayItemPool then
            Util.WrapPoolAcquire(self.trayItemPool, SkinTrayItem)
        end
    end
end

--[[ AddOns\Blizzard_SpellDiminishUI.xml ]]
-- Tray item templates are skinned dynamically via pool wrapping.

function private.AddOns.Blizzard_SpellDiminishUI()
    ------------------------------------------------
    -- Hook mixin prototypes via Util.Mixin
    ------------------------------------------------
    Util.Mixin(_G.SpellDiminishStatusTrayMixin, Hook.SpellDiminishStatusTrayMixin)
end
