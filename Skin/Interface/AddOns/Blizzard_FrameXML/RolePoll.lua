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
    -- RolePollPopup may not exist on all Classic flavors
    if not _G.RolePollPopup then return end

    if _G.RolePollPopup.Border then
        Skin.DialogBorderTemplate(_G.RolePollPopup.Border)
    end
    if _G.RolePollPopupCloseButton then
        Skin.UIPanelCloseButton(_G.RolePollPopupCloseButton)
    end
    if _G.RolePollPopupRoleButtonTank then
        Skin.LFGRoleButtonTemplate(_G.RolePollPopupRoleButtonTank)
    end
    if _G.RolePollPopupRoleButtonHealer then
        Skin.LFGRoleButtonTemplate(_G.RolePollPopupRoleButtonHealer)
    end
    if _G.RolePollPopupRoleButtonDPS then
        Skin.LFGRoleButtonTemplate(_G.RolePollPopupRoleButtonDPS)
    end
    if _G.RolePollPopupAcceptButton then
        Skin.UIPanelButtonTemplate(_G.RolePollPopupAcceptButton)
    end
end
