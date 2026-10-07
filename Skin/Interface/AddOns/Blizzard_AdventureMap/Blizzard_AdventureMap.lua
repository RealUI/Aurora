local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals _G

--[[ Core ]]
local Aurora = private.Aurora
local Base, Hook = Aurora.Base, Aurora.Hook
local Skin = Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

do --[[ AddOns\Blizzard_AdventureMap.lua ]]
    -- Quest dialog rewards (taint audit 2026-10-06, B170 follow-up): restyled
    -- in place after RefreshRewards has added and anchored them, never from
    -- the pool's Acquire (the old Acquire skin created a backdrop frame and an
    -- icon border on rewards AddReward went on to fill and anchor).
    function Hook.AdventureMapQuestChoiceDialog_RefreshRewards(self)
        for reward in self.rewardPool:EnumerateActive() do
            Util.SkinOnce(reward, Skin.AdventureMapQuestRewardTemplate)
        end
    end
end

do --[[ AddOns\Blizzard_AdventureMap.xml ]]
    -- In place only: ItemNameBG (the band beside the icon) becomes the flat
    -- name panel, the icon is cropped without a border texture.
    function Skin.AdventureMapQuestRewardTemplate(Button)
        Base.CropIcon(Button.Icon)
        Button.ItemNameBG:SetColorTexture(Color.frame.r, Color.frame.g, Color.frame.b, Color.frame.a)
    end
    -- Map insets live on the map canvas (pooled by the canvas, Acquire
    -- post-hook below): in place only. The close button keeps Blizzard's art;
    -- skinning it created textures and a backdrop mid map update.
    function Skin.AdventureMapInsetTemplate(Frame)
        Frame.ExpandedFrame.Border:SetTexture("")
        Frame.CollapsedFrame.TextBackground:SetAlpha(0)
    end
end

function private.AddOns.Blizzard_AdventureMap()
    ----====####################====----
    --   Blizzard_AdventureMapUtils   --
    ----====####################====----


    ----====####################====----
    --   AM_ZoneSummaryDataProvider   --
    ----====####################====----


    ----====####################====----
    --         AM_QuestDialog         --
    ----====####################====----
    local AdventureMapQuestChoiceDialog = _G.AdventureMapQuestChoiceDialog

    _G.hooksecurefunc(AdventureMapQuestChoiceDialog, "RefreshRewards", Hook.AdventureMapQuestChoiceDialog_RefreshRewards)

    -- AdventureMapFrame is no longer a named global; the pool is created inside
    -- AdventureMapMixin:OnLoad, so hook the mixin to wrap it after it is set up.
    _G.hooksecurefunc(_G.AdventureMapMixin, "OnLoad", function(self)
        Util.WrapPoolAcquire(self:GetMapInsetPool(), "AdventureMapInsetTemplate")
    end)

    AdventureMapQuestChoiceDialog.Rewards:SetAlpha(0)
    AdventureMapQuestChoiceDialog.Background:Hide()

    Skin.FrameTypeFrame(AdventureMapQuestChoiceDialog)
    AdventureMapQuestChoiceDialog:SetBackdropOption("offsets", {
        left = 3,
        right = 3,
        top = 14,
        bottom = -1,
    })

    Skin.UIPanelCloseButton(AdventureMapQuestChoiceDialog.CloseButton)

    local ScrollBar = AdventureMapQuestChoiceDialog.Details.ScrollBar
    Skin.FrameTypeScrollBar(ScrollBar)
    if ScrollBar.Top then ScrollBar.Top:Hide() end
    if ScrollBar.Bottom then ScrollBar.Bottom:Hide() end
    if ScrollBar.Middle then ScrollBar.Middle:Hide() end
    if ScrollBar.Background then ScrollBar.Background:Hide() end

    Skin.UIPanelButtonTemplate(AdventureMapQuestChoiceDialog.DeclineButton)
    Skin.UIPanelButtonTemplate(AdventureMapQuestChoiceDialog.AcceptButton)


    ----====####################====----
    --   AM_QuestChoiceDataProvider   --
    ----====####################====----


    ----====#####################====----
    --    AM_QuestOfferDataProvider    --
    ----====#####################====----


    ----====####################====----
    --     AM_MissionDataProvider     --
    ----====####################====----


    ----====####################====----
    --   Blizzard_AdventureMapInset   --
    ----====####################====----


    ----====#####################====----
    --      Blizzard_AdventureMap      --
    ----====#####################====----

end
