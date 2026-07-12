local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base, Skin = Aurora.Base, Aurora.Skin
local Color = Aurora.Color

--[[ AddOns\Blizzard_CombatLog.lua ]]
-- Quick-filter buttons are created dynamically in
-- Blizzard_CombatLog_Update_QuickButtons via CreateFrame.
-- We post-hook that function to skin any new buttons.

--[[ AddOns\Blizzard_CombatLog.xml ]]
-- CombatLogQuickButtonFrame_Custom is defined in XML with a
-- background texture and child buttons. Skinning is applied
-- in the addon registration function below.

function private.AddOns.Blizzard_CombatLog()
    ------------------------------------------------
    -- Skin the filter bar container
    ------------------------------------------------
    local quickButtonFrame = _G.CombatLogQuickButtonFrame_Custom
    if not quickButtonFrame then return end

    Base.StripBlizzardTextures(quickButtonFrame)
    Base.SetBackdrop(quickButtonFrame, Color.frame)

    ------------------------------------------------
    -- Helper: skin a single quick-filter button
    ------------------------------------------------
    local function SkinQuickButton(button)
        if not button or button._auroraSkinned then return end
        Skin.FrameTypeButton(button)
        button._auroraSkinned = true
    end

    ------------------------------------------------
    -- Skin any already-existing quick-filter buttons
    ------------------------------------------------
    local i = 1
    while true do
        local button = _G["CombatLogQuickButtonFrameButton" .. i]
        if not button then break end
        SkinQuickButton(button)
        i = i + 1
    end

    ------------------------------------------------
    -- Hook Update_QuickButtons to skin future buttons
    ------------------------------------------------
    _G.hooksecurefunc("Blizzard_CombatLog_Update_QuickButtons", function()
        local idx = 1
        while true do
            local button = _G["CombatLogQuickButtonFrameButton" .. idx]
            if not button then break end
            SkinQuickButton(button)
            idx = idx + 1
        end
    end)
end
