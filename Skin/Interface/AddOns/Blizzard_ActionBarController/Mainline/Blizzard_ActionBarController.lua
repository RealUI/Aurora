local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals floor max ipairs tinsert select unpack

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

local function SetTexture(texture, anchor, left, right, top, bottom)
    if left then
        texture:SetTexCoord(left, right, top, bottom)
    end
    texture:ClearAllPoints()
    texture:SetPoint("TOPLEFT", anchor, 1, -1)
    texture:SetPoint("BOTTOMRIGHT", anchor, -1, 1)
end

do --[[ FrameXML\ActionBarController.lua ]]
    do --[[ MainMenuBarMicroButtons.lua ]]
        local anchors = {
            MicroButtonAndBagsBar = 11,
            MainMenuBarArtFrame = 555,
        }
        function Hook.MoveMicroButtons(anchor, anchorTo, relAnchor, x, y, isStacked)
            _G.CharacterMicroButton:ClearAllPoints()
            _G.CharacterMicroButton:SetPoint(anchor, anchorTo, relAnchor, anchors[anchorTo] or x, y)
            _G.LFDMicroButton:ClearAllPoints()
            if isStacked then
                _G.LFDMicroButton:SetPoint("TOPLEFT", _G.CharacterMicroButton, "BOTTOMLEFT", 0, -1)
            else
                _G.LFDMicroButton:SetPoint("BOTTOMLEFT", _G.GuildMicroButton, "BOTTOMRIGHT", 1, 0)
            end
        end
    end
    do --[[ StatusTrackingManager.lua ]]
        Hook.StatusTrackingManagerMixin = {}
        function Hook.StatusTrackingManagerMixin:UpdateBarTicks()
            for i, barContainer in ipairs(self.barContainers) do
                local shownBar = barContainer.bars[barContainer.shownBarIndex];
                if shownBar then
                    Util.PositionBarTicks(shownBar.StatusBar, 10, Color.frame)
                end
            end
        end
    end
    do --[[ ExpBar.xml ]]
        Hook.ExhaustionTickMixin = {}
        function Hook.ExhaustionTickMixin:UpdateTickPosition()
            if self:IsShown() then
                local playerCurrXP = _G.UnitXP("player")
                local playerMaxXP = _G.UnitXPMax("player")
                local exhaustionThreshold = _G.GetXPExhaustion()
                local exhaustionStateID = _G.GetRestState()

                local parent = self:GetParent()
                if exhaustionStateID and exhaustionStateID >= 3 then
                    self.Normal:SetPoint("LEFT", parent , "RIGHT", 0, 0)
                end

                if exhaustionThreshold then
                    local parentWidth = parent:GetWidth()
                    local exhaustionTickSet = max(((playerCurrXP + exhaustionThreshold) / playerMaxXP) * parentWidth, 0)
                    exhaustionTickSet = _G.Round(exhaustionTickSet - 1)
                    if exhaustionTickSet < parentWidth then
                        self.Normal:SetPoint("LEFT", parent, "LEFT", exhaustionTickSet, 0)
                    end
                end
            end
        end
    end
    do --[[ MainMenuBar.lua ]]
        function Hook.MainMenuTrackingBar_Configure(frame, isOnTop)
            if isOnTop then
                frame.StatusBar:SetHeight(7)
            else
                frame.StatusBar:SetHeight(9)
            end
        end
        function Hook.UpdateMicroButtons()
            if _G.UnitLevel("player") >= _G.SHOW_SPEC_LEVEL then
                _G.QuestLogMicroButton:SetPoint("BOTTOMLEFT", _G.ProfessionMicroButton, "BOTTOMRIGHT", 2, 0);
            end
        end
    end
end

