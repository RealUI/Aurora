local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Color = Aurora.Color

function private.AddOns.Blizzard_Subtitles()
    -- Apply a flat backdrop with reduced alpha for subtitle readability over cinematic content.
    -- Do NOT modify SubtitleBackground (Blizzard dynamically resizes/recolors via CVar).
    -- Do NOT modify font objects or font strings on the Subtitles array (preserve accessibility).
    Base.SetBackdrop(_G.SubtitlesFrame, Color.frame, 0.4)
end
