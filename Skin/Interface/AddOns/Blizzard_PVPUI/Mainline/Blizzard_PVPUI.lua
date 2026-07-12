local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals _G ipairs next pairs select

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

do --[[ AddOns\Blizzard_PVPUI.lua ]]
    Hook.NewPvpSeasonMixin = {}
    function Hook.NewPvpSeasonMixin:OnShow()
        while not self.SeasonDescriptions do
            -- Can't seem to be able to properly hook OnShow for this frame, so just
            -- show cycle it to force the SeasonDescriptions to be created.
            self:Show()
            self:Hide()
        end

        for i = 1, #self.SeasonDescriptions do
            self.SeasonDescriptions[i]:SetTextColor(Color.grayLight:GetRGB())
        end
    end
    function Hook.PVPQueueFrame_SelectButton(index)
        local buttons = _G.PVPQueueFrame.CategoryButtons
        if buttons then
            for buttonIndex, button in ipairs(buttons) do
                if buttonIndex == index then
                    button.Background:Show()
                else
                    button.Background:Hide()
                end
            end
        else
            for i = 1, 4 do
                local button = _G.PVPQueueFrame["CategoryButton"..i]
                if i == index then
                    button.Background:Show()
                else
                    button.Background:Hide()
                end
            end
        end

        Hook.NewPvpSeasonMixin.OnShow(_G.PVPQueueFrame.NewSeasonPopup)
    end

    function Hook.PVPUIScrollBoxUpdate(Frame)
        for _, child in next, { Frame.ScrollTarget:GetChildren() } do
            local Button = child.Button
            if Button and not Button._auroraSkinned then
                    Skin.PVPUIScrollBoxUpdateTemplate(Button)
                    Button._auroraSkinned = true
            end
        end
    end
    function Skin.PVPUIScrollBoxUpdateTemplate(Button)
        Base.SetBackdrop(Button, Color.button)
        Button.Background:Hide()
        Button.Label:SetPoint("BOTTOMLEFT", 6, 0)
        Button.Label:SetPoint("TOPRIGHT")
        Button.Label:SetJustifyV("MIDDLE")
        local r, g, b = Color.highlight:GetRGB()
        local highlight = Button:GetHighlightTexture()
        highlight:SetColorTexture(r, g, b, 0.5)
        highlight:SetPoint("BOTTOMRIGHT")
    end
end

