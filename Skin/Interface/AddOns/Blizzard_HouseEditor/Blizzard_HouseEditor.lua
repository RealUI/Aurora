local _, private = ...
if private.shouldSkip() then return end

---@diagnostic disable: undefined-global

--[[ Lua Globals ]]
-- luacheck: globals _G ipairs pairs string

--[[ Core ]]
local Aurora = private.Aurora
local Base, Hook, Skin = Aurora.Base, Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util


-- Helper to hide decorative housing textures by atlas name prefix
local decorativeAtlases = {
    ["housing-basic-container"] = true,
    ["housing-basic-container-woodheader"] = true,
    ["housing-decorative-foliage"] = true,
    ["housing-foliage"] = true,
    ["house-chest-container-bg"] = true,
    ["house-chest-header-bg"] = true,
    ["house-chest-corbel"] = true,
    ["decor-abilitybar-bg"] = true,
    ["decor-abilitybar-bookend"] = true,
    ["housing-floor-container-bg"] = true,
}

local function IsDecorativeAtlas(atlasName)
    if not atlasName then return false end
    for prefix in _G.next, decorativeAtlases do
        if string.find(atlasName, prefix, 1, true) then
            return true
        end
    end
    return false
end

local function HideDecorativeRegions(frame)
    if not frame then return end
    if frame.IsForbidden and frame:IsForbidden() then return end
    for _, region in pairs({frame:GetRegions()}) do
        if region:IsObjectType("Texture") then
            local atlas = region:GetAtlas()
            if IsDecorativeAtlas(atlas) then
                region:SetAlpha(0)
            end
        end
    end
end

-- Safe frame access: returns nil if frame is nil or forbidden
local function SafeFrame(frame)
    if not frame then return nil end
    if frame.IsForbidden and frame:IsForbidden() then return nil end
    return frame
end

-- Skin a PlacedDecorList or FixtureOptionList panel (housing-basic-container pattern)
local function SkinListPanel(panel)
    if not SafeFrame(panel) then return end
    if panel._auroraSkinned then return end
    panel._auroraSkinned = true

    if panel.Background then panel.Background:SetAlpha(0) end
    if panel.Header then panel.Header:SetAlpha(0) end
    if panel.DecorativeFoliage then panel.DecorativeFoliage:SetAlpha(0) end

    Base.SetBackdrop(panel, Color.frame)

    if panel.ScrollBox then Skin.WowScrollBoxList(panel.ScrollBox) end
    if panel.ScrollBar then Skin.MinimalScrollBar(panel.ScrollBar) end
end

-- Skin a dye/customization pane (housing-basic-container pattern)
local function SkinCustomizationPane(pane)
    if not SafeFrame(pane) then return end
    if pane._auroraSkinned then return end
    pane._auroraSkinned = true

    if pane.Background then pane.Background:SetAlpha(0) end
    if pane.WoodHeader then pane.WoodHeader:SetAlpha(0) end
    if pane.Header then pane.Header:SetAlpha(0) end

    Base.SetBackdrop(pane, Color.frame)

    -- Dye pane buttons
    if pane.ButtonFrame then
        if pane.ButtonFrame.CancelButton then
            Skin.UIPanelButtonTemplate(pane.ButtonFrame.CancelButton)
        end
        if pane.ButtonFrame.ApplyButton then
            Skin.UIPanelButtonTemplate(pane.ButtonFrame.ApplyButton)
        end
        if pane.ButtonFrame.Divider then
            pane.ButtonFrame.Divider:SetAlpha(0)
        end
    end

    -- Dye slot popout scroll
    if pane.DyeSlotScrollBox then
        Skin.WowScrollBoxList(pane.DyeSlotScrollBox)
    end
    if pane.DyeSlotScrollBar then
        Skin.MinimalScrollBar(pane.DyeSlotScrollBar)
    end

    -- 12.1: customization components moved under CustomizeComponentContainer
    -- (PetPane layoutIndex 1, DyePane layoutIndex 2)
    local container = pane.CustomizeComponentContainer
    if container then
        if container.PetPane and container.PetPane.BehaviorDropdown then
            Skin.WowStyle2DropdownTemplate(container.PetPane.BehaviorDropdown)
        end
        -- container.DyePane (HousingDyePaneTemplate) stays stock first pass:
        -- its slot/cost widgets are functional art; the scroll UI lives on
        -- the DyeSelectionPopout, skinned via SkinModeFrameChildren
    end
end

-- Skin the RoomComponentPane (housing-basic-container pattern)
local function SkinRoomComponentPane(pane)
    if not SafeFrame(pane) then return end
    if pane._auroraSkinned then return end
    pane._auroraSkinned = true

    if pane.Background then pane.Background:SetAlpha(0) end
    if pane.Header then pane.Header:SetAlpha(0) end

    Base.SetBackdrop(pane, Color.frame)
end


-- Track which mode frames have been skinned (deferred skinning)
local skinnedModeFrames = {}

