local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals next ipairs select setmetatable

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Color = Aurora.Color
local Config = private.Config

local function IsConfigEnabled(optionKey)
    local auroraConfig = _G.AuroraConfig or Config and Config.defaults
    return auroraConfig == nil or auroraConfig[optionKey] ~= false
end

--[[ Taint rules (binding): .kiro/steering/objective-tracker-taint.md, R1-R7
    The tracker measures and pools everything below, so this skin only
    restyles EXISTING regions in place: colours, textures and atlases with no
    size or anchor change. Art is hidden with SetTexture("") only. Nothing is
    written onto Blizzard's frames or tables; skin state lives in the weak
    tables below. Hooks are hooksecurefunc post-hooks on module and header
    instances (verified secure, spec tracker-widget-taint-rewrite task 1.3).
    Left as Blizzard art on purpose:
      * blocks and lines (fonts come from the global font objects; blocks
        measure their text height)
      * POI buttons, quest item buttons and the find-group button
      * the container's NineSlice background (Edit Mode opacity) and the
        container FilterButton
      * the Scenario and UI widget modules below their headers: stage block,
        widget blocks, criteria bars and timers, Maw buffs and tiered entrance
        traits (R4, owner decision D3)
--]]

local styledBars = setmetatable({}, { __mode = "k" })
local styledBlocks = setmetatable({}, { __mode = "k" })

local function ClearTexture(texture)
    if texture and texture.SetTexture then
        texture:SetTexture("")
    end
end

--[[ Header arrows ]]
-- Draws a small triangle on the button's existing texture with vertex
-- offsets: no new region, no size or anchor change. Vertex order is
-- 1 upper-left, 2 lower-left, 3 upper-right, 4 lower-right.
local function SetArrow(texture, collapsed, color)
    if not texture then return end

    local width, height = texture:GetSize()
    if not width or width <= 0 or not height or height <= 0 then
        width, height = texture:GetParent():GetSize()
    end
    if not width or width <= 0 or not height or height <= 0 then
        return
    end

    texture:SetColorTexture(color:GetRGB())

    local arrowWidth = width * 0.5
    local arrowHeight = arrowWidth * 0.5
    local dx, dy = (width - arrowWidth) / 2, (height - arrowHeight) / 2
    local half = width / 2
    if collapsed then
        -- pointing down: click to expand
        texture:SetVertexOffset(1, dx, -dy)
        texture:SetVertexOffset(3, -dx, -dy)
        texture:SetVertexOffset(2, half, dy)
        texture:SetVertexOffset(4, -half, dy)
    else
        -- pointing up: click to collapse
        texture:SetVertexOffset(1, half, -dy)
        texture:SetVertexOffset(3, -half, -dy)
        texture:SetVertexOffset(2, dx, dy)
        texture:SetVertexOffset(4, -dx, dy)
    end
end

local function StyleMinimizeButton(button, collapsed)
    if not button then return end
    -- Blizzard re-sets both atlases in the header's SetCollapsed, so this
    -- runs again from the post-hook there.
    SetArrow(button:GetNormalTexture(), collapsed, Color.white)
    SetArrow(button:GetPushedTexture(), collapsed, Color.highlight)
end

local function OnHeaderSetCollapsed(header, collapsed)
    StyleMinimizeButton(header.MinimizeButton, collapsed)
end

-- Container header (ObjectiveTrackerContainerHeaderTemplate) and module
-- headers (ObjectiveTrackerModuleHeaderTemplate) share the region names.
local function StyleHeader(header, collapsed)
    if not header then return end

    -- A flat dark band in place of Blizzard's orange-brown header art. The
    -- first build only desaturated and tinted the atlas with Color.highlight,
    -- which under RealUI's orange highlight looked exactly like Blizzard's art
    -- (owner, 2026-10-05). SetColorTexture keeps the region and its atlas size.
    local background = header.Background
    if background then
        local r, g, b = Color.button:GetRGB()
        background:SetColorTexture(r, g, b, 0.6)
    end
    -- Gold flourish played by the module header's AddAnim.
    ClearTexture(header.Shine)
    ClearTexture(header.Glow)

    if header.Text then
        header.Text:SetTextColor(Color.white:GetRGB())
    end

    local button = header.MinimizeButton
    if button then
        local highlight = button:GetHighlightTexture()
        if highlight then
            local r, g, b = Color.highlight:GetRGB()
            highlight:SetColorTexture(r, g, b, 0.25)
        end
        StyleMinimizeButton(button, collapsed)
        if header.SetCollapsed then
            _G.hooksecurefunc(header, "SetCollapsed", OnHeaderSetCollapsed)
        end
    end
