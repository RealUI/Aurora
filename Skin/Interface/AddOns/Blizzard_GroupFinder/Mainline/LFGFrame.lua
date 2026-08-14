local _, private = ...
if private.shouldSkip() then
    return
end

--[[ Lua Globals ]]
-- luacheck: globals pairs hooksecurefunc

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

local LFGRoleEnumToString = {
    [_G.Enum.LFGRole.Tank] = "TANK",
    [_G.Enum.LFGRole.Healer] = "HEALER",
    [_G.Enum.LFGRole.Damage] = "DAMAGER",
    [_G.Constants.LFG_ROLEConstants.LFG_ROLE_NO_ROLE] = "GUIDE"
}

local DIALOG_BORDER_PIECES = {
    "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner",
    "TopEdge", "BottomEdge", "LeftEdge", "RightEdge",
}

local function WipeDialogBorderTextures(border)
    for _, pieceName in next, DIALOG_BORDER_PIECES do
        local piece = Util.GetNineSlicePiece(border, pieceName)
        if piece then
            piece:SetTexture("")
        end
    end
end

local LEGACY_BUTTON_TEXTURE_KEYS = {
    "Left", "Right", "Middle",
    "left", "right", "middle",
    "LeftTexture", "RightTexture", "MiddleTexture",
    "leftTexture", "rightTexture", "middleTexture",
}

local function HideLegacyButtonArt(button)
    for _, key in next, LEGACY_BUTTON_TEXTURE_KEYS do
        local texture = button[key]
        if texture and texture.SetAlpha then
            texture:SetAlpha(0)
            texture:Hide()
        end
    end

    for _, region in next, {button:GetRegions()} do
        if region:GetObjectType() == "Texture" then
            local name = region:GetName()
            if name then
                local lower = name:lower()
                if lower:find("left", 1, true) or lower:find("middle", 1, true) or lower:find("right", 1, true) then
                    region:SetAlpha(0)
                    region:Hide()
                end
            end
        end
    end
end

