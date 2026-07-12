local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin

--do --[[ AddOns\Blizzard_DebugTools.lua ]]
--end

--do --[[ AddOns\Blizzard_DebugTools.xml ]]
--end

function private.AddOns.Blizzard_DebugTools()
    if not private.disabled.tooltips then
        Skin.SharedTooltipTemplate(_G.FrameStackTooltip)
    end
end
