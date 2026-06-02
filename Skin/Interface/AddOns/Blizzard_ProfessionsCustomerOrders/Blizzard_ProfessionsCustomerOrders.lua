local _, private = ...
if private.shouldSkip() then return end

local Aurora = private.Aurora
local Base, Hook, Skin = Aurora.Base, Aurora.Hook, Aurora.Skin
local Util = Aurora.Util

do --[[ AddOns\Blizzard_ProfessionsCustomerOrders.lua ]]
    -- Skin tabs on the customer orders frame and reposition them.
    --
    -- Blizzard ships two tabs (BrowseTab, OrdersTab), but third-party addons
    -- such as Myu's Knowledge Points Tracker insert additional tabs on the
    -- frame. Without an explicit pass here, those tabs render with vanilla
    -- Blizzard sizing (too wide, hit area extending past the frame edge,
    -- mouseover offset). We discover tabs by walking the frame's children
    -- and identifying anything inheriting PanelTabButtonTemplate (detected
    -- via the LeftActive region), so this works for any number of tabs.
    function Skin.ProfessionsCustomerOrdersFrameTabTemplate(Button)
        Skin.PanelTabButtonTemplate(Button)
        -- _auroraTabResize is already set by PanelTabButtonTemplate; mark
        -- the button so we don't re-skin it on subsequent OnShow passes.
        Button._auroraOrderTabSkinned = true
    end

    function Hook.ProfessionsCustomerOrdersFrame_RefreshTabs(Frame)
        local tabs = {}
        for _, child in next, { Frame:GetChildren() } do
            -- PanelTabButtonTemplate exposes a LeftActive region; this is a
            -- stable shape-test for "is this a tab" without depending on
            -- frame names.
            if child.LeftActive and child.GetText then
                if not child._auroraOrderTabSkinned then
                    Skin.ProfessionsCustomerOrdersFrameTabTemplate(child)
                end
                tabs[#tabs + 1] = child
            end
        end
        if #tabs > 0 then
            Util.PositionRelative("TOPLEFT", Frame, "BOTTOMLEFT", 20, -1, 1, "Right", tabs)
        end
    end

    -- Skin a recipe list row acquired from the ScrollBox element factory.
    local function SkinRecipeListRow(button)
        if not button or button._auroraSkinned then return end
        button._auroraSkinned = true

        if button.Icon then
            Base.CropIcon(button.Icon, button)
        end
        if button.IconBorder then
            button.IconBorder:SetAlpha(0)
        end
    end

    -- Skin an order list row (MyOrders tab) acquired from the ScrollBox element factory.
    local function SkinOrderListRow(button)
        if not button or button._auroraSkinned then return end
        button._auroraSkinned = true

        if button.Icon then
            Base.CropIcon(button.Icon, button)
        end
        if button.IconBorder then
            button.IconBorder:SetAlpha(0)
        end
    end

    -- Hook ScrollBox Update to skin dynamically created recipe list rows.
    function Hook.ProfessionsCustomerOrdersRecipeListScrollBoxUpdate(scrollBox)
        for _, child in next, { scrollBox.ScrollTarget:GetChildren() } do
            SkinRecipeListRow(child)
        end
    end

    -- Hook ScrollBox Update to skin dynamically created order list rows (MyOrders).
    function Hook.ProfessionsCustomerOrdersMyOrdersScrollBoxUpdate(scrollBox)
        for _, child in next, { scrollBox.ScrollTarget:GetChildren() } do
            SkinOrderListRow(child)
        end
    end

    -- Hook ScrollBox Update to skin dynamically created current listings rows (Form).
    function Hook.ProfessionsCustomerOrdersCurrentListingsScrollBoxUpdate(scrollBox)
        for _, child in next, { scrollBox.ScrollTarget:GetChildren() } do
            SkinOrderListRow(child)
        end
    end
end

function private.AddOns.Blizzard_ProfessionsCustomerOrders()
    local Frame = _G.ProfessionsCustomerOrdersFrame
    if not Frame then return end

    ------------------------------------
    -- Main frame (PortraitFrameTemplate)
    ------------------------------------
    Skin.FrameTypeFrame(Frame)

    ------------------------------------
    -- Tabs
    ------------------------------------
    -- Skin Blizzard's known tabs immediately so they look right on first show.
    if Frame.BrowseTab then
        Skin.ProfessionsCustomerOrdersFrameTabTemplate(Frame.BrowseTab)
    end
    if Frame.OrdersTab then
        Skin.ProfessionsCustomerOrdersFrameTabTemplate(Frame.OrdersTab)
    end
    -- Reposition (and pick up any third-party tabs) on first show, and on every
    -- subsequent show in case other addons add or remove tabs at runtime.
    Hook.ProfessionsCustomerOrdersFrame_RefreshTabs(Frame)
    Frame:HookScript("OnShow", Hook.ProfessionsCustomerOrdersFrame_RefreshTabs)

    ------------------------------------
    -- Money frame inset
    ------------------------------------
    if Frame.MoneyFrameInset then
        Base.StripBlizzardTextures(Frame.MoneyFrameInset)
    end
    if Frame.MoneyFrameBorder then
        Base.StripBlizzardTextures(Frame.MoneyFrameBorder)
    end

    ------------------------------------
    -- Browse Orders tab
    ------------------------------------
    local BrowseOrders = Frame.BrowseOrders
    if BrowseOrders then
        -- Search bar buttons
        local SearchBar = BrowseOrders.SearchBar
        if SearchBar then
            if SearchBar.SearchButton then
                Skin.FrameTypeButton(SearchBar.SearchButton)
            end
            if SearchBar.FavoritesSearchButton then
                Skin.FrameTypeButton(SearchBar.FavoritesSearchButton)
            end
        end

        -- Category list
        local CategoryList = BrowseOrders.CategoryList
        if CategoryList then
            Util.HideNineSlice(CategoryList)
            if CategoryList.Background then
                CategoryList.Background:SetAlpha(0)
            end
        end

        -- Recipe list
        local RecipeList = BrowseOrders.RecipeList
        if RecipeList then
            Util.HideNineSlice(RecipeList)
            if RecipeList.Background then
                RecipeList.Background:SetAlpha(0)
            end

            -- Hook ScrollBox Update to skin recipe list rows as they are created
            if RecipeList.ScrollBox then
                _G.hooksecurefunc(RecipeList.ScrollBox, "Update", Hook.ProfessionsCustomerOrdersRecipeListScrollBoxUpdate)
            end
        end
    end

    ------------------------------------
    -- My Orders tab
    ------------------------------------
    local MyOrdersPage = Frame.MyOrdersPage
    if MyOrdersPage then
        if MyOrdersPage.RefreshButton then
            Skin.FrameTypeButton(MyOrdersPage.RefreshButton)
        end

        local OrderList = MyOrdersPage.OrderList
        if OrderList then
            Util.HideNineSlice(OrderList)
            if OrderList.Background then
                OrderList.Background:SetAlpha(0)
            end

            -- Hook ScrollBox Update to skin order list rows as they are created
            if OrderList.ScrollBox then
                _G.hooksecurefunc(OrderList.ScrollBox, "Update", Hook.ProfessionsCustomerOrdersMyOrdersScrollBoxUpdate)
            end
        end
    end

    ------------------------------------
    -- Order Form
    ------------------------------------
    local Form = Frame.Form
    if Form then
        -- Back button
        if Form.BackButton then
            Skin.FrameTypeButton(Form.BackButton)
        end

        -- Output icon (recipe icon)
        if Form.OutputIcon then
            Base.CropIcon(Form.OutputIcon)
        end

        -- Left and right panel backgrounds
        if Form.LeftPanelBackground then
            Util.HideNineSlice(Form.LeftPanelBackground)
            if Form.LeftPanelBackground.Background then
                Form.LeftPanelBackground.Background:SetAlpha(0)
            end
        end
        if Form.RightPanelBackground then
            Util.HideNineSlice(Form.RightPanelBackground)
            if Form.RightPanelBackground.Background then
                Form.RightPanelBackground.Background:SetAlpha(0)
            end
        end

        -- Recipe header decorative texture
        if Form.RecipeHeader then
            Form.RecipeHeader:SetAlpha(0)
        end

        -- Checkboxes
        if Form.AllocateBestQualityCheckbox then
            Skin.FrameTypeCheckButton(Form.AllocateBestQualityCheckbox)
        end
        if Form.TrackRecipeCheckbox and Form.TrackRecipeCheckbox.Checkbox then
            Skin.FrameTypeCheckButton(Form.TrackRecipeCheckbox.Checkbox)
        end

        -- Payment container buttons
        local PaymentContainer = Form.PaymentContainer
        if PaymentContainer then
            if PaymentContainer.ListOrderButton then
                Skin.FrameTypeButton(PaymentContainer.ListOrderButton)
            end
            if PaymentContainer.CancelOrderButton then
                Skin.FrameTypeButton(PaymentContainer.CancelOrderButton)
            end

            -- Note edit box border
            if PaymentContainer.NoteEditBox and PaymentContainer.NoteEditBox.Border then
                PaymentContainer.NoteEditBox.Border:SetAlpha(0)
            end
        end

        -- Current listings panel
        local CurrentListings = Form.CurrentListings
        if CurrentListings then
            Base.StripBlizzardTextures(CurrentListings)

            if CurrentListings.CloseButton then
                Skin.FrameTypeButton(CurrentListings.CloseButton)
            end

            local CLOrderList = CurrentListings.OrderList
            if CLOrderList then
                Util.HideNineSlice(CLOrderList)
                if CLOrderList.Background then
                    CLOrderList.Background:SetAlpha(0)
                end

                -- Hook ScrollBox Update to skin current listings rows
                if CLOrderList.ScrollBox then
                    _G.hooksecurefunc(CLOrderList.ScrollBox, "Update", Hook.ProfessionsCustomerOrdersCurrentListingsScrollBoxUpdate)
                end
            end
        end

        -- Reagent slot pool — wrap Acquire to skin reagent icons dynamically
        if Form.reagentSlotPool then
            Util.WrapPoolAcquire(Form.reagentSlotPool, function(slot)
                if slot._auroraSkinned then return end
                slot._auroraSkinned = true

                if slot.Button then
                    Base.CropIcon(slot.Button)
                end
            end)
        end
    end
end