-- Deferred skinning for each mode frame's children on first activation
local function SkinModeFrameChildren(modeFrame)
    if not SafeFrame(modeFrame) then return end
    if skinnedModeFrames[modeFrame] then return end
    skinnedModeFrames[modeFrame] = true

    -- Hide decorative regions on the mode frame itself
    HideDecorativeRegions(modeFrame)

    -- PlacedDecorList (ExpertDecorMode has one)
    if modeFrame.PlacedDecorList then
        SkinListPanel(modeFrame.PlacedDecorList)
    end

    -- PlacedDecorListButton (ExpertDecorMode)
    if modeFrame.PlacedDecorListButton then
        Skin.BaseHousingControlButtonTemplate(modeFrame.PlacedDecorListButton)
    end

    -- SubButtonBar / SubmodeBar submode buttons
    local subBar = modeFrame.SubButtonBar or modeFrame.SubmodeBar
    if subBar then
        HideDecorativeRegions(subBar)
        if subBar.Buttons then
            for _, button in ipairs(subBar.Buttons) do
                Skin.BaseHousingControlButtonTemplate(button)
            end
        end
    end

    -- DecorCustomizationsPane (CustomizeMode)
    if modeFrame.DecorCustomizationsPane then
        SkinCustomizationPane(modeFrame.DecorCustomizationsPane)
    end

    -- DyeSelectionPopout (CustomizeMode — global frame DyeSelectionPopout)
    local dyePopout = modeFrame.DyeSelectionPopout or (modeFrame:GetName() and _G[modeFrame:GetName() .. ".DyeSelectionPopout"])
    if not dyePopout then
        -- DyeSelectionPopout is a named child, not parentKey — try global
        dyePopout = _G.DyeSelectionPopout
    end
    if SafeFrame(dyePopout) and not dyePopout._auroraSkinned then
        SkinCustomizationPane(dyePopout)
    end

    -- RoomComponentCustomizationsPane (CustomizeMode)
    if modeFrame.RoomComponentCustomizationsPane then
        SkinRoomComponentPane(modeFrame.RoomComponentCustomizationsPane)
    end

    -- PetCustomizationsPane (CustomizeMode, 12.1) — chest-style panel,
    -- structural clone of StoragePanel but with plain templates
    local petPane = SafeFrame(modeFrame.PetCustomizationsPane)
    if petPane and not petPane._auroraSkinned then
        petPane._auroraSkinned = true
        if petPane.Background then petPane.Background:SetAlpha(0) end
        if petPane.HeaderBackground then petPane.HeaderBackground:SetAlpha(0) end
        if petPane.CornerBorder then petPane.CornerBorder:SetAlpha(0) end
        HideDecorativeRegions(petPane)
        Base.SetBackdrop(petPane, Color.frame)

        if petPane.SearchBox then Skin.SearchBoxTemplate(petPane.SearchBox) end
        if petPane.Filters then Skin.FilterButton(petPane.Filters) end
        if petPane.OptionsContainer then
            if petPane.OptionsContainer.ScrollBox then
                Skin.WowScrollBoxList(petPane.OptionsContainer.ScrollBox)
            end
            if petPane.OptionsContainer.ScrollBar then
                Skin.MinimalScrollBar(petPane.OptionsContainer.ScrollBar)
            end
        end
        if petPane.CollapseButton then
            HideDecorativeRegions(petPane.CollapseButton)
        end
    end

    -- FloorSelect (LayoutMode)
    if modeFrame.FloorSelect then
        local floorSelect = modeFrame.FloorSelect
        if SafeFrame(floorSelect) and not floorSelect._auroraSkinned then
            floorSelect._auroraSkinned = true
            if floorSelect.Background then floorSelect.Background:SetAlpha(0) end
            if floorSelect.ScrollBox then Skin.WowScrollBoxList(floorSelect.ScrollBox) end
        end
    end

    -- FixtureOptionList (ExteriorCustomizationMode)
    if modeFrame.FixtureOptionList then
        SkinListPanel(modeFrame.FixtureOptionList)
    end

    -- CoreOptionsPanel dropdowns (ExteriorCustomizationMode)
    if modeFrame.CoreOptionsPanel then
        local panel = modeFrame.CoreOptionsPanel
        local dropdownKeys = {
            "HouseTypeOption", "HouseSizeOption", "BaseStyleOption",
            "BaseVariantOption", "RoofStyleOption", "RoofVariantOption",
        }
        for _, key in ipairs(dropdownKeys) do
            local option = panel[key]
            if option and option.Dropdown and not option._auroraSkinned then
                option._auroraSkinned = true
                Skin.WowStyle2DropdownTemplate(option.Dropdown)
            end
        end
    end
end


do --[[ AddOns\Blizzard_HouseEditor\Blizzard_HouseEditor.lua ]]
    Hook.HouseEditorFrameMixin = {}
    function Hook.HouseEditorFrameMixin:OnActiveModeChanged(newMode)
        -- Deferred skinning: skin each mode frame's children on first activation
        if self.activeModeFrame then
            SkinModeFrameChildren(self.activeModeFrame)
        end
    end
