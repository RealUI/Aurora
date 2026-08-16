local _, private = ...
if private.shouldSkip() then return end

---@diagnostic disable: undefined-global

--[[ Lua Globals ]]
-- luacheck: globals

local _G = _G

--[[ Core ]]
local Aurora = private.Aurora
local Base, Hook, Skin = Aurora.Base, Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

local function SetHousingActionButtonState(Button, state)
    if not Button._auroraHousingActionButton then
        return
    end

    local borderColor = Color.button
    local textColor = _G.NORMAL_FONT_COLOR

    if not state.isEnabled then
        borderColor = Color.button:Lightness(-0.4)
        textColor = _G.DISABLED_FONT_COLOR
    elseif state.isPressed then
        borderColor = Color.highlight:Lightness(-0.15)
        textColor = _G.HIGHLIGHT_FONT_COLOR
    elseif state.isActive then
        borderColor = Color.highlight
        textColor = _G.HIGHLIGHT_FONT_COLOR
    elseif state.isHovered then
        borderColor = Color.yellow
        textColor = _G.NORMAL_FONT_COLOR
    end

    Button:SetBackdropBorderColor(borderColor:GetRGB())

    if Button.Text then
        Button.Text:SetTextColor(textColor:GetRGB())
    end

    if Button.ExpandedArrow then
        Button.ExpandedArrow:SetVertexColor(borderColor:GetRGB())
    end
end

local function SetCatalogEntryState(Button, stateColor)
    if not Button._auroraHousingCatalogEntry then
        return
    end

    Button:SetBackdropBorderColor(stateColor:GetRGB())
end

do --[[ AddOns\Blizzard_HousingTemplates\Blizzard_HousingActionButton.lua ]]
    Hook.BaseHousingActionButtonMixin = {}
    function Hook.BaseHousingActionButtonMixin:UpdateVisuals(isPressed)
        if not self._auroraHousingActionButton then
            return
        end

        SetHousingActionButtonState(self, self:GetState(isPressed))
    end

    Hook.HousingCatalogEntryMixin = {}
    function Hook.HousingCatalogEntryMixin:UpdateBackground(isPressed)
        if not self._auroraHousingCatalogEntry then
            return
        end

        local borderColor = Color.button
        if isPressed then
            borderColor = Color.yellow
        elseif self.isSelected then
            borderColor = Color.highlight
        end

        SetCatalogEntryState(self, borderColor)
    end
    function Hook.HousingCatalogEntryMixin:OnEnter()
        if not self._auroraHousingCatalogEntry or self.isSelected then
            return
        end

        SetCatalogEntryState(self, Color.yellow)
    end
    function Hook.HousingCatalogEntryMixin:OnLeave()
        if not self._auroraHousingCatalogEntry then
            return
        end

        SetCatalogEntryState(self, self.isSelected and Color.highlight or Color.button)
    end
end

do --[[ AddOns\Blizzard_HousingTemplates\Blizzard_HousingCatalogTemplates.xml ]]
    function Skin.ScrollingHousingCatalogTemplate(Frame)
        if private.IsSkinned(Frame) then
            return
        end

        private.SetSkinned(Frame, true)

        Skin.WowScrollBoxList(Frame.ScrollBox)
        Skin.MinimalScrollBar(Frame.ScrollBar)
    end
end

do --[[ AddOns\Blizzard_HousingTemplates\Blizzard_HousingCatalogEntry.xml ]]
    function Skin.BaseHousingCatalogEntryTemplate(Button)
        if private.IsSkinned(Button) then
            return
        end

        private.SetSkinned(Button, true)
        Button._auroraHousingCatalogEntry = true

        Base.SetBackdrop(Button, Color.button, 0.2)
        Button:SetBackdropOption("offsets", {
            left = 0,
            right = 0,
            top = 0,
            bottom = 0,
        })

        Button.Background:SetAlpha(0)
        Button.HoverBackground:SetAlpha(0)

        Base.CropIcon(Button.Icon)

        if Button.CustomizeIcon then
            Button.CustomizeIcon:SetDesaturated(true)
            Button.CustomizeIcon:SetVertexColor(Color.highlight:GetRGB())
        end

        if Button.InfoIcon then
            Button.InfoIcon:SetVertexColor(Color.highlight:GetRGB())
        end

        if Button.InfoText then
            Button.InfoText:SetShadowOffset(1, -1)
        end

        SetCatalogEntryState(Button, Color.button)
    end
end

