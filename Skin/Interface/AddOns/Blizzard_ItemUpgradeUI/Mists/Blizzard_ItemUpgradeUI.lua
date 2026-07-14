local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Base, Skin = Aurora.Base, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

--[[ Mists (5.5.4) item upgrade window — the ReforgingUI's modernized
    sibling: same EtherealFrameTemplate chrome and body tints, but with
    parentKeys throughout (MarbleBg/Lines/ReceiptBG/HorzBar, keyed
    ItemButton pieces). Same treatment: alpha-sweep chrome, restore
    content/state textures, flatten the item slot, MagicButton.
    Evidence: wow-ui-source-classic/Interface/AddOns/
    Blizzard_ItemUpgradeUI/Mists/Blizzard_ItemUpgradeUI.xml.
]]

function private.AddOns.Blizzard_ItemUpgradeUI()
    local ItemUpgradeFrame = _G.ItemUpgradeFrame
    if not ItemUpgradeFrame then return end

    -- alpha-sweeps marble/purple/EtherealLines + template chrome
    Skin.EtherealFrameTemplate(ItemUpgradeFrame)

    -- content/state textures that must survive the sweep
    for _, key in ipairs({"ReceiptBG", "MissingFadeOut", "HorzBar"}) do
        if ItemUpgradeFrame[key] then
            ItemUpgradeFrame[key]:SetAlpha(1)
        end
    end

    local itemButton = ItemUpgradeFrame.ItemButton
    if itemButton then
        for _, key in ipairs({"Frame", "Grabber", "TextFrame", "TextGrabber"}) do
            if itemButton[key] then
                itemButton[key]:SetAlpha(0)
            end
        end
        Base.SetBackdrop(itemButton, Color.frame, Color.frame.a)
        if itemButton.IconTexture then
            Base.CropIcon(itemButton.IconTexture)
        end
        local pushed = itemButton:GetPushedTexture()
        if pushed then
            Base.CropIcon(pushed)
        end
        local highlight = itemButton:GetHighlightTexture()
        if highlight then
            local r, g, b = Color.highlight:GetRGB()
            highlight:SetBlendMode("BLEND")
            highlight:SetColorTexture(r, g, b, 0.2)
        end
    end

    -- bottom button bar: black strip + inner/bottom tile borders
    if ItemUpgradeFrame.ButtonFrame then
        Util.HideFrameTextures(ItemUpgradeFrame.ButtonFrame)
    end
    if _G.ItemUpgradeFrameMoneyFrame then
        Util.HideFrameTextures(_G.ItemUpgradeFrameMoneyFrame)
    end
    if _G.ItemUpgradeFrameUpgradeButton then
        Skin.MagicButtonTemplate(_G.ItemUpgradeFrameUpgradeButton)
    end
end
