local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals next select

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util
local Config = private.Config

local function IsConfigEnabled(optionKey)
    local auroraConfig = _G.AuroraConfig or Config and Config.defaults
    return auroraConfig == nil or auroraConfig[optionKey] ~= false
end

do --[[ AddOns\Blizzard_ObjectiveTracker.lua ]]
    Hook.ObjectiveTrackerFrameMixin = {}
    Hook.ObjectiveTrackerBlockMixin = {}
    function Hook.ObjectiveTrackerBlockMixin:AddObjective(objectiveKey, text, template, ...)
        local line = self.usedLines[objectiveKey]
        if line and not private.IsSkinned(line) then
            local tpl = template or self.parentModule.lineTemplate
            if Skin[tpl] then
                Skin[tpl](line)
            end
            private.SetSkinned(line, true)
        end
    end
    function Hook.ObjectiveTrackerBlockMixin:AddTimerBar(duration, startTime)
        Util.SkinOnce(self.lastRegion, Skin.ObjectiveTrackerTimerBarTemplate)
    end
    function Hook.ObjectiveTrackerBlockMixin:AddProgressBar(id, lineSpacing)
        Util.SkinOnce(self.lastRegion, Skin.ObjectiveTrackerProgressBarTemplate)
    end
    function Hook.ObjectiveTrackerBlockMixin:AddRightEdgeFrame(settings, identifier, ...)
        local frame = self.rightEdgeFrame
        if frame and not private.IsSkinned(frame) then
            if Skin[settings.template] then
                Skin[settings.template](frame)
            end
            private.SetSkinned(frame, true)
        end
    end
    Hook.ObjectiveTrackerContainerHeaderMixin = {}
    function Hook.ObjectiveTrackerContainerHeaderMixin:SetCollapsed(collapsed)
        local btn = self.MinimizeButton
        if btn._auroraArrow then
            Base.SetTexture(btn._auroraArrow, collapsed and "arrowDown" or "arrowUp")
            -- Blizzard's SetCollapsed calls SetAtlas which re-shows the texture; hide it again
            local t = btn:GetNormalTexture()
            if t then t:SetAlpha(0) end
            t = btn:GetPushedTexture()
            if t then t:SetAlpha(0) end
        end
    end
    Hook.ObjectiveTrackerModuleHeaderMixin = {}
    function Hook.ObjectiveTrackerModuleHeaderMixin:SetCollapsed(collapsed)
        local btn = self.MinimizeButton
        if btn._auroraArrow then
            Base.SetTexture(btn._auroraArrow, collapsed and "arrowDown" or "arrowUp")
            local t = btn:GetNormalTexture()
            if t then t:SetAlpha(0) end
            t = btn:GetPushedTexture()
            if t then t:SetAlpha(0) end
        end
    end
    Hook.ObjectiveTrackerQuestPOIBlockMixin = {}
    function Hook.ObjectiveTrackerQuestPOIBlockMixin:GetPOIButton(style)
        local btn = self.poiButton
        if not btn then return end
        local r, g, b = Color.button:GetRGB()
        local t = btn:GetNormalTexture()
        if t then
            t:SetDesaturated(true)
            t:SetVertexColor(r, g, b)
        end
        t = btn:GetPushedTexture()
        if t then
            t:SetDesaturated(true)
            t:SetVertexColor(r * 0.8, g * 0.8, b * 0.8)
        end
        t = btn:GetHighlightTexture()
        if t then t:SetAlpha(0) end
        if btn.Glow then btn.Glow:SetAlpha(0) end
        if btn.HighlightTexture then btn.HighlightTexture:SetAlpha(0) end
        Util.SkinOnce(btn, function(button) Base.CropIcon(button.Display.Icon) end)
    end
end