do --[[ AddOns\Blizzard_HousingTemplates\Blizzard_HousingCatalogCategories.xml ]]
    function Skin.HousingCatalogCategoryTemplate(Button)
        if private.IsSkinned(Button) then
            return
        end

        private.SetSkinned(Button, true)
        Button._auroraHousingActionButton = true

        Base.SetBackdrop(Button, Color.button, 0.2)
        Button:SetBackdropOption("offsets", {
            left = 0,
            right = 0,
            top = 0,
            bottom = 0,
        })

        if Button.SelectedBackground then
            Base.SetBackdrop(Button.SelectedBackground, Color.highlight, 0.2)
            Button.SelectedBackground:SetBackdropOption("offsets", {
                left = 6,
                right = 6,
                top = 8,
                bottom = 8,
            })

            if Button.SelectedBackground.FlipbookSparkle then
                Button.SelectedBackground.FlipbookSparkle:SetAlpha(0)
            end
            if Button.SelectedBackground.Highlight then
                Button.SelectedBackground.Highlight:SetAlpha(0)
            end
        end

        SetHousingActionButtonState(Button, Button:GetState(false))
    end

    function Skin.HousingCategoryBackButtonTemplate(Button)
        Skin.HousingCatalogCategoryTemplate(Button)

        if Button.Text then
            Button.Text:SetTextColor(_G.NORMAL_FONT_COLOR:GetRGB())
        end
    end

    function Skin.HousingCatalogCategoriesTemplate(Frame)
        if private.IsSkinned(Frame) then
            return
        end

        private.SetSkinned(Frame, true)

        Base.SetBackdrop(Frame, Color.frame)

        if Frame.Background then
            Frame.Background:SetAlpha(0)
        end
        if Frame.TopBorder then
            Frame.TopBorder:SetAlpha(0)
        end
        if Frame.SubcategoriesDivider then
            Frame.SubcategoriesDivider:SetAlpha(0)
        end

        Skin.HousingCategoryBackButtonTemplate(Frame.BackButton)
        Skin.HousingCatalogCategoryTemplate(Frame.AllSubcategoriesStandIn)
    end
end

do --[[ AddOns\Blizzard_HousingTemplates\Blizzard_HousingCatalogFilters.xml ]]
    function Skin.HousingCatalogFiltersTemplate(Frame)
        if private.IsSkinned(Frame) then
            return
        end

        private.SetSkinned(Frame, true)

        Skin.FilterButton(Frame.FilterDropdown)
    end

    function Skin.HousingCatalogSearchBoxTemplate(EditBox)
        if private.IsSkinned(EditBox) then
            return
        end

        private.SetSkinned(EditBox, true)

        Skin.SearchBoxTemplate(EditBox)
    end
end

function private.AddOns.Blizzard_HousingTemplates()
    _G.hooksecurefunc(_G.ScrollingHousingCatalogMixin, "OnLoad", function(self)
        Skin.ScrollingHousingCatalogTemplate(self)
    end)
    _G.hooksecurefunc(_G.HousingCatalogEntryMixin, "OnLoad", function(self)
        Skin.BaseHousingCatalogEntryTemplate(self)
    end)
    _G.hooksecurefunc(_G.HousingCatalogEntryMixin, "UpdateBackground", Hook.HousingCatalogEntryMixin.UpdateBackground)
    _G.hooksecurefunc(_G.HousingCatalogEntryMixin, "OnEnter", Hook.HousingCatalogEntryMixin.OnEnter)
    _G.hooksecurefunc(_G.HousingCatalogEntryMixin, "OnLeave", Hook.HousingCatalogEntryMixin.OnLeave)

    _G.hooksecurefunc(_G.HousingCatalogCategoriesMixin, "OnLoad", function(self)
        Skin.HousingCatalogCategoriesTemplate(self)
        Util.WrapPoolAcquire(self.categoryPool, Skin.HousingCatalogCategoryTemplate)
        Util.WrapPoolAcquire(self.subcategoryPool, Skin.HousingCatalogCategoryTemplate)
    end)

    _G.hooksecurefunc(_G.HousingCatalogFiltersMixin, "Initialize", function(self)
        Skin.HousingCatalogFiltersTemplate(self)
    end)
    _G.hooksecurefunc(_G.HousingCatalogSearchBoxMixin, "OnLoad", function(self)
        Skin.HousingCatalogSearchBoxTemplate(self)
    end)

    _G.hooksecurefunc(_G.BaseHousingActionButtonMixin, "UpdateVisuals", Hook.BaseHousingActionButtonMixin.UpdateVisuals)
end