local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals pairs

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin

do --[[ FrameXML\RolePoll.lua ]]
    -- RolePollPopupRoleButton_Enable/_Disable call SetNormalAtlas on every
    -- show, which put Blizzard's role circle back under Aurora's tint and
    -- round mask (a coloured tile with a big glossy circle). Re-apply the
    -- Aurora icon after both; desaturate it when the role is unavailable.
    local ROLE_ICONS = {}
    local function RefreshRoleIcon(button, disabled)
        local enum = _G.Enum and _G.Enum.LFGRole
        if enum and not ROLE_ICONS[enum.Tank] then
            ROLE_ICONS[enum.Tank] = "iconTANK"
            ROLE_ICONS[enum.Healer] = "iconHEALER"
            ROLE_ICONS[enum.Damage] = "iconDAMAGER"
        end
        local icon = ROLE_ICONS[button.role]
        local texture = button:GetNormalTexture()
        if icon and texture then
            Base.SetTexture(texture, icon)
            texture:SetDesaturated(disabled)
        end
    end
    function Hook.RolePollPopupRoleButton_Enable(button)
        RefreshRoleIcon(button, false)
    end
    function Hook.RolePollPopupRoleButton_Disable(button)
        RefreshRoleIcon(button, true)
    end
end

do --[[ FrameXML\RolePoll.xml ]]
    function Skin.RolePollRoleButtonTemplate(Button)
        Base.SetTexture(Button:GetNormalTexture(), "icon"..(Button.role or "GUIDE"))
        Skin.UICheckButtonTemplate(Button.checkButton)
        Button.checkButton:SetPoint("BOTTOMLEFT", -4, -4)
    end
end

function private.FrameXML.RolePoll()
    _G.hooksecurefunc("RolePollPopupRoleButton_Enable", Hook.RolePollPopupRoleButton_Enable)
    _G.hooksecurefunc("RolePollPopupRoleButton_Disable", Hook.RolePollPopupRoleButton_Disable)

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
