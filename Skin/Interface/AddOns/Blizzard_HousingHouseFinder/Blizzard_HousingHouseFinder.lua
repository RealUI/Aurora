local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base, Hook, Skin = Aurora.Base, Aurora.Hook, Aurora.Skin
local Color = Aurora.Color

do --[[ AddOns\Blizzard_HousingHouseFinder\Blizzard_HousingHouseFinder.lua ]]
    -- Neighborhood buttons (taint audit 2026-10-06, B170 follow-up):
    -- restyled in place after Blizzard has populated the list, never from the
    -- pools' Acquire (the old post-hook added a backdrop to buttons Blizzard
    -- went on to Init, select and lay out).
    function Hook.HouseFinderFrame_PopulateNeighborhoodList(self)
        for button in self.neighborhoodButtonPool:EnumerateActive() do
            Skin.HouseFinderNeighborhoodButtonTemplate(button)
        end
    end
    function Hook.HouseFinderFrame_PopulateBNetNeighborhoodList(self)
        for button in self.bnetNeighborhoodButtonPool:EnumerateActive() do
            Skin.HouseFinderNeighborhoodButtonTemplate(button)
        end
    end
end

do --[[ AddOns\Blizzard_HousingHouseFinder\Blizzard_HousingHouseFinder.xml ]]
    -- In place only: Select/Deselect re-atlas ButtonBackground (default,
    -- recommended, selected), so it is tinted rather than replaced; the tint
    -- survives SetAtlas and the selected tile stays distinguishable.
    function Skin.HouseFinderNeighborhoodButtonTemplate(Button)
        if private.IsSkinned(Button) then return end
        private.SetSkinned(Button, true)

        if Button.ButtonBackground then
            Button.ButtonBackground:SetDesaturated(true)
            Button.ButtonBackground:SetVertexColor(Color.button:GetRGB())
        end
    end
end

function private.AddOns.Blizzard_HousingHouseFinder()
    ----
    -- Main Frame (PortraitFrameTemplate)
    ----
    local HouseFinderFrame = _G.HouseFinderFrame

    Skin.PortraitFrameTemplate(HouseFinderFrame)

    ----
    -- NeighborhoodListFrame
    ----
    local NeighborhoodListFrame = HouseFinderFrame.NeighborhoodListFrame

    -- Hide decorative background textures
    if NeighborhoodListFrame.NeighborhoodListBG then
        NeighborhoodListFrame.NeighborhoodListBG:SetAlpha(0)
    end
    if NeighborhoodListFrame.NeighborhoodTitleBG then
        NeighborhoodListFrame.NeighborhoodTitleBG:SetAlpha(0)
    end

    -- BNetFriendSearchBox — skin as SearchBox and hide Common-Input-Border textures
    local SearchBox = NeighborhoodListFrame.BNetFriendSearchBox
    if SearchBox then
        Skin.SearchBoxTemplate(SearchBox)
        if SearchBox.LeftBorder then SearchBox.LeftBorder:SetAlpha(0) end
        if SearchBox.RightBorder then SearchBox.RightBorder:SetAlpha(0) end
        if SearchBox.MiddleBorder then SearchBox.MiddleBorder:SetAlpha(0) end
    end

    -- RefreshButton
    if NeighborhoodListFrame.RefreshButton then
        Skin.FrameTypeButton(NeighborhoodListFrame.RefreshButton)
    end

    ----
    -- Neighborhood Button Pools
    ----
    _G.hooksecurefunc(HouseFinderFrame, "PopulateNeighborhoodList", Hook.HouseFinderFrame_PopulateNeighborhoodList)
    _G.hooksecurefunc(HouseFinderFrame, "PopulateBNetNeighborhoodList", Hook.HouseFinderFrame_PopulateBNetNeighborhoodList)

    ----
    -- GuildSubdivisionDropdown (WowStyle1ArrowDropdownTemplate)
    ----
    if HouseFinderFrame.GuildSubdivisionDropdown then
        Skin.WowStyle1ArrowDropdownTemplate(HouseFinderFrame.GuildSubdivisionDropdown)
    end

    ----
    -- PlotInfoFrame
    ----
    local PlotInfoFrame = HouseFinderFrame.PlotInfoFrame

    Base.SetBackdrop(PlotInfoFrame, Color.frame)

    -- Hide decorative background textures
    if PlotInfoFrame.Background then PlotInfoFrame.Background:SetAlpha(0) end
    if PlotInfoFrame.PlotTitleBG then PlotInfoFrame.PlotTitleBG:SetAlpha(0) end
    if PlotInfoFrame.VisitButtonBG then PlotInfoFrame.VisitButtonBG:SetAlpha(0) end
    if PlotInfoFrame.VisitDescriptionBG then PlotInfoFrame.VisitDescriptionBG:SetAlpha(0) end

    -- Hide filigree textures
    if PlotInfoFrame.TopRightFiligree then PlotInfoFrame.TopRightFiligree:SetAlpha(0) end
    if PlotInfoFrame.BottomLeftFiligree then PlotInfoFrame.BottomLeftFiligree:SetAlpha(0) end
    if PlotInfoFrame.BottomRightFiligree then PlotInfoFrame.BottomRightFiligree:SetAlpha(0) end

    -- VisitHouseButton (UIPanelButtonHeightScaledTemplate)
    Skin.UIPanelButtonTemplate(PlotInfoFrame.VisitHouseButton)

    -- BackButton (custom button with icon/label)
    if PlotInfoFrame.BackButton then
        Skin.FrameTypeButton(PlotInfoFrame.BackButton)
    end

    ----
    -- HouseFinderMapCanvasFrame — leave map canvas unskinned, just hide wood border
    ----
    local WoodBorderFrame = HouseFinderFrame.WoodBorderFrame
    if WoodBorderFrame and WoodBorderFrame.Border then
        WoodBorderFrame.Border:SetAlpha(0)
    end
end
