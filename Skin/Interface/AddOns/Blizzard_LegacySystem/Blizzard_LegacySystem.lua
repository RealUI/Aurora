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
-- The reward track and the challenge page are flat like every other Aurora
-- surface (B211): Blizzard's card plates, frames, ribbons and buttons are
-- cleared, and the cards get Aurora backdrops, square icons and flat state
-- colours. The points crest and shields are kept: they carry the number, in
-- line with the PVPRankFrame badges.
--
-- **The tree page is deliberately left stock.** Its contents inherit
-- TalentButtonSquareTemplate, TalentEdgeArrowTemplate, TalentFrameBaseTemplate
-- and RingedMaskedButtonTemplate, none of which Aurora skins on any flavor, so
-- skinning it here would mean writing the shared talent-tree treatment as a
-- side effect of a Forever-only addon. That belongs with the talent frame.
--
-- Taint (.kiro/steering/objective-tracker-taint.md): the cards are pooled, so
-- Blizzard art is cleared with SetTexture("") (rule 2) and cleared again from
-- a post-hook on whichever Blizzard method re-sets the atlas; nothing on a card
-- is resized or re-anchored (rule 3); skin state lives in the weak-keyed local
-- tables below, never on the card (rule 1); no function is replaced and no
-- script is set (rules 6, 8).

-- Clear a Blizzard texture region. Nil-safe, so one missing region cannot
-- stop the rest of a skin (that is how B210 left the window half skinned).
local SkinTrackArrow -- defined with the reward track templates below

local function ClearArt(texture)
    if texture then
        texture:SetTexture("")
    end
end

do --[[ AddOns\Blizzard_LegacySystemTemplates.xml ]]
    -- Inherits LargeSideTabButtonTemplate -- the fourth surface to reuse it,
    -- after the character panel mode tabs, Professions and Collections.
    function Skin.LegacySystemTabTemplate(Frame)
        Skin.LargeSideTabButtonTemplate(Frame)
    end

    -- A StatusBar with a Legacy-Progressbar-Fill and a Legacy-Progressbar-Frame
    -- overlay. The fill is content; the frame is chrome, set only in XML.
    function Skin.LegacyProgressBarTemplate(StatusBar)
        if not StatusBar then return end

        ClearArt(StatusBar.ProgressBarFrame)
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
        ClearArt(Frame.ProgressBarBackground)

        Skin.LegacyProgressBarTemplate(Frame.PointsBar)

        -- Frame.Shield is left stock; see the note above.
    end
end

