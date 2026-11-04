local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

do --[[ AddOns\Blizzard_ItemInteractionUI.lua ]]
    Hook.ItemInteractionMixin = {}
    function Hook.ItemInteractionMixin:UpdateCostFrame()
        local costsMoney = self:CostsGold()
        local costsCurrency = self:CostsCurrency()
        local hasPrice = costsMoney or costsCurrency
        local buttonFrame = self.ButtonFrame
        -- Use Bg directly instead of NineSlice:GetBackdropTexture("bg")
        -- since we no longer install BackdropMixin on the NineSlice.
        local bg = self.Bg

        if not hasPrice then
            buttonFrame.ActionButton:SetPoint("BOTTOM", bg, 0, 5)
        else
            buttonFrame.ActionButton:SetPoint("BOTTOMRIGHT", bg, -5, 5)
        end
    end
end

--do --[[ AddOns\Blizzard_ItemInteractionUI.xml ]]
--end

function private.AddOns.Blizzard_ItemInteractionUI()
    local ItemInteractionFrame = _G.ItemInteractionFrame
    Util.Mixin(ItemInteractionFrame, Hook.ItemInteractionMixin)

    -- TAINT-SAFE: ItemInteractionFrame calls protected functions
    -- C_ItemInteraction.PerformItemInteraction() and InitializeFrame().
    -- The old Skin.PortraitFrameTemplate path tainted the frame hierarchy
    -- via BackdropMixin writes + NineSlicePanelTemplate + FrameTypeButton.
    Skin.TaintSafePortraitFrameTemplate(ItemInteractionFrame)

    -- The hook UpdateCostFrame references NineSlice:GetBackdropTexture("bg")
    -- which requires BackdropMixin.  Since we no longer install BackdropMixin,
    -- use the Bg texture directly as the anchor reference instead.
    local bg = ItemInteractionFrame.Bg
    local titleText = ItemInteractionFrame.TitleContainer
    titleText:ClearAllPoints()
    titleText:SetPoint("TOPLEFT", bg)
    titleText:SetPoint("BOTTOMRIGHT", bg, "TOPRIGHT", 0, -private.FRAME_TITLE_HEIGHT)
    if ItemInteractionFrame.CloseButton then
        ItemInteractionFrame.CloseButton:SetPoint("TOPRIGHT", bg, 5.6, 5)
    end

    do -- ItemSlot
        local ItemSlot = ItemInteractionFrame.ItemSlot
        Base.CreateBackdrop(ItemSlot, {
            bgFile = [[Interface\PaperDoll\UI-Backpack-EmptySlot]],
            tile = false,
            offsets = {
                left = -1,
                right = -1,
                top = -1,
                bottom = -1,
            }
        })
        ItemSlot:SetBackdropColor(1, 1, 1, 1)
        ItemSlot:SetBackdropBorderColor(Color.cyan, 1)
        Base.CropIcon(ItemSlot:GetBackdropTexture("bg"))

        ItemSlot:SetSize(58, 58)
        ItemSlot:ClearAllPoints()
        ItemSlot:SetPoint("TOPLEFT", 143, -97)

        ItemSlot.Icon:ClearAllPoints()
        ItemSlot.Icon:SetPoint("TOPLEFT", 1, -1)
        ItemSlot.Icon:SetPoint("BOTTOMRIGHT", -1, 1)
        Base.CropIcon(ItemSlot.Icon)
        Base.KeepIconCrop(ItemSlot.Icon)

        ItemSlot.GlowOverlay:SetAlpha(0)
    end

    local ButtonFrame = ItemInteractionFrame.ButtonFrame
    -- TAINT-SAFE: ActionButton triggers the protected interaction path
    Skin.TaintSafeUIPanelButtonTemplate(ButtonFrame.ActionButton)
    Skin.ThinGoldEdgeTemplate(ButtonFrame.MoneyFrameEdge)
    ButtonFrame.MoneyFrameEdge:ClearAllPoints()
    ButtonFrame.MoneyFrameEdge:SetPoint("BOTTOMLEFT", bg, 5, 5)
    ButtonFrame.MoneyFrameEdge:SetPoint("TOPRIGHT", ButtonFrame.ActionButton, "TOPLEFT", -5, 0)
    Skin.BackpackTokenTemplate(ButtonFrame.Currency)
    ButtonFrame.Currency:SetPoint("BOTTOMRIGHT", ButtonFrame.MoneyFrameEdge, -9, 4)
    Skin.SmallMoneyFrameTemplate(ButtonFrame.MoneyFrame)
    ButtonFrame.MoneyFrame:SetPoint("BOTTOMRIGHT", ButtonFrame.MoneyFrameEdge, 7, 5)

    ButtonFrame.BlackBorder:SetAlpha(0)
    ButtonFrame.ButtonBorder:Hide()
    ButtonFrame.ButtonBottomBorder:Hide()
end