do
    --[[ FrameXML\LFGFrame.lua ]]
    function Hook.LFG_SetRoleIconIncentive(roleButton, incentiveIndex)
        local roleIcon = roleButton:GetNormalTexture()
        if roleIcon._auroraBorder == nil then
            return
        end
        if incentiveIndex then
            roleIcon._auroraBorder:SetColorTexture(Color.yellow:GetRGB())
        else
            roleIcon._auroraBorder:SetColorTexture(Color.black:GetRGB())
        end
    end
    function Hook.LFGDungeonReadyPopup_Update()
        local proposalExists, _, _, subtypeID, _, _, role, hasResponded, _, _, _, _, _, _, isSilent =
            _G.GetLFGProposal()
        if not proposalExists or isSilent then
            return
        end

        --When the group doesn't require a role (like scenarios and legacy raids), we get "NONE" as the role
        if role == "NONE" then
            role = _G.Enum.LFGRole.Damage
        end

        if not hasResponded then
            local readyDialogBG = _G.LFGDungeonReadyDialog and _G.LFGDungeonReadyDialog.background
            if readyDialogBG then
                readyDialogBG:SetDesaturated(true)
                readyDialogBG:SetVertexColor(0.28, 0.28, 0.28, 0.4) -- static: not a theme color
            end

            if subtypeID == _G.LFG_SUBTYPEID_RAID then
                _G.LFGDungeonReadyDialog.Border:SetBackdropBorderColor(Color.yellow, 1)
            else
                _G.LFGDungeonReadyDialog.Border:SetBackdropBorderColor(Color.frame, 1)
            end

            if _G.LFGDungeonReadyDialogRoleIcon:IsShown() then
                Base.SetTexture(_G.LFGDungeonReadyDialogRoleIconTexture, "icon" .. role)
            end
        end
    end
    function Hook.LFGDungeonReadyStatusIndividual_UpdateIcon(button)
        local _, role = _G.GetLFGProposalMember(button:GetID())
        Base.SetTexture(button.texture, "icon" .. role)

        Util.SkinOnce(button, Skin.LFGDungeonReadyStatusPlayerTemplate)
    end
    function Hook.LFGDungeonReadyStatusGrouped_UpdateIcon(button, buttonRole)
        Base.SetTexture(button.texture, "icon" .. buttonRole)

        Util.SkinOnce(button, Skin.LFGDungeonReadyStatusPlayerTemplate)
    end
    function Hook.LFGDungeonReadyStatusRoleless_UpdateCount(readyButton)
        Base.SetTexture(readyButton.texture, "iconGUIDE")

        Util.SkinOnce(readyButton, Skin.LFGDungeonReadyStatusPlayerTemplate)
    end
    function Hook.LFGRewardsFrame_SetItemButton(
        parentFrame,
        dungeonID,
        index,
        id,
        name,
        texture,
        numItems,
        rewardType,
        rewardID,
        quality,
        shortageIndex,
        showTankIcon,
        showHealerIcon,
        showDamageIcon)
        local parentName = parentFrame:GetName()
        local frame = _G[parentName .. "Item" .. index]

        if not frame._auroraIconBorder then
            Skin.LFGRewardsLootTemplate(frame)
        end

        Base.SetTexture(frame.roleIcon1.texture, "icon" .. (frame.roleIcon1.role or "GUIDE"))
        Base.SetTexture(frame.roleIcon2.texture, "icon" .. (frame.roleIcon2.role or "GUIDE"))

        if shortageIndex then
            frame._auroraIconBorder:SetBackdropBorderColor(Color.yellow)
        end
    end
    function Hook.LFGCooldownCover_Update(self)
        local nextIndex, numPlayers, prefix = 1
        if _G.IsInRaid() then
            numPlayers = _G.GetNumGroupMembers()
            prefix = "raid"
        else
            numPlayers = _G.GetNumSubgroupMembers()
            prefix = "party"
        end

        for i = 1, numPlayers do
            if nextIndex > #self.Names then
                break
            end

            local unit = prefix .. i
            if _G.UnitHasLFGDeserter(unit) or (self.showCooldown and _G.UnitHasLFGRandomCooldown(unit)) or self.showAll then
                -- Was UnitName's second return (the REALM) used as a class token —
                -- the recolor never fired. Correct API + WoW 12 secret guards.
                local _, classToken = _G.UnitClass(unit)
                if _G.issecretvalue(classToken) then classToken = nil end
                local classColor = classToken and _G.CUSTOM_CLASS_COLORS[classToken]
                local name = _G.GetUnitName(unit, true)
                if classColor and name and not _G.issecretvalue(name) then
                    self.Names[nextIndex]:SetFormattedText("|c%s%s|r", classColor.colorStr, name)
                end
                nextIndex = nextIndex + 1
            end
        end
    end
end

