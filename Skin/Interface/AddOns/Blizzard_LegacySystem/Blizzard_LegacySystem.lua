local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals next

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color = Aurora.Color

-- Forever-only addon (## AllowLoadGameType: camelot), LoadOnDemand: the Legacy
-- system -- the "Progress Track" window. Three pages behind side tabs: a reward
-- track, a challenge list with a detail pane, and a talent-style legacy tree.
--
-- Scope of this pass: the frame, the tabs, the reward track and the challenge
-- page. **The tree page is deliberately left stock.** Its contents inherit
-- TalentButtonSquareTemplate, TalentEdgeArrowTemplate, TalentFrameBaseTemplate
-- and RingedMaskedButtonTemplate, none of which Aurora skins on any flavor, so
-- skinning it here would mean writing the shared talent-tree treatment as a
-- side effect of a Forever-only addon. That belongs with the talent frame.

do --[[ AddOns\Blizzard_LegacySystemTemplates.xml ]]
    -- Inherits LargeSideTabButtonTemplate -- the fourth surface to reuse it,
    -- after the character panel mode tabs, Professions and Collections.
    function Skin.LegacySystemTabTemplate(Frame)
        Skin.LargeSideTabButtonTemplate(Frame)
    end

    -- A StatusBar with a Legacy-Progressbar-Fill and a Legacy-Progressbar-Frame
    -- overlay. The fill is content; the frame is chrome.
    function Skin.LegacyProgressBarTemplate(StatusBar)
        if not StatusBar then return end

        if StatusBar.ProgressBarFrame then
            StatusBar.ProgressBarFrame:SetAlpha(0)
        end

        Skin.FrameTypeStatusBar(StatusBar)
    end

    -- The points readout: a UI-Legacy-Points-icon-c60 shield with the number on
    -- top. The shield is the affordance and is kept, in line with the
    -- PVPRankFrame badges and the stable happiness face -- which means there is
    -- nothing here to skin.
    --
    -- It previously called Base.SetHighlight, which threw
    -- "api.lua:250: attempt to call a nil value": SetHighlight reads
    -- GetBackdropColor to work out the colour to return to, so it only works on
    -- a frame that already has an Aurora backdrop. This button has none, and
    -- should not get one.

    function Skin.LegacyChallengePointSummaryTemplate(Frame)
        if not Frame then return end

        -- Legacy-Progressbar-BG behind the bar; Aurora's backdrop replaces it.
        if Frame.ProgressBarBackground then
            Frame.ProgressBarBackground:SetAlpha(0)
        end

        Skin.LegacyProgressBarTemplate(Frame.PointsBar)

        -- Frame.Shield is left stock; see the note above.
    end
end

do --[[ AddOns\Blizzard_LegacyRewardTrack.xml ]]
    function Skin.LegacyRewardCardTemplate(Frame)
        if not Frame or private.IsSkinned(Frame) then return end
        private.SetSkinned(Frame, true)

        -- RewardCardBG is the card plate and IconBorder the gold ring around
        -- the reward icon; both are chrome. LevelSquare carries the required
        -- level and EarnedCheckmark whether it is unlocked, so both stay.
        if Frame.RewardCardBG then
            Frame.RewardCardBG:SetAlpha(0)
        end
        if Frame.IconBorder then
            Frame.IconBorder:SetAlpha(0)
        end

        Base.SetBackdrop(Frame, Color.button)
        Base.CropIcon(Frame.Icon, Frame)

        -- Highlight (70532) is the card-plate atlas drawn additively on hover,
        -- which would bring back the plate faded out above. Blizzard only
        -- toggles it with SetShown, so the alpha holds. The card is a Frame,
        -- so Base.SetHighlight (it calls IsEnabled) does not apply.
        if Frame.Highlight then
            Frame.Highlight:SetAlpha(0)
            Frame:HookScript("OnEnter", function(card)
                card:SetBackdropBorderColor(Color.highlight, 1)
            end)
            Frame:HookScript("OnLeave", function(card)
                card:SetBackdropBorderColor(Color.button, 1)
            end)
        end
    end
end

do --[[ AddOns\Blizzard_LegacyChallenge*.xml, Blizzard_LegacySystemTemplates.xml ]]
    -- Pooled rows are tracked here, not with private.SetSkinned: Aurora's
    -- Hook.AchievementTemplateMixin:Init (which the legacy cards inherit)
    -- recolours any IsSkinned card through its NineSlice, and these have none.
    local skinned = _G.setmetatable({}, {__mode = "k"})

    -- LegacyChallengeCategoryTemplate is a ListHeaderVisualTemplate whose
    -- RefreshCardArt re-sets both atlases on every Init and SetSelected, so
    -- the flat colours go back on after each call. Parents keep the header
    -- band; leaves get a quieter band, and the selected leaf the highlight.
    local function SetCategoryArt(button)
        local normal = button:GetNormalTexture()
        local highlight = button:GetHighlightTexture()
        if normal then
            if button.collapsable then
                local r, g, b = Color.button:GetRGB()
                normal:SetColorTexture(r, g, b, 0.6)
            elseif button.selected then
                local r, g, b = Color.highlight:GetRGB()
                normal:SetColorTexture(r, g, b, 0.5)
            else
                local r, g, b = Color.button:GetRGB()
                normal:SetColorTexture(r, g, b, 0.3)
            end
        end
        if highlight then
            local r, g, b = Color.highlight:GetRGB()
            highlight:SetColorTexture(r, g, b, 0.25)
        end
    end
    function Skin.LegacyChallengeCategoryTemplate(Button)
        if not skinned[Button] then
            skinned[Button] = true
            _G.hooksecurefunc(Button, "RefreshCardArt", SetCategoryArt)
        end
        SetCategoryArt(Button)
    end

    -- Card border: the highlight while selected or hovered, otherwise plain.
    local function SetCardBorder(card)
        local lit = card:IsMouseOver() or (card.IsSelected and card:IsSelected())
        card:SetBackdropBorderColor(lit and Color.highlight or Color.button, 1)
    end
    function Skin.LegacyChallengeTemplate(EventButton)
        if skinned[EventButton] then
            SetCardBorder(EventButton)
            return
        end
        skinned[EventButton] = true

        -- RefreshStateArt and Saturate/Desaturate re-set these atlases and
        -- toggle them with SetShown; alpha 0 holds through both.
        for _, key in next, {"Background", "BackgroundTop", "BackgroundMiddle", "BackgroundBottom", "SelectedOverlay", "TitleBar"} do
            if EventButton[key] then
                EventButton[key]:SetAlpha(0)
            end
        end
        Base.SetBackdrop(EventButton, Color.frame)

        local Icon = EventButton.Icon
        if Icon and Icon.texture then
            if Icon.frame then Icon.frame:SetAlpha(0) end
            Base.CropIcon(Icon.texture, Icon)
        end

        _G.hooksecurefunc(EventButton, "RefreshStateArt", SetCardBorder)
        EventButton:HookScript("OnEnter", SetCardBorder)
        EventButton:HookScript("OnLeave", SetCardBorder)
        SetCardBorder(EventButton)
    end

    -- Objective rows: Background is a static atlas Blizzard only shows or
    -- hides, so one flat tint holds. Counted criteria use the point bar.
    function Skin.LegacyChallengeCriteriaTemplate(Frame)
        if skinned[Frame] then return end
        skinned[Frame] = true

        if Frame.Background then
            local r, g, b = Color.button:GetRGB()
            Frame.Background:SetColorTexture(r, g, b, 0.5)
        end
        if Frame.ProgressBarBackground then
            Frame.ProgressBarBackground:SetAlpha(0)
        end
        Skin.LegacyProgressBarTemplate(Frame.ProgressBar)
    end
end

local function SkinScrollArea(Frame)
    if not Frame then return end
    Skin.WowScrollBoxList(Frame.ScrollBox)
    Skin.MinimalScrollBar(Frame.ScrollBar)
end

-- Rows are built by the list views' factories; skin each after Blizzard's
-- initializer has run (same path as the Social UI and trainer lists).
local function SkinScrollRows(ScrollBox, skinRow)
    if not ScrollBox then return end
    if _G.ScrollUtil and _G.ScrollUtil.AddInitializedFrameCallback then
        _G.ScrollUtil.AddInitializedFrameCallback(ScrollBox, function(_, row)
            skinRow(row)
        end, ScrollBox)
    end
    ScrollBox:ForEachFrame(skinRow)
end

function private.AddOns.Blizzard_LegacySystem()
    local LegacySystemFrame = _G.LegacySystemFrame
    if not LegacySystemFrame then return end

    Skin.PortraitFrameTemplate(LegacySystemFrame)

    -- Tabs come from the parentArray rather than a fixed 1..3, the same way the
    -- character panel and Collections build theirs.
    for _, tab in next, (LegacySystemFrame.Tabs or {}) do
        Skin.LegacySystemTabTemplate(tab)
    end

    ----====#####################====----
    --          RewardTrackPage        --
    ----====#####################====----
    local RewardTrackPage = LegacySystemFrame.RewardTrackPage
    if RewardTrackPage then
        Skin.LegacyProgressBarTemplate(RewardTrackPage.LegacyRewardProgressBar)

        -- Cards are acquired from RewardTrackFrameMixin's elementPool on the
        -- LegacyRewardProgressFrame (elementTemplate is a KeyValue, so there is
        -- no named pool on the page itself). Init releases and re-acquires the
        -- whole set, so hook that -- and sweep first, because the page may
        -- already have been populated before this skin runs. Hooking alone
        -- would have missed the initial set, which is what the talent tab strip
        -- got wrong.
        local ProgressFrame = RewardTrackPage.LegacyRewardProgressFrame
        if ProgressFrame then
            local function SkinCards(self)
                if not self.elementPool then return end
                for card in self.elementPool:EnumerateActive() do
                    Skin.LegacyRewardCardTemplate(card)
                end
            end

            SkinCards(ProgressFrame)
            if ProgressFrame.Init then
                _G.hooksecurefunc(ProgressFrame, "Init", SkinCards)
            end
        end
    end

    ----====#####################====----
    --          ChallengesPage         --
    ----====#####################====----
    local ChallengesPage = LegacySystemFrame.ChallengesPage
    if ChallengesPage then
        -- Legacy-Challenge-BG, the brown plate behind the whole page.
        if ChallengesPage.Background then
            ChallengesPage.Background:SetAlpha(0)
        end

        local CategoryList = ChallengesPage.CategoryList
        SkinScrollArea(CategoryList)
        if CategoryList then
            if CategoryList.SearchBox then
                Skin.SearchBoxTemplate(CategoryList.SearchBox)
            end
            if CategoryList.FilterDropdown then
                Skin.FilterButton(CategoryList.FilterDropdown)
            end
            SkinScrollRows(CategoryList.ScrollBox, function(row)
                if row.RefreshCardArt then
                    Skin.LegacyChallengeCategoryTemplate(row)
                end
            end)
        end

        local DetailPane = ChallengesPage.DetailPane
        SkinScrollArea(DetailPane)
        if DetailPane then
            SkinScrollRows(DetailPane.ScrollBox, function(row)
                if row.RefreshStateArt then
                    Skin.LegacyChallengeTemplate(row)
                end
            end)
        end

        -- One shared objectives frame, reparented to the selected card;
        -- its criteria come from a pool, so skin them after each Display.
        local Objectives = _G.LegacyChallengeObjectives
        if Objectives and Objectives.criteriaPool then
            _G.hooksecurefunc(Objectives, "Display", function(self)
                for criteria in self.criteriaPool:EnumerateActive() do
                    Skin.LegacyChallengeCriteriaTemplate(criteria)
                end
            end)
        end

        Skin.LegacyChallengePointSummaryTemplate(ChallengesPage.LegacyChallengePointSummary)

        -- A plain divider between the list and the detail pane.
        if ChallengesPage.VerticalDivider then
            ChallengesPage.VerticalDivider:SetAlpha(0)
        end
    end

    -- TreePage: see the note at the top of this file. Left stock.
end
