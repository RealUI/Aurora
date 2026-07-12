local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Util = Aurora.Util

do --[[ AddOns\Blizzard_ItemUpgradeUI.lua ]]
    Hook.ItemUpgradeMixin = {}
    function Hook.ItemUpgradeMixin:UpdateUpgradeItemInfo()
        local UpgradeItemButton = self.UpgradeItemButton
        if not self.upgradeInfo then
            Hook.SetItemButtonQuality(UpgradeItemButton, _G.Enum.ItemQuality.Uncommon)

            local tex = UpgradeItemButton:GetNormalTexture()
            tex:SetAllPoints(UpgradeItemButton.icon)
            Base.CropIcon(tex)
        end

        Base.CropIcon(UpgradeItemButton:GetPushedTexture())
    end
    function Hook.ItemUpgradeMixin:InitDropdown()
        Skin.DropdownButton(self.ItemInfo.Dropdown, 130)
    end
end

do --[[ AddOns\Blizzard_ItemUpgradeUI.xml ]]
    function Skin.ItemUpgradeTooltipTemplate(GameTooltip)
        Skin.SharedTooltipTemplate(GameTooltip)
    end
    function Skin.ItemUpgradePreviewTemplate(GameTooltip)
        Skin.ItemUpgradeTooltipTemplate(GameTooltip)
    end
end

function private.AddOns.Blizzard_ItemUpgradeUI()
    local ItemUpgradeFrame = _G.ItemUpgradeFrame
    Util.Mixin(ItemUpgradeFrame, Hook.ItemUpgradeMixin)

    -- TAINT-SAFE: ItemUpgradeFrame.OnConfirm() calls the protected
    -- C_ItemUpgrade.UpgradeItem().  The old Skin.PortraitFrameTemplate path
    -- wrote BackdropMixin methods + _auroraNineSlice + SetButtonColor/
    -- GetButtonColor directly into the frame table hierarchy, tainting it.
    -- Use the taint-safe version that only calls widget API.
    Skin.TaintSafePortraitFrameTemplate(ItemUpgradeFrame)

    ItemUpgradeFrame.BottomBG:Hide()

    ItemUpgradeFrame.BottomPanel_Flash:Hide()
    ItemUpgradeFrame.IdleGlow:Hide()
    ItemUpgradeFrame.Ring:Hide()

    ItemUpgradeFrame.BottomBGShadow:Hide()
    ItemUpgradeFrame.TopBG:Hide()
    ItemUpgradeFrame.MicaFleckSheen:Hide()

    local UpgradeItemButton = ItemUpgradeFrame.UpgradeItemButton
    Skin.FrameTypeItemButton(UpgradeItemButton)
    Base.CropIcon(UpgradeItemButton.EmptySlotGlow)
    UpgradeItemButton.EmptySlotGlow:SetAllPoints(UpgradeItemButton.icon)
    UpgradeItemButton.ButtonFrame:Hide()

    Skin.ItemUpgradePreviewTemplate(ItemUpgradeFrame.LeftItemPreviewFrame)
    Skin.ItemUpgradePreviewTemplate(ItemUpgradeFrame.RightItemPreviewFrame)

    -- TAINT-SAFE: The UpgradeButton triggers the CONFIRM_UPGRADE_ITEM
    -- static popup which calls ItemUpgradeFrame:OnConfirm() →
    -- C_ItemUpgrade.UpgradeItem() (protected).  Use taint-safe button skin.
    Skin.TaintSafeUIPanelButtonTemplate(ItemUpgradeFrame.UpgradeButton)
    local glow = ItemUpgradeFrame.UpgradeButton.GlowAnim:GetAnimations()
    glow:SetFromAlpha(0.0)
    glow:SetToAlpha(0.2)

    Skin.ThinGoldEdgeTemplate(ItemUpgradeFrame.PlayerCurrenciesBorder)
end
