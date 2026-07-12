local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Util = Aurora.Util

--[[ Classic-family AuctionFrame (era/TBC share this Classic file).
    Evidence: wow-ui-source-era/Interface/AddOns/Blizzard_AuctionUI/Classic/
    Blizzard_AuctionUI.xml (root L3: plain wide frame, unnamed sheet art;
    three panels Browse/Bid/Auctions) and Blizzard_AuctionUITemplates.xml
    (AuctionTabTemplate inherits CharacterFrameTabButtonTemplate; sort
    columns use WhoFrame-ColumnTabs pieces with a kept sort Arrow;
    FauxScrollFrameTemplate lists). First-pass chrome skin — money input
    sub-boxes and row-level polish iterate on in-game screenshots.
]]

-- Column headers: hide the three WhoFrame-ColumnTabs pieces, keep the
-- sort-direction Arrow (it is the NormalTexture).
local function SkinSortButton(Button)
    local name = Button:GetName()
    _G[name.."Left"]:SetAlpha(0)
    _G[name.."Middle"]:SetAlpha(0)
    _G[name.."Right"]:SetAlpha(0)

    local highlight = Button:GetHighlightTexture()
    if highlight then
        highlight:SetBlendMode("BLEND")
        Util.SetHighlightColor(highlight, 0.2)
    end
end

local function SkinListButton(Button)
    local highlight = Button:GetHighlightTexture()
    if highlight then
        highlight:SetBlendMode("BLEND")
        Util.SetHighlightColor(highlight, 0.2)
    end

    local icon = _G[Button:GetName().."ItemIconTexture"]
    if icon then
        Aurora.Base.CropIcon(icon)
    end
end

local sortButtons = {
    -- Browse
    "BrowseQualitySort", "BrowseLevelSort", "BrowseDurationSort",
    "BrowseHighBidderSort", "BrowseCurrentBidSort",
    -- Bid
    "BidQualitySort", "BidLevelSort", "BidDurationSort", "BidBuyoutSort",
    "BidStatusSort", "BidBidSort",
    -- Auctions
    "AuctionsQualitySort", "AuctionsDurationSort", "AuctionsHighBidderSort",
    "AuctionsBidSort",
}

local panelButtons = {
    "BrowseSearchButton", "BrowseResetButton", "BrowseCloseButton",
    "BrowseBidButton", "BrowseBuyoutButton",
    "BidCloseButton", "BidBidButton", "BidBuyoutButton",
    "AuctionsCloseButton", "AuctionsCancelAuctionButton",
    "AuctionsCreateAuctionButton", "AuctionsStackSizeMaxButton",
    "AuctionsNumStacksMaxButton",
}

local scrollFrames = {
    "BrowseFilterScrollFrame", "BrowseScrollFrame", "BidScrollFrame",
    "AuctionsScrollFrame",
}

local radioButtons = {
    "AuctionsShortAuctionButton", "AuctionsMediumAuctionButton",
    "AuctionsLongAuctionButton",
}

function private.AddOns.Blizzard_AuctionUI()
    local AuctionFrame = _G.AuctionFrame

    Util.HideFrameTextures(AuctionFrame)
    Skin.FrameTypeFrame(AuctionFrame)
    -- Wide classic sheet; bounds tuned like the other 384-style frames
    AuctionFrame:SetBackdropOption("offsets", {
        left = 0,
        right = 2,
        top = 0,
        bottom = 26,
    })

    Skin.UIPanelCloseButton(_G.AuctionFrameCloseButton)

    for _, name in ipairs({"AuctionFrameBrowse", "AuctionFrameBid", "AuctionFrameAuctions"}) do
        local panel = _G[name]
        if panel then
            Util.HideFrameTextures(panel)
        end
    end

    local i = 1
    while _G["AuctionFrameTab"..i] do
        Skin.CharacterFrameTabButtonTemplate(_G["AuctionFrameTab"..i])
        i = i + 1
    end

    for _, name in ipairs(sortButtons) do
        local button = _G[name]
        if button then
            SkinSortButton(button)
        end
    end

    for _, name in ipairs(panelButtons) do
        local button = _G[name]
        if button then
            Skin.UIPanelButtonTemplate(button)
        end
    end

    for _, name in ipairs(scrollFrames) do
        local scrollFrame = _G[name]
        if scrollFrame then
            Skin.FauxScrollFrameTemplate(scrollFrame)
        end
    end

    for _, name in ipairs(radioButtons) do
        local button = _G[name]
        if button then
            Skin.UIRadioButtonTemplate(button)
        end
    end

    Skin.InputBoxInstructionsTemplate(_G.BrowseName)
    if _G.BrowseDropdown then
        Skin.DropdownButton(_G.BrowseDropdown)
    end
    if _G.AuctionsStackSizeEntry then
        Skin.FrameTypeEditBox(_G.AuctionsStackSizeEntry)
    end
    if _G.AuctionsNumStacksEntry then
        Skin.FrameTypeEditBox(_G.AuctionsNumStacksEntry)
    end

    -- List rows (created in the panels' OnLoad, so they exist by now)
    for _, prefix in ipairs({"BrowseButton", "BidButton", "AuctionsButton"}) do
        local n = 1
        while _G[prefix..n] do
            SkinListButton(_G[prefix..n])
            n = n + 1
        end
    end

    -- Sell-item slot
    local sellIcon = _G.AuctionsItemButtonIconTexture
    if sellIcon then
        Aurora.Base.CropIcon(sellIcon)
    end
end
