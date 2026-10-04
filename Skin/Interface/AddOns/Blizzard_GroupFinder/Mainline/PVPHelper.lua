local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin

-- Aurora role icon keys; anything else keeps Blizzard's atlas.
local ROLE_ICONS = {
    TANK = "iconTANK",
    HEALER = "iconHEALER",
    DAMAGER = "iconDAMAGER",
}

do --[[ FrameXML\PVPHelper.lua ]]
    function Hook.PVPReadyDialog_Display(self, index, displayName, isRated, queueType, gameType, role)
        local icon = role and ROLE_ICONS[role]
        if icon then
            Base.SetTexture(self.roleIcon.texture, icon)
        end
    end
end

--do --[[ FrameXML\PVPHelper.xml ]]
--end

-- FrameXML, not AddOns: "PVPHelper" is a file in Blizzard_GroupFinder, not an
-- addon, so as private.AddOns.PVPHelper (2c5d1d78 until 2026-10-04) it never
-- ran (B158).
function private.FrameXML.PVPHelper()

    --[[ PVPFramePopup ]]--

    --[[ PVPRoleCheckPopup ]]--

    --[[ PVPReadyDialog ]]--
    if private.isRetail then
        _G.hooksecurefunc("PVPReadyDialog_Display", Hook.PVPReadyDialog_Display)

        local PVPReadyDialog = _G.PVPReadyDialog
        Skin.DialogBorderTranslucentTemplate(PVPReadyDialog.Border)
        local bg = PVPReadyDialog.Border:GetBackdropTexture("bg")

        PVPReadyDialog.background:SetAlpha(0.75)
        PVPReadyDialog.background:ClearAllPoints()
        PVPReadyDialog.background:SetPoint("TOPLEFT", bg, 1, -1)
        PVPReadyDialog.background:SetPoint("BOTTOMRIGHT", bg, -1, 68)

        PVPReadyDialog.bottomArt:Hide()

        Skin.UIPanelHideButtonNoScripts(_G.PVPReadyDialogCloseButton)
        -- The hide-button box is inset 11px right / 10px top in the button;
        -- Blizzard's anchor was made for the ornate border, so it hung over
        -- Aurora's. Put the box 4px inside the border backdrop's corner.
        _G.PVPReadyDialogCloseButton:ClearAllPoints()
        _G.PVPReadyDialogCloseButton:SetPoint("TOPRIGHT", bg, "TOPRIGHT", 11 - 4, 10 - 4)
        -- Enter calls AcceptBattlefieldPort(self:GetParent().activeIndex, ...),
        -- which is protected. It reads only activeIndex, which Blizzard writes;
        -- keep the buttons free of addon table writes all the same.
        Skin.TaintSafeUIPanelButtonTemplate(PVPReadyDialog.enterButton)
        Skin.TaintSafeUIPanelButtonTemplate(PVPReadyDialog.leaveButton)

        PVPReadyDialog.roleIcon:SetSize(64, 64)
    end
end
