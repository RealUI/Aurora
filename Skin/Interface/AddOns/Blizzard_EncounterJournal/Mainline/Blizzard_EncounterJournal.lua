local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals select next

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util


local function SkinSearchButton(button)
    button:ClearNormalTexture()
    button:ClearPushedTexture()

    local r, g, b = Color.highlight:GetRGB()
    local highlight = button.selectedTexture or button:GetHighlightTexture()
    highlight:SetColorTexture(r, g, b, 0.2)
end

do --[[ AddOns\Blizzard_EncounterJournal.lua ]]
    do --[[ Blizzard_EncounterJournal ]]
        local numcCreatureButtons = 1
        function Hook.EncounterJournal_ShowCreatures(clearDisplayInfo)
            local creatureButton = _G.EncounterJournal.encounter.info.creatureButtons[numcCreatureButtons]
            while creatureButton do
                Skin.EncounterCreatureButtonTemplate(creatureButton)
                numcCreatureButtons = numcCreatureButtons + 1
                creatureButton = _G.EncounterJournal.encounter.info.creatureButtons[numcCreatureButtons]
            end
        end
        function Hook.EncounterJournal_UpdateButtonState(self)
            if self:GetParent().expanded then
                self.expandedIcon:SetTextColor(Color.white:GetRGB())
                self.title:SetTextColor(Color.white:GetRGB())
            else
                self.expandedIcon:SetTextColor(Color.grayLight:GetRGB())
                self.title:SetTextColor(Color.grayLight:GetRGB())
            end
        end
        function Hook.EncounterJournal_SetBullets(object, description, hideBullets)
            local parent = object:GetParent()

            if parent.Bullets then
                for _, bullet in next, parent.Bullets do
                    Util.SkinOnce(bullet, Skin.EncounterOverviewBulletTemplate)
                end
            end
        end
        function Hook.EncounterJournal_SetUpOverview(self, overviewSectionID, index)
            local infoHeader = self.overviews[index]
            Util.SkinOnce(infoHeader, Skin.EncounterInfoTemplate)
            infoHeader.button._abilityIconBG:Hide()
        end
        function Hook.EncounterJournal_ToggleHeaders(self, doNotShift)
            local index = 1
            local infoHeader = _G["EncounterJournalInfoHeader"..index]
            while infoHeader do
                Util.SkinOnce(infoHeader, Skin.EncounterInfoTemplate)
                infoHeader.button._abilityIconBG:SetShown(infoHeader.button.abilityIcon:IsShown())

                index = index + 1
                infoHeader = _G["EncounterJournalInfoHeader"..index]
            end
        end
        function Hook.EncounterJournal_UpdateFilterString()
            local classID = _G.EJ_GetLootFilter()
            if classID > 0 then
                local classInfo = _G.C_CreatureInfo.GetClassInfo(classID)
                if classInfo then
                    local filterBG = _G.EncounterJournal.encounter.info.LootContainer.classClearFilter.bg
                    filterBG:SetVertexColor(_G.CUSTOM_CLASS_COLORS[classInfo.classFile]:GetRGB())
                end
            end
        end
        function Hook.EJSuggestFrame_UpdateRewards(suggestion)
            local rewardData = suggestion.reward.data
            if rewardData then
                Base.CropCircularIcon(suggestion.reward.icon)
            end
        end
        function Hook.EJSuggestFrame_RefreshDisplay()
            local self = _G.EncounterJournal.suggestFrame
            for i = 1, _G.AJ_MAX_NUM_SUGGESTIONS do
                local suggestion = self["Suggestion"..i]
                Base.CropCircularIcon(suggestion.icon)

                --local data = self.suggestions[i]
                --if data then
                    --suggestion.icon:SetTexture(data.iconPath)
                --end
            end
        end
        function Hook.EncounterJournal_DisplayInstance()
            local icon = _G.EncounterJournal.encounter.info.instanceButton.icon
            icon:SetMask("")
            icon:SetTexCoord(.08, .92, .08, .92)
        end

        Hook.JourneyProgressFrameMixin = {}
        function Hook.JourneyProgressFrameMixin:OnLoad()
            Util.WrapPoolAcquire(self.rewardPool, Skin.JourneyProgressRewardCardTemplate)
        end

        Hook.JourneyOverviewHighlightsFrameMixin = {}
        function Hook.JourneyOverviewHighlightsFrameMixin:OnLoad()
            Util.WrapPoolAcquire(self.highlightPool, Skin.JourneyOverviewHighlightTemplate)
        end
    end
    do --[[ Blizzard_EncounterJournal ]]
        Hook.RuneforgeLegendaryPowerLootJournalMixin = {}
        function Hook.RuneforgeLegendaryPowerLootJournalMixin:OnPowerSet(oldPowerID, newPowerID)
            if self.BackgroundOverlay:IsShown() then
                self:SetBackdropBorderColor(Color.gray:GetRGB())
            else
                self:SetBackdropBorderColor(_G.LEGENDARY_ORANGE_COLOR:GetRGB())
            end
            self.BackgroundOverlay:Hide()
        end
    end