do --[[ AddOns\Blizzard_PVPUI.xml ]]
    function Skin.SeasonRewardFrameTemplate(Frame)
        Frame.Ring:Hide()
        Base.CropCircularIcon(Frame.Icon, Frame)
    end
    function Skin.PVPSeasonChangesNoticeTemplate(Frame)
        Frame.BottomLeftCorner:Hide()
        Frame.BottomRightCorner:Hide()
        Frame.TopLeftCorner:Hide()
        Frame.TopRightCorner:Hide()

        Frame.BottomBorder:Hide()
        Frame.TopBorder:Hide()
        Frame.LeftBorder:Hide()
        Frame.RightBorder:Hide()

        Frame.LeftHide:Hide()
        Frame.LeftHide2:Hide()
        Frame.RightHide:Hide()
        Frame.RightHide2:Hide()
        Frame.BottomHide:Hide()
        Frame.BottomHide2:Hide()

        Frame.Background:SetColorTexture(Color.black.r, Color.black.g, Color.black.b, 0.75)
        Frame.Background:SetPoint("TOPLEFT")
        Frame.Background:SetPoint("BOTTOMRIGHT")

        Frame.TopLeftFiligree:Hide()
        Frame.TopRightFiligree:Hide()

        Frame.NewSeason:SetTextColor(Color.white:GetRGB())
        Frame.SeasonDescriptionHeader:SetTextColor(Color.grayLight:GetRGB())

        Skin.UIPanelButtonTemplate(Frame.Leave)
    end
    function Skin.PVPRewardTemplate(Frame)
        Frame.Border:Hide()
        Base.CropCircularIcon(Frame.Icon, Frame)
    end
    Skin.PVPStandardRewardTemplate = Skin.PVPRewardTemplate
    Skin.PVPAchievementRewardTemplate = Skin.PVPRewardTemplate

    function Skin.PVPConquestBarTemplate(StatusBar)
        Skin.FrameTypeStatusBar(StatusBar)
        StatusBar.Border:Hide()
        StatusBar.Background:Hide()

        Skin.PVPConquestRewardButton(StatusBar.Reward)
        StatusBar.Reward:SetPoint("LEFT", StatusBar, "RIGHT", -5, 0)
    end
    function Skin.PVPQueueFrameButtonTemplate(Button)
        Skin.FrameTypeButton(Button)
        Button:SetBackdropOption("offsets", {
            left = 2,
            right = 0,
            top = -3,
            bottom = -5,
        })

        local bg = Button:GetBackdropTexture("bg")
        Util.SetHighlightColor(Button.Background, Color.frame.a)
        Button.Background:SetAllPoints(bg)
        Button.Background:Hide()

        Button.Ring:Hide()
        Base.CropIcon(Button.Icon)
    end
    function Skin.PVPCasualActivityButton(Button)
        -- Taint-safe: Do NOT call Skin.FrameTypeButton here.
        -- These buttons become HonorFrame.BonusFrame.selectedButton, and Blizzard
        -- reads .bgID/.arenaID/.queueID/.isBrawl from them in the protected
        -- HonorFrame_Queue() → C_PvP.JoinBattlefield() call chain.
        -- Writing to the button table (SetBackdrop, hooksecurefunc, SetButtonColor)
        -- taints it, causing ADDON_ACTION_FORBIDDEN on JoinBattlefield().
        Button:SetNormalTexture("")
        Button:SetPushedTexture("")
        Button:SetHighlightTexture("")
        Button:SetDisabledTexture("")

        Util.SetHighlightColor(Button.SelectedTexture, Color.frame.a)
        Button.SelectedTexture:ClearAllPoints()
        Button.SelectedTexture:SetPoint("TOPLEFT")
        Button.SelectedTexture:SetPoint("BOTTOMRIGHT")
    end
    function Skin.PVPCasualStandardButtonTemplate(Button)
        Skin.PVPCasualActivityButton(Button)
        Skin.PVPStandardRewardTemplate(Button.Reward)
    end
    function Skin.PVPCasualSpecialEventButtonTemplate(Button)
        Skin.PVPCasualActivityButton(Button)
        Skin.PVPAchievementRewardTemplate(Button.Reward)
    end
    function Skin.PVPRatedActivityButtonTemplate(Button)
        -- Taint-safe: Do NOT call Skin.FrameTypeButton here.
        -- These buttons become ConquestFrame.selectedButton, and Blizzard reads
        -- .id from them in the protected ConquestFrameJoinButton_OnClick() path.
        Button:SetNormalTexture("")
        Button:SetPushedTexture("")
        Button:SetHighlightTexture("")
        Button:SetDisabledTexture("")

        Util.SetHighlightColor(Button.SelectedTexture, Color.frame.a)
        Button.SelectedTexture:ClearAllPoints()
        Button.SelectedTexture:SetPoint("TOPLEFT")
        Button.SelectedTexture:SetPoint("BOTTOMRIGHT")

        Skin.PVPStandardRewardTemplate(Button.Reward)
        Skin.PVPRatedTierTemplate(Button.Tier)
    end
end

