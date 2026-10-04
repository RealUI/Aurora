local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Util = Aurora.Util

-- Aurora role icon keys; anything else keeps Blizzard's atlas.
local ROLE_ICONS = {
    TANK = "iconTANK",
    HEALER = "iconHEALER",
    DAMAGER = "iconDAMAGER",
}

do --[[ FrameXML\PvpPopup.lua ]]
    -- Art only. The earlier version also re-did Blizzard's role-button layout
    -- (its own centre offset and a stale 15px gap; Blizzard uses 22) and
    -- replaced RolePool.Acquire with an addon function. Blizzard lays the
    -- buttons out itself, so only the icon is swapped here.
    Hook.PvpRoleButtonWithCountMixin = {}
    function Hook.PvpRoleButtonWithCountMixin:Setup(roleInfo)
        local icon = roleInfo and ROLE_ICONS[roleInfo.role]
        if icon then
            Base.SetTexture(self.Texture, icon)
        end
    end
end

--do --[[ FrameXML\PvpPopup.xml ]]
--end

-- FrameXML, not AddOns: "PvpPopup" is a file in Blizzard_GroupFinder, not an
-- addon, so as private.AddOns.PvpPopup (2c5d1d78 until 2026-10-04) it never
-- ran (B158).
function private.FrameXML.PvpPopup()
    -- Pooled role buttons are created after this runs, so they copy the
    -- hooked Setup from the mixin table.
    Util.Mixin(_G.PvpRoleButtonWithCountMixin, Hook.PvpRoleButtonWithCountMixin)

    local ReadyStatus = _G.ReadyStatus
    Skin.DialogBorderTemplate(ReadyStatus.Border)
    Skin.MinimizeButton(ReadyStatus.CloseButton)
end
