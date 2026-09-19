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

    -- Skin.LFGRoleButtonTemplate is registered by the Blizzard_GroupFinder skin,
    -- and Blizzard_GroupFinder does not load on WoW Forever (Camelot ships
    -- Blizzard_GroupFinder_VanillaStyle instead), so the template is absent
    -- there while this file still loads. Skin the role buttons only when it is.
    if Skin.LFGRoleButtonTemplate then
        Skin.LFGRoleButtonTemplate(_G.RolePollPopupRoleButtonTank)
        Skin.LFGRoleButtonTemplate(_G.RolePollPopupRoleButtonHealer)
        Skin.LFGRoleButtonTemplate(_G.RolePollPopupRoleButtonDPS)
    end

    Skin.UIPanelButtonTemplate(_G.RolePollPopupAcceptButton)
end
