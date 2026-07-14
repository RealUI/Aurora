local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin

--[[ Mists (5.5.4) LFG shared dialogs — the queue-pop popups:
    LFGDungeonReadyPopup (ready-status board + the ready dialog with the
    dungeon painting, which is KEPT — content art) and LFGInvitePopup
    (party invite with role selection; role buttons stock — Mainline-only
    skin chain). Evidence: wow-ui-source-classic/Interface/AddOns/
    Blizzard_GroupFinder/Classic/LFGFrame.xml.
]]

function private.FrameXML.LFGFrame()
    -- queue-pop ready board
    local ReadyStatus = _G.LFGDungeonReadyStatus
    if ReadyStatus and ReadyStatus.Border then
        Skin.DialogBorderTemplate(ReadyStatus.Border)
    end

    -- ready dialog: dungeon painting + divider kept
    local ReadyDialog = _G.LFGDungeonReadyDialog
    if ReadyDialog then
        if ReadyDialog.Border then
            Skin.DialogBorderTranslucentTemplate(ReadyDialog.Border)
        end
        if _G.LFGDungeonReadyDialogCloseButton then
            Skin.UIPanelCloseButton(_G.LFGDungeonReadyDialogCloseButton)
        end
        if ReadyDialog.enterButton then
            Skin.UIPanelButtonTemplate(ReadyDialog.enterButton)
        end
        if ReadyDialog.leaveButton then
            Skin.UIPanelButtonTemplate(ReadyDialog.leaveButton)
        end
    end

    -- party invite popup
    local InvitePopup = _G.LFGInvitePopup
    if InvitePopup then
        if InvitePopup.Border then
            Skin.DialogBorderTemplate(InvitePopup.Border)
        end
        if _G.LFGInvitePopupAcceptButton then
            Skin.UIPanelButtonTemplate(_G.LFGInvitePopupAcceptButton)
        end
        if _G.LFGInvitePopupDeclineButton then
            Skin.UIPanelButtonTemplate(_G.LFGInvitePopupDeclineButton)
        end
    end
end
