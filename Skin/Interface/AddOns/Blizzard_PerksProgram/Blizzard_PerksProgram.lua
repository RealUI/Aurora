local _, private = ...
if private.shouldSkip() then return end

local Aurora = private.Aurora
local Base, Hook, Skin = Aurora.Base, Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

do --[[ AddOns\Blizzard_PerksProgram.lua ]]
    -- Skin a product button acquired from the ScrollBox element factory.
    local function SkinProductButton(button)
        if not button or private.IsSkinned(button) then return end
        private.SetSkinned(button, true)

        local contents = button.ContentsContainer
        if contents then
            if contents.Icon then
                Base.CropIcon(contents.Icon, button)
            end
        end
    end

    -- Hook ScrollBox Update to skin dynamically created product buttons.
    function Hook.PerksProgramProductsScrollBoxUpdate(scrollBox)
        for _, child in next, { scrollBox.ScrollTarget:GetChildren() } do
            SkinProductButton(child)
        end
    end

    -- Cart and ensemble item rows (PerksProgramItemDetailsScrollButtonTemplate
    -- and its cart/set variants). Pooled, so restyled in place from the row's
    -- own refresh: a flat row instead of the pet-list art, a square icon, no
    -- gold ensemble brace. The icon's 1px border takes the highlight colour
    -- while the item is the one being previewed, where Blizzard shows its
    -- gold border. Borders live in a weak table, not on the row.
    local itemIconBorders = _G.setmetatable({}, { __mode = "k" })
    local function SkinItemRow(row)
        if private.IsSkinned(row) then return itemIconBorders[row] end
        private.SetSkinned(row, true)

        local r, g, b = Color.button:GetRGB()
        row.BackgroundTexture:SetColorTexture(r, g, b, 0.3)
        r, g, b = Color.highlight:GetRGB()
        row.HighlightTexture:SetColorTexture(r, g, b, 0.15)
        row.IconBorder:SetAlpha(0) -- Blizzard re-sets its atlas, never its alpha
        if row.TopBraceTexture then row.TopBraceTexture:Hide() end
        if row.BottomBraceTexture then row.BottomBraceTexture:Hide() end

        itemIconBorders[row] = Base.CropIcon(row.Icon, row)
        return itemIconBorders[row]
    end

    Hook.PerksProgramScrollItemDetailsMixin = {}
    function Hook.PerksProgramScrollItemDetailsMixin:UpdatePreviewStatusIcon()
        local border = SkinItemRow(self)
        if not border then return end
        if self.enabled and self.elementData and self.elementData.selected then
            border:SetColorTexture(Color.highlight:GetRGB())
        else
            border:SetColorTexture(0, 0, 0)
        end
    end

    -- Product list add/remove cart toggle. UpdateCartState re-applies its
    -- 128-redbutton-cart-add/minus art, glyph included, on every change, so
    -- the art is cleared again each time; a flat button with the cart icon
    -- and a plus/minus badge stands in. Icons live in a weak table.
    local cartToggleBadges = _G.setmetatable({}, { __mode = "k" })
    Hook.ProductCartToggleButtonMixin = {}
    function Hook.ProductCartToggleButtonMixin:UpdateCartState(itemInCart)
        local badge = cartToggleBadges[self]
        if not badge then
            Skin.FrameTypeButton(self)
            local cart = self:CreateTexture(nil, "ARTWORK")
            cart:SetAtlas("perks-shoppingcart")
            cart:SetSize(20, 20)
            cart:SetPoint("CENTER")

            badge = self:CreateTexture(nil, "OVERLAY")
            badge:SetSize(12, 12)
            badge:SetPoint("TOPRIGHT", -2, -2)
            cartToggleBadges[self] = badge
        end

        self:ClearNormalTexture()
        self:ClearPushedTexture()
        self:ClearDisabledTexture()
        self:ClearHighlightTexture()
        badge:SetAtlas(itemInCart and "common-icon-minus" or "common-icon-plus")
    end

    -- The ensemble header row's gold brace; the name and price stay.
    Hook.PerksProgramSetItemDetailsScrollHeaderMixin = {}
    function Hook.PerksProgramSetItemDetailsScrollHeaderMixin:InitHeader()
        if self.TopBraceTexture then
            self.TopBraceTexture:Hide()
        end
    end
