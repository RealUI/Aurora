local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Color = Aurora.Color
local Skin = Aurora.Skin
local Util = Aurora.Util

-- Taint-safe scroll box backdrop.
--
-- Skin.WowScrollBoxList → ScrollBoxBaseTemplate → Base.SetBackdrop writes
-- textures onto the ScrollBox table, marking it addon-modified. Both PVPMatch
-- scroll boxes drive TableBuilder cell construction, and PVPMatchTable's
-- Populate feeds a SECRET honorLevel into C_PvP.GetHonorRewardInfo — which
-- refuses secret arguments unless execution is untainted. Result: x10
-- "Secret values are only allowed during untainted execution" on entering a
-- battleground scoreboard (found 2026-08-22, epic BG).
--
-- Same cure as HonorFrame.SpecificScrollBox in Blizzard_PVPUI: put the
-- backdrop on a sibling frame positioned behind the scroll box, leaving the
-- scroll box itself untouched.
local function BackdropBehind(ScrollBox)
    local bg = _G.CreateFrame("Frame", nil, ScrollBox:GetParent())
    bg:SetAllPoints(ScrollBox)
    bg:SetFrameLevel(_G.math.max(ScrollBox:GetFrameLevel() - 1, 0))
    Base.SetBackdrop(bg, Color.frame)
    return bg
end

-- Retail panels (B160, 2026-11-21). Both frames used to get
-- Skin.FrameTypeFrame plus a planted _auroraNineSlice flag. FrameTypeFrame is
-- Base.SetBackdrop on the Blizzard frame itself: BackdropMixin methods, the
-- backdrop info and palette keys, a SetBackdropBorderColor hook, and nine
-- textures stored under NineSliceUtil's own piece keys (TopLeftCorner ...
-- Center), all written from addon code. SetupArtwork, run from Init on
-- joining the match, applies the faction NineSlice layout to the same frame
-- and reads those piece keys back, so the rest of Init ran tainted, including
-- ConstructPVPMatchTable, which builds the columns that Populate later runs
-- to call C_PvP.GetHonorRewardInfo with a secret honorLevel: the likely route
-- of B160 (no taint log was captured). The flag only told
-- Hook.NineSliceUtil.ApplyLayout (SharedXML\NineSlice.lua) to re-run
-- FrameTypeFrame after every SetupArtwork, repainting Blizzard's art with
-- Aurora's. Now nothing is written onto either frame: the panel is a sibling
-- frame, Blizzard creates and owns its NineSlice pieces, and a post-hook
-- keyed by this table fades them (SetAlpha(0), the doctrine's NineSlice
-- exception: ApplyLayout re-sets their atlases, so SetTexture("") would not
-- hold; they are not pooled, and nothing reads them back until the next
-- ApplyLayout, which only sets).
local retailPanels = setmetatable({}, {__mode = "k"})
local nineSlicePieces = {
    "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner",
    "TopEdge", "BottomEdge", "LeftEdge", "RightEdge", "Center",
}
local function HidePanelArt(Frame)
    for i = 1, #nineSlicePieces do
        local piece = Frame[nineSlicePieces[i]]
        if piece then
            piece:SetAlpha(0)
        end
    end
end
local function SkinRetailPanel(Frame)
    for _, region in next, {Frame:GetRegions()} do
        if region.GetAtlas and region:GetAtlas() == "groupfinder-background" then
            region:Hide()
            break
        end
    end

    -- The pieces are created by the first SetupArtwork, after this skin
    -- runs, so the hook does the work; this call covers a frame that was
    -- already initialized.
    retailPanels[Frame] = true
    HidePanelArt(Frame)

    local bg = _G.CreateFrame("Frame", nil, Frame)
    bg:SetAllPoints()
    bg:SetFrameLevel(Frame:GetFrameLevel())
    Base.SetBackdrop(bg, Color.frame, Util.GetFrameAlpha())
end

