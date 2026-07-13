local _, private = ...
if private.shouldSkip() then return end
-- Retail resolves the Mainline/ file first; this flat file is the
-- classic-family port. Belt and suspenders:
if private.isRetail then return end

--[[ Lua Globals ]]
-- luacheck: globals floor ipairs tinsert select unpack

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

--[[ Classic-family action bar (era/TBC/Mists). Port of the isClassic
    branches of the Mainline Blizzard_ActionBarController skin, verified
    against 1.15.8:
    - vanilla MICRO_BUTTONS = Character/Spellbook/Talent/QuestLog/Socials/
      Guild/WorldMap/MainMenu/Help — there is NO LFDMicroButton (the retail
      MoveMicroButtons hook indexed it unconditionally and would crash)
    - action/stance/pet buttons keep retail template names on 1.15
      (StanceButton1.., PetActionButton1.., ActionBarButtonTemplate)
]]

local function SetTexture(texture, anchor, left, right, top, bottom)
    if left then
        texture:SetTexCoord(left, right, top, bottom)
    end
    texture:ClearAllPoints()
    texture:SetPoint("TOPLEFT", anchor, 1, -1)
    texture:SetPoint("BOTTOMRIGHT", anchor, -1, 1)
end

do --[[ MainMenuBarMicroButtons ]]
    local anchors = {
        MicroButtonAndBagsBar = 11,
        MainMenuBarArtFrame = 555,
    }
    function Hook.MoveMicroButtons(anchor, anchorTo, relAnchor, x, y, isStacked)
        _G.CharacterMicroButton:ClearAllPoints()
        _G.CharacterMicroButton:SetPoint(anchor, anchorTo, relAnchor, anchors[anchorTo] or x, y)
    end

    local microButtonPrefix = [[Interface\Buttons\UI-MicroButton-]]
    local function SetMicroButton(button, info)
        local bg = button:GetBackdropTexture("bg")
        local left, right, top, bottom

        if info.texture then
            if info.coords then
                left, right, top, bottom = unpack(info.coords)
            else
                left, right, top, bottom = 0.2, 0.8, 0.08, 0.92
            end

            button:SetNormalTexture(info.texture)
            SetTexture(button:GetNormalTexture(), bg, left, right - 0.04, top + 0.04, bottom)

            button:SetPushedTexture(info.texture)
            button:GetPushedTexture():SetVertexColor(0.5, 0.5, 0.5) -- static: not a theme color
            SetTexture(button:GetPushedTexture(), bg, left + 0.04, right, top, bottom - 0.04)

            button:SetDisabledTexture(info.texture)
            button:GetDisabledTexture():SetDesaturated(true)
            SetTexture(button:GetDisabledTexture(), bg, left, right, top, bottom)
        elseif info.icon then
            left, right, top, bottom = 0.1875, 0.8125, 0.46875, 0.90625

            button:SetNormalTexture(microButtonPrefix..info.icon.."-Up")
            SetTexture(button:GetNormalTexture(), bg, left, right, top, bottom)

            button:SetPushedTexture(microButtonPrefix..info.icon.."-Down")
            SetTexture(button:GetPushedTexture(), bg, left, right, top, bottom)

            button:SetDisabledTexture(microButtonPrefix..info.icon.."-Disabled")
            SetTexture(button:GetDisabledTexture(), bg, left, right, top, bottom)
        end
    end

    function Skin.MainMenuBarMicroButton(Button, info)
        Skin.FrameTypeButton(Button)
        -- classic micro buttons are 28x58 with art only in the bottom part
        Button:SetHitRectInsets(0, 5, 24, 0)
        Button:SetBackdropOption("offsets", {
            left = 0,
            right = 5,
            top = 24,
            bottom = 0,
        })

        local bg = Button:GetBackdropTexture("bg")
        if Button.Flash then
            Button.Flash:SetPoint("TOPLEFT", bg, 1, -1)
            Button.Flash:SetPoint("BOTTOMRIGHT", bg, -1, 1)
            Button.Flash:SetTexCoord(.1818, .7879, .175, .875)
        end

        if info then
            SetMicroButton(Button, info)
        end
    end