do --[[ AddOns\Blizzard_LegacyRewardTrack.xml ]]
    -- "current" (the last tier reached; Blizzard's green card), "earned" or
    -- "locked", from the last Refresh. Kept here, not on the pooled card.
    local cardState = _G.setmetatable({}, {__mode = "k"})
    -- The flat level tile that replaces the Legacy-Rewards-Tracker-Diamond.
    local levelTiles = _G.setmetatable({}, {__mode = "k"})

    -- Card border: highlight on hover, green on the current tier, plain
    -- otherwise. The level tile follows the same state.
    local function SetRewardCardColors(card, hovered)
        local state = cardState[card]

        local border = Color.button
        if hovered then
            border = Color.highlight
        elseif state == "current" then
            border = Color.green
        end
        card:SetBackdropBorderColor(border, 1)

        local tile = levelTiles[card]
        if tile then
            local fill
            if state == "current" then
                fill = Color.Lightness(Color.green, -0.5)
            elseif state == "earned" then
                fill = Color.button
            else
                fill = Color.Lightness(Color.button, -0.3)
            end
            tile.border:SetColorTexture(border:GetRGB())
            tile.fill:SetColorTexture(fill:GetRGB())
        end
    end

    -- RenownLevelMixin:Refresh re-sets the card plate, the hover plate, the
    -- icon ring and the level diamond (SetAtlas) on every call, so they are
    -- cleared again after it. EarnedCheckmark is the unlocked cue and stays.
    local function ClearRewardArt(card)
        ClearArt(card.RewardCardBG)
        ClearArt(card.Highlight)
        ClearArt(card.IconBorder)
        ClearArt(card.LevelSquare)
    end

    local function OnRewardCardRefresh(card, _, displayLevel)
        local level = card.GetLevel and card:GetLevel() or 0
        local state = "locked"
        if type(displayLevel) == "number" and level <= displayLevel then
            state = level == displayLevel and "current" or "earned"
        end
        cardState[card] = state

        ClearRewardArt(card)
        SetRewardCardColors(card, card:IsMouseOver())
    end

    local function OnRewardCardEnter(card)
        SetRewardCardColors(card, true)
    end
    local function OnRewardCardLeave(card)
        SetRewardCardColors(card, false)
    end

    function Skin.LegacyRewardCardTemplate(Frame)
        if not Frame or private.IsSkinned(Frame) then return end
        private.SetSkinned(Frame, true)

        Base.SetBackdrop(Frame, Color.button)
        if Frame.Icon then
            Base.CropIcon(Frame.Icon, Frame)
        end

        -- The level number sits on the diamond at the top edge of the card;
        -- a flat tile takes its place under the number (Level is OVERLAY).
        -- These are new textures of our own, anchored to the diamond; the
        -- diamond itself is not resized or moved.
        if Frame.LevelSquare then
            local border = Frame:CreateTexture(nil, "ARTWORK", nil, 6)
            border:SetSize(34, 22)
            border:SetPoint("CENTER", Frame.LevelSquare)
            local fill = Frame:CreateTexture(nil, "ARTWORK", nil, 7)
            fill:SetPoint("TOPLEFT", border, 1, -1)
            fill:SetPoint("BOTTOMRIGHT", border, -1, 1)
            levelTiles[Frame] = {border = border, fill = fill}
        end

        ClearRewardArt(Frame)
        if Frame.Refresh then
            _G.hooksecurefunc(Frame, "Refresh", OnRewardCardRefresh)
        end

        -- Blizzard shows Highlight (the card plate drawn additively) on hover;
        -- it is cleared above, and the border takes the hover instead. The
        -- card is a Frame, so Base.SetHighlight (it calls IsEnabled) does
        -- not apply.
        Frame:HookScript("OnEnter", OnRewardCardEnter)
        Frame:HookScript("OnLeave", OnRewardCardLeave)
        SetRewardCardColors(Frame, false)
    end

    -- The track's scroll arrows (RewardTrackButtonTemplate) and jump arrows
    -- (RewardTrackJumpButtonTemplate) are only shown when the track scrolls.
    -- Same treatment as Aurora's nav buttons: a flat button with a drawn
    -- arrow; the jump arrows get a double arrow.
    function SkinTrackArrow(Button, isRight, isJump)
        if not Button or private.IsSkinned(Button) then return end
        private.SetSkinned(Button, true)

        Skin.FrameTypeButton(Button)

        local arrows = {}
        local count = isJump and 2 or 1
        for i = 1, count do
            local arrow = Button:CreateTexture(nil, "ARTWORK")
            if isJump then
                arrow:SetSize(5, 9)
                arrow:SetPoint("CENTER", i == 1 and -3 or 3, 0)
            else
                arrow:SetSize(7, 12)
                arrow:SetPoint("CENTER")
            end
            Base.SetTexture(arrow, isRight and "arrowRight" or "arrowLeft")
            arrows[i] = arrow
        end
        -- Greyed by Skin.FrameTypeButton's enable/disable repaint, as the
        -- arrows of Skin.NavButtonPrevious/Next are.
        Skin.SetButtonTextures(Button, arrows)
    end
end

do --[[ AddOns\Blizzard_LegacyChallenge*.xml, Blizzard_LegacySystemTemplates.xml ]]
    -- Pooled rows are tracked here, not with private.SetSkinned: Aurora's
    -- Hook.AchievementTemplateMixin:Init (which the legacy cards inherit)
    -- recolours any IsSkinned card through its NineSlice, and these have none.
    local skinned = _G.setmetatable({}, {__mode = "k"})
    -- The flat +/- box that replaces the red 128-redbutton-plus/minus.
    local plusMinus = _G.setmetatable({}, {__mode = "k"})

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

    -- RefreshStateArt re-sets the plate and the three expanded-card pieces
    -- and shows SelectedOverlay; Saturate/Desaturate re-set the TitleBar
    -- ribbon after it. All are cleared again after each of those calls.
    local CARD_ART = {"Background", "BackgroundTop", "BackgroundMiddle", "BackgroundBottom", "SelectedOverlay", "TitleBar"}
    local function OnCardArt(card)
        for i = 1, #CARD_ART do
            ClearArt(card[CARD_ART[i]])
        end
        SetCardBorder(card)
    end

    -- UpdatePlusMinusTexture shows or hides PlusMinus and re-sets its atlas
    -- (UpdatePlusMinusArt); it runs from Init, Collapse, Expand, Saturate
    -- and Desaturate, with `collapsed` already set.
    local function UpdatePlusMinus(card)
        local box = plusMinus[card]
        if not box or not card.PlusMinus then return end

        ClearArt(card.PlusMinus)
        box.frame:SetShown(card.PlusMinus:IsShown())
        box.plus:SetShown(not not card.collapsed)
    end
    local function CreatePlusMinus(card)
        local PlusMinus = card.PlusMinus
        if not PlusMinus then return end

        -- A child frame of our own over the region; not mouse-enabled, so
        -- clicks still reach the card's own OnClick.
        local frame = _G.CreateFrame("Frame", nil, card)
        frame:SetAllPoints(PlusMinus)
        Base.SetBackdrop(frame, Color.button)

        local plus = frame:CreateTexture(nil, "ARTWORK")
        plus:SetSize(1, 9)
        plus:SetPoint("CENTER")
        plus:SetColorTexture(1, 1, 1) -- static: not a theme color

        local minus = frame:CreateTexture(nil, "ARTWORK")
        minus:SetSize(9, 1)
        minus:SetPoint("CENTER")
        minus:SetColorTexture(1, 1, 1) -- static: not a theme color

        plusMinus[card] = {frame = frame, plus = plus}
        if card.UpdatePlusMinusTexture then
            _G.hooksecurefunc(card, "UpdatePlusMinusTexture", UpdatePlusMinus)
        end
        UpdatePlusMinus(card)
    end

    -- The Track checkbox (AchievementCheckButtonBaseTemplate) shown on a
    -- selected, unfinished challenge. Restyled in place: its label sits to the
    -- left of the box here, so nothing is re-anchored.
    local function SkinTracked(CheckButton)
        if not CheckButton then return end

        Skin.FrameTypeCheckButton(CheckButton)
        local check = CheckButton:GetCheckedTexture()
        if check then
            check:SetDesaturated(true)
            check:SetVertexColor(Color.highlight:GetRGB())
        end
    end

    function Skin.LegacyChallengeTemplate(EventButton)
        if skinned[EventButton] then
            SetCardBorder(EventButton)
            return
        end
        skinned[EventButton] = true

        Base.SetBackdrop(EventButton, Color.frame)

        local Icon = EventButton.Icon
        if Icon then
            -- Legacy-Tree-Frame-icon-frame is set only in XML (the legacy
            -- UpdateHeaderArt is a no-op). CropIcon drops the rounded
            -- UI-Frame-IconMask, so the icon is square.
            ClearArt(Icon.frame)
            if Icon.texture then
                Base.CropIcon(Icon.texture, Icon)
            end
        end

        -- The points shield keeps its icon (it carries the number); the
        -- Legacy-Challenge-Cards-Date-BG plate behind the completion date and
        -- check is set only in XML and only shown or hidden after.
        if EventButton.Shield then
            ClearArt(EventButton.Shield.CheckBackground)
        end

        CreatePlusMinus(EventButton)
        SkinTracked(EventButton.Tracked)

        for _, method in next, {"RefreshStateArt", "Saturate", "Desaturate"} do
            if EventButton[method] then
                _G.hooksecurefunc(EventButton, method, OnCardArt)
            end
        end
        EventButton:HookScript("OnEnter", SetCardBorder)
        EventButton:HookScript("OnLeave", SetCardBorder)
        OnCardArt(EventButton)
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
        ClearArt(Frame.ProgressBarBackground)
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
        -- Legacy-Rewards-Tracker-background, the page plate, and the
        -- Legacy-Progressbar-BG under the track bar. The crest at the top
        -- (Icon, with Points on it) is kept, like the shields.
        ClearArt(RewardTrackPage.Background)
        ClearArt(RewardTrackPage.ProgressBarBackground)

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

            SkinTrackArrow(ProgressFrame.LeftButton, false, false)
            SkinTrackArrow(ProgressFrame.RightButton, true, false)
            SkinTrackArrow(ProgressFrame.JumpLeftButton, false, true)
            SkinTrackArrow(ProgressFrame.JumpRightButton, true, true)

            -- The paragon plate after the last card, if the track has one.
            -- Its art is set only in XML; Init sets the icon texture, which
            -- keeps the crop.
            local Paragon = ProgressFrame.ClipFrame and ProgressFrame.ClipFrame.ParagonLevelFrame
            if Paragon then
                ClearArt(Paragon.Divider)
                ClearArt(Paragon.LabelBackground)
                ClearArt(Paragon.IconBorder)
                if Paragon.Icon then
                    Base.CropIcon(Paragon.Icon, Paragon)
                end
                if Paragon.HighlightTexture then
                    Base.CropIcon(Paragon.HighlightTexture)
                end
            end
        end
    end

    ----====#####################====----
    --          ChallengesPage         --
    ----====#####################====----
    local ChallengesPage = LegacySystemFrame.ChallengesPage
    if ChallengesPage then
        -- Legacy-Challenge-BG, the brown plate behind the whole page.
        ClearArt(ChallengesPage.Background)

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
