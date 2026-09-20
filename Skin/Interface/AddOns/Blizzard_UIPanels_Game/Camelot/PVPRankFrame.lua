local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals next

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin

-- Camelot-only surface: the PvP tab (mode tab 4 of the character panel).
-- Retail has no PVPRankFrame, so there is nothing to port.
--
-- Unlike the Reputation and Skills tabs this is not a list -- it is a single
-- info panel: a rank readout, an honor progress bar built on a Cooldown, a
-- faction badge and a reward button. Only the chrome is touched. The
-- FactionBadge and the NextRewardLevel badge are meaningful art and are kept,
-- per the same policy the GroupFinder skin follows.

function private.FrameXML.PVPRankFrame()
    local PVPRankFrame = _G.PVPRankFrame
    if not PVPRankFrame then return end

    local MainInfoFrame = PVPRankFrame.MainInfoFrame
    if MainInfoFrame then
        -- UI-Character-Info-Honor-LevelBG: a decorative rule behind the rank
        -- readout.
        if MainInfoFrame.Line then
            MainInfoFrame.Line:SetAlpha(0)
        end

        local ProgressBar = MainInfoFrame.RankProgressBarDisplay
        if ProgressBar then
            -- pvpqueue-sidebar-honorbar-background. The bar itself is a
            -- Cooldown, not a StatusBar, so Skin.FrameTypeStatusBar does not
            -- apply -- only its backing art is replaced.
            if ProgressBar.Bar then
                ProgressBar.Bar:SetAlpha(0)
            end
            if ProgressBar.Background then
                ProgressBar.Background:SetAlpha(0)
            end
        end

        if MainInfoFrame.DropDown then
            Skin.UIDropDownMenuTemplate(MainInfoFrame.DropDown)
        end

        if MainInfoFrame.NextRewardLevel and Skin.PVPHonorRewardTemplate then
            Skin.PVPHonorRewardTemplate(MainInfoFrame.NextRewardLevel)
        end
    end

    -- DetailFrame is a CharacterFrameSidePaneTemplate, as on the Reputation and
    -- Skills tabs: it slides into the right pane, so it has no border or close
    -- button of its own to skin.
end
