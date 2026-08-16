local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals select next ipairs pairs string

--[[ Core ]]
local Aurora = private.Aurora
local Base, Hook, Skin = Aurora.Base, Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util


-- Helper to hide all decorative textures on a frame by matching atlas names
local decorativeAtlases = {
    ["housing-dashboard-filigree"] = true,
    ["house-upgrade-radial-leaf"] = true,
    ["house-upgrade-radial-windowframe"] = true,
    ["house-upgrade-bg-radial-glow"] = true,
    ["house-upgrade-shadow-corbel"] = true,
    ["housing-dashboard-woodsign"] = true,
    ["housing-dashboard-foliage"] = true,
    ["housing-foliage"] = true,
    ["catalog-corbel"] = true,
    ["house-chest-nav-top-corbels"] = true,
}

local function IsDecorativeAtlas(atlasName)
    if not atlasName then return false end
    for prefix in next, decorativeAtlases do
        if string.find(atlasName, prefix, 1, true) then
            return true
        end
    end
    return false
end

local function HideDecorativeRegions(frame)
    if not frame then return end
    for _, region in pairs({frame:GetRegions()}) do
        if region:IsObjectType("Texture") then
            local atlas = region:GetAtlas()
            if IsDecorativeAtlas(atlas) then
                region:SetAlpha(0)
            end
        end
    end
end

do --[[ AddOns\Blizzard_HousingDashboard\Blizzard_HousingDashboard.lua ]]
    Hook.HousingDashboardFrameMixin = {}
    function Hook.HousingDashboardFrameMixin:SetTab(activeTab)
        for _, tab in ipairs(self.tabs) do
            local isActive = tab == self.activeTab
            if tab.tabButton._auroraIconBG then
                if isActive then
                    tab.tabButton._auroraIconBG:SetColorTexture(Color.yellow:GetRGB())
                else
                    tab.tabButton._auroraIconBG:SetColorTexture(Color.black:GetRGB())
                end
            end
        end
    end

    Hook.HousingUpgradeFrameMixin = {}
    function Hook.HousingUpgradeFrameMixin:OnHouseSelected(houseInfoID)
        if self.Background then self.Background:SetAlpha(0) end
        -- Hide anonymous filigree corners and other decorative regions
        HideDecorativeRegions(self)
    end

    Hook.InitiativesTabMixin = {}
    function Hook.InitiativesTabMixin:RefreshInitiativeTab()
        -- Hide initiative art backgrounds and corners
        if self.InitiativesArt then
            HideDecorativeRegions(self.InitiativesArt)
            if self.InitiativesArt.BorderArt then
                HideDecorativeRegions(self.InitiativesArt.BorderArt)
            end
        end
    end
end

do --[[ AddOns\Blizzard_HousingDashboard\Blizzard_HousingDashboard.xml ]]
    function Skin.HouseUpgradeRewardFrameTemplate(Frame)
        if private.IsSkinned(Frame) then
            return
        end

        private.SetSkinned(Frame, true)

        if Frame.Background then
            Frame.Background:SetAlpha(0)
        end
        Base.SetBackdrop(Frame, Color.frame)

        local PortraitFrame = Frame.PortraitFrame
        if PortraitFrame then
            if PortraitFrame.Background then
                PortraitFrame.Background:SetAlpha(0)
            end
            Base.SetBackdrop(PortraitFrame, Color.button)

            if PortraitFrame.Portrait then
                Base.CropIcon(PortraitFrame.Portrait, PortraitFrame)
            end
        end

        if Frame.ValueIncreaseReward and Frame.ValueIncreaseReward.Divider then
            Frame.ValueIncreaseReward.Divider:SetAlpha(0)
        end
    end

    function Skin.HousingDashboardSideTabTemplate(TabButton)
        -- 12.1: HousingDashboardSideTabTemplate was deleted; tabs are the
        -- shared LargeSideTabButtonTemplate (SidePanelTabButtonMixin —
        -- Background/Icon/SelectedTexture/TabGlow/HighlightTexture keys).
        if TabButton.Highlight then TabButton.Highlight:SetAlpha(0) end -- pre-12.1
        if TabButton.Background then TabButton.Background:SetAlpha(0) end
        if TabButton.SelectedTexture then
            -- flatten but keep Blizzard's selection show/hide meaningful
            TabButton.SelectedTexture:SetDesaturated(true)
            TabButton.SelectedTexture:SetVertexColor(Color.highlight:GetRGB())
        end

        -- Crop the icon and create the colored border
        local icon = TabButton.Icon
        if icon then
            TabButton._auroraIconBG = Base.CropIcon(icon, TabButton)
        end
    end