do --[[ FrameXML\ActionBarController.xml ]]
    do --[[ MainMenuBarMicroButtons.xml ]]
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
            if private.isRetail then
                Button:SetHitRectInsets(2, 2, 1, 1)
                Button:SetBackdropOption("offsets", {
                    left = 2,
                    right = 2,
                    top = 1,
                    bottom = 1,
                })
            else
                Button:SetHitRectInsets(0, 5, 24, 0)
                Button:SetBackdropOption("offsets", {
                    left = 0,
                    right = 5,
                    top = 24,
                    bottom = 0,
                })
            end

            local bg = Button:GetBackdropTexture("bg")
            Button.Flash:SetPoint("TOPLEFT", bg, 1, -1)
            Button.Flash:SetPoint("BOTTOMRIGHT", bg, -1, 1)
            Button.Flash:SetTexCoord(.1818, .7879, .175, .875)

            if info then
                SetMicroButton(Button, info)
            end
        end
        function Skin.MicroButtonAlertTemplate(Frame)
            Skin.GlowBoxTemplate(Frame)
            Skin.UIPanelCloseButton(Frame.CloseButton)
            Skin.GlowBoxArrowTemplate(Frame.Arrow)
        end
        function Skin.MainMenuBarWatchBarTemplate(Frame)
            local StatusBar = Frame.StatusBar
            Skin.FrameTypeStatusBar(StatusBar)
            StatusBar:SetHeight(9)

            StatusBar.WatchBarTexture0:SetAlpha(0)
            StatusBar.WatchBarTexture1:SetAlpha(0)
            StatusBar.WatchBarTexture2:SetAlpha(0)
            StatusBar.WatchBarTexture3:SetAlpha(0)

            StatusBar.XPBarTexture0:SetAlpha(0)
            StatusBar.XPBarTexture1:SetAlpha(0)
            StatusBar.XPBarTexture2:SetAlpha(0)
            StatusBar.XPBarTexture3:SetAlpha(0)

            Util.PositionBarTicks(StatusBar, 20)
            Frame.OverlayFrame.Text:SetPoint("CENTER")
        end
    end
    do --[[ StatusTrackingBarTemplate.xml ]]
        local statusBarMap = {
            "ReputationStatusBarTemplate",   -- [1] Reputation
            "HonorStatusBarTemplate",        -- [2] Honor
            "ArtifactStatusBarTemplate",     -- [3] Artifact
            "ExpStatusBarTemplate",          -- [4] Experience
            "AzeriteBarTemplate",            -- [5] Azerite
            "HouseFavorBarTemplate",         -- [6] HouseFavor
        }
        function Skin.StatusTrackingBarTemplate(Frame)
            _G.hooksecurefunc(Frame, "Hide", function(dialog)
                Util.ReleaseBarTicks(dialog.StatusBar)
            end)

            -- TAINT-SAFE: Skin.FrameTypeStatusBar + Base.SetBackdropColor both
            -- call Base.SetBackdrop which writes _aurora* fields onto the StatusBar
            -- Lua table and installs a runtime SetBackdropBorderColor hook that
            -- writes frame._auroraPaletteBorderDefault = false.  The status bars
            -- sit in the action-bar area alongside OverlayPlayerCastingBarFrame;
            -- when that hook fires during a combat-event batch it taints execution
            -- and propagates into CastingBarMixin:OnEvent, causing the forbidden-
            -- table errors in StopFinishAnims / GetTypeInfo.
            -- Use widget API calls only — no Lua table writes, no runtime hooks.
            local StatusBar = Frame.StatusBar
            StatusBar:SetStatusBarTexture(private.textures.plain)
            local tex = StatusBar:GetStatusBarTexture()
            if tex then tex:SetDrawLayer("BORDER") end
            if StatusBar.Background then StatusBar.Background:Hide() end
            if StatusBar.Underlay   then StatusBar.Underlay:Hide()   end
            if StatusBar.Overlay    then StatusBar.Overlay:Hide()    end
            if StatusBar.Border     then StatusBar.Border:SetAlpha(0) end
        end
        function Skin.StatusTrackingBarContainerTemplate(Frame)
            Frame.BarFrameTexture:Hide()
            for i, bar in pairs(Frame.bars) do
                local skinName = statusBarMap[i]
                if skinName and Skin[skinName] then
                    Skin[skinName](bar)
                end
            end
        end
    end
    do --[[ ExpBar.xml ]]
        function Skin.ExpStatusBarTemplate(Frame)
            Skin.StatusTrackingBarTemplate(Frame)
            Frame.ExhaustionLevelFillBar:SetPoint("BOTTOMLEFT")

            --[[
            ]]
            local tick = Frame.ExhaustionTick
            Util.Mixin(tick, Hook.ExhaustionTickMixin)
            local texture = tick.Normal
            texture:SetColorTexture(Color.white:GetRGB())
            texture:ClearAllPoints()
            texture:SetPoint("TOP", Frame)
            texture:SetPoint("BOTTOM", Frame)
            texture:SetWidth(2)

            local diamond = tick:CreateTexture(nil, "BORDER")
            diamond:SetPoint("BOTTOMLEFT", texture, "TOPLEFT", -3, -1)
            diamond:SetSize(9, 9)
            Base.SetTexture(diamond, "shapeDiamond")

            local highlight = tick.Highlight
            highlight:ClearAllPoints()
            highlight:SetPoint("TOPLEFT", diamond, -2, 2)
            highlight:SetPoint("BOTTOMRIGHT", diamond, 2, -2)
            Base.SetTexture(highlight, "shapeDiamond")
        end
    end
    do --[[ ReputationBar.xml ]]
        function Skin.ReputationStatusBarTemplate(Frame)
            Skin.StatusTrackingBarTemplate(Frame)
        end
    end
    do --[[ AzeriteBar.xml ]]
        function Skin.AzeriteBarTemplate(Frame)
            Skin.StatusTrackingBarTemplate(Frame)
        end
    end
    do --[[ ArtifactBar.xml ]]
        function Skin.ArtifactStatusBarTemplate(Frame)
            Skin.StatusTrackingBarTemplate(Frame)
        end
    end
    do --[[ HonorBar.xml ]]
        function Skin.HonorStatusBarTemplate(Frame)
            Skin.StatusTrackingBarTemplate(Frame)
        end
    end
    do --[[ HouseFavorBar.xml ]]
        function Skin.HouseFavorBarTemplate(Frame)
            Skin.StatusTrackingBarTemplate(Frame)
        end
    end
    do --[[ ActionButtonTemplate.xml ]]
        function Skin.ActionButtonTemplate(CheckButton)
            Base.CropIcon(CheckButton.icon)

            if CheckButton.cooldown then
                CheckButton.cooldown:ClearAllPoints()
                CheckButton.cooldown:SetPoint("TOPLEFT", CheckButton.icon, 3, -3)
                CheckButton.cooldown:SetPoint("BOTTOMRIGHT", CheckButton.icon, -3, 3)
            end
            if CheckButton.lossOfControlCooldown then
                CheckButton.lossOfControlCooldown:ClearAllPoints()
                CheckButton.lossOfControlCooldown:SetPoint("TOPLEFT", CheckButton.icon, 3, -3)
                CheckButton.lossOfControlCooldown:SetPoint("BOTTOMRIGHT", CheckButton.icon, -3, 3)
            end
            if CheckButton.chargeCooldown then
                CheckButton.chargeCooldown:ClearAllPoints()
                CheckButton.chargeCooldown:SetPoint("TOPLEFT", CheckButton.icon, 2, -2)
                CheckButton.chargeCooldown:SetPoint("BOTTOMRIGHT", CheckButton.icon, -2, 2)
            end

            CheckButton.Flash:SetColorTexture(1, 0, 0, 0.5) -- static: not a theme color
            CheckButton.NewActionTexture:SetAllPoints()
            CheckButton.NewActionTexture:SetTexCoord(0.15, 0.85, 0.15, 0.85)
            CheckButton.SpellHighlightTexture:SetAllPoints()
            CheckButton.SpellHighlightTexture:SetTexCoord(0.15, 0.85, 0.15, 0.85)
            CheckButton.AutoCastable:SetAllPoints()
            CheckButton.AutoCastable:SetTexCoord(0.21875, 0.765625, 0.21875, 0.765625)
            CheckButton.AutoCastShine:ClearAllPoints()
            CheckButton.AutoCastShine:SetPoint("TOPLEFT", 2, -2)
            CheckButton.AutoCastShine:SetPoint("BOTTOMRIGHT", -2, 2)

            if private.isVanilla then
                CheckButton:SetNormalTexture("")
            else
                CheckButton:ClearNormalTexture()
            end
            Base.CropIcon(CheckButton:GetPushedTexture())
            Base.CropIcon(CheckButton:GetHighlightTexture())
            Base.CropIcon(CheckButton:GetCheckedTexture())
        end
        function Skin.ActionBarButtonTemplate(CheckButton)
            Skin.ActionButtonTemplate(CheckButton)

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
    end
    do --[[ ActionBarTemplate.xml ]]
        function Skin.ActionBarTemplate(Frame)
        end
        function Skin.EditModeActionBarTemplate(Frame)
            Skin.ActionBarTemplate(Frame)
        end
    end
    do --[[ MultiActionBars.xml ]]
        function Skin.MultiBarButtonTemplate(CheckButton)
            Skin.ActionButtonTemplate(CheckButton)
            Base.SetBackdrop(CheckButton, Color.frame, 0.2)
            CheckButton:SetBackdropOption("offsets", {
                left = -1,
                right = -1,
                top = -1,
                bottom = -1,
            })

            _G[CheckButton:GetName().."FloatingBG"]:SetTexture("")
        end
        Skin.MultiBar1ButtonTemplate = Skin.MultiBarButtonTemplate
        Skin.MultiBar2ButtonTemplate = Skin.MultiBarButtonTemplate
        function Skin.MultiBar2ButtonNoBackgroundTemplate(CheckButton)
            Skin.ActionButtonTemplate(CheckButton)

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
        Skin.MultiBar3ButtonTemplate = Skin.MultiBarButtonTemplate
        Skin.MultiBar4ButtonTemplate = Skin.MultiBarButtonTemplate

        function Skin.HorizontalMultiBar1(Frame)
            local name = Frame:GetName().."Button"
            for i = 1, 12 do
                _G.print("Skinning MultiActionBars - HorizontalMultiBar1:", name..i)
                Skin.MultiBar1ButtonTemplate(_G[name..i])
            end
        end
        function Skin.HorizontalMultiBar2(Frame)
            local name = Frame:GetName().."Button"
            for i = 1, 6 do
                if private.isRetail then
                    Skin.MultiBar2ButtonNoBackgroundTemplate(_G[name..i])
                else
                    Skin.MultiBar2ButtonTemplate(_G[name..i])
                end
            end
            for i = 7, 12 do
                Skin.MultiBar2ButtonTemplate(_G[name..i])
            end
        end
        function Skin.VerticalMultiBar3(Frame)
            local name = Frame:GetName().."Button"
            for i = 1, 12 do
                Skin.MultiBar3ButtonTemplate(_G[name..i])
            end
        end
        function Skin.VerticalMultiBar4(Frame)
            local name = Frame:GetName().."Button"
            for i = 1, 12 do
                Skin.MultiBar4ButtonTemplate(_G[name..i])
            end
        end
    end
    do --[[ StanceBar.xml ]]
        function Skin.StanceButtonTemplate(CheckButton)
            Skin.ActionButtonTemplate(CheckButton)

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

            local name = CheckButton:GetName()
            _G[name.."NormalTexture2"]:Hide()
        end
    end
    do --[[ ExtraActionBar.xml ]]
        -- /run ActionButton_StartFlash(ExtraActionButton1)
        function Skin.ExtraActionButtonTemplate(CheckButton)
            Base.CropIcon(CheckButton.icon, CheckButton)

            CheckButton.HotKey:SetPoint("TOPLEFT", 5, -5)
            CheckButton.Count:SetPoint("TOPLEFT", -5, 5)
            CheckButton.style:Hide()

            CheckButton.cooldown:SetPoint("TOPLEFT")
            CheckButton.cooldown:SetPoint("BOTTOMRIGHT")

            CheckButton:ClearNormalTexture()
            Base.CropIcon(CheckButton:GetPushedTexture())
            Base.CropIcon(CheckButton:GetHighlightTexture())
        end
    end