do
    --[[ FrameXML\LFGFrame.xml ]]
    function Skin.LFGRoleButtonTemplate(Button)
        -- This is a fail-safe for when the role is not ENUM but a string
        if not Button then
            if private.isDev then
                _G.print("[Aurora-Dev]: Button is nil in LFGRoleButtonTemplate - Report to Aurora developers.")
            end
            return
        end
        if (Button.role == "TANK" or Button.role == "HEALER" or Button.role == "DAMAGER" or Button.role == nil) then
            Base.SetTexture(Button:GetNormalTexture(), "icon" .. (Button.role or "GUIDE"))
        else
            Base.SetTexture(Button:GetNormalTexture(), "icon" .. (LFGRoleEnumToString[Button.role]))
        end
        Skin.UICheckButtonTemplate(Button.checkButton)
        Button.checkButton:SetPoint("BOTTOMLEFT", -4, -4)
    end
    function Skin.LFGRoleButtonWithBackgroundTemplate(Button)
        Skin.LFGRoleButtonTemplate(Button)
    end
    function Skin.LFGRoleButtonWithBackgroundAndRewardTemplate(Button)
        Skin.LFGRoleButtonWithBackgroundTemplate(Button)
        Button.shortageBorder:SetAlpha(0)

        local incentiveIcon = Button.incentiveIcon
        incentiveIcon:SetSize(14, 14)
        incentiveIcon:SetPoint("BOTTOMRIGHT", -1, 1)

        incentiveIcon.texture:SetAllPoints(incentiveIcon)
        Base.CropIcon(incentiveIcon.texture)

        local border = incentiveIcon.border
        border:SetDrawLayer("ARTWORK", -2)
        border:SetColorTexture(Color.yellow:GetRGB())
        border:SetPoint("TOPLEFT", incentiveIcon.texture, -1, 1)
        border:SetPoint("BOTTOMRIGHT", incentiveIcon.texture, 1, -1)
    end
    function Skin.LFGSpecificChoiceTemplate(Frame)
        Skin.UICheckButtonTemplate(Frame.enableButton)
        Skin.ExpandOrCollapse(Frame.expandOrCollapseButton)
    end
    function Skin.LFGDungeonReadyRewardTemplate(Frame)
        Base.CropIcon(Frame.texture, Frame)
        _G[Frame:GetName() .. "Border"]:Hide()
    end

    function Skin.LFGRewardsLootTemplate(Button)
        Skin.LargeItemButtonTemplate(Button)
        Button.shortageBorder:SetAlpha(0)
        Button.IconBorder:SetAlpha(0)
    end
    function Skin.LFGRewardFrameTemplate(Frame)
        local name = Frame:GetName()
        Skin.LFGRewardsLootTemplate(_G[name .. "Item1"])
        Skin.LargeItemButtonTemplate(Frame.MoneyReward)
    end

    function Skin.LFGDungeonReadyStatusPlayerTemplate(Frame)
        Frame.texture:ClearAllPoints()
        Frame.texture:SetPoint("TOPLEFT", 1, -1)
        Frame.texture:SetPoint("BOTTOMRIGHT", -1, 1)

        Frame.statusIcon:SetPoint("BOTTOMLEFT", -5, -5)
    end

    function Skin.LFGCooldownCoverTemplate(Frame)
    end
    function Skin.LFGBackfillCoverTemplate(Frame)
        local name = Frame:GetName()
        Skin.UIPanelButtonTemplate(_G[name .. "BackfillButton"])
        Skin.UIPanelButtonTemplate(_G[name .. "NoBackfillButton"])
    end
end