end

--[[ Progress and timer bars ]]
local function StyleStatusBar(bar, color)
    if not bar or not bar.SetStatusBarTexture then return end

    local r, g, b = color:GetRGB()
    bar:SetStatusBarTexture(private.textures.plain)
    bar:SetStatusBarColor(r, g, b)

    local texture = bar:GetStatusBarTexture()
    if texture then
        Base.SetTexture(texture, "gradientUp")
        texture:SetVertexColor(r, g, b)
    end
end

local function StyleBarBackground(texture)
    if texture and texture.SetColorTexture then
        local r, g, b = Color.button:GetRGB()
        texture:SetColorTexture(r, g, b, Color.frame.a)
    end
end

-- ObjectiveTrackerProgressBarTemplate and ObjectiveTrackerTimerBarTemplate:
-- BorderLeft/Right/Mid art and an unnamed BACKGROUND colour texture.
local function StyleBorderedBar(frame)
    local bar = frame.Bar
    if not bar then return end

    ClearTexture(bar.BorderLeft)
    ClearTexture(bar.BorderRight)
    ClearTexture(bar.BorderMid)

    local statusTexture = bar:GetStatusBarTexture()
    for i = 1, select("#", bar:GetRegions()) do
        local region = select(i, bar:GetRegions())
        if region ~= statusTexture and region:IsObjectType("Texture")
        and region:GetDrawLayer() == "BACKGROUND" then
            StyleBarBackground(region)
        end
    end

    StyleStatusBar(bar, Color.highlight)
end

local BONUS_BAR_ART = {
    "BarFrame", "BarFrame2", "BarFrame3", "IconBG", "BarGlow", "Sheen", "Starburst",
}
local BONUS_BAR_FLARES = {
    "Flare1", "Flare2", "SmallFlare1", "SmallFlare2", "FullBarFlare1", "FullBarFlare2",
}

-- BonusTrackerProgressBarTemplate (bonus objectives, world quests). The
-- round reward icon stays; its ring and the flare animations are cleared.
local function StyleBonusBar(frame)
    local bar = frame.Bar
    for _, key in ipairs(BONUS_BAR_ART) do
        ClearTexture(bar[key])
    end
    for _, key in ipairs(BONUS_BAR_FLARES) do
        local flare = frame[key]
        if flare and flare.AlphaTextures then
            for _, texture in ipairs(flare.AlphaTextures) do
                ClearTexture(texture)
            end
        end
    end

    StyleBarBackground(bar.BarBG)
    StyleStatusBar(bar, Color.highlight)
end

local function StyleProgressBar(frame)
    local bar = frame and frame.Bar
    if not bar then return end

    if bar.BarFrame then
        if styledBars[frame] then
            -- UpdateReward (run from OnGet) re-atlases BarGlow every time.
            ClearTexture(bar.BarGlow)
            return
        end
        styledBars[frame] = true
        StyleBonusBar(frame)
    elseif bar.BorderLeft then
        if styledBars[frame] then return end
        styledBars[frame] = true
        StyleBorderedBar(frame)
    end
end

local function StyleTimerBar(frame)
    if not frame or styledBars[frame] then return end
    styledBars[frame] = true
    StyleBorderedBar(frame)
end