end

function private.FrameXML.Blizzard_ActionBarController()
    ----====#####################====----
    --     MainMenuBarMicroButtons     --
    ----====#####################====----
    if not private.disabled.mainmenubar and private.isClassic then
        _G.hooksecurefunc("UpdateMicroButtons", Hook.UpdateMicroButtons)
        _G.hooksecurefunc("MoveMicroButtons", Hook.MoveMicroButtons)

        local buttons = {}
        local buttonInfo = {
            SpellbookMicroButton = {
                texture = [[Interface\Icons\INV_Misc_Book_09]]
            },
            ProfessionMicroButton1 = {
                texture = [[Interface\Icons\INV_Misc_Wrench_01]]
            },
            TalentMicroButton = {
                texture = [[Interface\Icons\Ability_Marksmanship]]
            },
            PlayerSpellsMicroButton = {
                texture = [[Interface\Icons\Spell_Nature_WispSplode]]
            },
            AchievementMicroButton = {
                icon = "Achievement"
            },
            QuestLogMicroButton = {
                icon = "Quest"
            },
            SocialsMicroButton = {
                icon = "Socials"
            },
            PVPMicroButton = {},
            WorldMapMicroButton = {
                texture = [[Interface\WorldMap\WorldMap-Icon]],
                coords = {0.21875, 0.6875, 0.109375, 0.8125}
            },
            LFGMicroButton = {
                icon = "LFG"
            },
            MainMenuMicroButton = {
                icon = "MainMenu"
            },
            HelpMicroButton = {
                texture = [[Interface\Icons\INV_Misc_QuestionMark]]
            },
        }
        for i, name in _G.ipairs(_G.MICRO_BUTTONS) do
            local button = _G[name]
            Skin.MainMenuBarMicroButton(button, buttonInfo[name])
            tinsert(buttons, button)
        end

        SetTexture(_G.MicroButtonPortrait, _G.CharacterMicroButton:GetBackdropTexture("bg"))
        if private.isWrath then
            local kit = Util.GetTextureKit(_G.UnitFactionGroup("player"))
            _G.PVPMicroButtonTexture:SetAtlas(kit.emblemSmall, true)
            _G.PVPMicroButtonTexture:SetPoint("TOP", -2, -28)
        end
        _G.MainMenuBarPerformanceBar:SetPoint("TOPLEFT", 6, -33)
        _G.MainMenuBarPerformanceBar:SetSize(18, 9)

        Util.PositionRelative("BOTTOMLEFT", _G.MainMenuBarArtFrame, "BOTTOMLEFT", 555, 5, -2, "Right", buttons)
    end


    ----====#####################====----
    --    StatusTrackingBarTemplate    --
    ----====#####################====----

    ----====####################====----
    --             ExpBar             --
    ----====####################====----

    ----====#####################====----
    --          ReputationBar          --
    ----====#####################====----

    ----====####################====----
    --           AzeriteBar           --
    ----====####################====----

    ----====#####################====----
    --           ArtifactBar           --
    ----====#####################====----

    ----====####################====----
    --            HonorBar            --
    ----====####################====----

    ----====####################====----
    --       ActionBarConstants       --
    ----====####################====----

    ----====####################====----
    --          ActionButton          --
    ----====####################====----

    ----====#####################====----
    --      ActionButtonOverrides      --
    ----====#####################====----

    ----====####################====----
    --      ActionButtonTemplate      --
    ----====####################====----
    if not private.disabled.mainmenubar and private.isClassic then
        for i = 1, 12 do
            Skin.ActionBarButtonTemplate(_G["ActionButton"..i])
        end

        do -- ActionBarUpButton
            local ActionBarUpButton = _G.ActionBarUpButton
            Skin.FrameTypeButton(ActionBarUpButton)
            ActionBarUpButton:SetBackdropOption("offsets", {
                left = 8,
                right = 8,
                top = 8,
                bottom = 8,
            })

            local bg = ActionBarUpButton:GetBackdropTexture("bg")
            local arrow = ActionBarUpButton:CreateTexture(nil, "ARTWORK")
            arrow:SetPoint("TOPLEFT", bg, 3, -5)
            arrow:SetPoint("BOTTOMRIGHT", bg, -3, 5)
            Base.SetTexture(arrow, "arrowUp")
            ActionBarUpButton._auroraTextures = {arrow}
        end

        do -- ActionBarDownButton
            local ActionBarDownButton = _G.ActionBarDownButton
            Skin.FrameTypeButton(ActionBarDownButton)
            ActionBarDownButton:SetBackdropOption("offsets", {
                left = 8,
                right = 8,
                top = 8,
                bottom = 8,
            })

            local bg = ActionBarDownButton:GetBackdropTexture("bg")
            local arrow = ActionBarDownButton:CreateTexture(nil, "ARTWORK")
            arrow:SetPoint("TOPLEFT", bg, 3, -5)
            arrow:SetPoint("BOTTOMRIGHT", bg, -3, 5)
            Base.SetTexture(arrow, "arrowDown")
            ActionBarDownButton._auroraTextures = {arrow}
        end
    end


    ----====#####################====----
    --        ActionBarTemplate        --
    ----====#####################====----

    ----====#####################====----
    --         MultiActionBars         --
    ----====#####################====----
    if not private.disabled.mainmenubar and private.isClassic then
        local function ApplyMultiActionBarSkins()
            if not _G.MultiBarBottomLeft then
                return
            end

            Skin.HorizontalMultiBar1(_G.MultiBarBottomLeft)
            Skin.HorizontalMultiBar2(_G.MultiBarBottomRight)
            Skin.VerticalMultiBar3(_G.MultiBarRight)
            Skin.VerticalMultiBar4(_G.MultiBarLeft)
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
    end


    ----====#####################====----
    --           MainActionBar           --
    ----====#####################====----
    if not private.disabled.mainmenubar then
        if private.isRetail then
            local MainActionBar = _G.MainActionBar
            MainActionBar.BorderArt:SetAlpha(0)
            MainActionBar.EndCaps:SetAlpha(0)
        else
            _G.hooksecurefunc("MainMenuTrackingBar_Configure", Hook.MainMenuTrackingBar_Configure)

            --------------------
            -- MainMenuExpBar --
            --------------------
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
            select(6, _G.MainMenuExpBar:GetRegions()):Hide()

            ----------------------------
            -- MainMenuBarMaxLevelBar --
            ----------------------------
            _G.MainMenuBarMaxLevelBar:SetAlpha(0)

            -------------------------
            -- MainMenuBarArtFrame --
            -------------------------
            _G.MainMenuBarTexture0:SetAlpha(0)
            _G.MainMenuBarTexture1:SetAlpha(0)
            _G.MainMenuBarTexture2:SetAlpha(0)
            _G.MainMenuBarTexture3:SetAlpha(0)

            _G.MainMenuBarLeftEndCap:Hide()
            _G.MainMenuBarRightEndCap:Hide()

            ------------------------------------
            -- MainMenuBarPerformanceBarFrame --
            ------------------------------------
            if not private.isWrath then
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
                do -- Vertical status bar
                    local divHeight = PerformanceBar:GetHeight() / 3
                    local ypos = divHeight
                    for i = 1, 2 do
                        local texture = PerformanceBarFrame:CreateTexture(nil, "ARTWORK")
                        texture:SetColorTexture(Color.button:GetRGB())
                        texture:SetSize(1, 1)

                        texture:SetPoint("BOTTOMLEFT", bg, 0, floor(ypos))
                        texture:SetPoint("BOTTOMRIGHT", bg, 0, floor(ypos))
                        ypos = ypos + divHeight
                    end
                end
            end
        end
    end

    ----====#####################====----
    --     CustomActionBarOverlays     --
    ----====#####################====----

    ----====#####################====----
    --        StatusTrackingBar        --
    ----====#####################====----
    if not private.disabled.mainmenubar and private.isRetail then
        Util.Mixin(_G.StatusTrackingBarManager, Hook.StatusTrackingManagerMixin)
        Skin.StatusTrackingBarContainerTemplate(_G.MainStatusTrackingBarContainer)
        Skin.StatusTrackingBarContainerTemplate(_G.SecondaryStatusTrackingBarContainer)
    end


    ----====#####################====----
    --        OverrideActionBar        --
    ----====#####################====----

    ----====#####################====----
    --            StanceBar            --
    ----====#####################====----
    if not private.disabled.mainmenubar and private.isClassic then
        _G.StanceBarLeft:SetAlpha(0)
        _G.StanceBarMiddle:SetAlpha(0)
        _G.StanceBarRight:SetAlpha(0)

        for i = 1, _G.NUM_STANCE_SLOTS do
            Skin.StanceButtonTemplate(_G["StanceButton"..i])
        end
    end

    ----====####################====----
    --         ExtraActionBar         --
    ----====####################====----
    if private.isRetail then
        Skin.ExtraActionButtonTemplate(_G.ExtraActionButton1)
    end

    ----====####################====----
    --        PossessActionBar        --
    ----====####################====----

    ----====#####################====----
    --       ActionBarController       --
    ----====#####################====----
end
