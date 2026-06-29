local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

-- Guard: Blizzard_StoreUI may not exist in all Classic builds
if not _G.C_AddOns or not _G.C_AddOns.DoesAddOnExist or not _G.C_AddOns.DoesAddOnExist("Blizzard_StoreUI") then return end

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

function private.AddOns.Blizzard_StoreUI()
    local StoreFrame = _G.StoreFrame
    if not StoreFrame then return end

    -- Apply Aurora backdrop to the main store frame
    Base.SetBackdrop(StoreFrame, Color.frame, Util.GetFrameAlpha())

    -- Hide border/background art
    if StoreFrame.BG then
        StoreFrame.BG:Hide()
    end

    -- Skin navigation/category buttons
    if StoreFrame.NavBar then
        local navBar = StoreFrame.NavBar
        if navBar.homeButton then
            Skin.UIPanelButtonTemplate(navBar.homeButton)
        end
    end

    -- Skin category buttons if they exist as a list
    if StoreFrame.CategoryFrames then
        for _, catBtn in _G.ipairs(StoreFrame.CategoryFrames) do
            if catBtn and catBtn.HighlightTexture then
                catBtn.HighlightTexture:SetAlpha(0)
            end
        end
    end

    -- Skin product cards
    if StoreFrame.ProductCards then
        for _, card in _G.ipairs(StoreFrame.ProductCards) do
            if card then
                if card.Border then
                    card.Border:Hide()
                end
                if card.Highlight then
                    card.Highlight:SetAlpha(0)
                end
            end
        end
    end

    -- Skin purchase/buy button
    if StoreFrame.BuyButton then
        Skin.UIPanelButtonTemplate(StoreFrame.BuyButton)
    end

    -- Skin close button
    if StoreFrame.CloseButton then
        Skin.UIPanelCloseButton(StoreFrame.CloseButton)
    elseif _G.StoreFrameCloseButton then
        Skin.UIPanelCloseButton(_G.StoreFrameCloseButton)
    end
end