end


function private.AddOns.Blizzard_HouseEditor()
    ----
    -- Main Frame
    ----
    local HouseEditorFrame = _G.HouseEditorFrame
    if not HouseEditorFrame then return end

    -- SAFETY: Do NOT modify GameTooltip hierarchy, parenting, render layering,
    -- frame level, frame strata, or call SetAttribute on any frame.
    -- Use hooksecurefunc for ALL hooks. Use Util.Mixin for hook tables.

    -- Apply hook table via Util.Mixin (hooksecurefunc under the hood)
    Util.Mixin(HouseEditorFrame, Hook.HouseEditorFrameMixin)

    ----
    -- StoragePanel (HouseEditorStorageFrameTemplate)
    ----
    local StoragePanel = SafeFrame(HouseEditorFrame.StoragePanel)
    if StoragePanel then
        -- Hide decorative background textures
        if StoragePanel.Background then StoragePanel.Background:SetAlpha(0) end
        if StoragePanel.HeaderBackground then StoragePanel.HeaderBackground:SetAlpha(0) end
        if StoragePanel.CornerBorder then StoragePanel.CornerBorder:SetAlpha(0) end
        HideDecorativeRegions(StoragePanel)

        Base.SetBackdrop(StoragePanel, Color.frame)

        -- StoragePanel has OptionsContainer with ScrollBox/ScrollBar
        -- (skinned via HousingTemplates ScrollingHousingCatalogMixin:OnLoad hook)

        -- StoragePanel has Categories
        -- (skinned via HousingTemplates HousingCatalogCategoriesMixin:OnLoad hook)

        -- StoragePanel has SearchBox
        -- (skinned via HousingTemplates HousingCatalogSearchBoxMixin:OnLoad hook)

        -- StoragePanel has Filters
        -- (skinned via HousingTemplates HousingCatalogFiltersMixin:Initialize hook)

        -- TabSystem tabs — skin by iterating children
        -- (TabSystem frame doesn't have AcquireTab; that's on TabSystemOwnerMixin)
        if StoragePanel.TabSystem then
            local function SkinStorageTabs()
                for _, tab in ipairs({StoragePanel.TabSystem:GetChildren()}) do
                    if tab.Left and tab.LeftActive and not tab._auroraSkinned then
                        tab._auroraSkinned = true
                        Skin.TabSystemButtonTemplate(tab)
                    end
                end
            end

            -- Hook SetTab on the owner (StoragePanel) to skin tabs after creation
            if StoragePanel.SetTab then
                _G.hooksecurefunc(StoragePanel, "SetTab", SkinStorageTabs)
            end

            -- Skin any tabs that already exist
            SkinStorageTabs()
        end

        -- CollapseButton
        if StoragePanel.CollapseButton then
            HideDecorativeRegions(StoragePanel.CollapseButton)
        end

        -- 12.1: embedded blueprint collection (Blizzard_HousingBlueprint
        -- template; skin function defined in that module's file)
        if StoragePanel.BlueprintCollection and Skin.HousingBlueprintCollectionTemplate then
            Skin.HousingBlueprintCollectionTemplate(StoragePanel.BlueprintCollection)
        end
    end

    ----
    -- StorageButton (HouseEditorStorageButtonTemplate)
    ----
    local StorageButton = SafeFrame(HouseEditorFrame.StorageButton)
    if StorageButton then
        Skin.FrameTypeButton(StorageButton)
    end

    ----
    -- ModeBar — skin mode selection buttons via BaseHousingControlButtonTemplate
    ----
    local ModeBar = SafeFrame(HouseEditorFrame.ModeBar)
    if ModeBar then
        -- Hide decorative mode bar textures
        if ModeBar.Background then ModeBar.Background:SetAlpha(0) end
        if ModeBar.GradientBackground then ModeBar.GradientBackground:SetAlpha(0) end
        if ModeBar.BookendLeft then ModeBar.BookendLeft:SetAlpha(0) end
        if ModeBar.BookendRight then ModeBar.BookendRight:SetAlpha(0) end
        if ModeBar.Divider then ModeBar.Divider:SetAlpha(0) end
        HideDecorativeRegions(ModeBar)

        -- Skin all mode buttons
        local modeButtonKeys = {
            "BasicDecorModeButton", "ExpertDecorModeButton",
            "CustomizeModeButton", "CleanupModeButton",
            "LayoutModeButton", "ExteriorCustomizationModeButton",
        }
        for _, key in ipairs(modeButtonKeys) do
            local button = ModeBar[key]
            if button then
                Skin.BaseHousingControlButtonTemplate(button)
                if button.UpdateState then
                    button:UpdateState()
                end
            end
        end
    end

    ----
    -- MarketShoppingCartFrame — skinned by HousingMarketCart skin, NOT here
    ----

    ----
    -- Skin any currently active mode frame (in case addon loaded while editor is open)
    ----
    if HouseEditorFrame.activeModeFrame then
        SkinModeFrameChildren(HouseEditorFrame.activeModeFrame)
    end
end