do --[[ AddOns\Blizzard_ObjectiveTracker.xml ]]
    function Skin.QuestObjectiveItemButtonTemplate(Button)
        Base.CropIcon(Button.icon, Button)
        Button:ClearNormalTexture()
        Base.CropIcon(Button:GetPushedTexture())
        Base.CropIcon(Button:GetHighlightTexture())
    end
    function Skin.QuestObjectiveFindGroupButtonTemplate(Button)
        local bdFrame = _G.CreateFrame("Frame", nil, Button)
        bdFrame:SetPoint("TOPLEFT", 4, -4)
        bdFrame:SetPoint("BOTTOMRIGHT", -4, 4)
        bdFrame:SetFrameLevel(Button:GetFrameLevel())
        Base.SetBackdrop(bdFrame, Color.button)

        Button._auroraBDFrame = bdFrame
        Base.SetHighlight(Button)

        Button:ClearNormalTexture()
        Button:ClearPushedTexture()
        Button:ClearDisabledTexture()
        Button:ClearHighlightTexture()
    end

    Skin.ObjectiveTrackerBlockTemplate = private.nop
    function Skin.ObjectiveTrackerMinimizeButtonTemplate(Button)
        Skin.FrameTypeButton(Button)
        Button:SetBackdropOption("offsets", {
            left = 1,
            right = 2,
            top = 2,
            bottom = 1,
        })

        local t = Button:GetNormalTexture()
        if t then t:SetAlpha(0) end
        t = Button:GetPushedTexture()
        if t then t:SetAlpha(0) end
        t = Button:GetHighlightTexture()
        if t then t:SetAlpha(0) end

        local bg = Button:GetBackdropTexture("bg")
        local arrow = Button:CreateTexture(nil, "OVERLAY")
        arrow:SetPoint("TOPLEFT", bg, 2, -4)
        arrow:SetSize(9, 4.5)
        Button._auroraArrow = arrow
        Button._auroraTextures = {arrow}
        Base.SetTexture(arrow, "arrowUp")
    end

    function Skin.ObjectiveTrackerContainerHeaderTemplate(Frame)
        Frame.Background:Hide()

        local sep = Frame:CreateTexture(nil, "ARTWORK")
        sep:SetTexture([[Interface\LFGFrame\UI-LFG-SEPARATOR]])
        sep:SetTexCoord(0, 0.6640625, 0, 0.3125)
        sep:SetVertexColor(Color.highlight.r * 0.7, Color.highlight.g * 0.7, Color.highlight.b * 0.7)
        sep:SetPoint("BOTTOMLEFT", -30, -4)
        sep:SetSize(210, 30)

        Skin.ObjectiveTrackerMinimizeButtonTemplate(Frame.MinimizeButton)
        if Frame.FilterButton then
            Skin.ObjectiveTrackerMinimizeButtonTemplate(Frame.FilterButton)
        end
    end

    function Skin.ObjectiveTrackerModuleHeaderTemplate(Frame)
        Frame.Background:Hide()
        Frame.Shine:Hide()
        Frame.Glow:Hide()

        local sep = Frame:CreateTexture(nil, "ARTWORK")
        sep:SetTexture([[Interface\LFGFrame\UI-LFG-SEPARATOR]])
        sep:SetTexCoord(0, 0.6640625, 0, 0.3125)
        sep:SetVertexColor(Color.highlight.r * 0.5, Color.highlight.g * 0.5, Color.highlight.b * 0.5)
        sep:SetPoint("BOTTOMLEFT", -30, -4)
        sep:SetSize(210, 30)

        Skin.ObjectiveTrackerMinimizeButtonTemplate(Frame.MinimizeButton)
    end

    Skin.ObjectiveTrackerHeaderTemplate = Skin.ObjectiveTrackerModuleHeaderTemplate
    Skin.ObjectiveTrackerLineTemplate = private.nop
    Skin.ObjectiveTrackerCheckLineTemplate = private.nop
    function Skin.ObjectiveTrackerTimerBarTemplate(Frame)
        Skin.FrameTypeStatusBar(Frame.Bar)

        local left, right, mid, bg = Frame.Bar:GetRegions()
        left:Hide()
        right:Hide()
        mid:Hide()
        bg:Hide()
    end
    function Skin.ObjectiveTrackerProgressBarTemplate(Frame)
        local bar = Frame.Bar
        Skin.FrameTypeStatusBar(bar)

        local _, _, _, _, bg = bar:GetRegions()
        bar.BorderLeft:Hide()
        bar.BorderRight:Hide()
        bar.BorderMid:Hide()
        bg:Hide()
    end

    function Skin.QuestObjectiveAnimLineTemplate(Frame)
        Skin.ObjectiveTrackerLineTemplate(Frame)
        Frame.Check:SetAtlas("worldquest-tracker-checkmark")
        Frame.Check:SetSize(18, 16)
    end

    function Skin.AutoQuestPopUpBlockTemplate(Block)
        local Contents = Block.Contents or Block.ScrollChild
        if not Contents then return end
        Base.CreateBackdrop(Contents, private.backdrop, {
            tl = Contents.BorderTopLeft,
            tr = Contents.BorderTopRight,
            bl = Contents.BorderBotLeft,
            br = Contents.BorderBotRight,

            t = Contents.BorderTop,
            b = Contents.BorderBottom,
            l = Contents.BorderLeft,
            r = Contents.BorderRight,

            bg = Contents.Bg
        })

        Skin.FrameTypeFrame(Contents)
        Contents:SetBackdropBorderColor(Color.yellow:GetRGB())
        Contents:SetBackdropOption("offsets", {
            left = 35,
            right = -1,
            top = 3,
            bottom = 3
        })
    end

    function Skin.BonusObjectiveTrackerLineTemplate(Frame)
        Skin.ObjectiveTrackerCheckLineTemplate(Frame)
    end

    Skin.BonusObjectiveTrackerBlockTemplate = private.nop

    function Skin.BonusObjectiveTrackerHeaderTemplate(Frame)
        Skin.ObjectiveTrackerModuleHeaderTemplate(Frame)
    end

    function Skin.BonusTrackerProgressBarTemplate(Frame)
        local bar = Frame.Bar
        bar:ClearAllPoints()
        bar:SetPoint("TOPLEFT", 10, -10)
        Skin.FrameTypeStatusBar(bar)

        bar.BarFrame:Hide()
        bar.IconBG:SetAlpha(0)
        bar.BarBG:Hide()
        bar.Icon:SetSize(26, 26)
        bar.Icon:SetPoint("RIGHT", 33, 0)
        Base.CropCircularIcon(bar.Icon, bar)
    end

    function Skin.ScenarioTrackerProgressBarTemplate(Frame)
        local bar = Frame.Bar
        Skin.FrameTypeStatusBar(bar)

        bar.BarFrame:SetAlpha(0)
        bar.BarFrame2:SetAlpha(0)
        bar.BarFrame3:SetAlpha(0)
        bar.IconBG:SetAlpha(0)
        bar.BarBG:SetAlpha(0)
        bar.Icon:SetSize(26, 26)
        bar.Icon:SetPoint("RIGHT", 33, 0)
        Base.CropCircularIcon(bar.Icon)
    end
    Skin.ScenarioProgressBarTemplate = Skin.ScenarioTrackerProgressBarTemplate
