local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Util = Aurora.Util

do --[[ FrameXML\PVPUITemplates.lua ]]
    local factionIcon = _G.UnitFactionGroup("player") == "Horde" and [[Interface\Icons\UI_Horde_HonorboundMedal]] or [[Interface\Icons\UI_Alliance_7LegionMedal]]

    Hook.PVPConquestRewardMixin = {}
    function Hook.PVPConquestRewardMixin:SetTexture(texture, alpha)
        if not texture then
            self.Icon:SetTexture(factionIcon)
        end
    end
end

do --[[ FrameXML\PVPUITemplates.xml ]]
    function Skin.PVPConquestRewardButton(Button)
        Button.Ring:Hide()
        Base.CropCircularIcon(Button.Icon, Button)
    end
    function Skin.PVPHonorRewardTemplate(Button)
        Base.CropCircularIcon(Button.RewardIcon, Button)
        Button.IconCover:SetAllPoints(Button.RewardIcon)
        Button.RingBorder:Hide()
    end
    function Skin.PVPRatedTierTemplate(Frame)
    end
end

function private.FrameXML.PVPUITemplates()
    ----====####################====----
    --         PVPUITemplates         --
    ----====####################====----
    -- PVPConquestRewardMixin is Mainline-only (modern PVP conquest system)
    if _G.PVPConquestRewardMixin then
        Util.Mixin(_G.PVPConquestRewardMixin, Hook.PVPConquestRewardMixin)
    end

    -------------
    -- Section --
    -------------
end
