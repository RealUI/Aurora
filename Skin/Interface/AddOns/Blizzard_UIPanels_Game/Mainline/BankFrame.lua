local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals select

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Util = Aurora.Util
local Color = Aurora.Color

do --[[ FrameXML\BankFrame.xml ]]
    if not private.isRetail then
        function Skin.BankItemButtonGenericTemplate(ItemButton)
            Skin.FrameTypeItemButton(ItemButton)
            ItemButton:SetBackdropOptions({
                bgFile = [[Interface\PaperDoll\UI-Backpack-EmptySlot]],
                tile = false
            })
            ItemButton:SetBackdropColor(1, 1, 1, 0.75)
            Base.CropIcon(ItemButton:GetBackdropTexture("bg"))

            Base.CropIcon(ItemButton.IconQuestTexture)
        end
        function Skin.BankItemButtonBagTemplate(ItemButton)
            Skin.FrameTypeItemButton(ItemButton)
            Base.CropIcon(ItemButton.SlotHighlightTexture)
        end
        Skin.ReagentBankItemButtonGenericTemplate = Skin.BankItemButtonGenericTemplate

        -- BlizzWTF: Why is this not shared with ContainerFrame?
        function Skin.BankAutoSortButtonTemplate(Button)
            Button:SetSize(26, 26)
            Button:SetNormalTexture([[Interface\Icons\INV_Pet_Broom]])
            Button:GetNormalTexture():SetTexCoord(.13, .92, .13, .92)

            Button:SetPushedTexture([[Interface\Icons\INV_Pet_Broom]])
            Button:GetPushedTexture():SetTexCoord(.08, .87, .08, .87)

            local iconBorder = Button:CreateTexture(nil, "BACKGROUND")
            iconBorder:SetPoint("TOPLEFT", Button, -1, 1)
            iconBorder:SetPoint("BOTTOMRIGHT", Button, 1, -1)
            iconBorder:SetColorTexture(0, 0, 0) -- static: not a theme color
        end
    end
end

