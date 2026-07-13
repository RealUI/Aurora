local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

--[[ Classic-family special popups. Evidence: wow-ui-source-*/Interface/
    AddOns/Blizzard_StaticPopup_Game/Classic/StaticPopupSpecial.xml —
    PlayerReportFrame (BACKDROP_DIALOG_32_32 dialog with a Common-Input
    bordered comment box + Report/Cancel buttons). PetBattleQueueReadyFrame
    is also defined but is dead content on classic (no pet battles) — left
    alone.
]]

function private.FrameXML.Blizzard_StaticPopup_Game_StaticPopupSpecial()
    local PlayerReportFrame = _G.PlayerReportFrame
    if not PlayerReportFrame then return end

    Skin.FrameTypeFrame(PlayerReportFrame)

    -- Comment box: strip the nine Common-Input border pieces BEFORE the
    -- backdrop, then style like an input scroll frame
    local Comment = PlayerReportFrame.Comment
    if Comment then
        Util.HideFrameTextures(Comment)
        Base.SetBackdrop(Comment, Color.frame)
        Comment:SetBackdropBorderColor(Color.button)
        Skin.UIPanelScrollFrameTemplate(Comment.ScrollFrame)
    end

    Skin.UIPanelButtonTemplate(PlayerReportFrame.ReportButton)
    Skin.UIPanelButtonTemplate(PlayerReportFrame.CancelButton)
end
