local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals select ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Util = Aurora.Util

do --[[ AddOns\Blizzard_AuctionUI.xml ]]
    function Skin.AuctionSortButtonTemplate(Button)
        if not Button then return end
        Skin.FrameTypeButton(Button)
        Button:SetBackdropOption("offsets", {
            left = 1,
            right = 1,
            top = 1,
            bottom = 1,
        })
    end

    function Skin.AuctionTabTemplate(Button)
        if not Button then return end
        Skin.PanelTabButtonTemplate(Button)
    end

    function Skin.BrowseButtonTemplate(Button)
        if not Button then return end
        local name = Button:GetName()
        if not name then return end

        -- Strip row highlight textures
        local highlight = Button:GetHighlightTexture()
        if highlight then
            Util.SetHighlightColor(highlight, 0.5)
        end

        -- Skin the item icon button
        local itemButton = _G[name .. "Item"]
        if itemButton then
            Skin.FrameTypeItemButton(itemButton)
        end
    end

    function Skin.BidButtonTemplate(Button)
        if not Button then return end
        local name = Button:GetName()
        if not name then return end

        local highlight = Button:GetHighlightTexture()
        if highlight then
            Util.SetHighlightColor(highlight, 0.5)
        end

        local itemButton = _G[name .. "Item"]
        if itemButton then
            Skin.FrameTypeItemButton(itemButton)
        end
    end

    function Skin.AuctionsButtonTemplate(Button)
        if not Button then return end
        local name = Button:GetName()
        if not name then return end

        local highlight = Button:GetHighlightTexture()
        if highlight then
            Util.SetHighlightColor(highlight, 0.5)
        end

        local itemButton = _G[name .. "Item"]
        if itemButton then
            Skin.FrameTypeItemButton(itemButton)
        end
    end
end

