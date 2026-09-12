local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Color = Aurora.Color
local Skin = Aurora.Skin

--------------------------------------------------------------------------------
-- Flavor note (era / TBC / Mists -- resolved from Classic/ by all three)
--
-- Blizzard splits this addon per flavor (Mainline/ vs Classic/, plus a 3-line
-- Cata/Blizzard_TimeManagerOverrides.lua for cata+mists that only sets
-- CLOCK_Y_OVERRIDE), but the frame structure this skin touches is the same in
-- both trees: TimeManagerFrame inherits ButtonFrameTemplate, the alarm
-- dropdowns hang off AlarmTimeFrame by parentKey, the edit box is
-- InputBoxTemplate, the checks are UICheckButtonTemplate, and the stopwatch
-- textures keep their $parentBackgroundLeft / $parentLeft|Middle|Right names
-- (so StopwatchFrameBackgroundLeft and StopwatchTabFrame* resolve) with the
-- unnamed second StopwatchFrame region in the same order.
--
-- One real difference: classic's alarm dropdowns inherit
-- WowStyle1ThinDropdownTemplate where retail uses WowStyle1DropdownTemplate.
-- Skin.DropdownButton handles both, and the explicit SetWidth calls below
-- override the template width anyway -- but the widths are cosmetic tuning
-- picked against the retail template, so they are the thing to eyeball on a
-- classic client rather than anything that can fail loudly.
--------------------------------------------------------------------------------

function private.AddOns.Blizzard_TimeManager()
    _G.TimeManagerGlobe:Hide()
    _G.StopwatchFrameBackgroundLeft:Hide()
    _G.select(2, _G.StopwatchFrame:GetRegions()):Hide()
    _G.StopwatchTabFrameLeft:Hide()
    _G.StopwatchTabFrameMiddle:Hide()
    _G.StopwatchTabFrameRight:Hide()

    Skin.UICheckButtonTemplate(_G.TimeManagerStopwatchCheck)

    _G.TimeManagerFrame.AlarmTimeFrame.HourDropdown:SetWidth(80)
    _G.TimeManagerFrame.AlarmTimeFrame.MinuteDropdown:SetWidth(80)
    _G.TimeManagerFrame.AlarmTimeFrame.AMPMDropdown:SetWidth(90)

    Skin.ButtonFrameTemplate(_G.TimeManagerFrame)
    Skin.FrameTypeFrame(_G.StopwatchFrame)
    Skin.DropdownButton(_G.TimeManagerFrame.AlarmTimeFrame.HourDropdown)
    Skin.DropdownButton(_G.TimeManagerFrame.AlarmTimeFrame.MinuteDropdown)
    Skin.DropdownButton(_G.TimeManagerFrame.AlarmTimeFrame.AMPMDropdown)
    Skin.InputBoxTemplate(_G.TimeManagerAlarmMessageEditBox)
    Skin.UICheckButtonTemplate(_G.TimeManagerAlarmEnabledButton)
    Skin.UICheckButtonTemplate(_G.TimeManagerMilitaryTimeCheck)
    Skin.UICheckButtonTemplate(_G.TimeManagerLocalTimeCheck)
    Skin.UIPanelCloseButton(_G.StopwatchCloseButton) -- , "TOPRIGHT", _G.StopwatchFrame, "TOPRIGHT", -2, -2)

    local resetBtn = _G.StopwatchResetButton
    local playBtn = _G.StopwatchPlayPauseButton

    local function SkinStopwatchButton(Button)
        Button:SetSize(16, 16)
        Button:ClearHighlightTexture()
        Base.SetBackdrop(Button, Color.button)
        Base.SetHighlight(Button)
        local icon = Button:GetNormalTexture()
        if icon then
            Base.CropIcon(icon, Button) -- creates the black border bg once
            icon:SetTexCoord(.25, .75, .25, .75)
        end
    end

    SkinStopwatchButton(resetBtn)
    SkinStopwatchButton(playBtn)

    -- Re-anchor with proper gap at the new size
    resetBtn:ClearAllPoints()
    resetBtn:SetPoint("BOTTOMRIGHT", _G.StopwatchFrame, "BOTTOMRIGHT", -4, 4)
    playBtn:ClearAllPoints()
    playBtn:SetPoint("RIGHT", resetBtn, "LEFT", -2, 0)

    -- Reapply crop after Blizzard swaps the play/pause texture on click
    _G.hooksecurefunc(playBtn, "SetNormalTexture", function(self)
        local icon = self:GetNormalTexture()
        if icon then icon:SetTexCoord(.25, .75, .25, .75) end
    end)
end
