local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]

-- Camelot keeps retail's micro buttons and replaces only the bar behind them.
--
-- The TOC makes that explicit: [Family]\MainMenuBarMicroButtons.lua and .xml
-- both load unchanged, and Camelot\MainMenuBarMicroButtonsOverrides.lua only
-- changes which buttons appear and how they are gated (it adds
-- LegacyMicroButton). Only Shared\MainMenuBarMicroMenu.xml is excluded, and its
-- Camelot replacement differs from it by exactly two textures.
--
-- **This settles T3.3's open question.** The task proposed evaluating Aurora's
-- Classic\ skin against a Mainline\-style fork in-game; neither is the answer.
--   * The Classic\ skin is the wrong donor. It re-textures every micro button
--     with era icons and hooks MoveMicroButtons, which does not exist on
--     Forever at all (section 6 lists it among the dead hook names), so running
--     it here would throw before it skinned anything.
--   * Aurora leaves retail's micro buttons stock -- the whole micro button
--     block in Blizzard_ActionBarController is behind `private.isClassic`. Since
--     Camelot's buttons *are* retail's, stock is the consistent answer, and the
--     only work is the new bar art.
--
-- Placed in Camelot\ rather than flat: the flat path is tried first for a
-- collapsed addon, so a flat file would switch this on for Mainline too, where
-- the frame has no such art and Aurora has deliberately never skinned it.
function private.AddOns.Blizzard_MicroMenu()
    if private.disabled.mainmenubar then return end

    local MicroMenu = _G.MicroMenu
    if not MicroMenu then return end

    -- UI-HUD-ActionBar-Frame and UI-HUD-ActionBar-IconFrame-Background: the
    -- same gold plate and inlay the Camelot bag bar carries, handled the same
    -- way there (Blizzard_MainMenuBarBagButtons, BagsBar.BorderArt).
    if MicroMenu.BorderArt then
        MicroMenu.BorderArt:SetAlpha(0)
    end
    if MicroMenu.BackgroundArt then
        MicroMenu.BackgroundArt:SetAlpha(0)
    end
end