do --[[ AddOns\Blizzard_PVPMatch.xml ]]
    do --[[ PVPMatchTable.xml ]]
        -- Skin.PVPTableRowTemplate was removed (B160): it was never wired
        -- to the row factory, and it re-anchored and resized textures on
        -- the pooled table rows that Populate fills (doctrine rule 3).
        function Skin.PVPMatchResultsLoot(Button)
            if private.IsSkinned(Button) then
                return
            end

            private.SetSkinned(Button, true)

            -- In place (taint audit 2026-10-06, B170 follow-up): the loot
            -- buttons come from itemPool, acquired inside the results screen's
            -- setup, which keeps using them. The old skin put a backdrop and
            -- _auroraIconBorder on the button and re-anchored the icon to the
            -- backdrop. Now the icon is only cropped square (masks removed,
            -- SetTexCoord) and Blizzard's quality border stays.
            if Button.Icon then
                Base.CropIcon(Button.Icon)
            end

            if Button.NameFrame then
                Button.NameFrame:SetTexture("")
            end
        end
    end
end

-- Forever 70755 gives both frames Camelot layouts: a NineSlice child instead of
-- the art SetupArtwork swaps on retail, no inset border pieces, no loot pool and
-- no requeue button. Only the scroll and tab keys carry over, so Forever takes
-- its own path. Its background art has no parentKey, so it is found by atlas.
local camelotArt = {
    ["UI-Character-Info-Stat-BG"] = true,
    ["UI-Character-Info-Stat-StoneBG3"] = true,
    ["UI-Character-Info-ScrollLine"] = true,
}
local function HideCamelotArt(Frame)
    for _, region in next, {Frame:GetRegions()} do
        if region.GetAtlas and camelotArt[region:GetAtlas()] then
            region:Hide()
        end
    end
end
local function SkinCamelotPanel(Frame, CloseButton, Content, ScrollCategories, ScrollBox, ScrollBar, TabGroup, tabs)
    -- The panel backdrop follows the scroll box rule above: nothing is written
    -- onto Frame. It sits at Frame's own level, not behind the NineSlice, whose
    -- template sets frameLevel 500 and would put it over the whole table.
    Frame.NineSlice:SetAlpha(0)
    local bg = _G.CreateFrame("Frame", nil, Frame)
    bg:SetAllPoints()
    bg:SetFrameLevel(Frame:GetFrameLevel())
    Base.SetBackdrop(bg, Color.frame, Util.GetFrameAlpha())

    Skin.UIPanelCloseButtonDefaultAnchors(CloseButton)

    HideCamelotArt(Content)
    HideCamelotArt(ScrollCategories)
    BackdropBehind(ScrollBox)
    Skin.MinimalScrollBar(ScrollBar)

    for _, tab in ipairs(tabs) do
        Skin.PanelTabButtonTemplate(tab)
    end
    Util.PositionRelative("TOPLEFT", TabGroup, "BOTTOMLEFT", 20, 49, 1, "Right", tabs)
end