end

-- EncounterJournalEncounterFrameInfo

do --[[ AddOns\Blizzard_EncounterJournal.xml ]]
    do --[[ Blizzard_EncounterJournal ]]
        function Skin.EJButtonTemplate(Button)
            Skin.FrameTypeButton(Button)
            if Button.UpLeft then
                Button.UpLeft:SetTexture("")
                Button.UpRight:SetTexture("")
                Button.DownLeft:SetTexture("")
                Button.DownRight:SetTexture("")
                Button.HighLeft:SetTexture("")
                Button.HighRight:SetTexture("")
            end
            if Button.TopLeftCorner then
                Button.TopLeftCorner:SetTexture("")
                Button.TopRightCorner:SetTexture("")
                Button.LeftEdge:SetTexture("")
                Button.RightEdge:SetTexture("")
                Button.BottomLeftCorner:SetTexture("")
                Button.BottomRightCorner:SetTexture("")
                Button.TopEdge:SetTexture("")
                Button.BottomEdge:SetTexture("")
            end
        end
        function Skin.EncounterInstanceButtonTemplate(Button)
            Skin.FrameTypeButton(Button)

            Button.bgImage:SetAlpha(0.6)
            Button.bgImage:SetTexCoord(0.01953125, 0.66015625, 0.0390625, 0.7109375)
            Button.bgImage:SetPoint("TOPLEFT", 1, -1)
            Button.bgImage:SetPoint("BOTTOMRIGHT", -1, 1)

            Button.name:SetPoint("TOPLEFT", 4, -4)
            Button.name:SetPoint("BOTTOMRIGHT", -4, 4)
        end
        function Skin.EncounterSearchSMTemplate(Button)
            SkinSearchButton(Button)

            local name = Button:GetName()
            _G[name.."IconFrame"]:SetAlpha(0)
            Base.CropIcon(Button.icon, Button)
        end
        function Skin.EncounterSearchAllSMTemplate(Button)
            Skin.SearchBoxListAllButtonTemplate(Button)
        end
        function Skin.EncounterSearchLGTemplate(Button)
            Button.iconFrame:SetAlpha(0)
            Base.CropIcon(Button.icon, Button)
            Button.path:SetTextColor(Color.grayLight:GetRGB())
            Button.resultType:SetTextColor(Color.grayLight:GetRGB())

            Button:ClearNormalTexture()
            Button:ClearPushedTexture()

            local r, g, b = Color.highlight:GetRGB()
            Button:GetHighlightTexture():SetColorTexture(r, g, b, 0.2)
        end
        function Skin.EncounterCreatureButtonTemplate(Button)
            Button:ClearNormalTexture()
            Button:ClearHighlightTexture()
        end
        function Skin.EncounterBossButtonTemplate(Button)
            Skin.FrameTypeButton(Button)
            Button:SetBackdropOption("offsets", {
                left = 0,
                right = 0,
                top = 5,
                bottom = 5,
            })
        end
        function Skin.EncounterTabTemplate(Button)
            -- BlizzWTF: this doesn't use CheckButton like other side tabs, so we have to do custom.
            Button:SetSize(34, 34)
            Button:ClearPushedTexture()
            Button:ClearDisabledTexture()

            local normal = Button:GetNormalTexture()
            Base.CropIcon(normal, Button)
            normal:SetTexture(Button.selected:GetTexture())
            normal:SetTexCoord(Button.selected:GetTexCoord())
            normal:SetAllPoints()

            local highlight = Button:GetHighlightTexture()
            highlight:SetTexture([[Interface\Buttons\ButtonHilight-Square]])
            Base.CropIcon(highlight)

            local selected = Button.selected
            selected:SetTexture([[Interface\Buttons\CheckButtonHilight]])
            selected:SetBlendMode("ADD")
            selected:SetAllPoints()
            Base.CropIcon(selected)

            Button.unselected:SetAllPoints()
        end
        function Skin.EncounterOverviewBulletTemplate(Frame)
            Frame.Text:SetTextColor("p", Color.grayLight:GetRGB())
        end
        function Skin.EncounterDescriptionTemplate(Frame)
            Frame.Text:SetTextColor("p", Color.grayLight:GetRGB())
        end
        function Skin.EncounterInfoTemplate(Frame)
            local button = Frame.button
            Base.SetBackdrop(button, Color.button)
            Base.SetHighlight(button)
            button._abilityIconBG = Base.CropIcon(button.abilityIcon, button)

            button.eLeftUp:SetTexture("")
            button.eRightUp:SetTexture("")
            button.eLeftDown:SetTexture("")
            button.eRightDown:SetTexture("")
            button.cLeftUp:SetTexture("")
            button.cRightUp:SetTexture("")
            button.cLeftDown:SetTexture("")
            button.cRightDown:SetTexture("")

            button.eMidUp:SetTexture("")
            button.eMidDown:SetTexture("")
            button.cMidUp:SetTexture("")
            button.cMidDown:SetTexture("")

            local name = button:GetName()
            _G[name.."HighlightLeft"]:SetTexture("")
            _G[name.."HighlightRight"]:SetTexture("")
            _G[name.."HighlightMid"]:SetTexture("")

            Skin.EncounterDescriptionTemplate(Frame.overviewDescription)
            Frame.description:SetTextColor(Color.grayLight:GetRGB())
            Frame.descriptionBG:SetTexture("")
            Frame.descriptionBGBottom:SetTexture("")
        end
        function Skin.AdventureJournal_SecondaryTemplate(Frame)
            Base.SetBackdrop(Frame, Color.frame, Color.frame.a)
            Frame:SetBackdropOption("offsets", {
                left = 0,
                right = 0,
                top = 12,
                bottom = 0,
            })

            Frame.bg:Hide()
            Base.CropIcon(Frame.icon, Frame)
            Frame.iconRing:SetAlpha(0)

            Frame.centerDisplay.title.text:SetTextColor(Color.white:GetRGB())
            Frame.centerDisplay.description.text:SetTextColor(Color.grayLight:GetRGB())
            Skin.UIPanelButtonTemplate(Frame.centerDisplay.button)

            Frame.reward:SetPoint("BOTTOMRIGHT", Frame.icon, 9, -9)
            Base.CropCircularIcon(Frame.reward.icon, Frame.reward)
            Frame.reward.iconRing:SetAlpha(0)
            Frame.reward.iconRingHighlight:SetAlpha(0)
        end
        function Skin.EncounterItemTemplate(Button)
            Base.CropIcon(Button.icon)
            local bg = _G.CreateFrame("Frame", nil, Button)
            bg:SetPoint("TOPLEFT", Button.icon, -1, 1)
            bg:SetPoint("BOTTOMRIGHT", Button.icon, 1, -1)
            Base.SetBackdrop(bg, Color.black, 0)
            Button._auroraIconBorder = bg
            Button.armorType:SetTextColor(Color.gray:GetRGB())
            Button.slot:SetTextColor(Color.gray:GetRGB())
            Button.boss:SetTextColor(Color.gray:GetRGB())
            Button.bossTexture:SetTexture("")
            Button.bosslessTexture:SetTexture("")
        end
        function Skin.EncounterTierTabTemplate(Button)
            Button.mid:Hide()
            Button.left:Hide()
            Button.right:Hide()

            Button.midSelect:SetAlpha(0)
            Button.leftSelect:SetAlpha(0)
            Button.rightSelect:SetAlpha(0)

            Button.midHighlight:Hide()
            Button.leftHighlight:Hide()
            Button.rightHighlight:Hide()
        end
        function Skin.BottomEncounterTierTabTemplate(Button)
            Skin.PanelTabButtonTemplate(Button)
        end
        function Hook.EJInstanceSelectScrollUpdate(frame)
            frame:ForEachFrame(function(child)
                    if not child._auroraSkinned then
                    local bgImage = child.bgImage
                    if bgImage then
                        bgImage:SetAlpha(0.6)
                        bgImage:SetTexCoord(0.01953125, 0.66015625, 0.0390625, 0.7109375)
                        bgImage:SetPoint("TOPLEFT", 1, -1)
                        bgImage:SetPoint("BOTTOMRIGHT", -1, 1)
                    end
                    Skin.EncounterBossButtonTemplate(child)
                    child._auroraSkinned = true
                end
            end)
        end
        function  Hook.EJBossesScrollBoxScrollUpdate(frame)
            frame:ForEachFrame(function(child)
                Util.SkinOnce(child, Skin.EncounterBossButtonTemplate)
            end)
        end
        function Skin.JourneyOverviewHighlightTemplate(Frame)
            if Frame._auroraSkinned then
                return
            end

            Frame._auroraSkinned = true

            if Frame.Background then
                Frame.Background:SetAlpha(0)
            end
            Base.SetBackdrop(Frame, Color.frame, Color.frame.a)

            Frame.HighlightTitle:SetTextColor(Color.white:GetRGB())
            Frame.HighlightLevel:SetTextColor(Color.grayLight:GetRGB())
            Frame.HighlightDescription:SetTextColor(Color.grayLight:GetRGB())
        end
        function Skin.JourneyProgressRewardCardTemplate(Frame)
            if Frame._auroraSkinned then
                return
            end

            Frame._auroraSkinned = true

            if Frame.RewardCardBG then
                Frame.RewardCardBG:SetAlpha(0)
            end
            Base.SetBackdrop(Frame, Color.frame, Color.frame.a)
            Base.CropIcon(Frame.RewardCardIcon, Frame)
            Frame.RewardCardIconBorderDefault:SetAlpha(0)
            Frame.RewardCardName:SetTextColor(Color.white:GetRGB())
        end
    end
    do --[[ Blizzard_LootJournal ]]
        function Skin.RuneforgeLegendaryPowerLootJournalTemplate(Button)
            Util.Mixin(Button, Hook.RuneforgeLegendaryPowerLootJournalMixin)
            Base.CropIcon(Button.Icon)

            Base.SetBackdrop(Button)
            Button:SetBackdropOption("offsets", {
                left = 11,
                right = 249,
                top = 7,
                bottom = 7,
            })

            Button.CircleMask:Hide()
            Button.Background:Hide()
        end
    end
