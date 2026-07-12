local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

do --[[ AddOns\Blizzard_AuctionHouseUI.lua ]]
    do --[[ Blizzard_AuctionHouseTableBuilder ]]
        Hook.AuctionHouseTableCellFavoriteButtonMixin = {}
        function Hook.AuctionHouseTableCellFavoriteButtonMixin:UpdateFavoriteState()
            Base.SetTexture(self.NormalTexture, "shapeStar")
            Base.SetTexture(self.HighlightTexture, "shapeStar")

            if self:IsFavorite() then
                self.NormalTexture:SetAlpha(1)
            else
                if self.textureLocked then
                    self.NormalTexture:SetColorTexture(Color.grayDark:GetRGB())
                else
                    self.NormalTexture:SetAlpha(0)
                end

                self.HighlightTexture:SetColorTexture(Color.gray:GetRGB())
                self.HighlightTexture:SetBlendMode("DISABLE")
            end

            self.HighlightTexture:SetAlpha(1)
        end
        function Hook.AuctionHouseTableCellFavoriteButtonMixin:LockTexture()
            if not self:IsFavorite() then
                Base.SetTexture(self.NormalTexture, "shapeStar")
                self.NormalTexture:SetColorTexture(Color.grayDark:GetRGB())
                self.NormalTexture:SetAlpha(1)
            end
        end
        function Hook.AuctionHouseTableCellFavoriteButtonMixin:UnlockTexture()
            if not self:IsFavorite() then
                self.NormalTexture:SetAlpha(0)
            end
        end
        Hook.AuctionHouseTableHeaderStringMixin = {}
        function Hook.AuctionHouseTableHeaderStringMixin:SetArrowState(sortOrderState)
            self.Arrow:SetTexCoord(0, 1, 0, 1)
            if sortOrderState == _G.AuctionHouseSortOrderState.PrimarySorted then
                Base.SetTexture(self.Arrow, "arrowUp")
            elseif sortOrderState == _G.AuctionHouseSortOrderState.PrimaryReversed then
                Base.SetTexture(self.Arrow, "arrowDown")
            end
        end
    end
    do --[[ Blizzard_AuctionHouseCategoriesList ]]
        function Hook.AuctionHouseFilterButton_SetUp(button, info)
            if info.type == "subSubCategory" then
                Util.SetHighlightColor(button.SelectedTexture, 0.5)

                Util.SetHighlightColor(button.HighlightTexture, 0.5)
            else
                -- Blizzard sets NormalTexture to an atlas; hide it so Aurora styling takes effect
                button.NormalTexture:SetAlpha(0)
                button.HighlightTexture:SetAlpha(0)

                Util.SetHighlightColor(button.SelectedTexture, (info.selected and 0.5 or 0))
            end
        end
    end
    do --[[ Blizzard_AuctionHouseSearchBar ]]
        Hook.AuctionHouseFavoritesSearchButtonMixin = {}
        function Hook.AuctionHouseFavoritesSearchButtonMixin:UpdateState()
            self.Icon:SetDesaturated(false)

            if _G.C_AuctionHouse.HasFavorites() then
                self.Icon:SetColorTexture(Color.yellow:GetRGB())
            else
                self.Icon:SetColorTexture(Color.gray:GetRGB())
            end
        end
    end
    do --[[ Blizzard_AuctionHouseAuctionsFrame ]]
        Hook.AuctionHouseAuctionsSummaryLineMixin = {}
        function Hook.AuctionHouseAuctionsSummaryLineMixin:Init(listIndex)
            -- self.Icon._auroraIconBG:SetShown(self.Icon:IsShown())
            if not self.Icon._auroraIconBG then
                Skin.AuctionHouseAuctionsSummaryLineTemplate(self)
                self.Icon._auroraIconBG:SetShown(self.Icon:IsShown())
            else
                self.Icon._auroraIconBG:SetShown(self.Icon:IsShown())
            end
            self.IconBorder:Hide()
        end
    end
end

