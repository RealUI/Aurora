local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

function private.FrameXML.TradeFrame()
    local TradeFrame = _G.TradeFrame
    if not TradeFrame then return end

    -- TradeFrame does NOT inherit ButtonFrameTemplate in TBC — use manual skinning

    -- Hide all frame decoration textures (borders, background art)
    for _, region in next, {TradeFrame:GetRegions()} do
        local regionType = region:GetObjectType()
        if regionType == "Texture" then
            local drawLayer = region:GetDrawLayer()
            if drawLayer == "BORDER" or drawLayer == "ARTWORK" or drawLayer == "BACKGROUND" then
                region:Hide()
            end
        end
    end

    -- Apply Aurora backdrop
    Base.SetBackdrop(TradeFrame, Color.frame, Util.GetFrameAlpha())

    -- Skin close button
    local closeButton = _G.TradeFrameCloseButton or TradeFrame.CloseButton
    if closeButton then
        Skin.UIPanelCloseButton(closeButton)
    end

    -- Hide player portrait
    if _G.TradeFramePlayerPortrait then
        _G.TradeFramePlayerPortrait:Hide()
    end

    -- Hide recipient portrait and border decorations
    if _G.TradeFrameRecipientPortrait then
        _G.TradeFrameRecipientPortrait:Hide()
    end
    if _G.TradeRecipientPortraitFrame then
        _G.TradeRecipientPortraitFrame:Hide()
    end
    if _G.TradeRecipientBotLeftCorner then
        _G.TradeRecipientBotLeftCorner:Hide()
    end
    if _G.TradeRecipientLeftBorder then
        _G.TradeRecipientLeftBorder:Hide()
    end
    if _G.TradeRecipientBG then
        _G.TradeRecipientBG:Hide()
    end

    -- Skin trade and cancel buttons
    if _G.TradeFrameTradeButton then
        Skin.UIPanelButtonTemplate(_G.TradeFrameTradeButton)
    end
    if _G.TradeFrameCancelButton then
        Skin.UIPanelButtonTemplate(_G.TradeFrameCancelButton)
    end

    -- Skin inset frames
    if _G.TradePlayerItemsInset then
        Skin.InsetFrameTemplate(_G.TradePlayerItemsInset)
    end
    if _G.TradePlayerEnchantInset then
        Skin.InsetFrameTemplate(_G.TradePlayerEnchantInset)
    end
    if _G.TradeRecipientItemsInset then
        Skin.InsetFrameTemplate(_G.TradeRecipientItemsInset)
    end
    if _G.TradeRecipientEnchantInset then
        Skin.InsetFrameTemplate(_G.TradeRecipientEnchantInset)
    end
    if _G.TradePlayerInputMoneyInset then
        Skin.InsetFrameTemplate(_G.TradePlayerInputMoneyInset)
    end
    if _G.TradeRecipientMoneyInset then
        Skin.InsetFrameTemplate(_G.TradeRecipientMoneyInset)
    end
    if _G.TradeRecipientMoneyBg then
        Skin.ThinGoldEdgeTemplate(_G.TradeRecipientMoneyBg)
    end

    -- Skin highlight frames (hide their textures)
    local highlightNames = {
        "TradeHighlightPlayer",
        "TradeHighlightRecipient",
        "TradeHighlightPlayerEnchant",
        "TradeHighlightRecipientEnchant",
    }
    for _, name in _G.ipairs(highlightNames) do
        local frame = _G[name]
        if frame then
            local top = _G[name .. "Top"]
            local bottom = _G[name .. "Bottom"]
            local middle = _G[name .. "Middle"]
            if top then top:Hide() end
            if bottom then bottom:Hide() end
            if middle then middle:Hide() end

            Base.SetBackdrop(frame, Color.frame, 0)
            frame:SetBackdropColor(0, 1, 0, 0.3)
            frame:SetBackdropBorderColor(0, 1, 0, 0.9)
        end
    end

    -- Skin trade item slots for both player and recipient
    local users = { "Player", "Recipient" }
    for _, user in _G.ipairs(users) do
        local prefix = "Trade" .. user .. "Item"
        for i = 1, _G.MAX_TRADE_ITEMS or 7 do
            local name = prefix .. i
            local frame = _G[name]
            if not frame then break end

            -- Hide slot texture
            local slotTexture = _G[name .. "SlotTexture"]
            if slotTexture then
                slotTexture:Hide()
            end

            -- Skin item button
            local itemButton = _G[name .. "ItemButton"]
            if itemButton then
                Skin.FrameTypeItemButton(itemButton)
            end

            -- Hide name frame background texture and create Aurora-style name BG
            local nameFrame = _G[name .. "NameFrame"]
            if nameFrame then
                nameFrame:SetAlpha(0)
            end

            -- Create name background if the item button has a backdrop texture
            if itemButton then
                local bg = itemButton:GetBackdropTexture("bg")
                if bg then
                    local nameBG = _G.CreateFrame("Frame", nil, itemButton)
                    nameBG:SetFrameLevel(itemButton:GetFrameLevel())
                    nameBG:SetPoint("TOPLEFT", bg, "TOPRIGHT", 1, 0)
                    nameBG:SetPoint("BOTTOM", bg)
                    nameBG:SetPoint("RIGHT", frame, "RIGHT", -2, 0)
                    Base.SetBackdrop(nameBG, Color.frame)
                    itemButton._auroraNameBG = nameBG
                end
            end
        end
    end
end