function private.AddOns.LFGFrame()
    _G.hooksecurefunc("LFG_SetRoleIconIncentive", Hook.LFG_SetRoleIconIncentive)
    _G.hooksecurefunc("LFGDungeonReadyPopup_Update", Hook.LFGDungeonReadyPopup_Update)
    _G.hooksecurefunc("LFGDungeonReadyStatusIndividual_UpdateIcon", Hook.LFGDungeonReadyStatusIndividual_UpdateIcon)
    _G.hooksecurefunc("LFGDungeonReadyStatusGrouped_UpdateIcon", Hook.LFGDungeonReadyStatusGrouped_UpdateIcon)
    _G.hooksecurefunc("LFGDungeonReadyStatusRoleless_UpdateCount", Hook.LFGDungeonReadyStatusRoleless_UpdateCount)
    _G.hooksecurefunc("LFGRewardsFrame_SetItemButton", Hook.LFGRewardsFrame_SetItemButton)
    _G.hooksecurefunc("LFGCooldownCover_Update", Hook.LFGCooldownCover_Update)

    --------------------------
    -- LFGDungeonReadyPopup --
    --------------------------
    local statusBorder = _G.LFGDungeonReadyStatus.Border
    Skin.DialogBorderTemplate(statusBorder)
    WipeDialogBorderTextures(statusBorder)
    Skin.UIPanelHideButtonNoScripts(_G.LFGDungeonReadyStatusCloseButton)

    local LFGDungeonReadyDialog = _G.LFGDungeonReadyDialog
    LFGDungeonReadyDialog.background:ClearAllPoints()
    LFGDungeonReadyDialog.background:SetPoint("TOPLEFT", 6, -6)
    LFGDungeonReadyDialog.background:SetPoint("BOTTOMRIGHT", -6, 64)
    LFGDungeonReadyDialog.background:SetDesaturated(true)
    LFGDungeonReadyDialog.background:SetVertexColor(0.28, 0.28, 0.28, 0.4) -- static: not a theme color

    LFGDungeonReadyDialog.bottomArt:Hide()

    Skin.DialogBorderTranslucentTemplate(LFGDungeonReadyDialog.Border)
    WipeDialogBorderTextures(LFGDungeonReadyDialog.Border)
    Skin.UIPanelHideButtonNoScripts(_G.LFGDungeonReadyDialogCloseButton)
    Skin.UIPanelButtonTemplate(LFGDungeonReadyDialog.enterButton)
    Skin.UIPanelButtonTemplate(LFGDungeonReadyDialog.leaveButton)
    HideLegacyButtonArt(LFGDungeonReadyDialog.enterButton)
    HideLegacyButtonArt(LFGDungeonReadyDialog.leaveButton)

    _G.LFGDungeonReadyDialogRoleIcon:SetSize(64, 64)
    _G.LFGDungeonReadyDialogRoleIcon:ClearAllPoints()
    _G.LFGDungeonReadyDialogRoleIcon:SetPoint("BOTTOMLEFT", 121, 57)
    _G.LFGDungeonReadyDialogRoleIconLeaderIcon:SetPoint("TOPLEFT")
    Base.SetTexture(_G.LFGDungeonReadyDialogRoleIconLeaderIcon, "iconGUIDE")

    Skin.LFGDungeonReadyRewardTemplate(_G.LFGDungeonReadyDialogRewardsFrame.Rewards[1])
    Skin.LFGDungeonReadyRewardTemplate(_G.LFGDungeonReadyDialogRewardsFrame.Rewards[2])

    ------------------------
    -- LFGReadyCheckPopup --
    ------------------------
    local LFGReadyCheckPopup = _G.LFGReadyCheckPopup
    Skin.DialogBorderTemplate(LFGReadyCheckPopup.Border)
    WipeDialogBorderTextures(LFGReadyCheckPopup.Border)
    Skin.UIPanelButtonTemplate(LFGReadyCheckPopup.YesButton)
    Skin.UIPanelButtonTemplate(LFGReadyCheckPopup.NoButton)
    Util.PositionRelative("BOTTOMLEFT", LFGReadyCheckPopup, "BOTTOMLEFT", 32, 15, 5, "Right", {
        LFGReadyCheckPopup.YesButton,
        LFGReadyCheckPopup.NoButton,
    })

    --------------------
    -- LFGInvitePopup --
    --------------------
    local LFGInvitePopup = _G.LFGInvitePopup
    Skin.DialogBorderTemplate(LFGInvitePopup.Border)
    WipeDialogBorderTextures(LFGInvitePopup.Border)

    LFGInvitePopup.RoleButtons[1]:SetPoint("TOPLEFT", 35, -35)
    for i = 1, #LFGInvitePopup.RoleButtons do
        Skin.LFGRoleButtonTemplate(LFGInvitePopup.RoleButtons[i])
    end
    Skin.UIPanelButtonTemplate(_G.LFGInvitePopupAcceptButton)
    Skin.UIPanelButtonTemplate(_G.LFGInvitePopupDeclineButton)
    Util.PositionRelative(
        "BOTTOMLEFT",
        LFGInvitePopup,
        "BOTTOMLEFT",
        37,
        25,
        5,
        "Right",
        {
            _G.LFGInvitePopupAcceptButton,
            _G.LFGInvitePopupDeclineButton
        }
    )
end