do --[[ AddOns\Blizzard_AuctionHouseUI.xml ]]
    do --[[ Blizzard_AuctionHouseTableBuilder ]]
        function Skin.AuctionHouseTableCellFavoriteTemplate(Frame)
            local fWidth, fHeight = Frame:GetSize()
            local bWidth, bHeight = Frame.FavoriteButton:GetSize()

            local xOfs, yOfs = (fWidth / 2) - (bWidth / 2), (fHeight / 2) - (bHeight / 2)
            Frame.FavoriteButton:ClearAllPoints()
            Frame.FavoriteButton:SetPoint("TOPRIGHT", _G.Round(xOfs / 2), _G.Round(yOfs / 2))
            --Util.Mixin(Frame.FavoriteButton, Hook.AuctionHouseTableCellFavoriteButtonMixin)

            --Base.SetTexture(Frame.FavoriteButton.NormalTexture, "shapeStar")
            --Base.SetTexture(Frame.FavoriteButton.HighlightTexture, "shapeStar")
            --Frame.FavoriteButton.HighlightTexture:SetColorTexture(Color.gray:GetRGB())
        end
        function Skin.AuctionHouseTableCellItemDisplayTemplate(Frame)
            Frame.Icon._auroraBG = Base.CropIcon(Frame.Icon, Frame)
            Frame.IconBorder:SetAlpha(0)
        end
        function Skin.AuctionHouseTableHeaderStringTemplate(Button)
            Skin.ColumnDisplayButtonShortTemplate(Button)
            Button.Arrow:SetSize(10, 5)
        end
    end
    do --[[ Blizzard_AuctionHouseSharedTemplates ]]
        function Skin.AuctionHouseBackgroundTemplate(Frame)
            Frame.NineSlice.Center = Frame.Background
            Skin.NineSlicePanelTemplate(Frame.NineSlice)
        end
        function Skin.AuctionHouseItemDisplayBaseTemplate(Button)
            Skin.AuctionHouseBackgroundTemplate(Button)
        end
        function Skin.AuctionHouseItemDisplayTemplate(Button)
            Skin.AuctionHouseItemDisplayBaseTemplate(Button)
            Skin.CircularGiantItemButtonTemplate(Button.ItemButton)
        end
        function Skin.AuctionHouseInteractableItemDisplayTemplate(Frame)
            Skin.AuctionHouseItemDisplayBaseTemplate(Frame)
            Skin.GiantItemButtonTemplate(Frame.ItemButton)
        end
        function Skin.AuctionHouseQuantityInputEditBoxTemplate(Frame)
            Skin.LargeInputBoxTemplate(Frame)
        end
        function Skin.AuctionHouseRefreshFrameTemplate(Frame)
            Skin.RefreshButtonTemplate(Frame.RefreshButton)
        end
        function Skin.AuctionHouseBidFrameTemplate(Frame)
            Skin.MoneyInputFrameTemplate(Frame.BidAmount)
            Skin.UIPanelButtonTemplate(Frame.BidButton)
        end
        function Skin.AuctionHouseBuyoutFrameTemplate(Frame)
            Skin.UIPanelButtonTemplate(Frame.BuyoutButton)
        end
    end
    do --[[ Blizzard_AuctionHouseTab ]]
        function Skin.AuctionHouseFrameTabTemplate(Button)
            Skin.PanelTabButtonTemplate(Button)
            Button._auroraTabResize = true
        end
        function Skin.AuctionHouseFrameTopTabTemplate(Button)
            Skin.PanelTabButtonTemplate(Button)
        end
        function Skin.AuctionHouseFrameDisplayModeTabTemplate(Button)
            Skin.AuctionHouseFrameTabTemplate(Button)
        end
    end
    do --[[ Blizzard_AuctionHouseItemList ]]
        function Skin.AuctionHouseItemListLineTemplate(Button)
            Util.SetHighlightColor(Button.SelectedHighlight, 0.5)

            Util.SetHighlightColor(Button.HighlightTexture, 0.5)
        end
        function Skin.AuctionHouseFavoritableLineTemplate(Button)
            Skin.AuctionHouseItemListLineTemplate(Button)
        end
        function Skin.AuctionHouseItemListTemplate(Frame)
            Skin.AuctionHouseBackgroundTemplate(Frame)
            Skin.AuctionHouseRefreshFrameTemplate(Frame.RefreshFrame)
            --Skin.AuctionHouseItemListHeadersTemplate(Frame.HeaderContainer)
            Skin.WowScrollBoxList(Frame.ScrollBox)
            Skin.MinimalScrollBar(Frame.ScrollBar)
        end
    end
    do --[[ Blizzard_AuctionHouseCategoriesList ]]
        function Skin.AuctionCategoryButtonTemplate(Button)
            Skin.FrameTypeButton(Button)

            Button.NormalTexture:Hide()
            Util.SetHighlightColor(Button.HighlightTexture)
            Util.SetHighlightColor(Button.SelectedTexture)
        end
        function Skin.AuctionHouseCategoriesListTemplate(Frame)
            Skin.NineSlicePanelTemplate(Frame.NineSlice)
            Skin.WowScrollBoxList(Frame.ScrollBox)
            Skin.MinimalScrollBar(Frame.ScrollBar)
            Frame.Background:Hide()
        end
    end
    do --[[ Blizzard_AuctionHouseSearchBar ]]
        function Skin.AuctionHouseSearchBoxTemplate(EditBox)
            Skin.SearchBoxTemplate(EditBox)
        end
        function Skin.AuctionHouseFavoritesSearchButtonTemplate(Button)
            Util.Mixin(Button, Hook.AuctionHouseFavoritesSearchButtonMixin)

            Skin.SquareIconButtonTemplate(Button)
            Base.SetTexture(Button.Icon, "shapeStar")
        end
        function Skin.AuctionHouseLevelRangeEditBoxTemplate(EditBox)
            Skin.InputBoxTemplate(EditBox)
        end
        function Skin.AuctionHouseLevelRangeFrameTemplate(Frame)
            Skin.AuctionHouseLevelRangeEditBoxTemplate(Frame.MinLevel)
            Skin.AuctionHouseLevelRangeEditBoxTemplate(Frame.MaxLevel)
        end
        function Skin.AuctionHouseFilterButtonTemplate(Button)
            if Button.Icon then
                Button.Icon:SetSize(5, 10)
                Base.SetTexture(Button.Icon, "arrowRight")
            end
            Skin.DropdownButton(Button)
        end
        function Skin.AuctionHouseFilterDropDownMenuTemplate(Frame)
            Skin.DropdownButton(Frame)
        end
        function Skin.AuctionHouseSearchButtonTemplate(Button)
            Skin.UIPanelButtonTemplate(Button)
        end
        function Skin.AuctionHouseSearchBarTemplate(Frame)
            Skin.AuctionHouseFavoritesSearchButtonTemplate(Frame.FavoritesSearchButton)
            Skin.AuctionHouseSearchBoxTemplate(Frame.SearchBox)
            Skin.AuctionHouseSearchButtonTemplate(Frame.SearchButton)
            Skin.AuctionHouseFilterButtonTemplate(Frame.FilterButton)
        end
    end
    do --[[ Blizzard_AuctionHouseBrowseResultsFrame ]]
        function Skin.AuctionHouseBrowseResultsFrameTemplate(Frame)
            Skin.AuctionHouseItemListTemplate(Frame.ItemList)
        end
    end
    do --[[ Blizzard_AuctionHouseCommoditiesList ]]
        function Skin.AuctionHouseCommoditiesListTemplate(Frame)
            Skin.AuctionHouseItemListTemplate(Frame)
        end
        function Skin.AuctionHouseCommoditiesBuyListTemplate(Frame)
            Skin.AuctionHouseCommoditiesListTemplate(Frame)
        end
        function Skin.AuctionHouseCommoditiesSellListTemplate(Frame)
            Skin.AuctionHouseCommoditiesListTemplate(Frame)
        end
    end
    do --[[ Blizzard_AuctionHouseItemBuyFrame ]]
        function Skin.AuctionHouseItemBuyFrameTemplate(Frame)
            Skin.UIPanelButtonTemplate(Frame.BackButton)
            Skin.AuctionHouseItemDisplayTemplate(Frame.ItemDisplay)

            local nameBG = _G.CreateFrame("Frame", nil, Frame.ItemDisplay)
            nameBG:SetPoint("TOPLEFT", Frame.ItemDisplay.ItemButton, "TOPRIGHT", 0, -3)
            nameBG:SetPoint("BOTTOMRIGHT", -300, 17)
            Base.SetBackdrop(nameBG, Color.frame)

            Skin.AuctionHouseBuyoutFrameTemplate(Frame.BuyoutFrame)
            Skin.AuctionHouseBidFrameTemplate(Frame.BidFrame)
            Skin.AuctionHouseItemListTemplate(Frame.ItemList)
        end
    end
    do --[[ Blizzard_AuctionHouseSellFrame ]]
        function Skin.AuctionHouseSellFrameAlignedControlTemplate(Frame)
        end
        function Skin.AuctionHouseAlignedQuantityInputFrameTemplate(Frame)
            Skin.AuctionHouseSellFrameAlignedControlTemplate(Frame)
            Skin.AuctionHouseQuantityInputEditBoxTemplate(Frame.InputBox)
            Skin.UIPanelButtonTemplate(Frame.MaxButton)
        end
        function Skin.AuctionHouseAlignedPriceInputFrameTemplate(Frame)
            Skin.AuctionHouseSellFrameAlignedControlTemplate(Frame)
            Skin.LargeMoneyInputFrameTemplate(Frame.MoneyInputFrame)
        end
        function Skin.AuctionHouseAlignedDurationDropDownTemplate(Frame)
            Skin.AuctionHouseSellFrameAlignedControlTemplate(Frame)
            Skin.DropdownButton(Frame.Dropdown)
        end
        function Skin.AuctionHouseAlignedPriceDisplayTemplate(Frame)
            Skin.AuctionHouseSellFrameAlignedControlTemplate(Frame)
        end
        function Skin.AuctionHouseSellFrameTemplate(Frame)
            Skin.AuctionHouseBackgroundTemplate(Frame)

            Frame.CreateAuctionTabLeft:Hide()
            Frame.CreateAuctionTabMiddle:Hide()
            Frame.CreateAuctionTabRight:Hide()

            Skin.AuctionHouseInteractableItemDisplayTemplate(Frame.ItemDisplay)
            local _, _, itemheaderframe = Frame.ItemDisplay:GetRegions()
            itemheaderframe:Hide()

            local nameBG = _G.CreateFrame("Frame", nil, Frame.ItemDisplay)
            nameBG:SetPoint("TOPLEFT", Frame.ItemDisplay.ItemButton, "TOPRIGHT", 0, -1)
            nameBG:SetPoint("BOTTOMRIGHT", -12, 10)
            Base.SetBackdrop(nameBG, Color.frame)

            Skin.AuctionHouseAlignedQuantityInputFrameTemplate(Frame.QuantityInput)
            Skin.AuctionHouseAlignedPriceInputFrameTemplate(Frame.PriceInput)
            Skin.AuctionHouseAlignedDurationDropDownTemplate(Frame.Duration)
            Skin.AuctionHouseAlignedPriceDisplayTemplate(Frame.Deposit)
            Skin.UIPanelButtonTemplate(Frame.PostButton)
        end
    end
    do --[[ Blizzard_AuctionHouseCommoditiesSellFrame ]]
        function Skin.AuctionHouseCommoditiesSellFrameTemplate(Frame)
            Skin.AuctionHouseSellFrameTemplate(Frame)
        end
    end
    do --[[ Blizzard_AuctionHouseCommoditiesBuyFrame ]]
        function Skin.AuctionHouseCommoditiesBuyDisplayTemplate(Frame)
            Skin.AuctionHouseBackgroundTemplate(Frame)

            Skin.AuctionHouseItemDisplayTemplate(Frame.ItemDisplay)
            local _, _, itemheaderframe = Frame.ItemDisplay:GetRegions()
            itemheaderframe:Hide()

            local nameBG = _G.CreateFrame("Frame", nil, Frame.ItemDisplay)
            nameBG:SetPoint("TOPLEFT", Frame.ItemDisplay.ItemButton, "TOPRIGHT", 0, -3)
            nameBG:SetPoint("BOTTOMRIGHT", -12, 12)
            Base.SetBackdrop(nameBG, Color.frame)

            Skin.AuctionHouseAlignedQuantityInputFrameTemplate(Frame.QuantityInput)
            --Skin.AuctionHouseAlignedPriceDisplayTemplate(Frame.UnitPrice)
            --Skin.AuctionHouseAlignedPriceDisplayTemplate(Frame.TotalPrice)
            Skin.UIPanelButtonTemplate(Frame.BuyButton)
        end
        function Skin.AuctionHouseCommoditiesBuyFrameTemplate(Frame)
            Skin.UIPanelButtonTemplate(Frame.BackButton)
            Skin.AuctionHouseCommoditiesBuyDisplayTemplate(Frame.BuyDisplay)
            Skin.AuctionHouseCommoditiesBuyListTemplate(Frame.ItemList)
        end
    end
    do --[[ Blizzard_AuctionHouseItemSellFrame ]]
        function Skin.AuctionHouseItemSellFrameTemplate(Frame)
            Skin.AuctionHouseSellFrameTemplate(Frame)
            Skin.UICheckButtonTemplate(Frame.BuyoutModeCheckButton)
            Skin.AuctionHouseAlignedPriceInputFrameTemplate(Frame.SecondaryPriceInput)
        end
    end
    do --[[ Blizzard_AuctionHouseAuctionsFrame ]]
        function Skin.AuctionHouseAuctionsFrameTabTemplate(Button)
            Skin.AuctionHouseFrameTopTabTemplate(Button)
        end
        function Skin.AuctionHouseAuctionsSummaryLineTemplate(Button)
            Button.Icon._auroraIconBG = Base.CropIcon(Button.Icon, Button)
        end
        function Skin.AuctionHouseAuctionsFrameTemplate(Frame)
            Skin.AuctionHouseAuctionsFrameTabTemplate(Frame.AuctionsTab)
            Skin.AuctionHouseAuctionsFrameTabTemplate(Frame.BidsTab)
            Skin.UIPanelButtonTemplate(Frame.CancelAuctionButton)
            Skin.AuctionHouseBuyoutFrameTemplate(Frame.BuyoutFrame)
            Skin.AuctionHouseBidFrameTemplate(Frame.BidFrame)
            Skin.AuctionHouseBidFrameTemplate(Frame.BidFrame)

            Skin.AuctionHouseBackgroundTemplate(Frame.SummaryList)
            Skin.WowScrollBoxList(Frame.SummaryList.ScrollBox)
            Skin.MinimalScrollBar(Frame.SummaryList.ScrollBar)

            Skin.AuctionHouseItemDisplayTemplate(Frame.ItemDisplay)
            Skin.AuctionHouseItemListTemplate(Frame.AllAuctionsList)
            Skin.AuctionHouseItemListTemplate(Frame.BidsList)
            Skin.AuctionHouseItemListTemplate(Frame.ItemList)
            Skin.AuctionHouseCommoditiesListTemplate(Frame.CommoditiesList)
        end
    end
    do --[[ Blizzard_AuctionHouseWoWTokenFrame ]]
        function Skin.DummyAuctionHouseScrollBarTemplate(Slider)
            Skin.MinimalScrollBar(Slider)
        end
        function Skin.BrowseWowTokenResultsTemplate(Frame)
            Skin.AuctionHouseBackgroundTemplate(Frame)

            local GameTimeTutorial = Frame.GameTimeTutorial
            Skin.ButtonFrameTemplate(GameTimeTutorial)
            GameTimeTutorial.Tutorial:ClearAllPoints()
            GameTimeTutorial.Tutorial:SetPoint("TOPLEFT", 0, -private.FRAME_TITLE_HEIGHT)
            GameTimeTutorial.Tutorial:SetPoint("BOTTOMRIGHT", 0, 0)
            Skin.UIPanelGoldButtonTemplate(GameTimeTutorial.RightDisplay.StoreButton)

            Skin.MainHelpPlateButton(Frame.HelpButton)
            Skin.AuctionHouseItemDisplayTemplate(Frame.TokenDisplay)
            local _, _, itemheaderframe = Frame.TokenDisplay:GetRegions()
            itemheaderframe:Hide()

            local nameBG = _G.CreateFrame("Frame", nil, Frame.TokenDisplay)
            nameBG:SetPoint("TOPLEFT", Frame.TokenDisplay.ItemButton, "TOPRIGHT", 0, -3)
            nameBG:SetPoint("BOTTOMRIGHT", -12, 12)
            Base.SetBackdrop(nameBG, Color.frame)

            Skin.UIPanelButtonTemplate(Frame.Buyout)
            Skin.DummyAuctionHouseScrollBarTemplate(Frame.DummyScrollBar)
        end
        function Skin.WoWTokenSellFrameTemplate(Frame)
            Skin.AuctionHouseBackgroundTemplate(Frame)

            Frame.CreateAuctionTabLeft:Hide()
            Frame.CreateAuctionTabMiddle:Hide()
            Frame.CreateAuctionTabRight:Hide()

            Skin.AuctionHouseInteractableItemDisplayTemplate(Frame.ItemDisplay)
            local _, _, itemheaderframe = Frame.ItemDisplay:GetRegions()
            itemheaderframe:Hide()

            local nameBG = _G.CreateFrame("Frame", nil, Frame.ItemDisplay)
            nameBG:SetPoint("TOPLEFT", Frame.ItemDisplay.ItemButton, "TOPRIGHT", 0, -4)
            nameBG:SetPoint("BOTTOMRIGHT", -12, 12)
            Base.SetBackdrop(nameBG, Color.frame)

            Skin.UIPanelButtonTemplate(Frame.PostButton)
            Skin.AuctionHouseBackgroundTemplate(Frame.DummyItemList)
            Skin.DummyAuctionHouseScrollBarTemplate(Frame.DummyItemList.DummyScrollBar)
            Skin.RefreshButtonTemplate(Frame.DummyRefreshButton)
        end
    end
    do --[[ Blizzard_AuctionHouseBuyDialog ]]
        function Skin.AuctionHouseBuyDialogNotificationFrameTemplate(Frame)
        end
        function Skin.AuctionHouseDialogButtonTemplate(Button)
            Skin.UIPanelButtonTemplate(Button)
        end
        function Skin.AuctionHouseBuyDialogTemplate(Frame)
            Skin.DialogBorderDarkTemplate(Frame.Border)
            Skin.AuctionHouseDialogButtonTemplate(Frame.BuyNowButton)
            Skin.AuctionHouseDialogButtonTemplate(Frame.CancelButton)
            Skin.AuctionHouseDialogButtonTemplate(Frame.OkayButton)
            Skin.AuctionHouseBuyDialogNotificationFrameTemplate(Frame.Notification)
        end
    end