end

do --[[ ActionButtonTemplate ]]
    function Skin.ActionButtonTemplate(CheckButton)
        Base.CropIcon(CheckButton.icon)

        if CheckButton.cooldown then
            CheckButton.cooldown:ClearAllPoints()
            CheckButton.cooldown:SetPoint("TOPLEFT", CheckButton.icon, 3, -3)
            CheckButton.cooldown:SetPoint("BOTTOMRIGHT", CheckButton.icon, -3, 3)
        end

        CheckButton.Flash:SetColorTexture(1, 0, 0, 0.5) -- static: not a theme color
        if CheckButton.NewActionTexture then
            CheckButton.NewActionTexture:SetAllPoints()
            CheckButton.NewActionTexture:SetTexCoord(0.15, 0.85, 0.15, 0.85)
        end
        if CheckButton.SpellHighlightTexture then
            CheckButton.SpellHighlightTexture:SetAllPoints()
            CheckButton.SpellHighlightTexture:SetTexCoord(0.15, 0.85, 0.15, 0.85)
        end
        if CheckButton.AutoCastable then
            CheckButton.AutoCastable:SetAllPoints()
            CheckButton.AutoCastable:SetTexCoord(0.21875, 0.765625, 0.21875, 0.765625)
        end
        if CheckButton.AutoCastShine then
            CheckButton.AutoCastShine:ClearAllPoints()
            CheckButton.AutoCastShine:SetPoint("TOPLEFT", 2, -2)
            CheckButton.AutoCastShine:SetPoint("BOTTOMRIGHT", -2, 2)
        end

        CheckButton:SetNormalTexture("")
        Base.CropIcon(CheckButton:GetPushedTexture())
        Base.CropIcon(CheckButton:GetHighlightTexture())
        Base.CropIcon(CheckButton:GetCheckedTexture())
    end

    local function SlotBackdrop(CheckButton)
        Base.CreateBackdrop(CheckButton, {
            bgFile = [[Interface\PaperDoll\UI-Backpack-EmptySlot]],
            tile = false,
            offsets = {
                left = -1,
                right = -1,
                top = -1,
                bottom = -1,
            }
        })
        CheckButton:SetBackdropColor(1, 1, 1, 0.75)
        CheckButton:SetBackdropBorderColor(Color.frame:GetRGB())
        Base.CropIcon(CheckButton:GetBackdropTexture("bg"))
    end

    function Skin.ActionBarButtonTemplate(CheckButton)
        Skin.ActionButtonTemplate(CheckButton)
        -- flat, matching the static slot plates (the textured EmptySlot
        -- backdrop would show whenever the drag-grid reveals empty buttons)
        Base.SetBackdrop(CheckButton, Color.frame, 0.2)
    end
    function Skin.MultiBarButtonTemplate(CheckButton)
        -- MultiBar buttons stay VISIBLE when empty, so a textured slot
        -- backdrop (UI-Backpack-EmptySlot) reads as "filled". Flat backdrop
        -- at the exact button rect = same look as the main bar's empty
        -- slot plates.
        Skin.ActionButtonTemplate(CheckButton)
        Base.SetBackdrop(CheckButton, Color.frame, 0.2)

        _G[CheckButton:GetName().."FloatingBG"]:SetTexture("")
    end
    function Skin.StanceButtonTemplate(CheckButton)
        Skin.ActionButtonTemplate(CheckButton)
        SlotBackdrop(CheckButton)

        local texture2 = _G[CheckButton:GetName().."NormalTexture2"]
        if texture2 then
            texture2:Hide()
        end
    end
    function Skin.PetActionButtonTemplate(CheckButton)
        Skin.ActionButtonTemplate(CheckButton)
        SlotBackdrop(CheckButton)

        local texture2 = _G[CheckButton:GetName().."NormalTexture2"]
        if texture2 then
            texture2:Hide()
        end
    end
end

