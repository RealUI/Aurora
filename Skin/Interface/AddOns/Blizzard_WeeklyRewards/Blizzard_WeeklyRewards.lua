local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook = Aurora.Hook
local Skin = Aurora.Skin
local Color = Aurora.Color
local Util = Aurora.Util

do
    Hook.WeeklyRewardConfirmSelectionMixin = {}
    function Hook.WeeklyRewardConfirmSelectionMixin:RefreshRewards()
        local alsoItemsFrame = self.AlsoItemsFrame
        if alsoItemsFrame then
            Util.WrapPoolAcquire(alsoItemsFrame.pool, Skin.WeeklyRewardAlsoItemTemplate)
        end
    end

    function Hook.UpdateRewardSelection(frame)
        if not frame._auroraBG then
            return
        end
        _G.print("updateSelection got bg")
        if frame.SelectedTexture:IsShown() then
                frame.bg:SetBackdropBorderColor(1, .8, 0)
        else
                frame.bg:SetBackdropBorderColor(0, 0, 0)
        end
    end

    -- local IconColor = _G.ITEM_QUALITY_COLORS[_G.Enum.ItemQuality.Epic]
    function Hook.RewardIcon(ItemFrame)
        if not private.IsSkinned(ItemFrame) then
            Skin.FrameTypeFrame(ItemFrame)
            ItemFrame.Icon:SetPoint('LEFT', 6, 0)
            ItemFrame:DisableDrawLayer("BORDER")
            ItemFrame.bg = Base.CropIcon(ItemFrame.Icon, ItemFrame)
            private.SetSkinned(ItemFrame, true)
        end
    end

    function Skin.ActivityFrame(Frame, isObject)
        if Frame.Border then
            if isObject then
                _G.hooksecurefunc(Frame, "SetSelectionState", Hook.UpdateRewardSelection)
                _G.hooksecurefunc(Frame.ItemFrame, "SetDisplayedItem", Hook.RewardIcon)
            else
                Skin.ActivityFrameRewardsFrame(Frame)
            end
        end
    end
    function Hook.ReplaceRewardsTextIcon(frame, text)
        if not text then text = frame:GetText() end
        if not text or text == "" then return end
        local NewText, count = _G.gsub(text, "24:24:0:%-2", "14:14:0:0:64:64:5:59:5:59")
        if count > 0 then frame:SetFormattedText("%s", NewText) end
    end

    function Skin.ActivityFrameRewardsFrame(Frame)
        local frameBG = _G.CreateFrame("Frame", nil, Frame)
        frameBG:SetFrameLevel(Frame:GetFrameLevel())
        Base.SetBackdrop(frameBG, Color.frame)
        Frame._auroraBG = frameBG
    end

    function Skin.WeeklyRewardAlsoItemTemplate(Frame)
        Base.CropIcon(Frame.Icon)
    end
end


function private.AddOns.Blizzard_WeeklyRewards()
    local WeeklyRewardsFrame = _G.WeeklyRewardsFrame
    _G.hooksecurefunc(_G.WeeklyRewardConfirmSelectionMixin, "RefreshRewards", Hook.WeeklyRewardConfirmSelectionMixin.RefreshRewards)

    local HeaderFrame = WeeklyRewardsFrame.HeaderFrame
    if HeaderFrame then
        HeaderFrame:ClearAllPoints()
        HeaderFrame:SetPoint("TOP", WeeklyRewardsFrame, "TOP", 1, -42)
        Base.StripBlizzardTextures(HeaderFrame)
        HeaderFrame:SetHeight(64)
        HeaderFrame.Text:SetPoint("TOP", 0, -10)
        HeaderFrame.Text:SetFontObject("SystemFont_Shadow_Huge2")
        HeaderFrame.Text:SetShadowOffset(0, 0)
    end
    Base.StripBlizzardTextures(WeeklyRewardsFrame.BorderContainer)
    -- WeeklyRewardsFrame.BorderContainer:SetAlpha(0)
    -- WeeklyRewardsFrame.ConcessionFrame:SetAlpha(0)

    Base.StripBlizzardTextures(WeeklyRewardsFrame.SelectRewardButton)
    Skin.UIPanelButtonTemplate(WeeklyRewardsFrame.SelectRewardButton)
    WeeklyRewardsFrame.SelectRewardButton:SetPoint("BOTTOM", 0, 15)
    Skin.UIPanelCloseButton(WeeklyRewardsFrame.CloseButton)
    Skin.ActivityFrame(WeeklyRewardsFrame.RaidFrame)
    Skin.ActivityFrame(WeeklyRewardsFrame.MythicFrame)
    Skin.ActivityFrame(WeeklyRewardsFrame.PVPFrame)
    Skin.ActivityFrame(WeeklyRewardsFrame.WorldFrame)
    for _, Frame in pairs(WeeklyRewardsFrame.Activities) do
        Skin.ActivityFrame(Frame, true)
    end
    local ConcessionFrame = WeeklyRewardsFrame.ConcessionFrame
    local RewardsText = ConcessionFrame.RewardsFrame.Text
    Base.StripBlizzardTextures(ConcessionFrame)
    -- local RewardsFrame = ConcessionFrame.RewardsFrame
    -- Skin.UIPanelDynamicResizeButtonTemplate(RewardsFrame)
    Hook.ReplaceRewardsTextIcon(RewardsText)
    _G.hooksecurefunc(RewardsText, "SetText", Hook.ReplaceRewardsTextIcon)
end
