local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals select next

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color = Aurora.Color

do --[[ FrameXML\HelpFrame.lua ]]
    local selected
    function Hook.HelpFrame_SetSelectedButton(button)
        if selected and selected ~= button then
            selected:UnlockHighlight()
            selected:Enable()
        end

        button:LockHighlight()
        selected = button
    end
end

do --[[ FrameXML\HelpFrame.xml ]]
    function Skin.HelpFrameContainerFrameTemplate(Frame)
        Skin.TooltipBackdropTemplate(Frame)
    end
    function Skin.BrowserTemplate(Browser)
        Browser.BrowserInset:Hide()
        --Skin.InsetFrameTemplate(Browser.BrowserInset)
    end
end

function private.FrameXML.HelpFrame()
    ---------------
    -- HelpFrame --
    ---------------
    local HelpFrame = _G.HelpFrame
    if not HelpFrame then return end

    Skin.DefaultPanelTemplate(HelpFrame)
    if HelpFrame.Browser then
        Skin.BrowserTemplate(HelpFrame.Browser)
        HelpFrame.Browser:SetPoint("TOPLEFT", 1, -private.FRAME_TITLE_HEIGHT)
        HelpFrame.Browser:SetPoint("BOTTOMRIGHT", -1, 1)
    end


    ----------------------------
    -- BrowserSettingsTooltip --
    ----------------------------
    local BrowserSettingsTooltip = _G.BrowserSettingsTooltip
    if BrowserSettingsTooltip then
        Skin.HelpFrameContainerFrameTemplate(BrowserSettingsTooltip)
        if BrowserSettingsTooltip.CookiesButton then
            Skin.UIPanelButtonTemplate(BrowserSettingsTooltip.CookiesButton)
        end
    end


    -----------------------
    -- TicketStatusFrame --
    -----------------------
    if _G.TicketStatusFrameButton then
        Skin.FrameTypeFrame(_G.TicketStatusFrameButton)
    end


    --------------------------
    -- ReportCheatingDialog --
    --------------------------
    local ReportCheatingDialog = _G.ReportCheatingDialog
    if ReportCheatingDialog then
        if ReportCheatingDialog.Border then
            Skin.DialogBorderTemplate(ReportCheatingDialog.Border)
        end
        if ReportCheatingDialog.CommentFrame then
            Base.CreateBackdrop(ReportCheatingDialog.CommentFrame, private.backdrop, {
                bg = _G.ReportCheatingDialogCommentFrameMiddle,

                l = _G.ReportCheatingDialogCommentFrameLeft,
                r = _G.ReportCheatingDialogCommentFrameRight,
                t = _G.ReportCheatingDialogCommentFrameTop,
                b = _G.ReportCheatingDialogCommentFrameBottom,

                tl = _G.ReportCheatingDialogCommentFrameTopLeft,
                tr = _G.ReportCheatingDialogCommentFrameTopRight,
                bl = _G.ReportCheatingDialogCommentFrameBottomLeft,
                br = _G.ReportCheatingDialogCommentFrameBottomRight,

                borderLayer = "BACKGROUND",
                borderSublevel = -7,
            })
            Base.SetBackdrop(ReportCheatingDialog.CommentFrame, Color.frame)
            ReportCheatingDialog.CommentFrame:SetBackdropBorderColor(Color.button)
        end
        if ReportCheatingDialog.reportButton then
            Skin.UIPanelButtonTemplate(ReportCheatingDialog.reportButton)
        end
        if _G.ReportCheatingDialogCancelButton then
            Skin.UIPanelButtonTemplate(_G.ReportCheatingDialogCancelButton)
        end
    end
end