end

-- /run AuctionHouseFrame:SetDisplayMode(AuctionHouseFrameDisplayMode.WoWTokenSell)
function private.AddOns.Blizzard_AuctionHouseUI()
    ----====####################====----
    --      Blizzard_AuctionData      --
    ----====####################====----


    ----====#####################====----
    --    Blizzard_AuctionHouseUtil    --
    ----====#####################====----


    ----====############%%%########====----
    -- Blizzard_AuctionHouseTableBuilder --
    ----====############%%%########====----
    Util.Mixin(_G.AuctionHouseTableCellFavoriteButtonMixin, Hook.AuctionHouseTableCellFavoriteButtonMixin)
    Util.Mixin(_G.AuctionHouseTableHeaderStringMixin, Hook.AuctionHouseTableHeaderStringMixin)


    ----====################%%########====----
    -- Blizzard_AuctionHouseSharedTemplates --
    ----====################%%########====----


    ----====####################====----
    --    Blizzard_AuctionHouseTab    --
    ----====####################====----


    ----====#########################====----
    -- Blizzard_AuctionHouseCategoriesList --
    ----====#########################====----
    _G.hooksecurefunc("AuctionHouseFilterButton_SetUp", Hook.AuctionHouseFilterButton_SetUp)


    ----====####################====----
    -- Blizzard_AuctionHouseSearchBar --
    ----====####################====----


    ----====#############################====----
    -- Blizzard_AuctionHouseBrowseResultsFrame --
    ----====#############################====----


    ----====################%%########====----
    -- Blizzard_AuctionHouseCommoditiesList --
    ----====################%%########====----


    ----====############%%%########====----
    -- Blizzard_AuctionHouseItemBuyFrame --
    ----====############%%%########====----


    ----====####################====----
    -- Blizzard_AuctionHouseSellFrame --
    ----====####################====----


    ----====####################%%%########====----
    -- Blizzard_AuctionHouseCommoditiesSellFrame --
    ----====####################%%%########====----


    ----====####################%%########====----
    -- Blizzard_AuctionHouseCommoditiesBuyFrame --
    ----====####################%%########====----


    ----====########################====----
    -- Blizzard_AuctionHouseItemSellFrame --
    ----====########################====----


    ----====########################====----
    -- Blizzard_AuctionHouseAuctionsFrame --
    ----====########################====----
    Util.Mixin(_G.AuctionHouseAuctionsSummaryLineMixin, Hook.AuctionHouseAuctionsSummaryLineMixin)


    ----====########################====----
    -- Blizzard_AuctionHouseWoWTokenFrame --
    ----====########################====----


    ----====####################====----
    -- Blizzard_AuctionHouseBuyDialog --
    ----====####################====----


    ----====####################====----
    -- Blizzard_AuctionHouseMultisell --
    ----====####################====----


    ----====####################====----
    --   Blizzard_AuctionHouseFrame   --
    ----====####################====----
    local AuctionHouseFrame = _G.AuctionHouseFrame
    Skin.PortraitFrameTemplate(AuctionHouseFrame)

    Skin.InsetFrameTemplate(AuctionHouseFrame.MoneyFrameInset)
    Skin.ThinGoldEdgeTemplate(AuctionHouseFrame.MoneyFrameBorder)
    local _, _, _, border = AuctionHouseFrame.MoneyFrameBorder:GetRegions()
    border:Hide()

    Skin.AuctionHouseFrameDisplayModeTabTemplate(AuctionHouseFrame.BuyTab)
    Skin.AuctionHouseFrameDisplayModeTabTemplate(AuctionHouseFrame.SellTab)
    Skin.AuctionHouseFrameDisplayModeTabTemplate(AuctionHouseFrame.AuctionsTab)
    Util.PositionRelative("TOPLEFT", AuctionHouseFrame, "BOTTOMLEFT", 20, -1, 1, "Right", AuctionHouseFrame.Tabs)

    ---------------------
    -- Browsing frames --
    ---------------------
    Skin.AuctionHouseSearchBarTemplate(AuctionHouseFrame.SearchBar)
    Skin.AuctionHouseCategoriesListTemplate(AuctionHouseFrame.CategoriesList)
    Skin.AuctionHouseBrowseResultsFrameTemplate(AuctionHouseFrame.BrowseResultsFrame)
    Skin.BrowseWowTokenResultsTemplate(AuctionHouseFrame.WoWTokenResults)

    ----------------
    -- Buy frames --
    ----------------
    Skin.AuctionHouseCommoditiesBuyFrameTemplate(AuctionHouseFrame.CommoditiesBuyFrame)
    Skin.AuctionHouseItemBuyFrameTemplate(AuctionHouseFrame.ItemBuyFrame)

    -----------------
    -- Sell frames --
    -----------------
    Skin.AuctionHouseItemSellFrameTemplate(AuctionHouseFrame.ItemSellFrame)
    Skin.AuctionHouseItemListTemplate(AuctionHouseFrame.ItemSellList)

    Skin.AuctionHouseCommoditiesSellFrameTemplate(AuctionHouseFrame.CommoditiesSellFrame)
    Skin.AuctionHouseCommoditiesSellListTemplate(AuctionHouseFrame.CommoditiesSellList)

    Skin.WoWTokenSellFrameTemplate(AuctionHouseFrame.WoWTokenSellFrame)

    ---------------------
    -- Auctions frames --
    ---------------------
    Skin.AuctionHouseAuctionsFrameTemplate(AuctionHouseFrame.AuctionsFrame)

    -------------
    -- Dialogs --
    -------------
    Skin.AuctionHouseBuyDialogTemplate(AuctionHouseFrame.BuyDialog)
end
