local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Hook, Skin = Aurora.Hook, Aurora.Skin

do --[[ FrameXML\MovieFrame.lua ]]
    function Hook.MovieFrameCloseDialog_OnShow(self)
        self:SetScale(_G.UIParent:GetScale())
    end
end

--do --[[ FrameXML\MovieFrame.xml ]]
--end

function private.FrameXML.MovieFrame()
    _G.MovieFrame.CloseDialog:HookScript("OnShow", Hook.MovieFrameCloseDialog_OnShow)

    if private.isRetail then
        Skin.DialogBorderTemplate(_G.MovieFrame.CloseDialog.Border)
    else
        Skin.DialogBorderTemplate(_G.MovieFrame.CloseDialog)
    end
    -- 12.0.5: buttons moved into a HorizontalLayoutFrame wrapper (CloseDialog.Buttons)
    local buttons = _G.MovieFrame.CloseDialog.Buttons
    local confirmBtn = buttons and buttons.ConfirmButton or _G.MovieFrame.CloseDialog.ConfirmButton
    local resumeBtn = buttons and buttons.ResumeButton or _G.MovieFrame.CloseDialog.ResumeButton
    if confirmBtn then
        Skin.CinematicDialogButtonTemplate(confirmBtn)
    end
    if resumeBtn then
        Skin.CinematicDialogButtonTemplate(resumeBtn)
    end
end