end

function private.AddOns.Blizzard_EncounterJournal()
    ----====#####################====----
    --    Blizzard_EncounterJournal    --
    ----====#####################====----
    _G.hooksecurefunc("EncounterJournal_ShowCreatures", Hook.EncounterJournal_ShowCreatures)
    _G.hooksecurefunc("EncounterJournal_UpdateButtonState", Hook.EncounterJournal_UpdateButtonState)
    _G.hooksecurefunc("EncounterJournal_SetBullets", Hook.EncounterJournal_SetBullets)
    _G.hooksecurefunc("EncounterJournal_SetUpOverview", Hook.EncounterJournal_SetUpOverview)
    _G.hooksecurefunc("EncounterJournal_ToggleHeaders", Hook.EncounterJournal_ToggleHeaders)
    _G.hooksecurefunc("EncounterJournal_UpdateFilterString", Hook.EncounterJournal_UpdateFilterString)
    _G.hooksecurefunc("EJSuggestFrame_UpdateRewards", Hook.EJSuggestFrame_UpdateRewards)
    _G.hooksecurefunc("EJSuggestFrame_RefreshDisplay", Hook.EJSuggestFrame_RefreshDisplay)
    _G.hooksecurefunc("EncounterJournal_DisplayInstance", Hook.EncounterJournal_DisplayInstance)
    _G.hooksecurefunc(_G.JourneyProgressFrameMixin, "OnLoad", Hook.JourneyProgressFrameMixin.OnLoad)
    _G.hooksecurefunc(_G.JourneyOverviewHighlightsFrameMixin, "OnLoad", Hook.JourneyOverviewHighlightsFrameMixin.OnLoad)

    local EncounterJournal = _G.EncounterJournal
    Skin.PortraitFrameTemplate(EncounterJournal)

    Skin.SearchBoxListTemplate(EncounterJournal.searchBox)
    Skin.BottomPopupScrollBoxTemplate(EncounterJournal.searchResults)

    local navBar = EncounterJournal.navBar
    -- Skin.NavBarTemplate(navBar) -- this is skinned from hooks in NavigationBar.lua
    navBar:SetPoint("TOPLEFT", 10, -private.FRAME_TITLE_HEIGHT)
    navBar:SetPoint("RIGHT", EncounterJournal.searchBox, "LEFT", -10, 0)
    navBar.InsetBorderBottomLeft:Hide()
    navBar.InsetBorderBottomRight:Hide()
    navBar.InsetBorderBottom:Hide()
    navBar.InsetBorderLeft:Hide()
    navBar.InsetBorderRight:Hide()

    Skin.InsetFrameTemplate(EncounterJournal.inset)

    ------------------
    -- MonthlyActivitiesFrame --
    ------------------
    local MonthlyActivitiesFrame = _G.EncounterJournalMonthlyActivitiesFrame
    local ThemeContainer = MonthlyActivitiesFrame.ThemeContainer
    local ThresholdContainer = MonthlyActivitiesFrame.ThresholdContainer
    local MonthlyActivitiesFrameBg = MonthlyActivitiesFrame.Bg

    MonthlyActivitiesFrame.HelpButton:Hide()
    MonthlyActivitiesFrame.Divider:Hide()
    MonthlyActivitiesFrame.DividerVertical:Hide()
    MonthlyActivitiesFrameBg:SetAlpha(0)

    ThemeContainer:SetAlpha(0)
    ThemeContainer.Top:SetTexture("")
    ThemeContainer.Bottom:SetTexture("")
    ThemeContainer.Left:SetTexture("")
    ThemeContainer.Right:SetTexture("")

    Skin.FrameTypeStatusBar(ThresholdContainer.ThresholdBar)
    select(3, ThresholdContainer.ThresholdBar:GetRegions()):Hide()
    Skin.FrameTypeStatusBar(ThresholdContainer.BonusThresholdBar)
    select(3, ThresholdContainer.BonusThresholdBar:GetRegions()):Hide()
    ThresholdContainer.BarBorder:SetTexture("")
    Skin.MinimalScrollBar(MonthlyActivitiesFrame.FilterList.ScrollBar)
    Skin.WowScrollBoxList(MonthlyActivitiesFrame.FilterList.ScrollBox)
    Skin.MinimalScrollBar(MonthlyActivitiesFrame.ScrollBar)
    Skin.WowScrollBoxList(MonthlyActivitiesFrame.ScrollBox)

    --------------------
    -- InstanceSelect --
    --------------------
    local instanceSelect = _G.EncounterJournalInstanceSelect
    instanceSelect.evergreenBg:SetAlpha(0)
    instanceSelect.bg:SetAlpha(0)
    Skin.DropdownButton(instanceSelect.ExpansionDropdown)
    Skin.WowScrollBoxList(instanceSelect.ScrollBox)
    Skin.MinimalScrollBar(instanceSelect.ScrollBar)
    _G.hooksecurefunc(instanceSelect.ScrollBox, 'Update', Hook.EJInstanceSelectScrollUpdate)

    --------------------
    -- EncounterFrame --
    --------------------
    local encounter = EncounterJournal.encounter

    local instance = encounter.instance
    instance.loreBG:SetTexCoord(0.05859375, 0.703125, 0.08203125, 0.576171875)
    instance.loreBG:SetSize(330, 253)
    instance.loreBG:SetPoint("TOP", 3, -51)
    instance.loreBG:SetAlpha(0.8)

    instance.title:SetPoint("TOP", instance.loreBG, 0, -25)

    instance.titleBG:ClearAllPoints()
    instance.titleBG:SetPoint("BOTTOM", instance.title, 0, -29)

    instance.mapButton:SetPoint("BOTTOMLEFT", 36, 125)
    instance.mapButton:GetRegions():SetTexCoord(0.013671875, 0.3359375, 0.8525390625, 0.8955078125)

    Skin.ScrollingFontTemplate(instance.LoreScrollingFont)
    instance.LoreScrollingFont:SetTextColor(Color.grayLight)
    Skin.MinimalScrollBar(instance.LoreScrollBar)

    local info = encounter.info
    info:GetRegions():Hide()

    info.leftShadow:SetTexture([[Interface\LFGFrame\UI-LFG-SEPARATOR]])
    info.leftShadow:SetTexCoord(0, 0.6640625, 0, 0.3125)
    info.rightShadow:SetTexture([[Interface\LFGFrame\UI-LFG-SEPARATOR]])
    info.rightShadow:SetTexCoord(0, 0.6640625, 0, 0.3125)

    info.encounterTitle:SetTextColor(Color.white:GetRGB())
    info.instanceTitle:SetTextColor(Color.white:GetRGB())
    Base.CropIcon(info.instanceButton.icon)
    info.instanceButton:ClearNormalTexture()
    info.instanceButton:GetHighlightTexture():Hide()

    Skin.EncounterTabTemplate(info.overviewTab)
    Skin.EncounterTabTemplate(info.lootTab)
    Skin.EncounterTabTemplate(info.bossTab)
    Skin.EncounterTabTemplate(info.modelTab)

    Util.PositionRelative("TOPLEFT", info, "TOPRIGHT", 10, -40, 5, "Down", {
        info.overviewTab,
        info.lootTab,
        info.bossTab,
        info.modelTab,
    })

    Skin.WowScrollBoxList(info.BossesScrollBox)
    _G.hooksecurefunc(info.BossesScrollBox, 'Update', Hook.EJBossesScrollBoxScrollUpdate)
    Skin.MinimalScrollBar(info.BossesScrollBar)
    Skin.EJButtonTemplate(info.difficulty)

    Skin.ScrollFrameTemplate(info.detailsScroll)
    info.detailsScroll.child.description:SetTextColor(Color.grayLight:GetRGB())

    local overviewScroll = info.overviewScroll
    Skin.ScrollFrameTemplate(overviewScroll)
    overviewScroll.child.loreDescription:SetTextColor(Color.grayLight:GetRGB())
    overviewScroll.child.header:SetDesaturated(true)
    _G.EncounterJournalEncounterFrameInfoOverviewScrollFrameScrollChildTitle:SetTextColor(Color.white:GetRGB())
    Skin.EncounterDescriptionTemplate(overviewScroll.child.overviewDescription)

    local LootContainer = info.LootContainer
    local classFilterBG = LootContainer.classClearFilter:GetRegions()
    classFilterBG:SetDesaturated(true)
    LootContainer.classClearFilter.bg = classFilterBG

    Skin.WowScrollBoxList(LootContainer.ScrollBox)
    Skin.MinimalScrollBar(LootContainer.ScrollBar)
    Skin.EJButtonTemplate(LootContainer.filter)
    Skin.EJButtonTemplate(LootContainer.slotFilter)

    local model = info.model
    model.dungeonBG:Hide()
    _G.EncounterJournalEncounterFrameInfoModelFrameShadow:Hide()
    _G.EncounterJournalEncounterFrameInfoModelFrameTitleBG:Hide()


    ------------------
    -- SuggestFrame --
    ------------------
    local suggestFrame = EncounterJournal.suggestFrame

    local Suggestion1 = suggestFrame.Suggestion1
    Suggestion1.bg:Hide()
    Base.SetBackdrop(Suggestion1, Color.frame, Color.frame.a)
    Suggestion1:SetBackdropOption("offsets", {
        left = 0,
        right = 0,
        top = 12,
        bottom = 0,
    })

    Base.CropCircularIcon(Suggestion1.icon, Suggestion1)
    Suggestion1.iconRing:SetAlpha(0)

    Suggestion1.centerDisplay.title.text:SetTextColor(Color.white:GetRGB())
    Suggestion1.centerDisplay.description.text:SetTextColor(Color.grayLight:GetRGB())

    Skin.UIPanelButtonTemplate(Suggestion1.button)

    Base.CropCircularIcon(Suggestion1.reward.icon, Suggestion1.reward)
    Suggestion1.reward.text:SetTextColor(Color.grayLight:GetRGB())
    Suggestion1.reward.iconRing:SetAlpha(0)
    Suggestion1.reward.iconRingHighlight:SetAlpha(0)

    Skin.NavButtonPrevious(Suggestion1.prevButton)
    Skin.NavButtonNext(Suggestion1.nextButton)

    Skin.AdventureJournal_SecondaryTemplate(suggestFrame.Suggestion2)
    Skin.AdventureJournal_SecondaryTemplate(suggestFrame.Suggestion3)



    ------------------
    -- Tab Frames --
    ------------------
    Skin.BottomEncounterTierTabTemplate(_G.EncounterJournalMonthlyActivitiesTab)
    Skin.BottomEncounterTierTabTemplate(_G.EncounterJournalSuggestTab)
    Skin.BottomEncounterTierTabTemplate(_G.EncounterJournalDungeonTab)
    Skin.BottomEncounterTierTabTemplate(_G.EncounterJournalRaidTab)
    Skin.BottomEncounterTierTabTemplate(_G.EncounterJournalLootJournalTab)
    Skin.BottomEncounterTierTabTemplate(_G.EncounterJournalJourneysTab)
    Skin.BottomEncounterTierTabTemplate(EncounterJournal.TutorialsTab)
    Util.PositionRelative("TOPLEFT", EncounterJournal, "BOTTOMLEFT", 20, -1, 1, "Right", {
        _G.EncounterJournalJourneysTab,
        _G.EncounterJournalMonthlyActivitiesTab,
        _G.EncounterJournalSuggestTab,
        _G.EncounterJournalDungeonTab,
        _G.EncounterJournalRaidTab,
        _G.EncounterJournalLootJournalTab,
        EncounterJournal.TutorialsTab,
    })


    -----------------------------
    -- EncounterJournalTooltip --
    -----------------------------
    if not private.disabled.tooltips then
        local tooltip = _G.EncounterJournalTooltip
        Skin.FrameTypeFrame(tooltip)

        Base.CropIcon(tooltip.Item1.icon)
        Base.SetBackdrop(tooltip.Item1, Color.black, Color.frame.a)
        local bg = tooltip.Item1:GetBackdropTexture("bg")
        bg:SetPoint("TOPLEFT", tooltip.Item1.icon, -1, 1)
        bg:SetPoint("BOTTOMRIGHT", tooltip.Item1.icon, 1, -1)
        tooltip.Item1._auroraIconBorder = tooltip.Item1

        Base.CropIcon(tooltip.Item2.icon)
        Base.SetBackdrop(tooltip.Item2, Color.black, Color.frame.a)
        bg = tooltip.Item2:GetBackdropTexture("bg")
        bg:SetPoint("TOPLEFT", tooltip.Item2.icon, -1, 1)
        bg:SetPoint("BOTTOMRIGHT", tooltip.Item2.icon, 1, -1)
        tooltip.Item2._auroraIconBorder = tooltip.Item2
    end



    ----====############################====----
    --     EncounterJournalEncounterFrame     --
    ----====############################====----
    Skin.MinimalScrollBar(_G.EncounterJournalEncounterFrameInstanceFrame.LoreScrollBar)
    Skin.MinimalScrollBar(_G.EncounterJournalEncounterFrameInfo.LootContainer.ScrollBar)
	Skin.MinimalScrollBar(_G.EncounterJournalEncounterFrameInfoDetailsScrollFrame.ScrollBar)
	Skin.MinimalScrollBar(_G.EncounterJournalEncounterFrameInfoOverviewScrollFrame.ScrollBar)



    ----====############################====----
    --      EncounterJournal.LootJournal      --
    ----====############################====----
    local LootJournal = EncounterJournal.LootJournal
    local ItemSetsFrame = EncounterJournal.LootJournalItems.ItemSetsFrame
    LootJournal:GetRegions():Hide()

    Skin.DropdownButton(LootJournal.ClassDropdown)
    Skin.DropdownButton(ItemSetsFrame.ClassDropdown)

    Skin.DropdownButton(LootJournal.RuneforgePowerDropdown)
    Skin.WowScrollBoxList(LootJournal.ScrollBox)

    ----====#############################====----
    --      EncounterJournalJourneysFrame      --
    ----====#############################====----
    local EncounterJournalJourneysFrame = _G.EncounterJournalJourneysFrame
    Skin.MinimalScrollBar(EncounterJournalJourneysFrame.ScrollBar)
    Util.WrapPoolAcquire(EncounterJournalJourneysFrame.JourneyProgress.rewardPool, Skin.JourneyProgressRewardCardTemplate)
    Util.WrapPoolAcquire(EncounterJournalJourneysFrame.JourneyOverview.Highlights.highlightPool, Skin.JourneyOverviewHighlightTemplate)


    ----====####################====----
    --       Blizzard_Tutorials       --
    ----====####################====----
    -- Not sure what to expect here ..
    local TutorialsTab = EncounterJournal.TutorialsTab
    local TutorialsFrame = EncounterJournal.TutorialsFrame
    Skin.UIPanelButtonTemplate(TutorialsFrame.Contents.StartButton)
    TutorialsTab:GetRegions():Hide()

end