function private.FrameXML.BankFrame()
    if private.disabled.banks then return end
    if private.isRetail then
        --[[ BankFrame (11.2+) ]]--
        local BankFrame = _G.BankFrame
        Skin.PortraitFrameTemplate(BankFrame)
        if BankFrame.Background then BankFrame.Background:Hide() end

        if BankFrame.BankItemSearchBox then
            Skin.BagSearchBoxTemplate(BankFrame.BankItemSearchBox)
        end

        for _, tab in next, {BankFrame.TabSystem:GetChildren()} do
            Skin.PanelTabButtonTemplate(tab)
        end

        --[[ BankPanel ]]--
        local BankPanel = BankFrame.BankPanel

        if BankPanel.NineSlice then
            BankPanel.NineSlice:SetAlpha(0)
        end

        do
            local bg = BankPanel:CreateTexture(nil, "BACKGROUND", nil, -8)
            bg:SetColorTexture(Color.panelBg:GetRGBA())
            local anchor = BankPanel.NineSlice or BankPanel
            bg:SetPoint("TOPLEFT",     anchor, "TOPLEFT")
            bg:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT")
            BankPanel._auroraBackground = bg
        end

        if BankPanel.EdgeShadows then
            BankPanel.EdgeShadows:DisableDrawLayer("BORDER")
        end

        if BankPanel.AutoSortButton then
            local btn = BankPanel.AutoSortButton
            btn:ClearNormalTexture()
            btn:ClearPushedTexture()
            btn:ClearHighlightTexture()
            Base.SetBackdrop(btn, Color.button)

            local icon = btn:CreateTexture(nil, "ARTWORK")
            icon:SetAtlas("bags-button-autosort-up")
            icon:SetAllPoints()

            local pushedIcon = btn:CreateTexture(nil, "ARTWORK")
            pushedIcon:SetAtlas("bags-button-autosort-down")
            pushedIcon:SetAllPoints()
            pushedIcon:Hide()

            btn:HookScript("OnMouseDown", function() icon:Hide(); pushedIcon:Show() end)
            btn:HookScript("OnMouseUp",   function() pushedIcon:Hide(); icon:Show() end)
        end

        local MoneyFrame = BankPanel.MoneyFrame
        if MoneyFrame then
            if MoneyFrame.Border then
                Skin.ThinGoldEdgeTemplate(MoneyFrame.Border)
            end
            if MoneyFrame.WithdrawButton then
                Skin.UIPanelButtonTemplate(MoneyFrame.WithdrawButton)
            end
            if MoneyFrame.DepositButton then
                Skin.UIPanelButtonTemplate(MoneyFrame.DepositButton)
            end
        end

        local AutoDepositFrame = BankPanel.AutoDepositFrame
        if AutoDepositFrame and AutoDepositFrame.DepositButton then
            Skin.UIPanelButtonTemplate(AutoDepositFrame.DepositButton)
        end

        local PurchasePrompt = BankPanel.PurchasePrompt
        if PurchasePrompt
            and PurchasePrompt.TabCostFrame
            and PurchasePrompt.TabCostFrame.PurchaseButton
        then
            Skin.UIPanelButtonTemplate(PurchasePrompt.TabCostFrame.PurchaseButton)
        end

        local CleanupPopup = _G.BankCleanUpConfirmationPopup
        if CleanupPopup then
            if CleanupPopup.Border then
                CleanupPopup.Border:SetAlpha(0)
            end
            Skin.FrameTypeFrame(CleanupPopup)
            if CleanupPopup.AcceptButton then
                Skin.UIPanelButtonTemplate(CleanupPopup.AcceptButton)
            end
            if CleanupPopup.CancelButton then
                Skin.UIPanelButtonTemplate(CleanupPopup.CancelButton)
            end
            local cbFrame = CleanupPopup.HidePopupCheckbox
            local cb = cbFrame and cbFrame.Checkbox
            if cb then
                cb:ClearNormalTexture()
                cb:ClearPushedTexture()
                Base.SetBackdrop(cb, Color.black, Color.frame.a)
            end
        end

        --[[ Pooled frames — must be skinned after the pool generates them ]]--
        local function SkinBankPanelTabButton(tab)
            if tab.Border then tab.Border:Hide() end
            if not private.IsSkinned(tab) then
                Skin.FrameTypeButton(tab)
                if tab.Icon then Base.CropIcon(tab.Icon, tab) end
                private.SetSkinned(tab, true)
            end
            if tab.SelectedTexture then tab.SelectedTexture:SetShown(false) end
        end

        local function SkinBankItemButton(btn)
            if btn.Background then btn.Background:Hide() end
            if not private.IsSkinned(btn) then
                Skin.FrameTypeItemButton(btn)
                if btn.IconQuestTexture then Base.CropIcon(btn.IconQuestTexture) end
                private.SetSkinned(btn, true)
            end
        end

        BankPanel:HookScript("OnShow", function(self)
            if self.bankTabPool then
                for tab in self.bankTabPool:EnumerateActive() do
                    SkinBankPanelTabButton(tab)
                end
            end
            if self.itemButtonPool then
                for btn in self.itemButtonPool:EnumerateActive() do
                    SkinBankItemButton(btn)
                end
            end
            if self.PurchaseTab and not private.IsSkinned(self.PurchaseTab) then
                SkinBankPanelTabButton(self.PurchaseTab)
            end
        end)

        if _G.BankPanelMixin then
            _G.hooksecurefunc(_G.BankPanelMixin, "RefreshBankTabs", function(self)
                if self.bankTabPool then
                    for tab in self.bankTabPool:EnumerateActive() do
                        SkinBankPanelTabButton(tab)
                    end
                end
            end)
            _G.hooksecurefunc(_G.BankPanelMixin, "GenerateItemSlotsForSelectedTab", function(self)
                if self.itemButtonPool then
                    for btn in self.itemButtonPool:EnumerateActive() do
                        SkinBankItemButton(btn)
                    end
                end
            end)
        end

        if _G.BankPanelItemButtonMixin then
            _G.hooksecurefunc(_G.BankPanelItemButtonMixin, "UpdateBackgroundForBankType", function(self)
                if self.Background then self.Background:Hide() end
            end)
        end

        if _G.BankPanelTabMixin then
            _G.hooksecurefunc(_G.BankPanelTabMixin, "RefreshVisuals", function(self)
                if self.SelectedTexture then self.SelectedTexture:SetShown(false) end
            end)
        end

        return
    end

    --[[ BankFrame (Classic / pre-11.2) ]]--
    local BankFrame = _G.BankFrame
    Skin.PortraitFrameTemplate(BankFrame)
    select(4, BankFrame:GetRegions()):Hide() -- Bank-Background
    Skin.PanelTabButtonTemplate(_G.BankFrameTab1)
    Skin.PanelTabButtonTemplate(_G.BankFrameTab2)
    Skin.PanelTabButtonTemplate(_G.BankFrameTab3)

    Util.PositionRelative("TOPLEFT", BankFrame, "BOTTOMLEFT", 20, -1, 1, "Right", {
        _G.BankFrameTab1,
        _G.BankFrameTab2,
        _G.BankFrameTab3,
    })

    Skin.BagSearchBoxTemplate(_G.BankItemSearchBox)
    Skin.BankAutoSortButtonTemplate(_G.BankItemAutoSortButton)

    local BankSlotsFrame = _G.BankSlotsFrame
    BankSlotsFrame:DisableDrawLayer("BORDER")
    select(9, BankSlotsFrame:GetRegions()):SetDrawLayer("OVERLAY") -- ITEMSLOTTEXT
    select(10, BankSlotsFrame:GetRegions()):SetDrawLayer("OVERLAY") -- BAGSLOTTEXT

    Skin.UIPanelButtonTemplate(_G.BankFramePurchaseButton)
    Skin.ThinGoldEdgeTemplate(_G.BankFrameMoneyFrameBorder)

    --[[ ReagentBankFrame ]]--
    local ReagentBankFrame = _G.ReagentBankFrame
    ReagentBankFrame:DisableDrawLayer("BACKGROUND")
    ReagentBankFrame:DisableDrawLayer("BORDER")
    ReagentBankFrame:DisableDrawLayer("ARTWORK")

    Skin.UIPanelButtonTemplate(ReagentBankFrame.DespositButton)

    ReagentBankFrame.UnlockInfo:DisableDrawLayer("BORDER")
    Skin.UIPanelButtonTemplate(_G.ReagentBankFrameUnlockInfoPurchaseButton) -- BlizzWTF: no parentKey?
end
