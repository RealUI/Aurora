local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs select

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Util = Aurora.Util

--[[ Classic-family player-to-player TradeFrame (era/TBC/Mists share this
    Classic file). Evidence: wow-ui-source-*/Interface/AddOns/
    Blizzard_UIPanels_Game/Classic/TradeFrame.xml (root L153:
    ButtonFrameTemplate with EXTRA recipient chrome — a second portrait ring
    and border tiles named TradeRecipient*). The green accept-highlight
    overlays are deliberately kept (trade-state feedback).
]]

local function SkinTradeItem(Frame)
    Frame.SlotTexture:SetAlpha(0)

    local itemButton = _G[Frame:GetName().."ItemButton"]
    if itemButton then
        Skin.FrameTypeItemButton(itemButton)
    end
end

local tradeInsets = {
    "TradeRecipientItemsInset", "TradeRecipientEnchantInset",
    "TradePlayerItemsInset", "TradePlayerEnchantInset",
    "TradePlayerInputMoneyInset", "TradeRecipientMoneyInset",
}

function private.FrameXML.TradeFrame()
    local TradeFrame = _G.TradeFrame

    Skin.ButtonFrameTemplate(TradeFrame)

    -- Recipient-side chrome (second portrait ring, border tiles, portrait)
    for i = 1, select("#", TradeFrame:GetRegions()) do
        local region = select(i, TradeFrame:GetRegions())
        if region:IsObjectType("Texture") then
            local name = region:GetName()
            if name and name:find("^TradeRecipient") then
                region:SetAlpha(0)
            end
        end
    end

    for _, name in ipairs(tradeInsets) do
        local inset = _G[name]
        if inset then
            Skin.InsetFrameTemplate(inset)
        end
    end

    for i = 1, 7 do
        SkinTradeItem(_G["TradeRecipientItem"..i])
        SkinTradeItem(_G["TradePlayerItem"..i])
    end

    Skin.UIPanelButtonTemplate(_G.TradeFrameTradeButton)
    Skin.UIPanelButtonTemplate(_G.TradeFrameCancelButton)

    -- TradePlayerInputMoneyFrame is NOT skinned: Blizzard forbids it
    -- (Classic/TradeFrame.lua L19 SetForbidden, anti-scam hardening) and any
    -- widget call on it from addon code errors with "bad self".

    Util.HideFrameTextures(_G.TradeRecipientMoneyBg)
end
