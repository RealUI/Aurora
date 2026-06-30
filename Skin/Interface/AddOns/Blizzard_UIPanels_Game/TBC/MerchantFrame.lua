local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals select

--[[ Core ]]
local Aurora = private.Aurora
local Base, Hook, Skin = Aurora.Base, Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

do --[[ FrameXML\MerchantFrame.lua ]]
    local numCurrencies = 0
    function Hook.MerchantFrame_UpdateCurrencies()
        local maxCurrencies = _G.MAX_MERCHANT_CURRENCIES or 6
        for i = numCurrencies + 1, maxCurrencies do
            local button = _G["MerchantToken"..i]
            if button then
                if Skin.BackpackTokenTemplate then
                    Skin.BackpackTokenTemplate(button)
                end
                numCurrencies = numCurrencies + 1
            end
        end
    end
end

do --[[ FrameXML\MerchantFrame.xml ]]
    function Skin.MerchantItemTemplate(Frame)
        if not Frame then return end
        local name = Frame:GetName()
        if not name then return end

        local slotTexture = _G[name.."SlotTexture"]
        if slotTexture then
            slotTexture:Hide()
        end

        local nameFrame = _G[name.."NameFrame"]
        if nameFrame then
            nameFrame:Hide()
        end

        local itemButton = Frame.ItemButton
        if itemButton then
            local bg = _G.CreateFrame("Frame", nil, Frame)
            bg:SetPoint("TOPLEFT", itemButton.icon or itemButton, "TOPRIGHT", 2, 1)
            bg:SetPoint("BOTTOMRIGHT", 0, -4)
            Base.SetBackdrop(bg, Color.frame)

            if Frame.Name then
                Frame.Name:SetParent(bg)
                Frame.Name:SetDrawLayer("OVERLAY")
                Frame.Name:ClearAllPoints()
                Frame.Name:SetPoint("TOPLEFT", bg, 2, -1)
                Frame.Name:SetPoint("BOTTOMRIGHT", bg, 0, 14)
            end

            Skin.FrameTypeItemButton(itemButton)
        end

        local altCurrencyFrame = _G[name.."AltCurrencyFrame"]
        if altCurrencyFrame and Skin.SmallAlternateCurrencyFrameTemplate then
            Skin.SmallAlternateCurrencyFrameTemplate(altCurrencyFrame)
        end
    end
end

