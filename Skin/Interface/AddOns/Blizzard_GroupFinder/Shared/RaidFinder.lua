local _, private = ...
if private.shouldSkip() then return end

-- [[ Core ]]
local Aurora = private.Aurora
local Hook, Skin = Aurora.Hook, Aurora.Skin

do --[[ FrameXML\RaidFinder.lua ]]
    function Hook.RaidFinderQueueFrameCooldownFrame_Update()
        local numPlayers, prefix
        if _G.IsInRaid() then
            numPlayers = _G.GetNumGroupMembers()
            prefix = "raid"
        else
            numPlayers = _G.GetNumSubgroupMembers()
            prefix = "party"
        end

        local cooldowns = 0
        for i = 1, numPlayers do
            local unit = prefix .. i
            if _G.UnitHasLFGDeserter(unit) and not _G.UnitIsUnit(unit, "player") then
                cooldowns = cooldowns + 1
                if cooldowns <= _G.MAX_RAID_FINDER_COOLDOWN_NAMES then
                    -- WoW 12 combat: guard secret class token (table index) and
                    -- secret name (SetFormattedText) — skip recolor when withheld.
                    -- Shared file: also loads on Mists, where issecretvalue is nil.
                    local isSecret = _G.issecretvalue or function() return false end
                    local _, classToken = _G.UnitClass(unit)
                    if isSecret(classToken) then classToken = nil end
                    local classColor = classToken and _G.CUSTOM_CLASS_COLORS[classToken]
                    local name = _G.UnitName(unit)
                    if classColor and name and not isSecret(name) then
                        _G["RaidFinderQueueFrameCooldownFrameName" .. cooldowns]:SetFormattedText("|c%s%s|r", classColor.colorStr, name)
                    end
                end
            end
        end
    end
end

do --[[ FrameXML\RaidFinder.xml ]]
    function Skin.RaidFinderRoleButtonTemplate(Button)
        -- the LFG role button skin chain is Mainline-only; stock on classic
        if Skin.LFGRoleButtonWithBackgroundAndRewardTemplate then
            Skin.LFGRoleButtonWithBackgroundAndRewardTemplate(Button)
        end
    end
end

function private.FrameXML.RaidFinder()
    _G.hooksecurefunc("RaidFinderQueueFrameCooldownFrame_Update", Hook.RaidFinderQueueFrameCooldownFrame_Update)

    local RaidFinderFrame = _G.RaidFinderFrame
    _G.RaidFinderFrameRoleBackground:Hide()

    RaidFinderFrame.NoRaidsCover:SetPoint("TOPRIGHT", 0, -25)
    RaidFinderFrame.NoRaidsCover:SetPoint("BOTTOMLEFT", 0, 0)

    Skin.InsetFrameTemplate(_G.RaidFinderFrameRoleInset)
    Skin.InsetFrameTemplate(_G.RaidFinderFrameBottomInset)

    --------------------------
    -- RaidFinderQueueFrame --
    --------------------------
    _G.RaidFinderQueueFrameBackground:Hide()

    -- Several LFG skin chains are Mainline-only — guard everything on
    -- classic (5.5.4 loads this file); unskinned pieces are Milestone C
    Skin.RaidFinderRoleButtonTemplate(_G.RaidFinderQueueFrameRoleButtonTank)
    Skin.RaidFinderRoleButtonTemplate(_G.RaidFinderQueueFrameRoleButtonHealer)
    Skin.RaidFinderRoleButtonTemplate(_G.RaidFinderQueueFrameRoleButtonDPS)
    if Skin.LFGRoleButtonTemplate then
        Skin.LFGRoleButtonTemplate(_G.RaidFinderQueueFrameRoleButtonLeader)
    end
    Skin.DropdownButton(_G.RaidFinderQueueFrameSelectionDropdown)
    _G.RaidFinderQueueFrameSelectionDropdown:ClearAllPoints()
    _G.RaidFinderQueueFrameSelectionDropdown:SetPoint("BOTTOMLEFT", _G.RaidFinderQueueFrame, "BOTTOMLEFT", 131, 289)
    _G.RaidFinderQueueFrameSelectionDropdown:SetPoint("BOTTOMRIGHT", _G.RaidFinderQueueFrame, "BOTTOMRIGHT", -30, 289)

    if Skin.ScrollFrameTemplate then
        Skin.ScrollFrameTemplate(_G.RaidFinderQueueFrameScrollFrame)
    end
    if Skin.LFGRewardFrameTemplate then
        Skin.LFGRewardFrameTemplate(_G.RaidFinderQueueFrameScrollFrameChildFrame)
    end

    if Skin.LFGBackfillCoverTemplate and _G.RaidFinderQueueFramePartyBackfill then
        Skin.LFGBackfillCoverTemplate(_G.RaidFinderQueueFramePartyBackfill)
    end
    if Skin.LFGCooldownCoverTemplate and _G.RaidFinderQueueFrame.CooldownFrame then
        Skin.LFGCooldownCoverTemplate(_G.RaidFinderQueueFrame.CooldownFrame)
    end
    if _G.RaidFinderQueueFrameIneligibleFrame and _G.RaidFinderQueueFrameIneligibleFrame.leaveQueueButton then
        Skin.UIPanelButtonTemplate(_G.RaidFinderQueueFrameIneligibleFrame.leaveQueueButton)
    end

    if _G.RaidFinderFrameFindRaidButton then
        Skin.MagicButtonTemplate(_G.RaidFinderFrameFindRaidButton)
    end
end
