local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin

do --[[ FrameXML\BankFrame.xml ]]
    function Skin.BankItemButtonGenericTemplate(ItemButton)
        if not ItemButton then return end
        if Skin.FrameTypeItemButton then
            Skin.FrameTypeItemButton(ItemButton)
        else
            Skin.FrameTypeButton(ItemButton)
        end
        ItemButton:SetBackdropOptions({
            bgFile = [[Interface\PaperDoll\UI-Backpack-EmptySlot]],
            tile = false
        })
        ItemButton:SetBackdropColor(1, 1, 1, 0.75)
        local bg = ItemButton:GetBackdropTexture("bg")
        if bg then
            Base.CropIcon(bg)
        end
        if ItemButton.IconQuestTexture then
            Base.CropIcon(ItemButton.IconQuestTexture)
        end
    end

    function Skin.BankItemButtonBagTemplate(ItemButton)
        if not ItemButton then return end
        if Skin.FrameTypeItemButton then
            Skin.FrameTypeItemButton(ItemButton)
        else
            Skin.FrameTypeButton(ItemButton)
        end
        if ItemButton.SlotHighlightTexture then
            Base.CropIcon(ItemButton.SlotHighlightTexture)
        end
    end
end

function private.FrameXML.BankFrame()
    if private.disabled.banks then return end

    local BankFrame = _G.BankFrame
    if not BankFrame then return end

    local Color = Aurora.Color
    local Util = Aurora.Util

    -- BankFrame does NOT inherit ButtonFrameTemplate in TBC — use manual skinning
    -- Hide all frame regions (border art, portrait art, background textures)
    for _, region in next, {BankFrame:GetRegions()} do
        local regionType = region:GetObjectType()
        if regionType == "Texture" then
            local drawLayer = region:GetDrawLayer()
            if drawLayer == "BORDER" or drawLayer == "ARTWORK" then
                region:Hide()
            end
        end
    end

    -- Hide portrait texture explicitly (may be a named global)
    if _G.BankPortraitTexture then
        _G.BankPortraitTexture:Hide()
    end

    -- Apply Aurora backdrop AFTER hiding regions
    Base.SetBackdrop(BankFrame, Color.frame, Util.GetFrameAlpha())

    -- Skin close button
    if _G.BankCloseButton then
        Skin.UIPanelCloseButton(_G.BankCloseButton)
    end

    -- Skin bank item slots (28 slots created by BankSlotsFrame_OnLoad)
    local BankSlotsFrame = _G.BankSlotsFrame
    if BankSlotsFrame then
        BankSlotsFrame:DisableDrawLayer("BORDER")

        local NUM_BANKGENERIC_SLOTS = _G.NUM_BANKGENERIC_SLOTS or 28
        for i = 1, NUM_BANKGENERIC_SLOTS do
            local button = BankSlotsFrame["Item" .. i] or _G["BankFrameItem" .. i]
            if button then
                Skin.BankItemButtonGenericTemplate(button)
            end
        end

        -- Skin purchased bag slots (7 bag buttons)
        local NUM_BANKBAGSLOTS = _G.NUM_BANKBAGSLOTS or 7
        for i = 1, NUM_BANKBAGSLOTS do
            local bagButton = BankSlotsFrame["Bag" .. i]
            if bagButton then
                Skin.BankItemButtonBagTemplate(bagButton)
            end
        end
    end

    -- Skin purchase button
    if _G.BankFramePurchaseButton then
        Skin.UIPanelButtonTemplate(_G.BankFramePurchaseButton)
    end
end