end

do --[[ AddOns\Blizzard_PerksProgram.xml ]]
    function Skin.PerksProgramProductButtonTemplate(Button)
        if private.IsSkinned(Button) then return end
        private.SetSkinned(Button, true)

        local contents = Button.ContentsContainer
        if contents then
            if contents.Icon then
                Base.CropIcon(contents.Icon, Button)
            end
        end
    end

    function Skin.PerksProgramCheckboxTemplate(CheckButton)
        Skin.FrameTypeCheckButton(CheckButton)

        -- checkmark-minimal keeps its atlas size and centre anchor; recolour only
        local check = CheckButton:GetCheckedTexture()
        if check then
            check:SetDesaturated(true)
            check:SetVertexColor(Color.highlight:GetRGB())
        end
    end

    -- SharedButtonLargeTemplate: the red three-slice art comes from Left,
    -- Center and Right, which Skin.FrameTypeButton alone leaves in place.
    function Skin.PerksProgramButtonTemplate(Button)
        Skin.SharedButtonLargeTemplate(Button)
    end
    -- PerksProgramUIButtonTemplate (UIButtonTemplate): the whole look, glyph
    -- included, is the normal atlas from buttonArtKit, set once at load.
    -- Clearing it clears the glyph, so the glyph comes back as an icon.
    function Skin.PerksProgramIconButton(Button, atlas)
        Skin.FrameTypeButton(Button)
        local icon = Button:CreateTexture(nil, "ARTWORK")
        icon:SetAtlas(atlas)
        icon:SetSize(26, 26)
        icon:SetPoint("CENTER")
    end

    function Skin.HeaderSortButtonTemplate(Button)
        -- Sort header buttons — strip decorative textures, leave functional
        if Button.Arrow then
            Button.Arrow:SetDesaturated(true)
            Button.Arrow:SetVertexColor(Color.highlight:GetRGB())
        end
    end

    function Skin.PerksProgramDetailsFrameTemplate(Frame)
        -- Details frame is a VerticalLayoutFrame — no backdrop needed,
        -- just ensure text colours are readable.
    end
end

