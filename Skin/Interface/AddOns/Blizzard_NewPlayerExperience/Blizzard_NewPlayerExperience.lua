local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin

--do --[[ AddOns\Blizzard_NewPlayerExperience.lua ]]
--end

--do --[[ AddOns\Blizzard_TutorialKeyboardMouseFrame.xml ]]
--end

function private.AddOns.Blizzard_NewPlayerExperience()
    ----====####################====----
    --  TutorialKeyboardMouseFrame    --
    ----====####################====----
    -- The new-character keyboard/mouse intro. The keyboard picture is the
    -- content and stays; only the buttons are skinned. SkipTutorialButton
    -- is Camelot-only (Forever 70450).
    if _G.KeyboardMouseConfirmButton then
        Skin.UIPanelButtonTemplate(_G.KeyboardMouseConfirmButton)
    end
    if _G.SkipTutorialButton then
        Skin.UIPanelButtonTemplate(_G.SkipTutorialButton)
    end
end
