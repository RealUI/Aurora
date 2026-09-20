local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals next

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

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
    -- PVPRankFrame badges and the stable happiness face.
    function Skin.LegacyPointShield(Button)
        if not Button then return end
        Base.SetHighlight(Button)
    end

    function Skin.LegacyChallengePointSummaryTemplate(Frame)
        if not Frame then return end

        -- Legacy-Progressbar-BG behind the bar; Aurora's backdrop replaces it.
        if Frame.ProgressBarBackground then
            Frame.ProgressBarBackground:SetAlpha(0)
        end

        Skin.LegacyProgressBarTemplate(Frame.PointsBar)

        if Frame.Shield then
            Skin.LegacyPointShield(Frame.Shield)
        end
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
    end
end

local function SkinScrollArea(Frame)
    if not Frame then return end
    Skin.WowScrollBoxList(Frame.ScrollBox)
    Skin.MinimalScrollBar(Frame.ScrollBar)
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
        SkinScrollArea(ChallengesPage.CategoryList)
        SkinScrollArea(ChallengesPage.DetailPane)

        Skin.LegacyChallengePointSummaryTemplate(ChallengesPage.LegacyChallengePointSummary)

        -- A plain divider between the list and the detail pane.
        if ChallengesPage.VerticalDivider then
            ChallengesPage.VerticalDivider:SetAlpha(0)
        end
    end

    -- TreePage: see the note at the top of this file. Left stock.
end
