local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs select

--[[ Core ]]
local Aurora = private.Aurora
local Base, Skin = Aurora.Base, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

--[[ Classic Era MerchantFrame.
    Evidence: wow-ui-source-era/Interface/AddOns/Blizzard_UIPanels_Game/
    Vanilla/MerchantFrame.xml (root L88: inherits ButtonFrameTemplate).
    First ButtonFrameTemplate consumer of the Classic template layer.
    Era deltas vs the retail skin this was adapted from: tabs are
    CharacterFrameTabButtonTemplate, no SellAllJunk/FilterDropdown/
    ExtraCurrency, page buttons are the classic 32x32 arrow style, and the
    money frames are left stock for now (Blizzard_MoneyFrame port pending).
]]

function Skin.MerchantItemTemplate(Frame)
    local name = Frame:GetName()
    _G[name.."SlotTexture"]:Hide()
    _G[name.."NameFrame"]:Hide()

    local bg = _G.CreateFrame("Frame", nil, Frame)
    bg:SetPoint("TOPLEFT", Frame.ItemButton.icon, "TOPRIGHT", 2, 1)
    bg:SetPoint("BOTTOMRIGHT", 0, -4)
    Base.SetBackdrop(bg, Color.frame)

    Frame.Name:SetParent(bg)
    Frame.Name:SetDrawLayer("OVERLAY")
    Frame.Name:ClearAllPoints()
    Frame.Name:SetPoint("TOPLEFT", bg, 2, -1)
    Frame.Name:SetPoint("BOTTOMRIGHT", bg, 0, 14)

    Skin.FrameTypeItemButton(Frame.ItemButton)
end

function private.FrameXML.MerchantFrame()
    Skin.ButtonFrameTemplate(_G.MerchantFrame)

    -- Extra named art on top of the template
    _G.MerchantFramePortrait:SetAlpha(0)
    _G.BuybackBG:SetTexture("")
    _G.MerchantFrameBottomLeftBorder:SetAlpha(0)
    _G.MerchantFrameBottomRightBorder:SetAlpha(0)

    for i = 1, 12 do
        local item = _G["MerchantItem"..i]
        if item then
            Skin.MerchantItemTemplate(item)
        end
    end

    _G.MerchantRepairAllButton:ClearPushedTexture()
    Base.CropIcon(_G.MerchantRepairAllIcon, _G.MerchantRepairAllButton)
    _G.MerchantGuildBankRepairButton:ClearPushedTexture()
    Base.CropIcon(_G.MerchantGuildBankRepairButtonIcon, _G.MerchantGuildBankRepairButton)

    do
        local BuyBackItem = _G.MerchantBuyBackItem
        local name = BuyBackItem:GetName()
        _G[name.."SlotTexture"]:Hide()
        _G[name.."NameFrame"]:Hide()

        local bg = _G.CreateFrame("Frame", nil, BuyBackItem)
        bg:SetPoint("TOPLEFT", BuyBackItem.ItemButton.icon, "TOPRIGHT", 2, 1)
        bg:SetPoint("BOTTOMRIGHT", 0, -1)
        Base.SetBackdrop(bg, Color.frame)

        BuyBackItem.Name:SetParent(bg)
        BuyBackItem.Name:SetDrawLayer("OVERLAY")
        BuyBackItem.Name:ClearAllPoints()
        BuyBackItem.Name:SetPoint("TOPLEFT", bg, 2, -1)
        BuyBackItem.Name:SetPoint("BOTTOMRIGHT", bg, 0, 14)

        Skin.FrameTypeItemButton(BuyBackItem.ItemButton)
    end

    _G.MerchantMoneyInset:Hide()
    Util.HideFrameTextures(_G.MerchantMoneyBg)

    -- Page buttons: Aurora nav-button style (flat box + arrow). Regions are
    -- (label FontString, circle-background Texture) in XML order.
    do
        local label, bg = _G.MerchantPrevPageButton:GetRegions()
        bg:Hide()
        Skin.NavButtonPrevious(_G.MerchantPrevPageButton)
        label:SetPoint("LEFT", _G.MerchantPrevPageButton, "RIGHT", 3, 0)

        label, bg = _G.MerchantNextPageButton:GetRegions()
        bg:Hide()
        Skin.NavButtonNext(_G.MerchantNextPageButton)
        label:SetPoint("RIGHT", _G.MerchantNextPageButton, "LEFT", -3, 0)
    end

    Skin.CharacterFrameTabButtonTemplate(_G.MerchantFrameTab1)
    Skin.CharacterFrameTabButtonTemplate(_G.MerchantFrameTab2)
end
