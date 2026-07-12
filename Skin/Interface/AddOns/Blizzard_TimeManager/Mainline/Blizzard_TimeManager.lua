local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Color = Aurora.Color
local Skin = Aurora.Skin

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
