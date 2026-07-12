local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals select next

-- [[ Core ]]
local Aurora = private.Aurora
local Base, Hook, Skin = Aurora.Base, Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

do --[[ AddOns\Blizzard_AchievementUI.lua ]]
    local IN_GUILD_VIEW = false
    local red, green, blue = Color.red:Hue(0.03), Color.green:Lightness(-0.4), Color.blue:Hue(-0.05)
    local redDesat, greenDesat, blueDesat = red:Saturation(-0.4), green:Saturation(-0.4), blue:Saturation(-0.4)

    function Hook.AchievementFrame_RefreshView()
        IN_GUILD_VIEW = _G.AchievementFrame.Header.Title:GetText() == _G.GUILD_ACHIEVEMENTS_TITLE

        if IN_GUILD_VIEW then
            _G.AchievementFrameGuildEmblemLeft:SetVertexColor(1, 1, 1, 0.25) -- static: not a theme color
            _G.AchievementFrameGuildEmblemRight:SetVertexColor(1, 1, 1, 0.25) -- static: not a theme color
        end
    end
    function Hook.AchievementButton_UpdatePlusMinusTexture(button)
        if button:IsForbidden() then return end -- twitter achievement share is protected
        if button.PlusMinus:IsShown() then
            button._auroraPlusMinus:Show()
            if button.collapsed then
                button._auroraPlusMinus.plus:Show()
            else
                button._auroraPlusMinus.plus:Hide()
            end
        elseif button._auroraPlusMinus then
            button._auroraPlusMinus:Hide()
        end
    end
    function Hook.AchievementButton_Saturate(self)
        Base.SetBackdropColor(self.NineSlice, Color.button, 1)

        if IN_GUILD_VIEW then
            self.TitleBar:SetColorTexture(green:GetRGB())
        else
            if self.accountWide then
                self.TitleBar:SetColorTexture(blue:GetRGB())
            else
                self.TitleBar:SetColorTexture(red:GetRGB())
            end
        end

        if self.Description then
            self.Description:SetTextColor(.9, .9, .9)
            self.Description:SetShadowOffset(1, -1)
        end
    end
    function Hook.AchievementButton_Desaturate(self)
        Base.SetBackdropColor(self.NineSlice, Color.button, 1)

        if IN_GUILD_VIEW then
            self.TitleBar:SetColorTexture(greenDesat:GetRGB())
        else
            if self.accountWide then
                self.TitleBar:SetColorTexture(blueDesat:GetRGB())
            else
                self.TitleBar:SetColorTexture(redDesat:GetRGB())
            end
        end
    end
    do -- AchievementStatTemplateMixin
        Hook.AchievementStatTemplateMixin = {}
        function Hook.AchievementStatTemplateMixin:Init(elementData)
            local category = elementData.id;
            local colorIndex = elementData.colorIndex;
            if elementData.header then
                self.Left:Hide();
                self.Middle:Hide();
                self.Right:Hide();
                self.Background:Show();
                self.Background:SetAlpha(1.0)
                self.Background:SetBlendMode("DISABLE")
                self.Background:SetColorTexture(Color.button:GetRGB())
            else
                local id, _, _, _, _, _, _, _, _, _ = _G.GetAchievementInfo(category);
                if not id then return end
                if not colorIndex then
                    _G.print("AchievementStatTemplateMixin:Init - colorIndex is nil")
                    -- colorIndex = index;
                end
                if (colorIndex % 2) == 1 then
                    self.Background:Hide();
                else
                    self.Background:Show();
                    self.Background:SetColorTexture(1, 1, 1, 0.25); -- static: not a theme color
                end
            end
        end
    end

    local numAchievements = 0
    function Hook.AchievementFrameSummary_UpdateAchievements(...)
        for i = numAchievements + 1, _G.ACHIEVEMENTUI_MAX_SUMMARY_ACHIEVEMENTS do
            local button = _G["AchievementFrameSummaryAchievement"..i]
            if button then
                Skin.SummaryAchievementTemplate(button)
                if button.saturatedStyle then
                    Hook.AchievementButton_Saturate(button)
                else
                    Hook.AchievementButton_Desaturate(button)
                end

                if i > 1 then
                    local anchorTo = _G["AchievementFrameSummaryAchievement"..i-1]
                    button:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", 0, -1 )
                    button:SetPoint("TOPRIGHT", anchorTo, "BOTTOMRIGHT", 0, -1 )
                end
                numAchievements = numAchievements + 1
            end
        end
    end

    local SearchPreviewButtonHieght = 27
    function Hook.AchievementFrame_ShowSearchPreviewResults()
        local numResults = _G.GetNumFilteredAchievements()
        if numResults > 5 then
            numResults = 6
        end

        _G.AchievementFrame.SearchPreviewContainer:SetPoint("BOTTOM", _G.AchievementFrame.SearchBox, 0, -(numResults * SearchPreviewButtonHieght))
    end
