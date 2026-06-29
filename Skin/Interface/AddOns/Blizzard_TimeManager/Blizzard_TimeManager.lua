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
    if _G.TimeManagerGlobe then
        _G.TimeManagerGlobe:Hide()
    end
    if _G.StopwatchFrameBackgroundLeft then
        _G.StopwatchFrameBackgroundLeft:Hide()
    end
    if _G.StopwatchFrame then
        _G.select(2, _G.StopwatchFrame:GetRegions()):Hide()
    end
    if _G.StopwatchTabFrameLeft then _G.StopwatchTabFrameLeft:Hide() end
    if _G.StopwatchTabFrameMiddle then _G.StopwatchTabFrameMiddle:Hide() end
    if _G.StopwatchTabFrameRight then _G.StopwatchTabFrameRight:Hide() end

    if _G.TimeManagerStopwatchCheck then
        Skin.UICheckButtonTemplate(_G.TimeManagerStopwatchCheck)
    end

    -- Modern dropdown API (Classic Anniversary uses the new Menu dropdown)
    local AlarmTimeFrame = _G.TimeManagerFrame and _G.TimeManagerFrame.AlarmTimeFrame
    if AlarmTimeFrame then
        if AlarmTimeFrame.HourDropdown then
            AlarmTimeFrame.HourDropdown:SetWidth(80)
            Skin.DropdownButton(AlarmTimeFrame.HourDropdown)
        end
        if AlarmTimeFrame.MinuteDropdown then
            AlarmTimeFrame.MinuteDropdown:SetWidth(80)
            Skin.DropdownButton(AlarmTimeFrame.MinuteDropdown)
        end
        if AlarmTimeFrame.AMPMDropdown then
            AlarmTimeFrame.AMPMDropdown:SetWidth(90)
            Skin.DropdownButton(AlarmTimeFrame.AMPMDropdown)
        end
    end

    if _G.TimeManagerFrame then
        Skin.ButtonFrameTemplate(_G.TimeManagerFrame)
    end
    if _G.StopwatchFrame then
        Skin.FrameTypeFrame(_G.StopwatchFrame)
    end
    if _G.TimeManagerAlarmMessageEditBox then
        Skin.InputBoxTemplate(_G.TimeManagerAlarmMessageEditBox)
    end
    if _G.TimeManagerAlarmEnabledButton then
        Skin.UICheckButtonTemplate(_G.TimeManagerAlarmEnabledButton)
    end
    if _G.TimeManagerMilitaryTimeCheck then
        Skin.UICheckButtonTemplate(_G.TimeManagerMilitaryTimeCheck)
    end
    if _G.TimeManagerLocalTimeCheck then
        Skin.UICheckButtonTemplate(_G.TimeManagerLocalTimeCheck)
    end
    if _G.StopwatchCloseButton then
        Skin.UIPanelCloseButton(_G.StopwatchCloseButton)
    end

    local resetBtn = _G.StopwatchResetButton
    local playBtn = _G.StopwatchPlayPauseButton

    if not resetBtn or not playBtn then return end

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