function private.FrameXML.Blizzard_ActionBarController()
    if private.disabled.mainmenubar then return end

    ----====#####################====----
    --     MainMenuBarMicroButtons     --
    ----====#####################====----
    _G.hooksecurefunc("MoveMicroButtons", Hook.MoveMicroButtons)

    local buttons = {}
    local buttonInfo = {
        SpellbookMicroButton = {
            texture = [[Interface\Icons\INV_Misc_Book_09]]
        },
        TalentMicroButton = {
            texture = [[Interface\Icons\Ability_Marksmanship]]
        },
        QuestLogMicroButton = {
            icon = "Quest"
        },
        SocialsMicroButton = {
            icon = "Socials"
        },
        GuildMicroButton = {
            texture = [[Interface\Icons\INV_Shirt_GuildTabard_01]]
        },
        WorldMapMicroButton = {
            texture = [[Interface\WorldMap\WorldMap-Icon]],
            coords = {0.21875, 0.6875, 0.109375, 0.8125}
        },
        MainMenuMicroButton = {
            icon = "MainMenu"
        },
        HelpMicroButton = {
            texture = [[Interface\Icons\INV_Misc_QuestionMark]]
        },
    }
    for _, name in ipairs(_G.MICRO_BUTTONS) do
        local button = _G[name]
        if button then
            Skin.MainMenuBarMicroButton(button, buttonInfo[name])
            tinsert(buttons, button)
        end
    end

    SetTexture(_G.MicroButtonPortrait, _G.CharacterMicroButton:GetBackdropTexture("bg"))
    _G.MainMenuBarPerformanceBar:SetPoint("TOPLEFT", 6, -33)
    _G.MainMenuBarPerformanceBar:SetSize(18, 9)

    Util.PositionRelative("BOTTOMLEFT", _G.MainMenuBarArtFrame, "BOTTOMLEFT", 555, 5, -2, "Right", buttons)

    ----====####################====----
    --          ActionButtons         --
    ----====####################====----
    -- Classic HIDES empty main-bar buttons (the slot visuals lived in the
    -- now-stripped bar art). Static slot plates on the art frame keep the
    -- grid visible without ever touching the secure buttons' shown state.
    for i = 1, 12 do
        local button = _G["ActionButton"..i]
        Skin.ActionBarButtonTemplate(button)

        local slot = _G.CreateFrame("Frame", nil, _G.MainMenuBarArtFrame)
        slot:SetAllPoints(button)
        slot:SetFrameLevel(1)
        Base.SetBackdrop(slot, Color.frame, 0.2)
    end

    for _, info in ipairs({{_G.ActionBarUpButton, "arrowUp"}, {_G.ActionBarDownButton, "arrowDown"}}) do
        local button, direction = info[1], info[2]
        Skin.FrameTypeButton(button)
        button:SetBackdropOption("offsets", {
            left = 8,
            right = 8,
            top = 8,
            bottom = 8,
        })

        local bg = button:GetBackdropTexture("bg")
        local arrow = button:CreateTexture(nil, "ARTWORK")
        arrow:SetPoint("TOPLEFT", bg, 3, -5)
        arrow:SetPoint("BOTTOMRIGHT", bg, -3, 5)
        Base.SetTexture(arrow, direction)
        button._auroraTextures = {arrow}
    end

    ----====#####################====----
    --         MultiActionBars         --
    ----====#####################====----
    local function ApplyMultiActionBarSkins()
        if not _G.MultiBarBottomLeft then
            return
        end

        -- no slot plates here: unlike the main bar, MultiBar buttons stay
        -- shown when empty and their own flat backdrop provides the slot
        for _, barName in ipairs({"MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarRight", "MultiBarLeft"}) do
            local buttonName = barName.."Button"
            for i = 1, 12 do
                local button = _G[buttonName..i]
                if button then
                    Skin.MultiBarButtonTemplate(button)
                end
            end
        end
    end

    if _G.RealUI and _G.RealUI.TryInCombat then
        _G.RealUI.TryInCombat(ApplyMultiActionBarSkins, false)
    elseif _G.InCombatLockdown and _G.InCombatLockdown() then
        local deferred = _G.CreateFrame("Frame")
        deferred:RegisterEvent("PLAYER_REGEN_ENABLED")
        deferred:SetScript("OnEvent", function(self)
            self:UnregisterEvent("PLAYER_REGEN_ENABLED")
            self:SetScript("OnEvent", nil)
            ApplyMultiActionBarSkins()
        end)
    else
        ApplyMultiActionBarSkins()
    end

    ----====####################====----
    --        Stance + pet bars       --
    ----====####################====----
    local i = 1
    while _G["StanceButton"..i] do
        Skin.StanceButtonTemplate(_G["StanceButton"..i])
        i = i + 1
    end
    i = 1
    while _G["PetActionButton"..i] do
        Skin.PetActionButtonTemplate(_G["PetActionButton"..i])
        i = i + 1
    end

    ----====####################====----
    --           MainMenuBar          --
    ----====####################====----
    _G.hooksecurefunc("MainMenuTrackingBar_Configure", function(frame, isOnTop)
        if isOnTop then
            frame.StatusBar:SetHeight(7)
        else
            frame.StatusBar:SetHeight(9)
        end
    end)

    -- MainMenuExpBar
    Skin.FrameTypeStatusBar(_G.MainMenuExpBar)
    Base.SetBackdropColor(_G.MainMenuExpBar, Color.frame)
    Util.PositionBarTicks(_G.MainMenuExpBar, 20, Color.frame)
    _G.MainMenuExpBar:SetHeight(9)
    _G.MainMenuExpBar:SetPoint("TOP", 0.4, 0)
    _G.ExhaustionLevelFillBar:SetHeight(9)

    _G.MainMenuXPBarTexture0:SetAlpha(0)
    _G.MainMenuXPBarTexture1:SetAlpha(0)
    _G.MainMenuXPBarTexture2:SetAlpha(0)
    _G.MainMenuXPBarTexture3:SetAlpha(0)
    local expOverlay = select(6, _G.MainMenuExpBar:GetRegions())
    if expOverlay then
        expOverlay:Hide()
    end

    -- MainMenuBarMaxLevelBar
    _G.MainMenuBarMaxLevelBar:SetAlpha(0)

    -- MainMenuBarArtFrame
    _G.MainMenuBarTexture0:SetAlpha(0)
    _G.MainMenuBarTexture1:SetAlpha(0)
    _G.MainMenuBarTexture2:SetAlpha(0)
    _G.MainMenuBarTexture3:SetAlpha(0)

    _G.MainMenuBarLeftEndCap:Hide()
    _G.MainMenuBarRightEndCap:Hide()

    -- MainMenuBarPerformanceBarFrame
    local PerformanceBarFrame = _G.MainMenuBarPerformanceBarFrame
    Base.SetBackdrop(PerformanceBarFrame, Color.button, Color.frame.a)
    PerformanceBarFrame:SetBackdropOption("offsets", {
        left = 1,
        right = 6,
        top = 13,
        bottom = 11,
    })

    local bg = PerformanceBarFrame:GetBackdropTexture("bg")
    local PerformanceBar = _G.MainMenuBarPerformanceBar
    Base.SetTexture(PerformanceBar, "gradientRight")
    PerformanceBar:ClearAllPoints()
    PerformanceBar:SetPoint("TOPLEFT", bg, 1, -1)
    PerformanceBar:SetPoint("BOTTOMRIGHT", bg, -1, 1)
    do -- Vertical status bar dividers
        local divHeight = PerformanceBar:GetHeight() / 3
        local ypos = divHeight
        for _ = 1, 2 do
            local texture = PerformanceBarFrame:CreateTexture(nil, "ARTWORK")
            texture:SetColorTexture(Color.button:GetRGB())
            texture:SetSize(1, 1)

            texture:SetPoint("BOTTOMLEFT", bg, 0, floor(ypos))
            texture:SetPoint("BOTTOMRIGHT", bg, 0, floor(ypos))
            ypos = ypos + divHeight
        end
    end
end
