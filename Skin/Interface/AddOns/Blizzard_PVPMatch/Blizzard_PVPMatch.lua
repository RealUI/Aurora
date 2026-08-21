local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Color = Aurora.Color
local Hook = Aurora.Hook
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

--do --[[ AddOns\Blizzard_PVPMatch.lua ]]
do
    Hook.PVPMatchResultsMixin = {}
    function Hook.PVPMatchResultsMixin:OnLoad()
        Util.WrapPoolAcquire(self.itemPool, Skin.PVPMatchResultsLoot)
    end
end

do --[[ AddOns\Blizzard_PVPMatch.xml ]]
    do --[[ PVPMatchTable.xml ]]
        function Skin.PVPTableRowTemplate(Frame)
            Frame.backgroundLeft:ClearAllPoints()
            Frame.backgroundLeft:SetPoint("TOPLEFT")
            Frame.backgroundLeft:SetTexture(private.textures.plain)
            Frame.backgroundLeft:SetHeight(15)
            Frame.backgroundLeft:SetAlpha(0.5)

            Frame.backgroundRight:ClearAllPoints()
            Frame.backgroundRight:SetPoint("TOPRIGHT")
            Frame.backgroundRight:SetTexture(private.textures.plain)
            Frame.backgroundRight:SetHeight(15)
            Frame.backgroundRight:SetAlpha(0.5)

            Frame.backgroundCenter:SetTexture(private.textures.plain)
            Frame.backgroundCenter:SetHeight(15)
            Frame.backgroundCenter:SetAlpha(0.5)
        end
        function Skin.PVPMatchResultsLoot(Button)
            if private.IsSkinned(Button) then
                return
            end

            private.SetSkinned(Button, true)

            -- NOT Skin.LargeItemButtonTemplate: that one is built for WIDE
            -- item rows (icon + a 108px name strip) and insets the backdrop
            -- `right = 108`. PVPMatchResults lays its loot out as small
            -- SQUARES, so the inset collapsed the backdrop to nothing — and
            -- since the icon anchors to that backdrop, the reward icons
            -- rendered as empty black boxes with only the quality border
            -- showing ("You earned" row, found 2026-08-22 after a BG win).
            -- Square-button variant: same backdrop + quality-border wiring
            -- (_auroraIconBorder), icon cropped to the button itself.
            Base.SetBackdrop(Button, Color.black, Color.frame.a)
            Button._auroraIconBorder = Button

            local bg = Button:GetBackdropTexture("bg")
            if Button.Icon then
                Base.CropIcon(Button.Icon)
                Button.Icon:ClearAllPoints()
                Button.Icon:SetPoint("TOPLEFT", bg, 1, -1)
                Button.Icon:SetPoint("BOTTOMRIGHT", bg, -1, 1)
            end

            if Button.NameFrame then
                Button.NameFrame:SetAlpha(0)
                Button.NameFrame:SetTexture("")
            end
            if Button.IconBorder then
                Button.IconBorder:SetAlpha(0)
            end
        end
    end
end

function private.AddOns.Blizzard_PVPMatch()
    ----====#####################====----
    --         PVPMatchResults         --
    ----====#####################====----
    local PVPMatchResults = _G.PVPMatchResults
    _G.hooksecurefunc(_G.PVPMatchResultsMixin, "OnLoad", Hook.PVPMatchResultsMixin.OnLoad)
    Skin.UIPanelCloseButton(PVPMatchResults.CloseButton)
    PVPMatchResults.CloseButton.Border:Hide()
    Util.WrapPoolAcquire(PVPMatchResults.itemPool, Skin.PVPMatchResultsLoot)

    -- Skin the outer frame so the NineSlice hook handles SetupArtwork's
    -- NineSliceUtil.ApplyLayoutByName (BFAMissionHorde/Alliance/GenericMetal)
    -- Hide the groupfinder-background BEFORE creating backdrop textures,
    -- otherwise GetRegions() may return an Aurora texture instead.
    for _, region in next, {PVPMatchResults:GetRegions()} do
        if region.GetAtlas and region:GetAtlas() == "groupfinder-background" then
            region:Hide()
            break
        end
    end
    Skin.FrameTypeFrame(PVPMatchResults)
    PVPMatchResults._auroraNineSlice = true

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

    -- Skin the outer frame so the NineSlice hook handles SetupArtwork's
    -- NineSliceUtil.ApplyLayoutByName (BFAMissionHorde/Alliance/GenericMetal)
    -- Hide the groupfinder-background BEFORE creating backdrop textures.
    for _, region in next, {PVPMatchScoreboard:GetRegions()} do
        if region.GetAtlas and region:GetAtlas() == "groupfinder-background" then
            region:Hide()
            break
        end
    end
    Skin.FrameTypeFrame(PVPMatchScoreboard)
    PVPMatchScoreboard._auroraNineSlice = true

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