--[[ "Quest Discovered!" / "Quest Complete!" popup (B50) ]]
local POPUP_BORDERS = {
    "BorderTopLeft", "BorderTopRight", "BorderBotLeft", "BorderBotRight",
    "BorderLeft", "BorderRight", "BorderTop", "BorderBottom",
}
-- The quest badge (QuestIconBg, QuestIconBadgeBorder, Exclamation/QuestionMark
-- and Forever's CircleMask), Shine and IconShine stay Blizzard's.
local function StylePopUp(block)
    if not block or styledBlocks[block] then return end
    local contents = block.Contents or block.ScrollChild
    if not contents then return end
    styledBlocks[block] = true

    for _, key in ipairs(POPUP_BORDERS) do
        ClearTexture(contents[key])
    end
    if contents.Bg then
        contents.Bg:SetColorTexture(Color.frame:GetRGBA())
    end
end

--[[ Hook targets ]]
-- Modules whose bars and popups are styled. Scenario and UI widget modules
-- are deliberately absent (R4): headers only.
local CONTENT_MODULES = {
    "QuestObjectiveTracker",
    "CampaignQuestObjectiveTracker",
    "AchievementObjectiveTracker",
    "BonusObjectiveTracker",
    "WorldQuestObjectiveTracker",
    "AdventureObjectiveTracker",
    "ProfessionsRecipeTracker",
    "InitiativeTasksObjectiveTracker",
    "MonthlyActivitiesObjectiveTracker",
}
local HEADER_ONLY_MODULES = {
    "UIWidgetObjectiveTracker",
    "ScenarioObjectiveTracker",
}
-- AutoQuestPopupTrackerMixin is mixed into the quest modules only.
local POPUP_MODULES = {
    QuestObjectiveTracker = true,
    CampaignQuestObjectiveTracker = true,
}
local POPUP_TEMPLATE = "AutoQuestPopUpBlockTemplate"

-- Post-hooks see no return values, so the new frame is read back out of the
-- module's own tables (a read, never a write).
local function OnGetProgressBar(module, key)
    local bars = module.usedProgressBars
    StyleProgressBar(bars and bars[key])
end
local function OnGetTimerBar(module, key)
    local bars = module.usedTimerBars
    StyleTimerBar(bars and bars[key])
end
local function OnGetBlock(module, id, optTemplate)
    if optTemplate ~= POPUP_TEMPLATE then return end
    local blocks = module.usedBlocks and module.usedBlocks[POPUP_TEMPLATE]
    StylePopUp(blocks and blocks[id])
end

local installed = false
function private.AddOns.Blizzard_ObjectiveTracker()
    -- The user toggle is the only switch: off means no hook at all.
    if not IsConfigEnabled("objectiveTracker") then return end
    if installed then return end
    installed = true

    local container = _G.ObjectiveTrackerFrame
    if container and container.Header then
        StyleHeader(container.Header, container.IsCollapsed and container:IsCollapsed())
    end

    for _, moduleName in ipairs(CONTENT_MODULES) do
        local module = _G[moduleName]
        if module then
            StyleHeader(module.Header, module.IsCollapsed and module:IsCollapsed())

            if module.GetProgressBar then
                _G.hooksecurefunc(module, "GetProgressBar", OnGetProgressBar)
            end
            if module.GetTimerBar then
                _G.hooksecurefunc(module, "GetTimerBar", OnGetTimerBar)
            end
            if POPUP_MODULES[moduleName] and module.GetBlock then
                _G.hooksecurefunc(module, "GetBlock", OnGetBlock)
            end
        end
    end

    for _, moduleName in ipairs(HEADER_ONLY_MODULES) do
        local module = _G[moduleName]
        if module then
            StyleHeader(module.Header, module.IsCollapsed and module:IsCollapsed())
        end
    end

    -- Mythic+ timer (Requirement 2.5): a fixed, unpooled block in the Scenario
    -- module. Only its own status bar is touched, in place; the block art,
    -- affixes and death counter stay Blizzard's.
    local scenario = _G.ScenarioObjectiveTracker
    local challengeMode = scenario and scenario.ChallengeModeBlock
    if challengeMode then
        ClearTexture(challengeMode.TimerBG)
        StyleBarBackground(challengeMode.TimerBGBack)
        StyleStatusBar(challengeMode.StatusBar, Color.cyan)
    end
end

