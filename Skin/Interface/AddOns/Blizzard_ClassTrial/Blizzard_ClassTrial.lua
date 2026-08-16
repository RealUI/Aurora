local _, private = ...
if private.shouldSkip() then return end

local Aurora = private.Aurora
local Base, _, Skin = Aurora.Base, Aurora.Hook, Aurora.Skin
local Color = Aurora.Color

-- SAFETY: Do NOT modify font objects (ThanksText, ClassNameText, DialogText, TimerText)
-- SAFETY: Do NOT call GetTextWidth, SetFont, or SetFontObject on any ClassTrial text element
-- SAFETY: Do NOT call any method that reads secure font metrics

function private.AddOns.Blizzard_ClassTrial()
    ------------------------------------
    -- ClassTrialThanksForPlayingDialog
    ------------------------------------
    local dialog = _G.ClassTrialThanksForPlayingDialog
    if dialog and not private.IsSkinned(dialog) then
        private.SetSkinned(dialog, true)

        -- Strip the DialogFrame atlas texture (ClassTrial-End-Frame)
        if dialog.DialogFrame then
            dialog.DialogFrame:SetAlpha(0)
        end

        -- Apply backdrop to the dialog area
        Base.SetBackdrop(dialog, Color.frame)

        -- Skin action buttons (UIPanelButtonTemplate)
        if dialog.BuyCharacterBoostButton then
            Skin.FrameTypeButton(dialog.BuyCharacterBoostButton)
        end
        if dialog.DecideLaterButton then
            Skin.FrameTypeButton(dialog.DecideLaterButton)
        end

        -- SAFETY: ThanksText, ClassNameText, DialogText are FontStrings
        -- Do NOT modify them — GetTextWidth is called in UpdateDialogButtons
    end

    ------------------------------------
    -- ClassTrialTimerDisplay
    ------------------------------------
    local timer = _G.ClassTrialTimerDisplay
    if timer and not private.IsSkinned(timer) then
        private.SetSkinned(timer, true)

        -- Strip background atlas textures
        if timer.BackgroundLeft then
            timer.BackgroundLeft:SetAlpha(0)
        end
        if timer.BackgroundRight then
            timer.BackgroundRight:SetAlpha(0)
        end

        -- Apply backdrop to the timer frame
        Base.SetBackdrop(timer, Color.frame)

        -- SAFETY: TimerText is a FontString — do NOT modify it
    end
end