function private.AddOns.Blizzard_PVPUI()
    -- Util.Mixin(_G.PVEFrameMixin, Hook.PVEFrameMixin)

    _G.hooksecurefunc("PVPQueueFrame_SelectButton", Hook.PVPQueueFrame_SelectButton)

    local PVPQueueFrame = _G.PVPQueueFrame
    local categoryButtons = PVPQueueFrame.CategoryButtons or {
        PVPQueueFrame.CategoryButton1,
        PVPQueueFrame.CategoryButton2,
        PVPQueueFrame.CategoryButton3,
        PVPQueueFrame.CategoryButton4,
        PVPQueueFrame.CategoryButton5,
    }
    for _, button in ipairs(categoryButtons) do
        if button then
            Skin.PVPQueueFrameButtonTemplate(button)
        end
    end

    ------------
    -- Casual --
    ------------
    local HonorFrame = _G.HonorFrame
    HonorFrame:SetPoint("BOTTOM")

    Skin.PVPConquestBarTemplate(HonorFrame.ConquestBar)
    Skin.InsetFrameTemplate(HonorFrame.Inset)
    Skin.LFGRoleButtonTemplate(HonorFrame.RoleList.TankIcon)
    Skin.LFGRoleButtonTemplate(HonorFrame.RoleList.HealerIcon)
    Skin.LFGRoleButtonTemplate(HonorFrame.RoleList.DPSIcon)
    Skin.DropdownButton(HonorFrame.TypeDropdown)
    -- Avoid tainting SpecificScrollBox directly — JoinButton reads .selectionID from it
    -- in a protected call (C_PvP.JoinBattlefield), so writing to its table would taint it.
    -- Instead, add the backdrop on a separate sibling frame positioned behind it.
    local scrollBoxBG = _G.CreateFrame("Frame", nil, HonorFrame.SpecificScrollBox:GetParent())
    scrollBoxBG:SetAllPoints(HonorFrame.SpecificScrollBox)
    scrollBoxBG:SetFrameLevel(HonorFrame.SpecificScrollBox:GetFrameLevel() - 1)
    Base.SetBackdrop(scrollBoxBG, Color.frame)
    Skin.MinimalScrollBar(HonorFrame.SpecificScrollBar)

    local BonusFrame = HonorFrame.BonusFrame
    BonusFrame.WorldBattlesTexture:Hide()
    Skin.PVPCasualStandardButtonTemplate(BonusFrame.RandomBGButton)
    Skin.PVPCasualStandardButtonTemplate(BonusFrame.RandomEpicBGButton)
    Skin.PVPCasualStandardButtonTemplate(BonusFrame.Arena1Button)
    Skin.PVPCasualStandardButtonTemplate(BonusFrame.BrawlButton)
    Skin.PVPCasualStandardButtonTemplate(BonusFrame.BrawlButton2)
    BonusFrame.ShadowOverlay:Hide()

    -- Taint-safe: Do NOT call Skin.MagicButtonTemplate here.
    -- QueueButton's OnClick calls HonorFrame_Queue() → JoinBattlefield() (protected).
    -- FrameTypeButton writes SetButtonColor + Base.SetBackdrop (CreateTexture) onto
    -- the button, marking it addon-modified and intermittently tainting the call chain.
    do
        local btn = HonorFrame.QueueButton
        if btn.Left then
            btn.Left:SetAlpha(0)
            btn.Left:Hide()
            btn.Right:SetAlpha(0)
            btn.Right:Hide()
        end
        if btn.Middle then
            btn.Middle:SetAlpha(0)
            btn.Middle:Hide()
        end
        if btn.LeftSeparator then
            btn.LeftSeparator:Hide()
        end
        if btn.RightSeparator then
            btn.RightSeparator:Hide()
        end
        btn:SetPoint("BOTTOM", 0, 5)
    end

    -----------
    -- Rated --
    -----------
    local ConquestFrame = _G.ConquestFrame
    ConquestFrame:SetPoint("BOTTOM")
    ConquestFrame:Hide()

    ConquestFrame.RatedBGTexture:Hide()
    Skin.PVPConquestBarTemplate(ConquestFrame.ConquestBar)
    Skin.InsetFrameTemplate(ConquestFrame.Inset)
    Skin.LFGRoleButtonTemplate(ConquestFrame.RoleList.TankIcon)
    Skin.LFGRoleButtonTemplate(ConquestFrame.RoleList.HealerIcon)
    Skin.LFGRoleButtonTemplate(ConquestFrame.RoleList.DPSIcon)

    Skin.PVPRatedActivityButtonTemplate(ConquestFrame.RatedSoloShuffle)
    Skin.PVPRatedActivityButtonTemplate(ConquestFrame.RatedBGBlitz)
    Skin.PVPRatedActivityButtonTemplate(ConquestFrame.Arena2v2)
    Skin.PVPRatedActivityButtonTemplate(ConquestFrame.Arena3v3)
    Skin.PVPRatedActivityButtonTemplate(ConquestFrame.RatedBG)
    ConquestFrame.ShadowOverlay:Hide()

    -- Taint-safe: Do NOT call Skin.MagicButtonTemplate here.
    -- JoinButton's OnClick calls ConquestFrameJoinButton_OnClick() → protected PvP calls.
    do
        local btn = ConquestFrame.JoinButton
        if btn.Left then
            btn.Left:SetAlpha(0)
            btn.Left:Hide()
            btn.Right:SetAlpha(0)
            btn.Right:Hide()
        end
        if btn.Middle then
            btn.Middle:SetAlpha(0)
            btn.Middle:Hide()
        end
        if btn.LeftSeparator then
            btn.LeftSeparator:Hide()
        end
        if btn.RightSeparator then
            btn.RightSeparator:Hide()
        end
        btn:SetPoint("BOTTOM", 0, 5)
    end

    Skin.GlowBoxTemplate(ConquestFrame.NoSeason)
    Skin.GlowBoxTemplate(ConquestFrame.Disabled)

    ----------------
    -- HonorInset --
    ----------------
    local HonorInset = PVPQueueFrame.HonorInset
    Skin.InsetFrameTemplate(HonorInset)
    local _, bg2 = HonorInset:GetRegions()
    bg2:Hide()


    local CasualPanel = HonorInset.CasualPanel
    Skin.PVPHonorRewardTemplate(CasualPanel.HonorLevelDisplay.NextRewardLevel)

    local NextRewardLevel = CasualPanel.HonorLevelDisplay.NextRewardLevel
    Base.CropCircularIcon(NextRewardLevel.RewardIcon, NextRewardLevel)
    NextRewardLevel.IconCover:SetAllPoints(NextRewardLevel.RewardIcon)
    NextRewardLevel.RingBorder:Hide()


    local RatedPanel = HonorInset.RatedPanel
    Skin.SeasonRewardFrameTemplate(RatedPanel.SeasonRewardFrame)

    local NewSeasonPopup = PVPQueueFrame.NewSeasonPopup
    Skin.PVPSeasonChangesNoticeTemplate(NewSeasonPopup)
    NewSeasonPopup:SetPoint("TOPLEFT", ConquestFrame, 4, -3)
    NewSeasonPopup:SetPoint("BOTTOMRIGHT", 0, 0)
    NewSeasonPopup.SeasonRewardText:SetTextColor(Color.grayLight:GetRGB())
    Skin.SeasonRewardFrameTemplate(NewSeasonPopup.SeasonRewardFrame)

    --------------------------
    -- TrainingGroundsFrame --
    --------------------------
    local TrainingGroundsFrame = _G.TrainingGroundsFrame
    Skin.InsetFrameTemplate(TrainingGroundsFrame.Inset)
    Skin.LFGRoleButtonTemplate(TrainingGroundsFrame.RoleList.TankIcon)
    Skin.LFGRoleButtonTemplate(TrainingGroundsFrame.RoleList.HealerIcon)
    Skin.LFGRoleButtonTemplate(TrainingGroundsFrame.RoleList.DPSIcon)
    TrainingGroundsFrame.BonusTrainingGroundList.ShadowOverlay:Hide()
    -- Taint-safe: same pattern as HonorFrame/ConquestFrame queue buttons
    do
        local btn = TrainingGroundsFrame.QueueButton
        if btn.Left then
            btn.Left:SetAlpha(0)
            btn.Left:Hide()
            btn.Right:SetAlpha(0)
            btn.Right:Hide()
        end
        if btn.Middle then
            btn.Middle:SetAlpha(0)
            btn.Middle:Hide()
        end
        if btn.LeftSeparator then
            btn.LeftSeparator:Hide()
        end
        if btn.RightSeparator then
            btn.RightSeparator:Hide()
        end
    end
	for _, i in pairs({"RandomTrainingGroundButton"}) do
        local button = TrainingGroundsFrame.BonusTrainingGroundList[i]
        Skin.PVPCasualStandardButtonTemplate(button)
    end
    Skin.DropdownButton(_G.TrainingGroundsFrameTypeDropdown)
    _G.hooksecurefunc(TrainingGroundsFrame.SpecificTrainingGroundList.ScrollBox, "Update", Hook.PVPUIScrollBoxUpdate)
end
