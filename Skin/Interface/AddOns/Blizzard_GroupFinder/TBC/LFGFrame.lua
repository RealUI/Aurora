local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

function private.AddOns.Blizzard_GroupFinder()
    --------------------------
    -- PVEFrame (container) --
    --------------------------
    local PVEFrame = _G.PVEFrame
    if PVEFrame then
        Base.SetBackdrop(PVEFrame, Color.frame, Util.GetFrameAlpha())

        -- Hide Blizzard portrait and border textures
        if PVEFrame.portrait then
            PVEFrame.portrait:SetAlpha(0)
        end
        if _G.PVEFramePortrait then
            _G.PVEFramePortrait:SetAlpha(0)
        end

        -- Hide background and border art
        local frameBGs = {
            "PVEFrameBlueBg",
            "PVEFrameTLCorner",
            "PVEFrameTRCorner",
            "PVEFrameBRCorner",
            "PVEFrameBLCorner",
            "PVEFrameLLVert",
            "PVEFrameRLVert",
            "PVEFrameBottomLine",
            "PVEFrameTopLine",
            "PVEFrameTopFiligree",
            "PVEFrameBottomFiligree",
        }
        for _, texName in _G.ipairs(frameBGs) do
            local tex = _G[texName]
            if tex then
                tex:SetAlpha(0)
            end
        end

        if PVEFrame.shadows then
            PVEFrame.shadows:SetAlpha(0)
        end

        -- Skin close button
        if _G.PVEFrameCloseButton then
            Skin.UIPanelCloseButton(_G.PVEFrameCloseButton)
        end

        -- Skin tabs
        for i = 1, 4 do
            local tab = _G["PVEFrameTab" .. i]
            if tab then
                Skin.PanelTabButtonTemplate(tab)
            end
        end

        -- Skin inset
        if PVEFrame.Inset then
            Skin.InsetFrameTemplate(PVEFrame.Inset)
        end
    end

    --------------------------------
    -- GroupFinderFrame (buttons) --
    --------------------------------
    local GroupFinderFrame = _G.GroupFinderFrame
    if GroupFinderFrame then
        for i = 1, 4 do
            local button = GroupFinderFrame["groupButton" .. i]
            if button then
                Skin.FrameTypeButton(button)
                button:SetBackdropOption("offsets", {
                    left = 2,
                    right = 2,
                    top = 2,
                    bottom = 2,
                })
                if button.ring then
                    button.ring:Hide()
                end
                if button.icon then
                    Base.CropCircularIcon(button.icon)
                end
            end
        end
    end

    --------------------
    -- LFDParentFrame --
    --------------------
    local LFDParentFrame = _G.LFDParentFrame
    if LFDParentFrame then
        if _G.LFDParentFrameRoleBackground then
            _G.LFDParentFrameRoleBackground:Hide()
        end
        if LFDParentFrame.TopTileStreaks then
            LFDParentFrame.TopTileStreaks:Hide()
        end

        if LFDParentFrame.Inset then
            Skin.InsetFrameTemplate(LFDParentFrame.Inset)
        end
    end

    --------------------
    -- LFDQueueFrame --
    --------------------
    local LFDQueueFrame = _G.LFDQueueFrame
    if LFDQueueFrame then
        if _G.LFDQueueFrameBackground then
            _G.LFDQueueFrameBackground:Hide()
        end

        -- Skin role buttons
        local roleButtons = {
            _G.LFDQueueFrameRoleButtonTank,
            _G.LFDQueueFrameRoleButtonHealer,
            _G.LFDQueueFrameRoleButtonDPS,
        }
        for _, roleButton in _G.ipairs(roleButtons) do
            if roleButton then
                if roleButton.checkButton then
                    Skin.UICheckButtonTemplate(roleButton.checkButton)
                end
                if roleButton.shortageBorder then
                    roleButton.shortageBorder:SetAlpha(0)
                end
                if roleButton.background then
                    roleButton.background:SetAlpha(0)
                end
            end
        end

        -- Skin leader button
        local leaderButton = _G.LFDQueueFrameRoleButtonLeader
        if leaderButton then
            if leaderButton.checkButton then
                Skin.UICheckButtonTemplate(leaderButton.checkButton)
            end
        end

        -- Skin type dropdown
        if _G.LFDQueueFrameTypeDropdown then
            Skin.DropdownButton(_G.LFDQueueFrameTypeDropdown)
        end

        -- Skin specific dungeon list ScrollBox
        if LFDQueueFrame.Specific then
            if LFDQueueFrame.Specific.ScrollBox then
                Skin.WowScrollBoxList(LFDQueueFrame.Specific.ScrollBox)
            end
            if LFDQueueFrame.Specific.ScrollBar then
                Skin.MinimalScrollBar(LFDQueueFrame.Specific.ScrollBar)
            end
        end

        -- Skin random scroll frame
        if _G.LFDQueueFrameRandomScrollFrame then
            Skin.ScrollFrameTemplate(_G.LFDQueueFrameRandomScrollFrame)
        end

        -- Skin find group button
        if _G.LFDQueueFrameFindGroupButton then
            Skin.MagicButtonTemplate(_G.LFDQueueFrameFindGroupButton)
        end

        -- Skin backfill and cooldown covers
        if LFDQueueFrame.PartyBackfill then
            local backfillName = LFDQueueFrame.PartyBackfill:GetName()
            if backfillName then
                local backfillBtn = _G[backfillName .. "BackfillButton"]
                if backfillBtn then
                    Skin.UIPanelButtonTemplate(backfillBtn)
                end
                local noBackfillBtn = _G[backfillName .. "NoBackfillButton"]
                if noBackfillBtn then
                    Skin.UIPanelButtonTemplate(noBackfillBtn)
                end
            end
        end
    end

    --------------------------
    -- LFDRoleCheckPopup --
    --------------------------
    local LFDRoleCheckPopup = _G.LFDRoleCheckPopup
    if LFDRoleCheckPopup then
        if LFDRoleCheckPopup.Border then
            Skin.DialogBorderTemplate(LFDRoleCheckPopup.Border)
        end

        -- Skin role check popup buttons
        local roleCheckButtons = {
            _G.LFDRoleCheckPopupRoleButtonTank,
            _G.LFDRoleCheckPopupRoleButtonHealer,
            _G.LFDRoleCheckPopupRoleButtonDPS,
        }
        for _, btn in _G.ipairs(roleCheckButtons) do
            if btn then
                if btn.checkButton then
                    Skin.UICheckButtonTemplate(btn.checkButton)
                end
            end
        end

        if _G.LFDRoleCheckPopupAcceptButton then
            Skin.UIPanelButtonTemplate(_G.LFDRoleCheckPopupAcceptButton)
        end
        if _G.LFDRoleCheckPopupDeclineButton then
            Skin.UIPanelButtonTemplate(_G.LFDRoleCheckPopupDeclineButton)
        end
    end

    --------------------------
    -- LFGDungeonReadyPopup --
    --------------------------
    local LFGDungeonReadyStatus = _G.LFGDungeonReadyStatus
    if LFGDungeonReadyStatus then
        if LFGDungeonReadyStatus.Border then
            Skin.DialogBorderTemplate(LFGDungeonReadyStatus.Border)
        end
        if _G.LFGDungeonReadyStatusCloseButton then
            Skin.UIPanelCloseButton(_G.LFGDungeonReadyStatusCloseButton)
        end
    end

    local LFGDungeonReadyDialog = _G.LFGDungeonReadyDialog
    if LFGDungeonReadyDialog then
        if LFGDungeonReadyDialog.background then
            LFGDungeonReadyDialog.background:SetDesaturated(true)
            LFGDungeonReadyDialog.background:SetVertexColor(0.28, 0.28, 0.28, 0.4)
        end
        if LFGDungeonReadyDialog.bottomArt then
            LFGDungeonReadyDialog.bottomArt:Hide()
        end
        if LFGDungeonReadyDialog.Border then
            Skin.DialogBorderTemplate(LFGDungeonReadyDialog.Border)
        end
        if _G.LFGDungeonReadyDialogCloseButton then
            Skin.UIPanelCloseButton(_G.LFGDungeonReadyDialogCloseButton)
        end
        if LFGDungeonReadyDialog.enterButton then
            Skin.UIPanelButtonTemplate(LFGDungeonReadyDialog.enterButton)
        end
        if LFGDungeonReadyDialog.leaveButton then
            Skin.UIPanelButtonTemplate(LFGDungeonReadyDialog.leaveButton)
        end
    end

    ------------------------
    -- LFGReadyCheckPopup --
    ------------------------
    local LFGReadyCheckPopup = _G.LFGReadyCheckPopup
    if LFGReadyCheckPopup then
        if LFGReadyCheckPopup.Border then
            Skin.DialogBorderTemplate(LFGReadyCheckPopup.Border)
        end
        if LFGReadyCheckPopup.YesButton then
            Skin.UIPanelButtonTemplate(LFGReadyCheckPopup.YesButton)
        end
        if LFGReadyCheckPopup.NoButton then
            Skin.UIPanelButtonTemplate(LFGReadyCheckPopup.NoButton)
        end
    end

    --------------------
    -- LFGInvitePopup --
    --------------------
    local LFGInvitePopup = _G.LFGInvitePopup
    if LFGInvitePopup then
        if LFGInvitePopup.Border then
            Skin.DialogBorderTemplate(LFGInvitePopup.Border)
        end
        if LFGInvitePopup.RoleButtons then
            for i = 1, #LFGInvitePopup.RoleButtons do
                local btn = LFGInvitePopup.RoleButtons[i]
                if btn and btn.checkButton then
                    Skin.UICheckButtonTemplate(btn.checkButton)
                end
            end
        end
        if _G.LFGInvitePopupAcceptButton then
            Skin.UIPanelButtonTemplate(_G.LFGInvitePopupAcceptButton)
        end
        if _G.LFGInvitePopupDeclineButton then
            Skin.UIPanelButtonTemplate(_G.LFGInvitePopupDeclineButton)
        end
    end
end
