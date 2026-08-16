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
    end

    function Skin.PerksProgramButtonTemplate(Button)
        Skin.FrameTypeButton(Button)
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
            -- Strip the NineSlice border on the product list
            if scrollContainer.Border then
                Util.HideNineSlice(scrollContainer)
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
                Util.HideNineSlice(detailsContainer)
                Base.StripBlizzardTextures(detailsContainer.Border)
            end
        end

        ----------------------------------------
        -- Shopping cart frame
        ----------------------------------------
        local cartFrame = ProductsFrame.PerksProgramShoppingCartFrame
        if cartFrame then
            if cartFrame.Background then
                Util.HideNineSlice(cartFrame)
                Base.StripBlizzardTextures(cartFrame.Background)
            end
            -- Skin the cart purchase button
            if cartFrame.PurchaseCartButton then
                Skin.FrameTypeButton(cartFrame.PurchaseCartButton)
            end
            -- Skin the clear cart button
            if cartFrame.ClearCartButton then
                Skin.FrameTypeButton(cartFrame.ClearCartButton)
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
            "ViewCartButton", "AddToCartButton", "RemoveFromCartButton",
        }
        for _, key in next, buttons do
            local btn = FooterFrame[key]
            if btn then
                Skin.FrameTypeButton(btn)
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
