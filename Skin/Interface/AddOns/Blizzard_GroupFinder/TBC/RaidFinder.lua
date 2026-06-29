local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

function private.FrameXML.RaidFinder()
    local RaidFinderFrame = _G.RaidFinderFrame
    if not RaidFinderFrame then return end

    -- Apply Aurora backdrop to the main frame
    Base.SetBackdrop(RaidFinderFrame, Color.frame, Util.GetFrameAlpha())

    -- Hide role background texture
    local roleBackground = _G.RaidFinderFrameRoleBackground
    if roleBackground then
        roleBackground:Hide()
    end

    -- Hide queue frame background
    local queueBackground = _G.RaidFinderQueueFrameBackground
    if queueBackground then
        queueBackground:Hide()
    end

    -- Skin inset frames
    local roleInset = _G.RaidFinderFrameRoleInset
    if roleInset and Skin.InsetFrameTemplate then
        Skin.InsetFrameTemplate(roleInset)
    end

    local bottomInset = _G.RaidFinderFrameBottomInset
    if bottomInset and Skin.InsetFrameTemplate then
        Skin.InsetFrameTemplate(bottomInset)
    end

    -- Skin the NoRaidsCover
    if RaidFinderFrame.NoRaidsCover then
        RaidFinderFrame.NoRaidsCover:SetPoint("TOPRIGHT", 0, -25)
        RaidFinderFrame.NoRaidsCover:SetPoint("BOTTOMLEFT", 0, 0)
    end

    --------------------------
    -- RaidFinderQueueFrame --
    --------------------------
    local RaidFinderQueueFrame = _G.RaidFinderQueueFrame
    if RaidFinderQueueFrame then
        -- Skin role buttons
        local tankButton = _G.RaidFinderQueueFrameRoleButtonTank
        if tankButton and Skin.LFGRoleButtonTemplate then
            Skin.LFGRoleButtonTemplate(tankButton)
        end

        local healerButton = _G.RaidFinderQueueFrameRoleButtonHealer
        if healerButton and Skin.LFGRoleButtonTemplate then
            Skin.LFGRoleButtonTemplate(healerButton)
        end

        local dpsButton = _G.RaidFinderQueueFrameRoleButtonDPS
        if dpsButton and Skin.LFGRoleButtonTemplate then
            Skin.LFGRoleButtonTemplate(dpsButton)
        end

        local leaderButton = _G.RaidFinderQueueFrameRoleButtonLeader
        if leaderButton and Skin.LFGRoleButtonTemplate then
            Skin.LFGRoleButtonTemplate(leaderButton)
        end

        -- Skin the raid selection dropdown
        local selectionDropdown = RaidFinderQueueFrame.SelectionDropdown or _G.RaidFinderQueueFrameSelectionDropdown
        if selectionDropdown and Skin.DropdownButton then
            Skin.DropdownButton(selectionDropdown)
        end

        -- Skin scroll frame
        local scrollFrame = _G.RaidFinderQueueFrameScrollFrame
        if scrollFrame and Skin.ScrollFrameTemplate then
            Skin.ScrollFrameTemplate(scrollFrame)
        end

        -- Skin reward frame content
        local rewardFrame = _G.RaidFinderQueueFrameScrollFrameChildFrame
        if rewardFrame and Skin.LFGRewardFrameTemplate then
            Skin.LFGRewardFrameTemplate(rewardFrame)
        end

        -- Skin backfill cover
        local backfill = _G.RaidFinderQueueFramePartyBackfill
        if backfill and Skin.LFGBackfillCoverTemplate then
            Skin.LFGBackfillCoverTemplate(backfill)
        end

        -- Skin cooldown cover
        local cooldownFrame = RaidFinderQueueFrame.CooldownFrame or _G.RaidFinderQueueFrameCooldownFrame
        if cooldownFrame and Skin.LFGCooldownCoverTemplate then
            Skin.LFGCooldownCoverTemplate(cooldownFrame)
        end

        -- Skin ineligible frame leave queue button
        local ineligibleFrame = _G.RaidFinderQueueFrameIneligibleFrame
        if ineligibleFrame and ineligibleFrame.leaveQueueButton then
            if Skin.UIPanelButtonTemplate then
                Skin.UIPanelButtonTemplate(ineligibleFrame.leaveQueueButton)
            end
        end
    end

    -- Skin the Find Raid button
    local findRaidButton = _G.RaidFinderFrameFindRaidButton
    if findRaidButton then
        if Skin.MagicButtonTemplate then
            Skin.MagicButtonTemplate(findRaidButton)
        elseif Skin.UIPanelButtonTemplate then
            Skin.UIPanelButtonTemplate(findRaidButton)
        end
    end
end
