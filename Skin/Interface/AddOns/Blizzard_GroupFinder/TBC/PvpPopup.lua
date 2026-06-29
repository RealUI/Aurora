local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

function private.FrameXML.PvpPopup()
    -----------------------------------------
    -- PVPFramePopup (Wargame challenge popup)
    -----------------------------------------
    local PVPFramePopup = _G.PVPFramePopup
    if PVPFramePopup then
        Base.SetBackdrop(PVPFramePopup, Color.frame, Util.GetFrameAlpha())

        -- Strip decorative border/background textures
        local bg = _G.PVPFramePopupBackground
        if bg then
            bg:Hide()
        end

        local ring = _G.PVPFramePopupRing
        if ring then
            ring:Hide()
        end

        -- Skin accept/decline buttons (inherit UIPanelButtonTemplate)
        local acceptButton = _G.PVPFramePopupAcceptButton
        if acceptButton then
            Skin.UIPanelButtonTemplate(acceptButton)
        end

        local declineButton = _G.PVPFramePopupDeclineButton
        if declineButton then
            Skin.UIPanelButtonTemplate(declineButton)
        end

        -- Skin close button
        if PVPFramePopup.closeButton then
            Skin.UIPanelCloseButton(PVPFramePopup.closeButton)
        end
    end

    -----------------------------------------
    -- PVPReadyDialog (BG/Arena queue popup)
    -----------------------------------------
    local PVPReadyDialog = _G.PVPReadyDialog
    if PVPReadyDialog then
        Base.SetBackdrop(PVPReadyDialog, Color.frame, Util.GetFrameAlpha())

        -- Strip the alert icon decorative texture
        local alertIcon = _G.PVPReadyDialogAlertIcon
        if alertIcon then
            alertIcon:Hide()
        end

        -- Skin enter battle button (inherits StaticPopupButtonTemplate)
        local enterButton = PVPReadyDialog.enterButton or _G.PVPReadyDialogEnterBattleButton
        if enterButton then
            Skin.UIPanelButtonTemplate(enterButton)
        end

        -- Skin hide/decline button (inherits StaticPopupButtonTemplate)
        local hideButton = PVPReadyDialog.hideButton or _G.PVPReadyDialogHideButton
        if hideButton then
            Skin.UIPanelButtonTemplate(hideButton)
        end

        -- Hide the separator line if present
        if PVPReadyDialog.Separator then
            PVPReadyDialog.Separator:Hide()
        end
    end
end
