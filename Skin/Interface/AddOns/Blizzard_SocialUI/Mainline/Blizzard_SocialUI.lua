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
    function Skin.SocialUITabTemplate(Button)
        -- LargeSideTabButtonTemplate + a Count fontstring
        if Button.Background then Button.Background:SetAlpha(0) end
        if Button.SelectedTexture then
            -- flatten but keep Blizzard's selection show/hide meaningful
            Button.SelectedTexture:SetDesaturated(true)
            Button.SelectedTexture:SetVertexColor(Color.highlight:GetRGB())
        end
        if Button.Icon then
            Base.CropIcon(Button.Icon, Button)
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
            if frame and not frame._auroraSkinned then
                frame._auroraSkinned = true
                Skin.SocialUIContactsFrameTemplate(frame)
            end
        end

        -- RaidFrame tab is not a contacts frame
        local raidFrame = socialUIFrame.RaidFrame
        if raidFrame and not raidFrame._auroraSkinned then
            raidFrame._auroraSkinned = true
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
        if bar.BattleNetBackground then bar.BattleNetBackground:SetAlpha(0) end
        local controls = bar.ControlsContainer
        if controls then
            if controls.OnlineStatusDropdown then
                Skin.DropdownButton(controls.OnlineStatusDropdown)
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
