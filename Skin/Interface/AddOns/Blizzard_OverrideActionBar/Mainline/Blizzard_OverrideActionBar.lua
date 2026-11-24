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
        self.Divider1:SetColorTexture(1, 1, 1)
        self.Divider2:SetColorTexture(1, 1, 1)
        self.leaveFrame.Divider3:SetColorTexture(1, 1, 1)

        -- Pitch track and marker get the same per-skin art
        self.PitchBG:SetColorTexture(Color.frame:GetRGB())
        self.PitchMarker:SetColorTexture(Color.highlight:GetRGB())
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

--[[ AddOns\Blizzard_OverrideActionBar.xml ]]
--[[ B261 (task 5.4), read from wow-ui-source (retail) and
    wow-ui-source-forever. Checkpoint 0 found Aurora's backdrop (the
    BackdropMixin methods and backdropInfo keys) on OverrideActionBarButton1-6
    and on the two pitch buttons. The spell buttons are secure action
    buttons, protected themselves (OverrideActionBarButtonTemplate inherits
    ActionBarButtonTemplate, OverrideActionBar.xml:3), which makes the bar
    they sit in protected too; the pitch buttons are under it
    (OverrideActionBar.xml:171, :196). So both are drawn with textures of
    the button's own, made once at skin time: no backdrop, no key, no frame
    of Aurora's, nothing anchored to anything but the button.

    Spell buttons: the empty-slot art and the 1px border the Layer 1
    backdrop drew (Skin.ActionBarButtonTemplate), as two BACKGROUND
    textures under the icon; Skin.ActionButtonTemplate restyles the icon
    and the state art in place, as before. ]]
local function SkinSpellButton(CheckButton)
    Skin.ActionButtonTemplate(CheckButton)

    local border = CheckButton:CreateTexture(nil, "BACKGROUND", nil, -8)
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetColorTexture(Color.frame:GetRGB())

    local bg = CheckButton:CreateTexture(nil, "BACKGROUND", nil, -7)
    bg:SetAllPoints()
    bg:SetTexture([[Interface\PaperDoll\UI-Backpack-EmptySlot]])
    bg:SetVertexColor(1, 1, 1, 0.75)
    Base.CropIcon(bg)
end

--[[ Pitch buttons: SetSkin re-textures their normal, pushed and
    highlight textures through references taken at OnLoad
    (OverrideActionBar.lua:69-76), so those stay Blizzard's, faded by
    alpha, which SetTexture leaves alone. The box is the button's own:
    a border and a fill in BACKGROUND, and a hover tint in the HIGHLIGHT
    layer, which the engine shows only while the cursor is on the button.
    The Layer 1 look was the button backdrop and Base.SetHighlight. ]]
local function SkinPitchButton(Button, arrowTexture)
    Button:GetNormalTexture():SetAlpha(0)
    Button:GetPushedTexture():SetAlpha(0)
    Button:GetHighlightTexture():SetAlpha(0)
    Button:SetSize(26, 26)

    local border = Button:CreateTexture(nil, "BACKGROUND", nil, -8)
    border:SetAllPoints()
    border:SetColorTexture(Color.button:GetRGB())

    local fill = Button:CreateTexture(nil, "BACKGROUND", nil, -7)
    fill:SetPoint("TOPLEFT", 1, -1)
    fill:SetPoint("BOTTOMRIGHT", -1, 1)
    fill:SetColorTexture(Color.Lightness(Color.button, -0.3):GetRGB())

    local hover = Button:CreateTexture(nil, "HIGHLIGHT")
    hover:SetPoint("TOPLEFT", 1, -1)
    hover:SetPoint("BOTTOMRIGHT", -1, 1)
    hover:SetColorTexture(1, 1, 1, 0.08) -- static: not a theme color
    hover:SetBlendMode("ADD")

    local arrow = Button:CreateTexture(nil, "ARTWORK")
    arrow:SetSize(14, 7)
    arrow:SetPoint("CENTER")
    Base.SetTexture(arrow, arrowTexture)
end

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

    -- Pitch controls. SetSkin re-textures every piece through references taken
    -- at OnLoad (PitchUpUp = the button's NormalTexture, ...), so the button
    -- textures are faded rather than cleared, and the art is hidden by alpha,
    -- which SetTexture leaves alone.
    local pitchFrame = OverrideActionBar.pitchFrame
    pitchFrame.PitchOverlay:SetAlpha(0)
    pitchFrame.PitchButtonBG:SetAlpha(0)
    pitchFrame.Divider1:ClearAllPoints()
    pitchFrame.Divider1:SetPoint("BOTTOM", pitchFrame, "BOTTOMRIGHT", 0, 13)
    pitchFrame.Divider1:SetSize(1, 59)
    pitchFrame.PitchBG:SetWidth(6)
    pitchFrame.PitchMarker:SetBlendMode("BLEND")
    pitchFrame.PitchMarker:SetSize(10, 3)
    SkinPitchButton(pitchFrame.PitchUpButton, "arrowUp")
    SkinPitchButton(pitchFrame.PitchDownButton, "arrowDown")

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

    -- OverrideActionBarButtonTemplate inherits ActionBarButtonTemplate: the
    -- look of ActionButton1-12, square icons included, without its backdrop.
    for i = 1, 6 do
        SkinSpellButton(OverrideActionBar["SpellButton"..i])
    end
end
