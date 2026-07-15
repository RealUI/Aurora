local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
-- (imports intentionally removed — the whole skin is disabled, see the
-- note below; re-import Base/Color when re-enabling)

function private.AddOns.Blizzard_Subtitles()
    -- Do NOT modify SubtitleBackground (Blizzard dynamically resizes/recolors via CVar).
    -- Do NOT modify font objects or font strings on the Subtitles array (preserve accessibility).
    --
    -- Disabled (2026-07-15, issue #179): SubtitlesFrame itself is a fixed
    -- 128px-tall, full-width strip anchored BOTTOMLEFT/BOTTOMRIGHT, shown for
    -- the entire duration of any movie/cinematic (OnMovieCinematicPlay),
    -- regardless of whether subtitle text is on screen. Backdropping it
    -- unconditionally renders as a persistent translucent bar across the
    -- bottom of the screen during every cutscene. Blizzard already handles
    -- readability itself via SubtitleBackground + the movieSubtitleBackground
    -- CVars, so there is nothing safe left here to skin.
    -- Base.SetBackdrop(_G.SubtitlesFrame, Color.frame, 0.4)
end