function private.AddOns.Blizzard_PVPMatch()
    if private.isForever then
        local results = _G.PVPMatchResults
        local resultsContent = results.content
        local resultsTabs = resultsContent.tabContainer.tabGroup
        SkinCamelotPanel(results, results.CloseButton, resultsContent, resultsContent.scrollCategories,
            resultsContent.scrollBox, resultsContent.scrollBar, resultsTabs,
            {resultsTabs.tab1, resultsTabs.tab2, resultsTabs.tab3})
        Skin.SharedButtonTemplate(results.buttonContainer.leaveButton)

        local scoreboard = _G.PVPMatchScoreboard
        local scoreContent = scoreboard.Content
        local scoreTabs = scoreContent.TabContainer.TabGroup
        SkinCamelotPanel(scoreboard, scoreboard.ClosePanelButton, scoreContent, scoreContent.ScrollCategories,
            scoreContent.ScrollBox, scoreContent.ScrollBar, scoreTabs,
            {scoreTabs.Tab1, scoreTabs.Tab2, scoreTabs.Tab3})
        return
    end

    ----====#####################====----
    --         PVPMatchResults         --
    ----====#####################====----
    -- SetupArtwork applies BFAMissionHorde/Alliance or GenericMetal to the
    -- frame itself; fade those pieces after Blizzard has set them (B160).
    _G.hooksecurefunc(_G.NineSliceUtil, "ApplyLayout", function(container)
        if retailPanels[container] then
            HidePanelArt(container)
        end
    end)

    local PVPMatchResults = _G.PVPMatchResults
    Skin.UIPanelCloseButton(PVPMatchResults.CloseButton)
    PVPMatchResults.CloseButton.Border:Hide()
    Util.WrapPoolAcquire(PVPMatchResults.itemPool, Skin.PVPMatchResultsLoot)

    SkinRetailPanel(PVPMatchResults)

    local resultsContent = PVPMatchResults.content
    resultsContent.background:Hide()
    resultsContent.InsetBorderTopLeft:Hide()
    resultsContent.InsetBorderTopRight:Hide()
    resultsContent.InsetBorderBottomLeft:Hide()
    resultsContent.InsetBorderBottomRight:Hide()
    resultsContent.InsetBorderTop:Hide()
    resultsContent.InsetBorderBottom:Hide()
    resultsContent.InsetBorderLeft:Hide()
    resultsContent.InsetBorderRight:Hide()

    BackdropBehind(resultsContent.scrollBox)
    Skin.MinimalScrollBar(resultsContent.scrollBar)

    local tabContainer = resultsContent.tabContainer
    tabContainer.InsetBorderTop:Hide()
    tabContainer.InsetBorderBottom:Hide()
    Skin.PanelTabButtonTemplate(tabContainer.tabGroup.tab1)
    Skin.PanelTabButtonTemplate(tabContainer.tabGroup.tab2)
    Skin.PanelTabButtonTemplate(tabContainer.tabGroup.tab3)
    Util.PositionRelative("TOPLEFT", tabContainer.tabGroup, "BOTTOMLEFT", 20, 49, 1, "Right", {
        tabContainer.tabGroup.tab1,
        tabContainer.tabGroup.tab2,
        tabContainer.tabGroup.tab3,
    })

    Skin.UIPanelButtonTemplate(PVPMatchResults.buttonContainer.requeueButton)
    Skin.UIPanelButtonTemplate(PVPMatchResults.buttonContainer.leaveButton)


    ----====####################====----
    --       PVPMatchScoreboard       --
    ----====####################====----
    local PVPMatchScoreboard = _G.PVPMatchScoreboard
    Skin.UIPanelCloseButton(PVPMatchScoreboard.CloseButton)

    SkinRetailPanel(PVPMatchScoreboard)

    local scoreContent = PVPMatchScoreboard.Content
    scoreContent.Background:Hide()
    scoreContent.InsetBorderTopLeft:Hide()
    scoreContent.InsetBorderTopRight:Hide()
    scoreContent.InsetBorderBottomLeft:Hide()
    scoreContent.InsetBorderBottomRight:Hide()
    scoreContent.InsetBorderTop:Hide()
    scoreContent.InsetBorderBottom:Hide()
    scoreContent.InsetBorderLeft:Hide()
    scoreContent.InsetBorderRight:Hide()

    BackdropBehind(scoreContent.ScrollBox)
    Skin.MinimalScrollBar(scoreContent.ScrollBar)

    local scoreTabContainer = scoreContent.TabContainer
    scoreTabContainer.InsetBorderTop:Hide()
    Skin.PanelTabButtonTemplate(scoreTabContainer.TabGroup.Tab1)
    Skin.PanelTabButtonTemplate(scoreTabContainer.TabGroup.Tab2)
    Skin.PanelTabButtonTemplate(scoreTabContainer.TabGroup.Tab3)
    Util.PositionRelative("TOPLEFT", scoreTabContainer.TabGroup, "BOTTOMLEFT", 20, 49, 1, "Right", {
        scoreTabContainer.TabGroup.Tab1,
        scoreTabContainer.TabGroup.Tab2,
        scoreTabContainer.TabGroup.Tab3,
    })
end
