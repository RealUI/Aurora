local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

--[[ Ported from the pre-reorg FrameXML skin (deprecated 2024-08, recovered
     from git history). The frame is unchanged; only the entry points moved:
     OverrideActionBar_SetSkin/_CalcSize globals became OverrideActionBarMixin
     methods, and the file is now a LoD Blizzard addon. The spell buttons
     inherit ActionBarButtonTemplate, so they take the same skin Aurora
     already applies to ActionButton1-12. ]]
do --[[ AddOns\Blizzard_OverrideActionBar.lua ]]
    Hook.OverrideActionBarMixin = {}
    function Hook.OverrideActionBarMixin:SetSkin(skin)
        -- SetSkin re-applies per-skin atlas art to the dividers; re-assert.
        self.Divider2:SetColorTexture(1, 1, 1)
        self.leaveFrame.Divider3:SetColorTexture(1, 1, 1)
    end
    function Hook.OverrideActionBarMixin:CalcSize()
        local anchor
        if self.HasExit and self.HasPitch then
            anchor = 103
        elseif self.HasPitch then
            anchor = 145
        elseif self.HasExit then
            anchor = 60
        else
            anchor = 100
        end

        self.Divider2:SetPoint("BOTTOM", anchor, 13)
        Util.PositionBarTicks(self.xpBar, 20, Color.frame)
    end
end

--do --[[ AddOns\Blizzard_OverrideActionBar.xml ]]
--end

function private.AddOns.Blizzard_OverrideActionBar()
    local OverrideActionBar = _G.OverrideActionBar
    _G.hooksecurefunc(OverrideActionBar, "SetSkin", Hook.OverrideActionBarMixin.SetSkin)
    _G.hooksecurefunc(OverrideActionBar, "CalcSize", Hook.OverrideActionBarMixin.CalcSize)

    OverrideActionBar.EndCapL:Hide()
    OverrideActionBar.EndCapR:Hide()

    OverrideActionBar.Divider2:SetSize(1, 59)

    OverrideActionBar._BG:Hide()
    OverrideActionBar.MicroBGL:Hide()
    OverrideActionBar._MicroBGMid:Hide()
    OverrideActionBar.MicroBGR:Hide()
    OverrideActionBar.ButtonBGR:Hide()
    OverrideActionBar._ButtonBGMid:Hide()
    OverrideActionBar.ButtonBGL:Hide()
    OverrideActionBar._Border:Hide()

    local leaveFrame = OverrideActionBar.leaveFrame
    leaveFrame:ClearAllPoints()
    leaveFrame:SetPoint("BOTTOMRIGHT", -98, 0)
    leaveFrame.Divider3:ClearAllPoints()
    leaveFrame.Divider3:SetPoint("BOTTOMLEFT", -24, 13)
    leaveFrame.Divider3:SetSize(1, 59)
    leaveFrame.ExitBG:Hide()
    leaveFrame.LeaveButton:ClearAllPoints()
    leaveFrame.LeaveButton:SetPoint("CENTER", leaveFrame.Divider3, "RIGHT", 39, 0)

    local xpBar = OverrideActionBar.xpBar
    Skin.FrameTypeStatusBar(xpBar)
    Base.SetBackdropColor(xpBar, Color.frame, 0)
    xpBar:SetHeight(10)
    xpBar.XpMid:Hide()
    xpBar.XpL:Hide()
    xpBar.XpR:Hide()
    for i = 1, 19 do
        local div = xpBar["XpDiv"..i]
        if div then
            div:Hide()
        end
    end

    local healthBar = OverrideActionBar.healthBar
    Skin.FrameTypeStatusBar(healthBar)
    healthBar.HealthBarBG:Hide()
    healthBar.HealthBarOverlay:Hide()

    local powerBar = OverrideActionBar.powerBar
    Skin.FrameTypeStatusBar(powerBar)
    powerBar.PowerBarBG:Hide()
    powerBar.PowerBarOverlay:Hide()

    -- OverrideActionBarButtonTemplate inherits ActionBarButtonTemplate —
    -- same skin as ActionButton1-12, square icons included.
    for i = 1, 6 do
        Skin.ActionBarButtonTemplate(OverrideActionBar["SpellButton"..i])
    end
end
