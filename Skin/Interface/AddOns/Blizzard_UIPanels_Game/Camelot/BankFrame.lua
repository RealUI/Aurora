local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals next

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color = Aurora.Color

-- Camelot's bank is retail-derived, not vanilla-derived, which the frame-name
-- jaccard in docs/Aurora-Forever-Camelot-Divergence.md §8 missed: it compared
-- only the names Camelot\BankFrame.xml declares itself and scored the file as
-- "own design, closest TBC 0.19". In fact BankFrame inherits BankFrameTemplate
-- and BankPanel inherits BankPanelTemplate, both from
-- Mainline\BankFrameTemplates.xml, which is [AllowLoadGameType mainline] and so
-- loads on Camelot. Everything BankPanelTemplate provides -- AutoSortButton,
-- EdgeShadows, MoneyFrame, NineSlice, PurchasePrompt, PurchaseTab,
-- TabSettingsMenu -- is therefore present here too.
--
-- What Camelot changes:
--   * no TabSystem. Retail's BankFrame.xml declares parentKey="TabSystem";
--     Camelot's does not, and the Mainline skin indexes it unguarded.
--   * page tabs instead: a bankPageTabPool of BankPageTabTemplate, which
--     inherits LargeSideTabButtonTemplate -- the same base as the character
--     panel's mode tabs, so it takes the shared side-tab skin.
--   * its own BagCost / BagText / MoneyDisplay / PurchaseButton on the frame.

function private.FrameXML.BankFrame()
    if private.disabled.banks then return end

    local BankFrame = _G.BankFrame
    if not BankFrame then return end

    Skin.PortraitFrameTemplate(BankFrame)
    if BankFrame.Background then BankFrame.Background:Hide() end

    if BankFrame.BankItemSearchBox then
        Skin.BagSearchBoxTemplate(BankFrame.BankItemSearchBox)
    end

    -- Guarded, unlike the Mainline skin: Camelot has no TabSystem.
    if BankFrame.TabSystem then
        for _, tab in next, {BankFrame.TabSystem:GetChildren()} do
            Skin.PanelTabButtonTemplate(tab)
        end
    end

    if BankFrame.PurchaseButton then
        Skin.UIPanelButtonTemplate(BankFrame.PurchaseButton)
    end

    --[[ BankPanel ]]--
    local BankPanel = BankFrame.BankPanel
    if not BankPanel then return end

    if BankPanel.NineSlice then
        BankPanel.NineSlice:SetAlpha(0)
    end

    do
        local bg = BankPanel:CreateTexture(nil, "BACKGROUND", nil, -8)
        bg:SetColorTexture(Color.panelBg:GetRGBA())
        local anchor = BankPanel.NineSlice or BankPanel
        bg:SetPoint("TOPLEFT", anchor, "TOPLEFT")
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
        btn:HookScript("OnMouseUp", function() pushedIcon:Hide(); icon:Show() end)
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

    local PurchasePrompt = BankPanel.PurchasePrompt
    if PurchasePrompt
        and PurchasePrompt.TabCostFrame
        and PurchasePrompt.TabCostFrame.PurchaseButton
    then
        Skin.UIPanelButtonTemplate(PurchasePrompt.TabCostFrame.PurchaseButton)
    end

    --[[ Pooled frames -- skinned as the pools hand them out ]]--
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

    -- Camelot-only: BankPageTabTemplate is a LargeSideTabButtonTemplate, the
    -- same base the character panel's mode tabs use, so it gets the shared
    -- side-tab skin rather than the BankPanel tab treatment above.
    local function SkinBankPageTab(tab)
        if private.IsSkinned(tab) then return end
        private.SetSkinned(tab, true)
        -- BankPageTabTemplate adds only KeyValues over LargeSideTabButtonTemplate,
        -- so the shared side-tab skin covers it -- icon cropping included.
        Skin.LargeSideTabButtonTemplate(tab)
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

    -- The page tab pool lives on BankFrame, not BankPanel.
    BankFrame:HookScript("OnShow", function(self)
        if self.bankPageTabPool then
            for tab in self.bankPageTabPool:EnumerateActive() do
                SkinBankPageTab(tab)
            end
        end
    end)
end
