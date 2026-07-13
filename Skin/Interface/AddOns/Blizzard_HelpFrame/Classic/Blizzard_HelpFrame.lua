local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Base, Skin = Aurora.Base, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

--[[ Classic-family GM help (era/TBC/Mists; retail resolves Mainline/).
    Evidence: wow-ui-source-era/Interface/AddOns/Blizzard_HelpFrame/
    HelpFrame.xml — a DefaultPanelTemplate shell around the in-game web
    Browser (content is a web view; nothing to skin inside), the ticket
    status chip, the browser-settings flyout, and the ReportCheatingDialog.
]]

function private.AddOns.Blizzard_HelpFrame()
    local HelpFrame = _G.HelpFrame
    if HelpFrame then
        Skin.DefaultPanelTemplate(HelpFrame)
        if HelpFrame.CloseButton then
            Skin.UIPanelCloseButton(HelpFrame.CloseButton)
        end
    end

    if _G.TicketStatusFrameButton then
        Skin.TooltipBackdropTemplate(_G.TicketStatusFrameButton)
    end

    local settings = _G.BrowserSettingsTooltip
    if settings then
        if Skin.TooltipBorderedFrameTemplate then
            Skin.TooltipBorderedFrameTemplate(settings)
        end
        if settings.CookiesButton then
            Skin.UIPanelButtonTemplate(settings.CookiesButton)
        end
    end

    local report = _G.ReportCheatingDialog
    if report then
        Util.HideFrameTextures(report)
        Skin.FrameTypeFrame(report)

        local comment = report.CommentFrame
        if comment then
            Util.HideFrameTextures(comment)
            Base.SetBackdrop(comment, Color.frame)
            comment:SetBackdropBorderColor(Color.button)
        end

        local name = report:GetName()
        for _, suffix in ipairs({"ReportButton", "CancelButton"}) do
            local button = _G[name..suffix]
            if button then
                Skin.UIPanelButtonTemplate(button)
            end
        end
    end
end
