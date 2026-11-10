local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals _G ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color = Aurora.Color
local Util = Aurora.Util

--[[ 12.1 Blizzard_SocialUI: the Social UI hub (SocialUIFrame,
    PortraitFrameTemplate) that replaces FriendsFrame when
    C_SocialUI.IsSystemEnabled(). Boot-loaded on Mainline; the frame and its
    per-tab content frames (created in Lua by CreateTabContentFrame at
    OnLoad) exist by the time this module runs. Shared template skins live
    in Blizzard_SocialUIShared. Tabs are LargeSideTabButtonTemplate pooled
    buttons anchored outside the frame's right edge.
    The FriendsFrame skin is untouched — both UIs coexist behind the
    C_SocialUI gate.
]]

do --[[ SocialUITemplates.xml ]]
    -- Pooled (socialTabPool, Acquire post-hook): in place only. The icon is
    -- cropped without a parent, so no border texture is created on the tab
    -- (taint audit 2026-10-06, B170 follow-up).
    function Skin.SocialUITabTemplate(Button)
        -- LargeSideTabButtonTemplate + a Count fontstring
        -- B223: alpha-zeroing Background left bare icons. Recolour Blizzard's
        -- own regions instead (no new textures): Background becomes the flat
        -- button fill, and selection/hover lose the tab silhouette, matching
        -- Skin.LargeSideTabButtonTemplate. Only the regions are re-anchored,
        -- never the tab itself.
        if Button.Background then
            local fill = Color.Lightness(Color.button, -0.3)
            Button.Background:ClearAllPoints()
            Button.Background:SetAllPoints(Button)
            Button.Background:SetColorTexture(fill.r, fill.g, fill.b, 1)
        end
        if Button.SelectedTexture then
            -- Blizzard still shows/hides it on selection (SetChecked)
            Button.SelectedTexture:ClearAllPoints()
            Button.SelectedTexture:SetAllPoints(Button)
            Util.SetHighlightColor(Button.SelectedTexture, 0.5)
        end
        if Button.HighlightTexture then
            Button.HighlightTexture:ClearAllPoints()
            Button.HighlightTexture:SetAllPoints(Button)
            Util.SetHighlightColor(Button.HighlightTexture, 0.2)
        end
        if Button.Icon then
            Base.CropIcon(Button.Icon)
        end
    end
end

do --[[ SocialUI.lua ]]
    local function SkinContentFrames(socialUIFrame)
        local contentKeys = {
            "FriendsList", "RecentAlliesList", "QuickJoinFrame",
            "FriendRequestsList", "RecruitAFriendFrame",
        }
        for _, key in ipairs(contentKeys) do
            local frame = socialUIFrame[key]
            if frame and not private.IsSkinned(frame) then
                private.SetSkinned(frame, true)
                Skin.SocialUIContactsFrameTemplate(frame)
            end
        end

        -- RaidFrame tab is not a contacts frame
        local raidFrame = socialUIFrame.RaidFrame
        if raidFrame and not private.IsSkinned(raidFrame) then
            private.SetSkinned(raidFrame, true)
            if raidFrame.AllAssistCheckButton then
                Skin.UICheckButtonTemplate(raidFrame.AllAssistCheckButton)
            end
        end
    end
    Hook.SocialUISkinContentFrames = SkinContentFrames
end

function private.AddOns.Blizzard_SocialUI()
    local SocialUIFrame = _G.SocialUIFrame
    if not SocialUIFrame then return end

    Skin.PortraitFrameTemplate(SocialUIFrame)
    -- InitializeFrameVisuals already set Bg to a black color texture at
    -- OnLoad; align it with Aurora's panel background
    if SocialUIFrame.Bg then
        SocialUIFrame.Bg:SetColorTexture(Color.panelBg:GetRGBA())
    end
    if SocialUIFrame.TopFade then SocialUIFrame.TopFade:SetAlpha(0) end
    if SocialUIFrame.BottomFade then SocialUIFrame.BottomFade:SetAlpha(0) end

    -- BattleNet bar chrome
    local bar = SocialUIFrame.BattleNetBar
    if bar then
        if bar.Background then bar.Background:SetAlpha(0) end
        local controls = bar.ControlsContainer
        if controls then
            -- B223: BattleNetBackground lives on ControlsContainer, not the
            -- bar, so the old bar.BattleNetBackground check never matched and
            -- Blizzard's blue battletag strip stayed.
            if controls.BattleNetBackground then controls.BattleNetBackground:SetAlpha(0) end
            local status = controls.OnlineStatusDropdown
            if status then
                Skin.DropdownButton(status)
                -- B223: 54px wide and showing only a presence icon, the
                -- shared ARTWORK arrow at RIGHT -8 does not show on this one.
                -- Pin it above the OVERLAY text, inside the right edge.
                local arrow = status._auroraArrow
                if arrow then
                    arrow:ClearAllPoints()
                    arrow:SetPoint("RIGHT", -6, 0)
                    arrow:SetDrawLayer("OVERLAY", 7)
                    arrow:Show()
                end
            end
            if controls.BattleNetMenuButton then
                Skin.SocialCardActionButtonTemplate(controls.BattleNetMenuButton)
            end
        end
    end

    -- Side tabs: pooled SocialUITabTemplate buttons
    if SocialUIFrame.socialTabPool then
        Util.WrapPoolAcquire(SocialUIFrame.socialTabPool, Skin.SocialUITabTemplate)
    end

    -- Tab content frames exist from OnLoad; the mixin hook is a safety net
    -- for frames (re)created later (e.g. feature availability changes)
    Hook.SocialUISkinContentFrames(SocialUIFrame)
    if SocialUIFrame.CreateContentFramesForSupportedTabs then
        _G.hooksecurefunc(SocialUIFrame, "CreateContentFramesForSupportedTabs", Hook.SocialUISkinContentFrames)
    end

    -- Side windows
    if SocialUIFrame.IgnoreListFrame then
        Skin.SocialUIIgnoreListFrameTemplate(SocialUIFrame.IgnoreListFrame)
    end
    local notice = SocialUIFrame.BattleNetUnavailableNoticeFrame
    if notice and notice.Border then
        Skin.DialogBorderTemplate(notice.Border)
    end
    local broadcast = SocialUIFrame.BattleNetBroadcastFrame
    if broadcast then
        if broadcast.Border then
            Skin.DialogBorderOpaqueTemplate(broadcast.Border)
        end
        if broadcast.UpdateButton then Skin.UIPanelButtonTemplate(broadcast.UpdateButton) end
        if broadcast.CancelButton then Skin.UIPanelButtonTemplate(broadcast.CancelButton) end
        -- the hand-rolled Common-Input-Border edit box stays stock first pass
    end
end
