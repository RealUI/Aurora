local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

function private.AddOns.Blizzard_MawBuffs()
    ----====####################====----
    --              File              --
    ----====####################====----

    -- Nothing is skinned here. The only MawBuffsContainer instance is the
    -- scenario tracker's MawBuffsBlock, which stays Blizzard art (tracker taint
    -- doctrine R4, spec tracker-widget-taint-rewrite task 4.2); the
    -- Skin.MawBuffsContainer / Skin.MawBuffsList skin was removed 2026-10-05.

    -- The ShouldShowMawBuffs wrapper that lived here (B97, 2026-08-29 to
    -- 2026-10-05) is gone, and must not come back. A login taint.log
    -- (tracker-widget-taint-rewrite task 5.8) showed it was the injector, not
    -- the cure: the scenario tracker's LayoutContents reads the global on every
    -- layout, starting with the tracker's first update at login, and reading
    -- an addon-written global taints the execution. The very next write
    -- (Module.lua:159 `state`) carried that taint into the whole tracker's
    -- layout state for the session. The GetAuraDataByIndex throw it was meant
    -- to hide only happens when the tracker is already tainted; fix the taint,
    -- never the global.
end
