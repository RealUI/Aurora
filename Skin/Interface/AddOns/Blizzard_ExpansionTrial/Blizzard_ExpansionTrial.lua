local _, private = ...
if private.shouldSkip() then return end

local Aurora = private.Aurora
local Skin = Aurora.Skin

function private.AddOns.Blizzard_ExpansionTrial()
    ------------------------------------------------
    -- ExpansionTrialCheckPointDialog
    -- Inherits BaseExpandableDialog, VerticalLayoutFrame
    -- Children: Title, Description, ExpansionImage, Button, EatAllInput, GainedLevelContainer
    -- BaseExpandableDialog provides: Top, Middle, Bottom, CloseButtonBG textures + CloseButton
    ------------------------------------------------
    local dialog = _G.ExpansionTrialCheckPointDialog
    if dialog and not private.IsSkinned(dialog) then
        private.SetSkinned(dialog, true)

        -- Strip BaseExpandableDialog textureKit regions (Top, Middle, Bottom, CloseButtonBG)
        if dialog.Top then
            dialog.Top:SetAlpha(0)
        end
        if dialog.Middle then
            dialog.Middle:SetAlpha(0)
        end
        if dialog.Bottom then
            dialog.Bottom:SetAlpha(0)
        end
        if dialog.CloseButtonBG then
            dialog.CloseButtonBG:SetAlpha(0)
        end

        -- Apply frame backdrop
        Skin.FrameTypeFrame(dialog)

        -- Skin the action button (UIPanelButtonTemplate)
        if dialog.Button then
            Skin.FrameTypeButton(dialog.Button)
        end

        -- Skin the close button (UIPanelCloseButtonNoScripts from BaseExpandableDialog)
        if dialog.CloseButton then
            Skin.UIPanelCloseButton(dialog.CloseButton)
        end
    end

    ------------------------------------------------
    -- Legacy: ExpansionTrialThanksForPlayingDialog
    -- Defined in Blizzard_ClassTrial XML, may still exist
    -- Inherits BaseExpandableDialog
    ------------------------------------------------
    local legacy = _G.ExpansionTrialThanksForPlayingDialog
    if legacy and not private.IsSkinned(legacy) then
        private.SetSkinned(legacy, true)

        -- Strip BaseExpandableDialog textureKit regions
        if legacy.Top then
            legacy.Top:SetAlpha(0)
        end
        if legacy.Middle then
            legacy.Middle:SetAlpha(0)
        end
        if legacy.Bottom then
            legacy.Bottom:SetAlpha(0)
        end
        if legacy.CloseButtonBG then
            legacy.CloseButtonBG:SetAlpha(0)
        end

        -- Apply frame backdrop
        Skin.FrameTypeFrame(legacy)

        -- Skin the action button
        if legacy.Button then
            Skin.FrameTypeButton(legacy.Button)
        end

        -- Skin the close button
        if legacy.CloseButton then
            Skin.UIPanelCloseButton(legacy.CloseButton)
        end
    end
end
