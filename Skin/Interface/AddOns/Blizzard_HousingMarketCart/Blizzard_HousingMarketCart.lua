local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base, Hook = Aurora.Base, Aurora.Hook
local Color, Util = Aurora.Color, Aurora.Util

-- Helper to skin a single cart item entry (HousingMarketCartItemTemplate)
local function SkinCartItemEntry(entry)
    if not entry or private.IsSkinned(entry) then return end
    private.SetSkinned(entry, true)

    -- Crop the item icon
    if entry.Icon then
        Base.CropIcon(entry.Icon, entry)
    end

    -- Decorative atlas hiding
    if entry.IconBorder then entry.IconBorder:SetAlpha(0) end
    if entry.HighlightTexture then entry.HighlightTexture:SetAlpha(0) end
    if entry.IconVignette then entry.IconVignette:SetAlpha(0) end
end

-- Helper to skin a bundle item entry (HousingMarketCartBundleItemTemplate)
local function SkinBundleItemEntry(entry)
    if not entry or private.IsSkinned(entry) then return end
    private.SetSkinned(entry, true)

    local vc = entry.VisualContainer
    if vc then
        -- Crop the item icon
        if vc.Icon then
            Base.CropIcon(vc.Icon, vc)
        end

        -- Decorative atlas hiding
        if vc.IconBorder then vc.IconBorder:SetAlpha(0) end
        if vc.HighlightTexture then vc.HighlightTexture:SetAlpha(0) end
        if vc.IconVignette then vc.IconVignette:SetAlpha(0) end
    end
end

do --[[ AddOns\Blizzard_HousingMarketCart\Blizzard_HousingMarketCartTemplates.lua ]]
    Hook.HousingMarketCartFrameMixin = {}
    function Hook.HousingMarketCartFrameMixin:OnLoad()
        -- Housing-specific overrides applied after base OnLoad (GenericShoppingCart)
        -- Apply flat backdrop to cart containers
        if self.CartVisibleContainer then
            Base.SetBackdrop(self.CartVisibleContainer, Color.frame)
        end
        if self.CartHiddenContainer then
            Base.SetBackdrop(self.CartHiddenContainer, Color.frame)
        end
    end

    function Hook.HousingMarketCartFrameMixin:FullUpdate()
        -- Re-skin cart entries after cart state changes (items added/removed)
        if self.ScrollBox then
            self.ScrollBox:ForEachFrame(function(frame)
                -- Determine entry type by checking for VisualContainer (bundle items have it)
                if frame.VisualContainer then
                    SkinBundleItemEntry(frame)
                elseif frame.Icon then
                    SkinCartItemEntry(frame)
                end
            end)
        end
    end
end

function private.AddOns.Blizzard_HousingMarketCart()
    -- HousingMarketCartFrameTemplate inherits ShoppingCartVisualsFrameTemplate.
    -- Base template styling (buttons, scrollbox, scrollbar, dividers, NineSlice
    -- hiding) is handled by the GenericShoppingCart skin via Util.Mixin on
    -- ShoppingCartVisualsFrameMixin:OnLoad. This skin applies housing-specific
    -- overrides only:
    --   - Base.SetBackdrop on CartVisibleContainer / CartHiddenContainer (OnLoad hook)
    --   - Base.CropIcon + decorative atlas hiding on cart item entries (FullUpdate hook)

    -- Apply housing-specific hooks via Util.Mixin
    Util.Mixin(_G.HousingMarketCartFrameMixin, Hook.HousingMarketCartFrameMixin)
end
