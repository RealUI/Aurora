local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals pairs

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin

--do --[[ FrameXML\RolePoll.lua ]]
--end

do --[[ FrameXML\RolePoll.xml ]]
    function Skin.RolePollRoleButtonTemplate(Button)
        Base.SetTexture(Button:GetNormalTexture(), "icon"..(Button.role or "GUIDE"))
        Skin.UICheckButtonTemplate(Button.checkButton)
        Button.checkButton:SetPoint("BOTTOMLEFT", -4, -4)
    end
end

function private.FrameXML.RolePoll()
    Skin.DialogBorderTemplate(_G.RolePollPopup.Border)
    Skin.UIPanelCloseButton(_G.RolePollPopupCloseButton)
    Skin.LFGRoleButtonTemplate(_G.RolePollPopupRoleButtonTank)
    Skin.LFGRoleButtonTemplate(_G.RolePollPopupRoleButtonHealer)
    Skin.LFGRoleButtonTemplate(_G.RolePollPopupRoleButtonDPS)
    Skin.UIPanelButtonTemplate(_G.RolePollPopupAcceptButton)
end
