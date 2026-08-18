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
        -- Use the owning module's progressBarTemplate rather than assuming the
        -- quest one: the scenario/delve modules declare
        -- progressBarTemplate = "ScenarioProgressBarTemplate", whose bar has
        -- BarFrame/BarFrame2/BarFrame3 instead of BorderLeft/Mid/Right, so the
        -- generic skin left delve criteria bars with Blizzard's art.
        local module = self.parentModule
        local template = module and module.progressBarTemplate
        local skinFunc = template and Skin[template] or Skin.ObjectiveTrackerProgressBarTemplate
        Util.SkinOnce(self.lastRegion, skinFunc)
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
        -- Fill-flare artwork (gold glow bursts played as the bar fills). Named
        -- individually because they are parentKeys on the bar frame, not a
        -- pooled array; guarded because the set differs per template.
        for _, key in next, {
            "Starburst", "BarGlow",
            "Flare1", "Flare2",
            "SmallFlare1", "SmallFlare2",
            "FullBarFlare1", "FullBarFlare2",
        } do
            local flare = Frame[key] or bar[key]
            if flare then
                flare:SetAlpha(0)
            end
        end
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

        -- GetBlock is the only generic point where a block and its template are
        -- both known, so hook it to skin any block template that has a Skin
        -- function. Without this, templates with no explicit call site were
        -- never skinned at all — AutoQuestPopUpBlockTemplate ("Quest
        -- Discovered!") being the case that surfaced it.
        --
        -- Hooked on the module FRAME, not ObjectiveTrackerModuleMixin: the
        -- concrete mixins are built with CreateFromMixins(ObjectiveTrackerModuleMixin, …)
        -- at file load and copied onto the frames at creation, so a late hook on
        -- the base mixin table would never reach them.
        --
        -- The block is read back out of the module's own usedBlocks table rather
        -- than tracked on the frame, keeping Blizzard's tracker tables free of
        -- addon fields (see docs/RealUI-Tracker-Ownership-Options.md).
        if module.GetBlock then
            _G.hooksecurefunc(module, "GetBlock", function(self, id, optTemplate)
                local template = optTemplate or self.blockTemplate
                local skinFunc = template and Skin[template]
                if not skinFunc then return end

                local blocks = self.usedBlocks and self.usedBlocks[template]
                Util.SkinOnce(blocks and blocks[id], skinFunc)
            end)
        end

        -- Same treatment for progress bars. The block-level AddProgressBar hook
        -- is not enough on its own: bars are acquired by the MODULE via
        -- GetProgressBar using the module's own progressBarTemplate, and the
        -- scenario/delve criteria bars were reaching neither the right skin nor
        -- any skin at all — their BarFrame/BarFrame2/BarFrame3 stayed visible.
        if module.GetProgressBar then
            _G.hooksecurefunc(module, "GetProgressBar", function(self, key)
                local skinFunc = self.progressBarTemplate and Skin[self.progressBarTemplate]
                if not skinFunc then return end

                local bars = self.usedProgressBars
                Util.SkinOnce(bars and bars[key], skinFunc)
            end)
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

    -- The scenario tracker's widget containers are declared inside its own XML
    -- (parentKey only, so no global name), which means Blizzard_UIWidgets never
    -- mixes its container hook into them the way it does for the named global
    -- containers. Their widgets therefore never reached the widget skins, and
    -- delve/scenario blocks kept Blizzard's art and widget fonts. Mixing the
    -- hook in here routes them through the same path; widgets are created on
    -- RegisterForWidgetSet, which happens after this runs.
    for _, blockName in next, { "StageBlock", "TopWidgetContainerBlock", "BottomWidgetContainerBlock" } do
        local block = _G.ScenarioObjectiveTracker[blockName]
        if block and block.WidgetContainer then
            Util.Mixin(block.WidgetContainer, Hook.UIWidgetContainerMixin)
        end
    end

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