function private.AddOns.Blizzard_PerksProgram()
    -- Rows are created from these mixins later, when a list first fills, so
    -- they pick up the post-hooks.
    Util.Mixin(_G.PerksProgramScrollItemDetailsMixin, Hook.PerksProgramScrollItemDetailsMixin)
    Util.Mixin(_G.PerksProgramSetItemDetailsScrollHeaderMixin, Hook.PerksProgramSetItemDetailsScrollHeaderMixin)
    Util.Mixin(_G.ProductCartToggleButtonMixin, Hook.ProductCartToggleButtonMixin)

    local PerksProgramFrame = _G.PerksProgramFrame
    if not PerksProgramFrame then return end

    ------------------------------------
    -- Main browse frame
    ------------------------------------
    Skin.FrameTypeFrame(PerksProgramFrame)

    ------------------------------------
    -- Products frame
    ------------------------------------
    local ProductsFrame = PerksProgramFrame.ProductsFrame
    if ProductsFrame then
        -- Strip the background overlay textures
        if ProductsFrame.LeftBackgroundOverlay then
            ProductsFrame.LeftBackgroundOverlay:SetAlpha(0)
        end
        if ProductsFrame.RightBackgroundOverlay then
            ProductsFrame.RightBackgroundOverlay:SetAlpha(0)
        end

        local scrollContainer = ProductsFrame.ProductsScrollBoxContainer
        if scrollContainer then
            -- Strip the NineSlice border on the product list. Here the
            -- NineSlicePanelTemplate is the `Border` child, not a `NineSlice`
            -- key, so Util.HideNineSlice does not apply (it printed "Report: No
            -- NineSlice for nil" for all three Trading Post panels).
            if scrollContainer.Border then
                Base.StripBlizzardTextures(scrollContainer.Border)
            end

            -- Strip the divider atlas texture
            if scrollContainer.PerksDividerTop then
                scrollContainer.PerksDividerTop:SetAlpha(0)
            end

            -- Skin sort header buttons
            if scrollContainer.NameSortButton then
                Skin.HeaderSortButtonTemplate(scrollContainer.NameSortButton)
            end
            if scrollContainer.TimeSortButton then
                Skin.HeaderSortButtonTemplate(scrollContainer.TimeSortButton)
            end
            if scrollContainer.PriceSortButton then
                Skin.HeaderSortButtonTemplate(scrollContainer.PriceSortButton)
            end

            -- Hook ScrollBox Update to skin product buttons as they are created
            if scrollContainer.ScrollBox then
                _G.hooksecurefunc(scrollContainer.ScrollBox, "Update", Hook.PerksProgramProductsScrollBoxUpdate)
            end

            -- Skin the frozen product hold frame
            local holdFrame = scrollContainer.PerksProgramHoldFrame
            if holdFrame then
                Base.StripBlizzardTextures(holdFrame)
            end
        end

        ----------------------------------------
        -- Product details container
        ----------------------------------------
        local detailsContainer = ProductsFrame.PerksProgramProductDetailsContainerFrame
        if detailsContainer then
            if detailsContainer.Border then
                Base.StripBlizzardTextures(detailsContainer.Border)
            end
        end

        ----------------------------------------
        -- Shopping cart frame
        ----------------------------------------
        local cartFrame = ProductsFrame.PerksProgramShoppingCartFrame
        if cartFrame then
            if cartFrame.Background then
                Base.StripBlizzardTextures(cartFrame.Background)
            end
            if cartFrame.CloseButton then
                Skin.UIPanelCloseButton(cartFrame.CloseButton)
            end
            if cartFrame.PurchaseCartButton then
                Skin.PerksProgramButtonTemplate(cartFrame.PurchaseCartButton)
            end
            -- Clear cart: like the view cart button, the trash can is part of
            -- the button art (buttonArtKit 128-RedButton-Delete).
            if cartFrame.ClearCartButton then
                Skin.PerksProgramIconButton(cartFrame.ClearCartButton, "common-icon-delete")
            end
        end
    end

    ------------------------------------
    -- Footer frame action buttons
    ------------------------------------
    local FooterFrame = PerksProgramFrame.FooterFrame
    if FooterFrame then
        local buttons = {
            "PurchaseButton", "RefundButton", "LeaveButton",
            "AddToCartButton", "RemoveFromCartButton",
        }
        for _, key in next, buttons do
            local btn = FooterFrame[key]
            if btn then
                Skin.PerksProgramButtonTemplate(btn)
            end
        end
        if FooterFrame.ViewCartButton then
            Skin.PerksProgramIconButton(FooterFrame.ViewCartButton, "perks-shoppingcart")
        end

        -- Model preview toggles. Restyle only: their .Text anchors chain the
        -- toggles to each other, and 12.1.5 drives them from the model scene.
        local toggles = {
            "TogglePlayerPreview", "ToggleMountSpecial",
            "ToggleHideArmor", "ToggleAttackAnimation",
        }
        for _, key in next, toggles do
            local toggle = FooterFrame[key]
            if toggle then
                Skin.PerksProgramCheckboxTemplate(toggle)
            end
        end

        -- Model rotate buttons (PerksModelSceneControlButtonTemplate): the
        -- perks-button-up art goes, the arrow Icon stays.
        local rotate = FooterFrame.RotateButtonContainer
        if rotate then
            for _, key in next, { "RotateLeftButton", "RotateRightButton" } do
                if rotate[key] then
                    Skin.FrameTypeButton(rotate[key])
                end
            end
        end
    end

    ------------------------------------
    -- Theme container decorative textures
    ------------------------------------
    local ThemeContainer = PerksProgramFrame.ThemeContainer
    if ThemeContainer then
        if ThemeContainer.ProductList then
            Base.StripBlizzardTextures(ThemeContainer.ProductList)
        end
        if ThemeContainer.ProductDetails then
            Base.StripBlizzardTextures(ThemeContainer.ProductDetails)
        end
    end
end