function private.FrameXML.MerchantFrame()
    _G.hooksecurefunc("MerchantFrame_UpdateCurrencies", Hook.MerchantFrame_UpdateCurrencies)

    -------------------
    -- MerchantFrame --
    -------------------
    local MerchantFrame = _G.MerchantFrame
    if not MerchantFrame then return end

    Skin.ButtonFrameTemplate(MerchantFrame)

    -- Hide the MerchantFrame's own BACKGROUND portrait texture (separate from the
    -- portrait handled by ButtonFrameTemplate); defined directly in TBC MerchantFrame.xml
    if _G.MerchantFramePortrait then
        _G.MerchantFramePortrait:SetAlpha(0)
    end

    -- Hide bottom border textures
    if _G.MerchantFrameBottomLeftBorder then
        _G.MerchantFrameBottomLeftBorder:SetAlpha(0)
    end
    if _G.MerchantFrameBottomRightBorder then
        _G.MerchantFrameBottomRightBorder:SetAlpha(0)
    end

    -- Skin merchant item buttons (TBC has MERCHANT_ITEMS_PER_PAGE = 10)
    local merchantItemCount = _G.MERCHANT_ITEMS_PER_PAGE or 10
    for i = 1, merchantItemCount do
        local item = _G["MerchantItem"..i]
        if item then
            Skin.MerchantItemTemplate(item)
        end
    end

    -- Skin repair buttons
    local repairAllButton = _G.MerchantRepairAllButton
    if repairAllButton then
        if repairAllButton.ClearPushedTexture then
            repairAllButton:ClearPushedTexture()
        end
        local icon = repairAllButton.Icon or _G.MerchantRepairAllIcon
        if icon then
            Base.CropIcon(icon, repairAllButton)
        end
    end

    local repairItemButton = _G.MerchantRepairItemButton
    if repairItemButton then
        if repairItemButton.ClearPushedTexture then
            repairItemButton:ClearPushedTexture()
        end
        local icon = repairItemButton.Icon
        if icon then
            Base.CropIcon(icon, repairItemButton)
        end
    end

    local guildRepairButton = _G.MerchantGuildBankRepairButton
    if guildRepairButton then
        if guildRepairButton.ClearPushedTexture then
            guildRepairButton:ClearPushedTexture()
        end
        local icon = guildRepairButton.Icon or _G.MerchantGuildBankRepairButtonIcon
        if icon then
            Base.CropIcon(icon, guildRepairButton)
        end
    end

    -- Skin buyback item
    local buyBackItem = _G.MerchantBuyBackItem
    if buyBackItem then
        local name = buyBackItem:GetName()
        if name then
            local slotTexture = _G[name.."SlotTexture"]
            if slotTexture then
                slotTexture:Hide()
            end

            local nameFrame = _G[name.."NameFrame"]
            if nameFrame then
                nameFrame:Hide()
            end

            local itemButton = buyBackItem.ItemButton
            if itemButton then
                local bg = _G.CreateFrame("Frame", nil, buyBackItem)
                bg:SetPoint("TOPLEFT", itemButton.icon or itemButton, "TOPRIGHT", 2, 1)
                bg:SetPoint("BOTTOMRIGHT", 0, -1)
                Base.SetBackdrop(bg, Color.frame)

                if buyBackItem.Name then
                    buyBackItem.Name:SetParent(bg)
                    buyBackItem.Name:SetDrawLayer("OVERLAY")
                    buyBackItem.Name:ClearAllPoints()
                    buyBackItem.Name:SetPoint("TOPLEFT", bg, 2, -1)
                    buyBackItem.Name:SetPoint("BOTTOMRIGHT", bg, 0, 14)
                end

                Skin.FrameTypeItemButton(itemButton)

                local moneyFrame = _G[name.."MoneyFrame"]
                if moneyFrame then
                    moneyFrame:SetPoint("BOTTOMLEFT", bg, 1, 1)
                end
            end
        end
    end

    -- Skin money area
    if _G.MerchantExtraCurrencyInset then
        _G.MerchantExtraCurrencyInset:SetAlpha(0)
    end
    if _G.MerchantExtraCurrencyBg then
        if Skin.ThinGoldEdgeTemplate then
            Skin.ThinGoldEdgeTemplate(_G.MerchantExtraCurrencyBg)
        end
    end
    if _G.MerchantMoneyInset then
        _G.MerchantMoneyInset:Hide()
    end
    if _G.MerchantMoneyBg then
        if Skin.ThinGoldEdgeTemplate then
            Skin.ThinGoldEdgeTemplate(_G.MerchantMoneyBg)
        end
        _G.MerchantMoneyBg:ClearAllPoints()
        _G.MerchantMoneyBg:SetPoint("BOTTOMRIGHT", MerchantFrame, -5, 5)
        _G.MerchantMoneyBg:SetSize(160, 22)
    end
    if _G.MerchantMoneyFrame then
        if Skin.SmallMoneyFrameTemplate then
            Skin.SmallMoneyFrameTemplate(_G.MerchantMoneyFrame)
        end
        _G.MerchantMoneyFrame:SetPoint("BOTTOMRIGHT", _G.MerchantMoneyBg or MerchantFrame, 7, 5)
    end

    -- Skin page navigation buttons
    local prevButton = _G.MerchantPrevPageButton
    if prevButton then
        Skin.FrameTypeButton(prevButton)
        prevButton:SetBackdropOption("offsets", {
            left = 5,
            right = 5,
            top = 5,
            bottom = 5,
        })
    end

    local nextButton = _G.MerchantNextPageButton
    if nextButton then
        Skin.FrameTypeButton(nextButton)
        nextButton:SetBackdropOption("offsets", {
            left = 5,
            right = 5,
            top = 5,
            bottom = 5,
        })
    end

    -- Skin tabs
    local tab1 = _G.MerchantFrameTab1
    if tab1 then
        Skin.PanelTabButtonTemplate(tab1)
    end
    local tab2 = _G.MerchantFrameTab2
    if tab2 then
        Skin.PanelTabButtonTemplate(tab2)
    end
    if tab1 and tab2 then
        Util.PositionRelative("TOPLEFT", MerchantFrame, "BOTTOMLEFT", 20, -1, 1, "Right", {
            tab1,
            tab2,
        })
    end
end