end

function private.AddOns.Blizzard_HousingDashboard()
    ----
    -- Main Frame
    ----
    local HousingDashboardFrame = _G.HousingDashboardFrame

    Skin.PortraitFrameTemplate(HousingDashboardFrame)

    -- Dark flat background
    if HousingDashboardFrame.Bg then
        HousingDashboardFrame.Bg:SetColorTexture(Color.panelBg:GetRGBA())
        HousingDashboardFrame.Bg:SetAllPoints(HousingDashboardFrame.NineSlice)
        HousingDashboardFrame.Bg:Show()
    end

    -- Hook the main mixin
    Util.Mixin(HousingDashboardFrame, Hook.HousingDashboardFrameMixin)

    ----
    -- Side Tab Buttons (right side; 12.1 adds a third CollectionTabButton
    -- and gathers them in the TabButtons parentArray)
    ----
    if HousingDashboardFrame.TabButtons then
        for _, tabButton in ipairs(HousingDashboardFrame.TabButtons) do
            Skin.HousingDashboardSideTabTemplate(tabButton)
        end
    else
        Skin.HousingDashboardSideTabTemplate(HousingDashboardFrame.HouseInfoTabButton)
        Skin.HousingDashboardSideTabTemplate(HousingDashboardFrame.CatalogTabButton)
    end

    ----
    -- HouseInfo Content
    ----
    local HouseInfoContent = HousingDashboardFrame.HouseInfoContent

    -- Dropdown (12.1: moved from HouseInfoContent.HouseDropdown to
    -- HousingDashboardFrame.HouseDropdown.Dropdown, WowStyle1DropdownTemplate)
    if HousingDashboardFrame.HouseDropdown and HousingDashboardFrame.HouseDropdown.Dropdown then
        Skin.DropdownButton(HousingDashboardFrame.HouseDropdown.Dropdown)
    elseif HouseInfoContent.HouseDropdown then
        Skin.WowStyle1ArrowDropdownTemplate(HouseInfoContent.HouseDropdown)
    end

    -- House Finder Button
    if HouseInfoContent.HouseFinderButton then
        Skin.UIPanelButtonTemplate(HouseInfoContent.HouseFinderButton)
    end

    -- No Houses Dashboard
    local NoHousesFrame = HouseInfoContent.DashboardNoHousesFrame
    if NoHousesFrame then
        if NoHousesFrame.Background then NoHousesFrame.Background:SetAlpha(0) end
        if NoHousesFrame.NoHouseButton then
            Skin.UIPanelButtonTemplate(NoHousesFrame.NoHouseButton)
        end
    end

    ----
    -- Inner Content Frame (House Level / Endeavors tabs)
    ----
    local ContentFrame = HouseInfoContent.ContentFrame
    if ContentFrame then
        -- Skin TabSystem top tabs when they are created
        local function SkinTabSystemTabs()
            if ContentFrame.TabSystem then
                for _, tab in ipairs({ContentFrame.TabSystem:GetChildren()}) do
                    if tab.Left and tab.LeftActive and not private.IsSkinned(tab) then
                        private.SetSkinned(tab, true)
                        Skin.TabSystemButtonTemplate(tab)
                    end
                end
            end
        end

        -- Hook Initialize to skin tabs after they're created
        if ContentFrame.Initialize then
            _G.hooksecurefunc(ContentFrame, "Initialize", SkinTabSystemTabs)
        end

        ----
        -- Initiatives / Endeavors Frame
        ----
        local InitiativesFrame = ContentFrame.InitiativesFrame
        if InitiativesFrame then
            Util.Mixin(InitiativesFrame, Hook.InitiativesTabMixin)

            -- Hide decorative art
            if InitiativesFrame.InitiativesArt then
                for _, region in pairs({InitiativesFrame.InitiativesArt:GetRegions()}) do
                    if region:IsObjectType("Texture") then
                        region:SetAlpha(0)
                    end
                end
            end

            -- Initiative Set Frame
            local InitiativeSetFrame = InitiativesFrame.InitiativeSetFrame
            if InitiativeSetFrame then
                -- Task list
                if InitiativeSetFrame.InitiativeTasks then
                    local TaskList = InitiativeSetFrame.InitiativeTasks
                    if TaskList.ScrollBox then Skin.WowScrollBoxList(TaskList.ScrollBox) end
                    if TaskList.ScrollBar then Skin.MinimalScrollBar(TaskList.ScrollBar) end
                    -- Hide decorative art: filigree corners, wood signs, foliage
                    HideDecorativeRegions(TaskList)
                    if TaskList.TaskListTitleContainer then
                        HideDecorativeRegions(TaskList.TaskListTitleContainer)
                    end
                end

                -- Activity log
                if InitiativeSetFrame.InitiativeActivity then
                    local ActivityLog = InitiativeSetFrame.InitiativeActivity
                    if ActivityLog.ScrollBox then Skin.WowScrollBoxList(ActivityLog.ScrollBox) end
                    if ActivityLog.ScrollBar then Skin.MinimalScrollBar(ActivityLog.ScrollBar) end
                    -- Hide decorative art: filigree corners, wood signs, foliage
                    HideDecorativeRegions(ActivityLog)
                    if ActivityLog.ActivityLogTitleContainer then
                        HideDecorativeRegions(ActivityLog.ActivityLogTitleContainer)
                    end
                end
            end
        end

        ----
        -- House Upgrade Frame
        ----
        local HouseUpgradeFrame = ContentFrame.HouseUpgradeFrame
        if HouseUpgradeFrame then
            Util.Mixin(HouseUpgradeFrame, Hook.HousingUpgradeFrameMixin)
            Util.WrapPoolAcquire(HouseUpgradeFrame.rewardPoolLarge, Skin.HouseUpgradeRewardFrameTemplate)
            Util.WrapPoolAcquire(HouseUpgradeFrame.rewardPoolSmall, Skin.HouseUpgradeRewardFrameTemplate)

            -- Hide background and all decorative art (filigree corners, etc.)
            if HouseUpgradeFrame.Background then HouseUpgradeFrame.Background:SetAlpha(0) end
            HideDecorativeRegions(HouseUpgradeFrame)

            -- CurrentLevelFrame: hide radial window frame and leaves
            local CurrentLevelFrame = HouseUpgradeFrame.CurrentLevelFrame
            if CurrentLevelFrame then
                local OuterBarFrame = CurrentLevelFrame.HouseBarFrame
                if OuterBarFrame then
                    -- Hide the ornate radial window frame (on outer HouseBarFrame)
                    if OuterBarFrame.frame then OuterBarFrame.frame:SetAlpha(0) end
                    -- Hide decorative leaves (on nested inner HouseBarFrame)
                    local InnerBarFrame = OuterBarFrame.HouseBarFrame
                    if InnerBarFrame then
                        for i = 1, 6 do
                            local leaf = InnerBarFrame["leaf" .. i]
                            if leaf then leaf:SetAlpha(0) end
                        end
                    end
                end
            end

            -- TrackFrame: hide glow and corbels
            local TrackFrame = HouseUpgradeFrame.TrackFrame
            if TrackFrame then
                HideDecorativeRegions(TrackFrame)
            end

            -- Watch Favor Button (checkbox)
            if HouseUpgradeFrame.WatchFavorButton then
                Skin.UICheckButtonTemplate(HouseUpgradeFrame.WatchFavorButton)
            end
        end
    end

    ----
    -- Catalog Content
    ----
    local CatalogContent = HousingDashboardFrame.CatalogContent
    if CatalogContent then
        -- Hide the background
        if CatalogContent.Background then CatalogContent.Background:SetAlpha(0) end

        -- Search box
        if CatalogContent.SearchBox then
            Skin.SearchBoxTemplate(CatalogContent.SearchBox)
        end

        -- Filter button
        if CatalogContent.Filters then
            Skin.FilterButton(CatalogContent.Filters)
        end

        -- Divider
        if CatalogContent.Divider then CatalogContent.Divider:SetAlpha(0) end

        -- Options container (scroll catalog)
        if CatalogContent.OptionsContainer then
            local OptionsContainer = CatalogContent.OptionsContainer
            if OptionsContainer.ScrollBox then Skin.WowScrollBoxList(OptionsContainer.ScrollBox) end
            if OptionsContainer.ScrollBar then Skin.MinimalScrollBar(OptionsContainer.ScrollBar) end
        end

        -- Categories sidebar
        if CatalogContent.Categories then
            local Categories = CatalogContent.Categories
            if Categories.ScrollBox then Skin.WowScrollBoxList(Categories.ScrollBox) end
            if Categories.ScrollBar then Skin.MinimalScrollBar(Categories.ScrollBar) end
            -- Hide decorative corbel and nav background
            if Categories.TopBorder then Categories.TopBorder:SetAlpha(0) end
            if Categories.Background then Categories.Background:SetAlpha(0) end
            if Categories.SubcategoriesDivider then Categories.SubcategoriesDivider:SetAlpha(0) end
        end

        -- Preview frame: hide corner brackets with vines
        if CatalogContent.PreviewFrame then
            local PreviewFrame = CatalogContent.PreviewFrame
            if PreviewFrame.PreviewBackground then PreviewFrame.PreviewBackground:SetAlpha(0) end
            if PreviewFrame.PreviewCornerLeft then PreviewFrame.PreviewCornerLeft:SetAlpha(0) end
            if PreviewFrame.PreviewCornerRight then PreviewFrame.PreviewCornerRight:SetAlpha(0) end
        end
    end

    ----
    -- Collection tab content (12.1 — third side tab; blueprint templates
    -- come from the Blizzard_HousingBlueprint module's Skin.* functions)
    ----
    local CollectionContent = HousingDashboardFrame.CollectionContent
    if CollectionContent then
        if CollectionContent.GearDropdown then
            Skin.DropdownButton(CollectionContent.GearDropdown)
        end
        if CollectionContent.ContentSummary and Skin.HousingBlueprintContentSummaryTemplate then
            Skin.HousingBlueprintContentSummaryTemplate(CollectionContent.ContentSummary)
        end
        if CollectionContent.BlueprintCollection and Skin.HousingBlueprintCollectionTemplate then
            Skin.HousingBlueprintCollectionTemplate(CollectionContent.BlueprintCollection)
        end
        if CollectionContent.Divider then
            CollectionContent.Divider:SetAlpha(0)
        end
        if CollectionContent.Categories then
            local Categories = CollectionContent.Categories
            if Categories.ScrollBox then Skin.WowScrollBoxList(Categories.ScrollBox) end
            if Categories.ScrollBar then Skin.MinimalScrollBar(Categories.ScrollBar) end
            if Categories.TopBorder then Categories.TopBorder:SetAlpha(0) end
            if Categories.Background then Categories.Background:SetAlpha(0) end
        end
    end
end