end

do --[[ AddOns\Blizzard_AchievementUI.xml ]]
    Hook.AchievementTemplateMixin = {}
    function Hook.AchievementTemplateMixin:Init(elementData)
        -- Re-apply icon skinning since Blizzard's Init restores Icon.frame texture/visibility each call
        if self.Icon then
            Skin.AchievementIconFrameTemplate(self.Icon)
        end
        -- Re-apply TitleBar colour. On pool re-use Saturate/Desaturate already runs via our
        -- hooksecurefunc, but guard anyway so we only touch frames that are fully skinned
        -- (NineSlice backdrop set up). First-creation case is handled in Hook.AchievementFrameAchievements.
        if self._auroraSkinned then
            if self.completed then
                Hook.AchievementButton_Saturate(self)
            else
                Hook.AchievementButton_Desaturate(self)
            end
        end
    end

    do -- AchievementsObjectivesMixin hooks (expanded achievement criteria/objectives)
        Hook.AchievementsObjectivesMixin = {}
        function Hook.AchievementsObjectivesMixin:GetCriteria(index)
            Util.SkinOnce(self.criterias[index], Skin.AchievementCriteriaTemplate)
        end
        function Hook.AchievementsObjectivesMixin:GetProgressBar(index)
            Util.SkinOnce(self.progressBars[index], Skin.AchievementProgressBarTemplate)
        end
        function Hook.AchievementsObjectivesMixin:GetMiniAchievement(index)
            -- Note: Blizzard typo in the field name ("Achivements" not "Achievements")
            Util.SkinOnce(self.miniAchivements[index], Skin.MiniAchievementTemplate)
        end
        function Hook.AchievementsObjectivesMixin:GetMeta(index)
            local meta = self.metas[index]
            if meta then
                if not meta._auroraSkinned then
                    Skin.MetaCriteriaTemplate(meta)
                    meta._auroraSkinned = true
                else
                    -- GetMeta resets Border texture on every call; re-hide it
                    meta.Border:Hide()
                end
            end
        end
    end

    function Hook.AchievementFrameSummary_Refresh()
        for i = 1, _G.ACHIEVEMENTUI_MAX_SUMMARY_ACHIEVEMENTS do
            local button = _G["AchievementFrameSummaryAchievement"..i]
            if button and button.Icon then
                Skin.AchievementIconFrameTemplate(button.Icon)
            end
        end
    end

    function Skin.AchievementSearchPreviewButton(Button)
        Button.SelectedTexture:SetPoint("TOPLEFT", 1, -1)
        Button.SelectedTexture:SetPoint("BOTTOMRIGHT", -1, 1)

        Button.IconFrame:SetAlpha(0)
        Base.CropIcon(Button.Icon, Button)

        Button:ClearNormalTexture()
        Button:ClearPushedTexture()
    end
    function Skin.AchievementFullSearchResultsButton(Button)
        Button.IconFrame:SetAlpha(0)
        Base.CropIcon(Button.Icon, Button)

        Button.Path:SetTextColor(Color.grayLight:GetRGB())
        Button.ResultType:SetTextColor(Color.grayLight:GetRGB())

        Button:ClearNormalTexture()
        Button:ClearPushedTexture()

        local r, g, b = Color.highlight:GetRGB()
        Button:GetHighlightTexture():SetColorTexture(r, g, b, 0.2)
    end
    function Skin.AchievementFrameSummaryCategoryTemplate(StatusBar)
        Skin.FrameTypeStatusBar(StatusBar)
        StatusBar:SetStatusBarColor(0.5, 0.5, 0.5)

        local name = StatusBar:GetName()
        StatusBar.Label:SetPoint("LEFT", 6, 0)
        StatusBar.Text:SetPoint("RIGHT", -6, 0)

        _G[name.."Left"]:Hide()
        _G[name.."Right"]:Hide()
        _G[name.."Middle"]:Hide()
        _G[name.."FillBar"]:Hide()

        local r, g, b = Color.highlight:GetRGB()
        _G[name.."ButtonHighlightLeft"]:Hide()
        _G[name.."ButtonHighlightRight"]:Hide()

        local highlight = _G[name.."ButtonHighlightMiddle"]
        highlight:SetAllPoints()
        highlight:SetColorTexture(r, g, b, 0.2)
    end
    function Skin.AchievementCheckButtonTemplate(CheckButton)
        Skin.FrameTypeCheckButton(CheckButton)
        CheckButton:SetBackdropOption("offsets", {
            left = 2,
            right = 2,
            top = 2,
            bottom = 2,
        })

        CheckButton:GetRegions():SetPoint("LEFT", CheckButton, "RIGHT", 2, 0)

        local bg = CheckButton:GetBackdropTexture("bg")
        local check = CheckButton:GetCheckedTexture()
        check:ClearAllPoints()
        check:SetPoint("TOPLEFT", bg, -6, 6)
        check:SetPoint("BOTTOMRIGHT", bg, 6, -6)
        check:SetDesaturated(true)
        check:SetVertexColor(Color.highlight:GetRGB())
    end
    function Skin.AchievementFrameTabButtonTemplate(Button)
        Skin.FrameTypeButton(Button)
        Button:SetButtonColor(Color.button, Util.GetFrameAlpha(), false)
        Button:SetHeight(28)

        Button.LeftActive:SetAlpha(0)
        Button.RightActive:SetAlpha(0)
        Button.MiddleActive:SetAlpha(0)
        Button.Left:SetAlpha(0)
        Button.Right:SetAlpha(0)
        Button.Middle:SetAlpha(0)

        Button.LeftHighlight:SetAlpha(0)
        Button.RightHighlight:SetAlpha(0)
        Button.MiddleHighlight:SetAlpha(0)

        local bg = Button:GetBackdropTexture("bg")
        Button.Text:ClearAllPoints()
        Button.Text:SetAllPoints(bg)

        Button._auroraTabResize = true
    end
    function Skin.AchievementCriteriaTemplate(Frame)
        -- Check texture (gold checkmark) is shown/hidden by Blizzard to indicate completion.
        -- Desaturate and tint it to match Aurora's style.
        Frame.Check:SetDesaturated(true)
        Frame.Check:SetVertexColor(Color.highlight:GetRGB())
    end
    function Skin.MiniAchievementTemplate(Frame)
        Base.CropIcon(Frame.Icon, Frame)
        Frame.Border:Hide()
    end
    function Skin.MetaCriteriaTemplate(Button)
        Base.CropIcon(Button.Icon, Button)
        Button.Border:Hide()
    end
    function Skin.AchievementProgressBarTemplate(StatusBar)
        Skin.FrameTypeStatusBar(StatusBar)
        StatusBar:SetStatusBarColor(0.5, 0.5, 0.5)

        local bg, _, left, right, center = StatusBar:GetRegions()
        bg:Hide()
        left:Hide()
        right:Hide()
        center:Hide()
    end
    function Skin.AchievementHeaderStatusBarTemplate(StatusBar)
        Skin.FrameTypeStatusBar(StatusBar)

        StatusBar.Left:Hide()
        StatusBar.Right:Hide()
        StatusBar.Middle:Hide()
        select(4, StatusBar:GetRegions()):Hide() -- FillBar
    end
    function Hook.AchievementFrameAchievements(Frame)
        for _, child in next, { Frame.ScrollTarget:GetChildren() } do
            if not child._auroraSkinned then
                Skin.AchievementFrameAchievements(child)
                child._auroraSkinned = true
                -- Saturate/Desaturate ran before Skin.AchievementTemplate added the hooksecurefunc.
                -- Re-apply Aurora colour now that the NineSlice backdrop is set up.
                if child.completed then
                    Hook.AchievementButton_Saturate(child)
                else
                    Hook.AchievementButton_Desaturate(child)
                end
            end
        end
    end
    function Skin.AchievementFrameAchievements(Frame)
        Util.HideNineSlice(Frame)
        Skin.AchievementTemplate(Frame)
        _G.hooksecurefunc(Frame, 'UpdatePlusMinusTexture', Hook.AchievementButton_UpdatePlusMinusTexture)
    end

    function Hook.AchievementCategoryTemplate(Frame)
        for _, child in next, { Frame.ScrollTarget:GetChildren() } do
            Util.SkinOnce(child.Button, Skin.AchievementCategoryTemplate)
        end
    end
    function Skin.AchievementCategoryTemplate(Button)
        Base.SetBackdrop(Button, Color.button)
        Button.Background:Hide()

        Button.Label:SetPoint("BOTTOMLEFT", 6, 0)
        Button.Label:SetPoint("TOPRIGHT")
        Button.Label:SetJustifyV("MIDDLE")

        local r, g, b = Color.highlight:GetRGB()
        local highlight = Button:GetHighlightTexture()
        highlight:SetColorTexture(r, g, b, 0.5)
        highlight:SetPoint("BOTTOMRIGHT")
    end
    function Skin.AchievementIconFrameTemplate(Frame)
        Frame.bling:Hide()
        Base.CropIcon(Frame.texture, Frame)
        Frame.frame:Hide()
    end
    function Skin.AchievementTemplate(EventButton)
        Skin.TooltipBorderBackdropTemplate(EventButton)
        _G.hooksecurefunc(EventButton, "Saturate", Hook.AchievementButton_Saturate)
        _G.hooksecurefunc(EventButton, "Desaturate", Hook.AchievementButton_Desaturate)
        EventButton.Background:Hide()
        EventButton.BottomLeftTsunami:Hide()
        EventButton.BottomRightTsunami:Hide()
        EventButton.TopLeftTsunami:Hide()
        EventButton.TopRightTsunami:Hide()
        EventButton.BottomTsunami1:Hide()
        EventButton.TopTsunami1:Hide()

        local titleMask = EventButton:CreateMaskTexture()
        titleMask:SetTexture([[Interface\FriendsFrame\PendingFriendNameBG-New]], "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        titleMask:SetAllPoints(EventButton.TitleBar)
        EventButton.TitleBar:AddMaskTexture(titleMask)
        EventButton.TitleBar:SetHeight(68)
        EventButton.TitleBar:SetPoint("TOPLEFT", 10, 8)
        EventButton.TitleBar:SetPoint("TOPRIGHT", -10, 8)

        EventButton.Glow:Hide()
        EventButton.RewardBackground:SetAlpha(0)
        EventButton.GuildCornerL:Hide()
        EventButton.GuildCornerR:Hide()

        EventButton.Label:SetPoint("TOP", 0, -4)
        EventButton.PlusMinus:SetAlpha(0)
        local plusMinus = _G.CreateFrame("Frame", nil, EventButton)
        Base.SetBackdrop(plusMinus, Color.button)
        plusMinus:SetAllPoints(EventButton.PlusMinus)

        plusMinus.plus = plusMinus:CreateTexture(nil, "ARTWORK")
        plusMinus.plus:SetSize(1, 7)
        plusMinus.plus:SetPoint("CENTER")
        plusMinus.plus:SetColorTexture(1, 1, 1) -- static: not a theme color

        plusMinus.minus = plusMinus:CreateTexture(nil, "ARTWORK")
        plusMinus.minus:SetSize(7, 1)
        plusMinus.minus:SetPoint("CENTER")
        plusMinus.minus:SetColorTexture(1, 1, 1) -- static: not a theme color
        EventButton._auroraPlusMinus = plusMinus

        Base.SetBackdrop(EventButton.Highlight, Color.highlight, Color.frame.a)
        EventButton.Highlight:DisableDrawLayer("OVERLAY")
        EventButton.Highlight:ClearAllPoints()
        EventButton.Highlight:SetPoint("TOPLEFT", 1, -1)
        EventButton.Highlight:SetPoint("BOTTOMRIGHT", -1, 1)

        Skin.AchievementIconFrameTemplate(EventButton.Icon)
        Skin.AchievementCheckButtonTemplate(EventButton.Tracked)
    end
    function Skin.ComparisonPlayerTemplate(Frame)
        _G.hooksecurefunc(Frame, "Saturate", Hook.AchievementButton_Saturate)
        _G.hooksecurefunc(Frame, "Desaturate", Hook.AchievementButton_Desaturate)

        Skin.TooltipBorderBackdropTemplate(Frame)
        Frame.Background:Hide()

        local titleMask = Frame:CreateMaskTexture()
        titleMask:SetTexture([[Interface\FriendsFrame\PendingFriendNameBG-New]], "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        titleMask:SetPoint("TOPLEFT", Frame.TitleBar, 0, 8)
        titleMask:SetPoint("BOTTOMRIGHT", Frame.TitleBar, 0, -15)

        Frame.TitleBar:AddMaskTexture(titleMask)
        Frame.TitleBar:ClearAllPoints()
        Frame.TitleBar:SetPoint("TOPLEFT", 10, -1)
        Frame.TitleBar:SetPoint("BOTTOMRIGHT", -10, 1)

        Frame.Glow:Hide()
        Frame.Label:SetPoint("TOP", 0, -4)

        Skin.AchievementIconFrameTemplate(Frame.Icon)
    end
    function Skin.SummaryAchievementTemplate(Frame)
        Skin.ComparisonPlayerTemplate(Frame)
        Frame:SetHeight(44)

        Base.SetBackdrop(Frame.Highlight, Color.highlight, Color.frame.a)
        Frame.Highlight:DisableDrawLayer("OVERLAY")
        Frame.Highlight:ClearAllPoints()
        Frame.Highlight:SetPoint("TOPLEFT", 1, -1)
        Frame.Highlight:SetPoint("BOTTOMRIGHT", -1, 1)
    end
    function Skin.ComparisonTemplate(Frame)
        Skin.ComparisonPlayerTemplate(Frame.player)

        _G.hooksecurefunc(Frame.friend, "Saturate", Hook.AchievementButton_Saturate)
        _G.hooksecurefunc(Frame.friend, "Desaturate", Hook.AchievementButton_Desaturate)

        Skin.TooltipBorderBackdropTemplate(Frame.friend)
        Frame.friend.background:Hide()
        Frame.friend.titleBar:Hide()
        Frame.friend.glow:Hide()

        Skin.AchievementIconFrameTemplate(Frame.friend.icon)
    end
    function Skin.AchievementStatTemplate(Button)
        Button.Left:SetAlpha(0)
        Button.Right:SetAlpha(0)
        Button.Middle:SetAlpha(0)
    end
    function Skin.ComparisonStatTemplate(Frame)
        Frame.left:SetAlpha(0)
        Frame.middle:SetAlpha(0)
        Frame.right:SetAlpha(0)

        Frame.left2:SetAlpha(0)
        Frame.middle2:SetAlpha(0)
        Frame.right2:SetAlpha(0)
    end
end

function private.AddOns.Blizzard_AchievementUI()
    _G.hooksecurefunc("AchievementFrame_RefreshView", Hook.AchievementFrame_RefreshView)
    _G.hooksecurefunc("AchievementFrame_ShowSearchPreviewResults", Hook.AchievementFrame_ShowSearchPreviewResults)
    _G.hooksecurefunc("AchievementFrameSummary_UpdateAchievements", Hook.AchievementFrameSummary_UpdateAchievements)
    _G.hooksecurefunc("AchievementFrameSummary_Refresh", Hook.AchievementFrameSummary_Refresh)

    ----------------------
    -- AchievementFrame --
    ----------------------
    local AchievementFrame = _G.AchievementFrame
    Skin.FrameTypeFrame(AchievementFrame)
    AchievementFrame:SetBackdropOption("offsets", {
        left = 2,
        right = 2,
        top = 2,
        bottom = 2,
    })
    AchievementFrame.Background:Hide()
    AchievementFrame.BackgroundBlackCover:Hide()
    local bg = AchievementFrame:GetBackdropTexture("bg")

    _G.AchievementFrameMetalBorderLeft:Hide()
    _G.AchievementFrameMetalBorderRight:Hide()
    _G.AchievementFrameMetalBorderBottom:Hide()
    _G.AchievementFrameMetalBorderTop:Hide()
    _G.AchievementFrameCategoriesBG:Hide()

    _G.AchievementFrameWaterMark:SetDesaturated(true)
    _G.AchievementFrameWaterMark:SetAlpha(0.5)

    _G.AchievementFrameGuildEmblemLeft:SetAlpha(0.5)
    _G.AchievementFrameGuildEmblemRight:SetAlpha(0.5)

    _G.AchievementFrameMetalBorderTopLeft:Hide()
    _G.AchievementFrameMetalBorderTopRight:Hide()
    _G.AchievementFrameMetalBorderBottomLeft:Hide()
    _G.AchievementFrameMetalBorderBottomRight:Hide()
    _G.AchievementFrameWoodBorderTopLeft:Hide()
    _G.AchievementFrameWoodBorderTopRight:Hide()
    _G.AchievementFrameWoodBorderBottomLeft:Hide()
    _G.AchievementFrameWoodBorderBottomRight:Hide()



    ------------
    -- Header --
    ------------
    local Header = AchievementFrame.Header
    -- Header frame is kept visible (but transparent) so DragMeAll can use it as a drag handle.
    -- All visual children are hidden individually below.
    Header.Left:Hide()
    Header.Right:Hide()

    Header.PointBorder:Hide()
    Header.Title:Hide()
    Header.LeftDDLInset:SetAlpha(0)
    Header.RightDDLInset:SetAlpha(0)
    Header.Points:SetParent(AchievementFrame)
    Header.Points:SetPoint("TOP", bg)
    Header.Points:SetPoint("BOTTOM", bg, "TOP", 0, -private.FRAME_TITLE_HEIGHT)
    Header.Shield:SetParent(AchievementFrame)

    _G.AchievementFrame_HideFilterDropdown(AchievementFrame)
    _G.AchievementFrame_TryShowFilterDropdown(AchievementFrame)

    ----------------
    -- Categories --
    ----------------
    local Categories = _G.AchievementFrameCategories
    Util.HideNineSlice(Categories)
    Skin.MinimalScrollBar(Categories.ScrollBar)
    Skin.WowScrollBoxList(Categories.ScrollBox)
    _G.hooksecurefunc(Categories.ScrollBox, 'Update', Hook.AchievementCategoryTemplate)

    ------------------
    -- Achievements --
    ------------------
    local Achievements = _G.AchievementFrameAchievements
    Achievements.Background:Hide()
    select(3, Achievements:GetRegions()):Hide()
    Skin.WowScrollBoxList(Achievements.ScrollBox)
    -- Achievements.ScrollBox:SetBackdropBorderColor(Color.yellow)
    Skin.MinimalScrollBar(Achievements.ScrollBar)
    select(3, Achievements:GetChildren()):Hide()
    Util.Mixin(_G.AchievementTemplateMixin, Hook.AchievementTemplateMixin)
    _G.hooksecurefunc(Achievements.ScrollBox, 'Update', Hook.AchievementFrameAchievements)
    Util.Mixin(_G.AchievementFrameAchievementsObjectives, Hook.AchievementsObjectivesMixin)

    -----------
    -- Stats --
    -----------
    local Stats = _G.AchievementFrameStats
    _G.AchievementFrameStatsBG:Hide()
    Skin.WowScrollBoxList(Stats.ScrollBox)
    --Stats.ScrollBox:SetBackdropBorderColor(Color.yellow) -- This is not working well with the scrollbox headers from stats.
    Skin.MinimalScrollBar(Stats.ScrollBar)
    select(4, _G.AchievementFrameStats:GetChildren()):Hide()
    Util.Mixin(_G.AchievementStatTemplateMixin, Hook.AchievementStatTemplateMixin)


    -------------
    -- Summary --
    -------------
    local Summary = _G.AchievementFrameSummary
    Summary.Background:Hide()
    Summary:GetChildren():Hide()

    _G.AchievementFrameSummaryAchievementsHeaderHeader:Hide()
    _G.AchievementFrameSummaryCategoriesHeaderTexture:Hide()

    Skin.FrameTypeStatusBar(_G.AchievementFrameSummaryCategoriesStatusBar)
    _G.AchievementFrameSummaryCategoriesStatusBar:SetStatusBarColor(0.5, 0.5, 0.5)
    _G.AchievementFrameSummaryCategoriesStatusBarTitle:SetPoint("LEFT", 6, 0)
    _G.AchievementFrameSummaryCategoriesStatusBarText:SetPoint("RIGHT", -6, 0)
    _G.AchievementFrameSummaryCategoriesStatusBarLeft:Hide()
    _G.AchievementFrameSummaryCategoriesStatusBarRight:Hide()
    _G.AchievementFrameSummaryCategoriesStatusBarMiddle:Hide()
    _G.AchievementFrameSummaryCategoriesStatusBarFillBar:Hide()
    for i = 1, 12 do
        Skin.AchievementFrameSummaryCategoryTemplate(_G["AchievementFrameSummaryCategoriesCategory"..i])
    end



    ----------------
    -- Comparison --
    ----------------
    local AchievementFrameComparison = _G.AchievementFrameComparison
    _G.AchievementFrameComparisonHeader:SetHeight(private.FRAME_TITLE_HEIGHT * 2)
    _G.AchievementFrameComparisonHeaderBG:Hide()
    _G.AchievementFrameComparisonHeaderPortrait:Hide()
    _G.AchievementFrameComparisonHeaderPortraitBg:Hide()
    _G.AchievementFrameComparisonHeaderName:ClearAllPoints()
    _G.AchievementFrameComparisonHeaderName:SetPoint("TOP")
    _G.AchievementFrameComparisonHeaderName:SetHeight(private.FRAME_TITLE_HEIGHT)
    _G.AchievementFrameComparisonHeader.Points:ClearAllPoints()
    _G.AchievementFrameComparisonHeader.Points:SetPoint("TOP", "$parentName", "BOTTOM", 0, 0)
    _G.AchievementFrameComparisonHeader.Points:SetHeight(private.FRAME_TITLE_HEIGHT)

    AchievementFrameComparison.Summary:SetHeight(24)
    for _, unit in next, {"Player", "Friend"} do
        local summary = AchievementFrameComparison.Summary[unit]
        summary:SetHeight(24)
        Util.HideNineSlice(summary)
        summary:GetRegions():Hide() -- Background
        Skin.AchievementHeaderStatusBarTemplate(summary.StatusBar)
        summary.StatusBar:ClearAllPoints()
        summary.StatusBar:SetPoint("TOPLEFT")
        summary.StatusBar:SetPoint("BOTTOMRIGHT")
    end

    Skin.WowScrollBoxList(AchievementFrameComparison.AchievementContainer.ScrollBox)
    Skin.MinimalScrollBar(AchievementFrameComparison.AchievementContainer.ScrollBar)

    Skin.WowScrollBoxList(AchievementFrameComparison.StatContainer.ScrollBox)
    Skin.MinimalScrollBar(AchievementFrameComparison.StatContainer.ScrollBar)

    select(5, AchievementFrameComparison:GetChildren()):Hide()

    _G.AchievementFrameComparisonBackground:Hide()
    _G.AchievementFrameComparison.Dark:SetAlpha(0)
    _G.AchievementFrameComparison.Watermark:SetAlpha(0)



    Skin.UIPanelCloseButton(_G.AchievementFrameCloseButton)
    Skin.AchievementFrameTabButtonTemplate(_G.AchievementFrameTab1)
    Skin.AchievementFrameTabButtonTemplate(_G.AchievementFrameTab2)
    Skin.AchievementFrameTabButtonTemplate(_G.AchievementFrameTab3)
    Util.PositionRelative("TOPLEFT", AchievementFrame, "BOTTOMLEFT", 20, -1, 1, "Right", {
        _G.AchievementFrameTab1,
        _G.AchievementFrameTab2,
        _G.AchievementFrameTab3,
    })

    local SearchBox = AchievementFrame.SearchBox
    Skin.SearchBoxTemplate(SearchBox)
    SearchBox:ClearAllPoints()
    SearchBox:SetPoint("TOPRIGHT", bg, -148, 0)

    local AchievementFrameFilterDropdown = _G.AchievementFrameFilterDropdown
    Skin.DropdownButton(AchievementFrameFilterDropdown)
    AchievementFrameFilterDropdown.resizeToText = false
    AchievementFrameFilterDropdown:SetParent(AchievementFrame)
    AchievementFrameFilterDropdown:SetPoint("TOPLEFT", bg, 25, -4)
    AchievementFrameFilterDropdown:SetHeight(16)
    AchievementFrameFilterDropdown:SetWidth(60)

    local SearchPreview = AchievementFrame.SearchPreviewContainer
    Skin.FrameTypeFrame(SearchPreview)
    SearchPreview.Background:Hide()
    SearchPreview.BorderAnchor:Hide()
    SearchPreview.BotRightCorner:Hide()
    SearchPreview.BottomBorder:Hide()
    SearchPreview.LeftBorder:Hide()
    SearchPreview.RightBorder:Hide()
    SearchPreview.TopBorder:Hide()
    for i = 1, #SearchPreview.searchPreviews do
        Skin.AchievementSearchPreviewButton(SearchPreview.searchPreviews[i])
    end

    local ShowAllSearchResults = SearchPreview.ShowAllSearchResults
    ShowAllSearchResults.SelectedTexture:SetPoint("TOPLEFT", 1, -1)
    ShowAllSearchResults.SelectedTexture:SetPoint("BOTTOMRIGHT", -1, 1)

    ShowAllSearchResults:ClearNormalTexture()
    ShowAllSearchResults:ClearPushedTexture()


    local SearchResults = AchievementFrame.SearchResults
    Skin.FrameTypeFrame(SearchResults)
    SearchResults:GetRegions():Hide() -- background

    local TitleText = SearchResults.TitleText
    TitleText:ClearAllPoints()
    TitleText:SetPoint("TOPLEFT")
    TitleText:SetPoint("BOTTOMRIGHT", SearchResults, "TOPRIGHT", 0, -private.FRAME_TITLE_HEIGHT)

    SearchResults.TopLeftCorner:Hide()
    SearchResults.TopRightCorner:Hide()
    SearchResults.TopBorder:Hide()
    SearchResults.BottomLeftCorner:Hide()
    SearchResults.BottomRightCorner:Hide()
    SearchResults.BottomBorder:Hide()
    SearchResults.LeftBorder:Hide()
    SearchResults.RightBorder:Hide()
    SearchResults.TopTileStreaks:Hide()
    SearchResults.TopLeftCorner2:Hide()
    SearchResults.TopRightCorner2:Hide()
    SearchResults.TopBorder2:Hide()

    Skin.UIPanelCloseButton(SearchResults.CloseButton)
    Skin.WowScrollBoxList(SearchResults.ScrollBox)
    Skin.MinimalScrollBar(SearchResults.ScrollBar)
end