function private.AddOns.Blizzard_AuctionUI()
    local AuctionFrame = _G.AuctionFrame
    if not AuctionFrame then return end

    ---------------------
    -- Main Frame      --
    ---------------------
    Skin.ButtonFrameTemplate(AuctionFrame)

    -- Hide Blizzard decorative textures
    local texturesToHide = {
        "AuctionFrameTopLeft", "AuctionFrameTop", "AuctionFrameTopRight",
        "AuctionFrameBotLeft", "AuctionFrameBot", "AuctionFrameBotRight",
        "AuctionFrameLeft", "AuctionFrameRight",
    }
    for _, name in _G.ipairs(texturesToHide) do
        if _G[name] then _G[name]:Hide() end
    end

    -- Close button
    if _G.AuctionFrameCloseButton then
        Skin.UIPanelCloseButton(_G.AuctionFrameCloseButton)
    end

    ---------------------
    -- Tabs            --
    ---------------------
    local NUM_AUCTION_TABS = 3
    local tabList = {}
    for i = 1, NUM_AUCTION_TABS do
        local tab = _G["AuctionFrameTab" .. i]
        if tab then
            Skin.AuctionTabTemplate(tab)
            tabList[#tabList + 1] = tab
        end
    end
    if #tabList > 0 then
        Util.PositionRelative("TOPLEFT", AuctionFrame, "BOTTOMLEFT", 20, -1, 1, "Right", tabList)
    end

    ---------------------
    -- Money Frame     --
    ---------------------
    if _G.AuctionFrameMoneyFrame then
        if Skin.SmallMoneyFrameTemplate then
            Skin.SmallMoneyFrameTemplate(_G.AuctionFrameMoneyFrame)
        end
    end

    ---------------------
    -- Filter Buttons  --
    ---------------------
    local NUM_FILTERS_TO_DISPLAY = _G.NUM_FILTERS_TO_DISPLAY or 15
    for i = 1, NUM_FILTERS_TO_DISPLAY do
        local filterButton = _G["AuctionFilterButton" .. i]
        if filterButton then
            Skin.FrameTypeButton(filterButton)
            if filterButton.NormalTexture then
                filterButton.NormalTexture:SetAlpha(0)
            end
            local highlight = filterButton:GetHighlightTexture()
            if highlight then
                Util.SetHighlightColor(highlight)
            end
        end
    end

    -------------------------
    -- Browse Panel        --
    -------------------------
    local BrowseFrame = _G.AuctionFrameBrowse
    if BrowseFrame then
        -- Search box
        local searchBox = _G.BrowseName or _G.BrowseSearchBox
        if searchBox then
            Skin.InputBoxTemplate(searchBox)
        end

        -- Level range inputs
        if _G.BrowseMinLevel then
            Skin.InputBoxTemplate(_G.BrowseMinLevel)
        end
        if _G.BrowseMaxLevel then
            Skin.InputBoxTemplate(_G.BrowseMaxLevel)
        end

        -- Sort header buttons
        local browseSortHeaders = {
            "BrowseQualitySort", "BrowseLevelSort", "BrowseDurationSort",
            "BrowseHighBidderSort", "BrowseCurrentBidSort",
        }
        for _, name in _G.ipairs(browseSortHeaders) do
            if _G[name] then
                Skin.AuctionSortButtonTemplate(_G[name])
            end
        end

        -- Scroll frame
        if _G.BrowseScrollFrame then
            if Skin.FauxScrollFrameTemplate then
                Skin.FauxScrollFrameTemplate(_G.BrowseScrollFrame)
            elseif _G.BrowseScrollFrame.ScrollBar then
                Skin.MinimalScrollBar(_G.BrowseScrollFrame.ScrollBar)
            end
        end

        -- Result item buttons
        local NUM_BROWSE_TO_DISPLAY = _G.NUM_BROWSE_TO_DISPLAY or 8
        for i = 1, NUM_BROWSE_TO_DISPLAY do
            local button = _G["BrowseButton" .. i]
            if button then
                Skin.BrowseButtonTemplate(button)
            end
        end

        -- Action buttons
        if _G.BrowseBidButton then
            Skin.UIPanelButtonTemplate(_G.BrowseBidButton)
        end
        if _G.BrowseBuyoutButton then
            Skin.UIPanelButtonTemplate(_G.BrowseBuyoutButton)
        end
        if _G.BrowseSearchButton then
            Skin.UIPanelButtonTemplate(_G.BrowseSearchButton)
        end
        if _G.BrowseResetButton then
            Skin.UIPanelButtonTemplate(_G.BrowseResetButton)
        end

        -- Navigation buttons
        if _G.BrowsePrevPageButton then
            Skin.FrameTypeButton(_G.BrowsePrevPageButton)
            _G.BrowsePrevPageButton:SetBackdropOption("offsets", {
                left = 5,
                right = 5,
                top = 5,
                bottom = 5,
            })
        end
        if _G.BrowseNextPageButton then
            Skin.FrameTypeButton(_G.BrowseNextPageButton)
            _G.BrowseNextPageButton:SetBackdropOption("offsets", {
                left = 5,
                right = 5,
                top = 5,
                bottom = 5,
            })
        end

        -- Bid price input
        if _G.BrowseBidPrice then
            if Skin.MoneyInputFrameTemplate then
                Skin.MoneyInputFrameTemplate(_G.BrowseBidPrice)
            end
        end

        -- Quality dropdown
        if _G.BrowseDropDown then
            if Skin.DropdownButton then
                Skin.DropdownButton(_G.BrowseDropDown)
            end
        end

        -- "Is Usable" and "Show on Player" checkboxes
        if _G.IsUsableCheckButton then
            Skin.UICheckButtonTemplate(_G.IsUsableCheckButton)
        end
        if _G.ShowOnPlayerCheckButton then
            Skin.UICheckButtonTemplate(_G.ShowOnPlayerCheckButton)
        end
    end

    -------------------------
    -- Bid Panel           --
    -------------------------
    local BidFrame = _G.AuctionFrameBid
    if BidFrame then
        -- Sort header buttons
        local bidSortHeaders = {
            "BidQualitySort", "BidLevelSort", "BidDurationSort",
            "BidBuyoutSort", "BidStatusSort", "BidBidSort",
        }
        for _, name in _G.ipairs(bidSortHeaders) do
            if _G[name] then
                Skin.AuctionSortButtonTemplate(_G[name])
            end
        end

        -- Scroll frame
        if _G.BidScrollFrame then
            if Skin.FauxScrollFrameTemplate then
                Skin.FauxScrollFrameTemplate(_G.BidScrollFrame)
            elseif _G.BidScrollFrame.ScrollBar then
                Skin.MinimalScrollBar(_G.BidScrollFrame.ScrollBar)
            end
        end

        -- Item buttons
        local NUM_BIDS_TO_DISPLAY = _G.NUM_BIDS_TO_DISPLAY or 9
        for i = 1, NUM_BIDS_TO_DISPLAY do
            local button = _G["BidButton" .. i]
            if button then
                Skin.BidButtonTemplate(button)
            end
        end

        -- Action buttons
        if _G.BidBidButton then
            Skin.UIPanelButtonTemplate(_G.BidBidButton)
        end
        if _G.BidBuyoutButton then
            Skin.UIPanelButtonTemplate(_G.BidBuyoutButton)
        end

        -- Bid price input
        if _G.BidBidPrice then
            if Skin.MoneyInputFrameTemplate then
                Skin.MoneyInputFrameTemplate(_G.BidBidPrice)
            end
        end
    end

    -------------------------
    -- Auctions Panel      --
    -------------------------
    local AuctionsFrame = _G.AuctionFrameAuctions
    if AuctionsFrame then
        -- Sort header buttons
        local auctionsSortHeaders = {
            "AuctionsQualitySort", "AuctionsDurationSort",
            "AuctionsHighBidderSort", "AuctionsBidSort",
        }
        for _, name in _G.ipairs(auctionsSortHeaders) do
            if _G[name] then
                Skin.AuctionSortButtonTemplate(_G[name])
            end
        end

        -- Scroll frame
        if _G.AuctionsScrollFrame then
            if Skin.FauxScrollFrameTemplate then
                Skin.FauxScrollFrameTemplate(_G.AuctionsScrollFrame)
            elseif _G.AuctionsScrollFrame.ScrollBar then
                Skin.MinimalScrollBar(_G.AuctionsScrollFrame.ScrollBar)
            end
        end

        -- Auction item buttons
        local NUM_AUCTIONS_TO_DISPLAY = _G.NUM_AUCTIONS_TO_DISPLAY or 9
        for i = 1, NUM_AUCTIONS_TO_DISPLAY do
            local button = _G["AuctionsButton" .. i]
            if button then
                Skin.AuctionsButtonTemplate(button)
            end
        end

        -- Create auction button
        if _G.AuctionsCreateAuctionButton then
            Skin.UIPanelButtonTemplate(_G.AuctionsCreateAuctionButton)
        end
        -- Cancel auction button
        if _G.AuctionsCancelAuctionButton then
            Skin.UIPanelButtonTemplate(_G.AuctionsCancelAuctionButton)
        end

        -- Stack size and num stacks entries
        if _G.AuctionsStackSizeEntry then
            Skin.InputBoxTemplate(_G.AuctionsStackSizeEntry)
        end
        if _G.AuctionsNumStacksEntry then
            Skin.InputBoxTemplate(_G.AuctionsNumStacksEntry)
        end

        -- Duration dropdown
        if _G.AuctionsDurationDropDown or _G.AuctionFrameAuctions.DurationDropDown then
            local dropdown = _G.AuctionsDurationDropDown or _G.AuctionFrameAuctions.DurationDropDown
            if Skin.DropdownButton then
                Skin.DropdownButton(dropdown)
            end
        end

        -- Start price and buyout price money inputs
        if _G.StartPrice then
            if Skin.MoneyInputFrameTemplate then
                Skin.MoneyInputFrameTemplate(_G.StartPrice)
            end
        end
        if _G.BuyoutPrice then
            if Skin.MoneyInputFrameTemplate then
                Skin.MoneyInputFrameTemplate(_G.BuyoutPrice)
            end
        end

        -- Auction item button (the item you're posting)
        local auctionsItemButton = _G.AuctionsItemButton
        if auctionsItemButton then
            Skin.FrameTypeItemButton(auctionsItemButton)
        end
    end
end
