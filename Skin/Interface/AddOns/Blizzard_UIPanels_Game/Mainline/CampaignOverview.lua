local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

do --[[ FrameXML\CampaignOverview.lua ]]
    Hook.CampaignOverviewMixin = {}
    function Hook.CampaignOverviewMixin:SetCampaign(campaignID)
        Skin.CampaignHeaderInPlace(self.Header)
    end
    function Hook.CampaignOverviewMixin:UpdateCampaignLoreText(campaignID, textEntries)
        local campaign, color = self.Header.campaign
        if campaign and Util.uiTextureKits[campaign.uiTextureKit] then
            color = Util.uiTextureKits[campaign.uiTextureKit].color
        else
            color = Color.highlight
        end

        -- Blizzard's lore dividers, tinted in place: no new texture file, size
        -- or anchor (taint audit 2026-10-06, B170 follow-up).
        for texture in self.texturePool:EnumerateActive() do
            texture:SetDesaturated(true)
            texture:SetVertexColor(color:GetRGB())
        end
    end
end

do --[[ FrameXML\CampaignOverview.xml ]]
    function Skin.CampaignOverviewTemplate(Frame)
        Skin.ScrollFrameTemplate(Frame.ScrollFrame)

        Frame.ScrollFrame.TopShadow:Hide()
        Frame.ScrollFrame.BottomShadow:Hide()
        Frame.BG:Hide()

        Util.Mixin(Frame, Hook.CampaignOverviewMixin)
    end
end

function private.FrameXML.CampaignOverview()
    ----====####################====----
    --              CampaignOverview              --
    ----====####################====----

    -------------
    -- Section --
    -------------
end