end

function private.AddOns.Blizzard_ObjectiveTracker()
    if not IsConfigEnabled("objectiveTracker") then return end

    Util.Mixin(_G.ObjectiveTrackerFrameMixin, Hook.ObjectiveTrackerFrameMixin)
    Util.Mixin(_G.ObjectiveTrackerBlockMixin, Hook.ObjectiveTrackerBlockMixin)
    Util.Mixin(_G.ObjectiveTrackerContainerHeaderMixin, Hook.ObjectiveTrackerContainerHeaderMixin)
    Util.Mixin(_G.ObjectiveTrackerModuleHeaderMixin, Hook.ObjectiveTrackerModuleHeaderMixin)
    Util.Mixin(_G.ObjectiveTrackerQuestPOIBlockMixin, Hook.ObjectiveTrackerQuestPOIBlockMixin)

    _G.ObjectiveTrackerFrame.NineSlice:Hide()
    Skin.ObjectiveTrackerContainerHeaderTemplate(_G.ObjectiveTrackerFrame.Header)

    local function SkinModule(module)
        if not module then return end
        if module.Header then
            Skin.ObjectiveTrackerModuleHeaderTemplate(module.Header)
        end
    end

    for _, moduleName in next, {
        "QuestObjectiveTracker",
        "CampaignQuestObjectiveTracker",
        "AchievementObjectiveTracker",
        "BonusObjectiveTracker",
        "WorldQuestObjectiveTracker",
        "AdventureObjectiveTracker",
        "ProfessionsRecipeTracker",
        "UIWidgetObjectiveTracker",
        "InitiativeTasksObjectiveTracker",
        "MonthlyActivitiesObjectiveTracker",
    } do
        SkinModule(_G[moduleName])
    end

    SkinModule(_G.ScenarioObjectiveTracker)

    local ScenarioStageBlock = _G.ScenarioObjectiveTracker.StageBlock
    if ScenarioStageBlock then
        ScenarioStageBlock.NormalBG:SetAlpha(0)

        local ssbBD = _G.CreateFrame("Frame", nil, ScenarioStageBlock)
        ssbBD:SetFrameLevel(ScenarioStageBlock:GetFrameLevel())
        ssbBD:SetAllPoints(ScenarioStageBlock.NormalBG)
        ssbBD:SetClipsChildren(true)
        ssbBD:SetPoint("TOPLEFT", ScenarioStageBlock.NormalBG, 3, -3)
        ssbBD:SetPoint("BOTTOMRIGHT", ScenarioStageBlock.NormalBG, -3, 3)
        Base.SetBackdrop(ssbBD, Color.button, 0.75)

        local overlay = ssbBD:CreateTexture(nil, "OVERLAY")
        overlay:SetSize(120, 120)
        overlay:SetPoint("TOPRIGHT", 23, 20)
        overlay:SetAlpha(0.2)
        overlay:SetDesaturated(true)

        -- The backdrop frame and overlay used to also be stored as
        -- ScenarioStageBlock._auroraBG / ._auroraOverlay. Nothing ever read
        -- them, and they were direct table writes onto the very Blizzard frame
        -- whose LayoutContents throws on tainted GetAuraDataByIndex — so the
        -- references are dropped rather than kept as dead taint surface. Both
        -- objects stay alive as children of ScenarioStageBlock.
    end
    local ScenarioChallengeModeBlock = _G.ScenarioObjectiveTracker.ChallengeModeBlock
    if ScenarioChallengeModeBlock then
        if ScenarioChallengeModeBlock.TimerBGBack then ScenarioChallengeModeBlock.TimerBGBack:Hide() end
        if ScenarioChallengeModeBlock.TimerBG then ScenarioChallengeModeBlock.TimerBG:Hide() end

        Skin.FrameTypeStatusBar(ScenarioChallengeModeBlock.StatusBar)
        ScenarioChallengeModeBlock.StatusBar:SetStatusBarColor(Color.cyan:GetRGB())
    end
    if _G.ScenarioObjectiveTracker.MawBuffsBlock then
        Skin.MawBuffsContainer(_G.ScenarioObjectiveTracker.MawBuffsBlock.Container)
    end
    -- Midnight's equivalent of MawBuffsBlock, shown in scenario/delve content.
    if _G.ScenarioObjectiveTracker.TieredEntranceTraitsBlock and Skin.TieredEntranceTraitsContainer then
        Skin.TieredEntranceTraitsContainer(_G.ScenarioObjectiveTracker.TieredEntranceTraitsBlock.Container)
    end
end
