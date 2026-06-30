local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals select

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

function private.AddOns.Blizzard_WorldMap()
    local WorldMapFrame = _G.WorldMapFrame
    if not WorldMapFrame then return end

    -- Apply Aurora backdrop to the world map frame
    Base.SetBackdrop(WorldMapFrame, Color.frame, Util.GetFrameAlpha())

    -- Hide map border textures
    -- TBC Classic Anniversary windowed map uses named border textures
    local borderTextures = {
        "WorldMapFrameTopBorder",
        "WorldMapFrameBottomBorder",
        "WorldMapFrameLeftBorder",
        "WorldMapFrameRightBorder",
        "WorldMapFrameTopLeftCorner",
        "WorldMapFrameTopRightCorner",
        "WorldMapFrameBottomLeftCorner",
        "WorldMapFrameBottomRightCorner",
        "WorldMapFrameBorderTop",
        "WorldMapFrameBorderBottom",
        "WorldMapFrameBorderLeft",
        "WorldMapFrameBorderRight",
    }
    for _, name in _G.ipairs(borderTextures) do
        local texture = _G[name]
        if texture then
            texture:Hide()
        end
    end

    -- Strip Blizzard decoration textures from the frame regions
    for i = 1, WorldMapFrame:GetNumRegions() do
        local region = select(i, WorldMapFrame:GetRegions())
        if region and region.GetObjectType and region:GetObjectType() == "Texture" then
            local drawLayer = region:GetDrawLayer()
            if drawLayer == "BORDER" or drawLayer == "ARTWORK" then
                local texture = region:GetTexture()
                if texture and type(texture) == "string" then
                    if texture:find("UI%-WorldMap") or texture:find("WorldMap") then
                        region:Hide()
                    end
                end
            end
        end
    end

    -- Skin close button
    local closeButton = _G.WorldMapFrameCloseButton or WorldMapFrame.CloseButton
    if closeButton then
        Skin.UIPanelCloseButton(closeButton)
    end

    -- Skin size-up / size-down buttons (toggle between windowed and maximized)
    local sizeUpButton = _G.WorldMapFrameSizeUpButton
    if sizeUpButton then
        Skin.FrameTypeButton(sizeUpButton)
    end

    local sizeDownButton = _G.WorldMapFrameSizeDownButton
    if sizeDownButton then
        Skin.FrameTypeButton(sizeDownButton)
    end

    -- Skin zone navigation buttons (continent/zone dropdowns or buttons)
    local continentDropDown = _G.WorldMapContinentDropDown
    if continentDropDown and Skin.UIDropDownMenuTemplate then
        Skin.UIDropDownMenuTemplate(continentDropDown)
    end

    local zoneDropDown = _G.WorldMapZoneDropDown
    if zoneDropDown and Skin.UIDropDownMenuTemplate then
        Skin.UIDropDownMenuTemplate(zoneDropDown)
    end

    -- Skin zone navigation arrows/buttons
    local zoneMinimapButton = _G.WorldMapZoneMinimapDropDown
    if zoneMinimapButton and Skin.UIDropDownMenuTemplate then
        Skin.UIDropDownMenuTemplate(zoneMinimapButton)
    end

    -- Skin overlay panels
    -- Quest objectives overlay (shows quest tracking on map)
    local questShowObjectives = _G.WorldMapQuestShowObjectives
    if questShowObjectives then
        Skin.FrameTypeCheckButton(questShowObjectives)
    end

    -- World map tooltip frame
    local tooltipFrame = _G.WorldMapTooltip
    if tooltipFrame then
        Base.SetBackdrop(tooltipFrame, Color.frame)
    end

    -- Skin the map detail panel / overlay frame
    local detailFrame = _G.WorldMapDetailFrame
    if detailFrame then
        -- The detail frame is the map tile container; leave it alone visually
        -- but strip any border art it may have
        if detailFrame.GetNumRegions then
            for i = 1, detailFrame:GetNumRegions() do
                local region = select(i, detailFrame:GetRegions())
                if region and region.GetObjectType and region:GetObjectType() == "Texture" then
                    local drawLayer = region:GetDrawLayer()
                    if drawLayer == "BORDER" then
                        region:Hide()
                    end
                end
            end
        end
    end

    -- Skin dungeon button overlay
    local dungeonButton = _G.WorldMapLevelDropDown
    if dungeonButton and Skin.UIDropDownMenuTemplate then
        Skin.UIDropDownMenuTemplate(dungeonButton)
    end

    -- Skin the map navigation bar (breadcrumb bar if present)
    local navBar = WorldMapFrame.NavBar or _G.WorldMapFrameNavBar
    if navBar then
        -- Strip navigation bar textures
        if navBar.GetNumRegions then
            for i = 1, navBar:GetNumRegions() do
                local region = select(i, navBar:GetRegions())
                if region and region.GetObjectType and region:GetObjectType() == "Texture" then
                    region:Hide()
                end
            end
        end
        -- Skin home button in nav bar
        local homeButton = navBar.home or navBar.HomeButton
        if homeButton then
            Skin.FrameTypeButton(homeButton)
        end
    end

    -- Skin map overlay toggle buttons (if present in this TBC build)
    local showDigSites = _G.WorldMapShowDigSites
    if showDigSites then
        Skin.FrameTypeCheckButton(showDigSites)
    end

    local trackQuest = _G.WorldMapTrackQuest
    if trackQuest then
        Skin.FrameTypeCheckButton(trackQuest)
    end
end
