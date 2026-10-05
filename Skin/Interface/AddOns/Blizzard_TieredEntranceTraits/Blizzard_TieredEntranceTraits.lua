local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

function private.AddOns.Blizzard_TieredEntranceTraits()
    ----====####################====----
    --   Blizzard_TieredEntranceTraits --
    ----====####################====----

    -- Nothing is skinned here. The templates in this addon are virtual and
    -- their only instance is ScenarioObjectiveTracker.TieredEntranceTraitsBlock
    -- .Container, inside the scenario tracker, which stays Blizzard art (tracker
    -- taint doctrine R4, spec tracker-widget-taint-rewrite task 4.3). The old
    -- skin could not be made in place: Skin.FrameTypeButton planted backdrop
    -- and colour fields on the container, ThemeOverlay and the spell art were
    -- hidden with SetAlpha(0), the spell icons lost their mask, and the list's
    -- framePool had its Acquire replaced by Util.WrapPoolAcquire (the pool the
    -- trackerscan baseline found). Removed 2026-10-05.
end
