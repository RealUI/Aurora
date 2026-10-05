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

        for texture in self.texturePool:EnumerateActive() do
            local _, line = texture:GetPoint()
            texture:SetTexture([[Interface\LFGFrame\UI-LFG-SEPARATOR]])
            texture:SetTexCoord(0, 0.6640625, 0, 0.3125)
            texture:SetPoint("BOTTOM", line, 0, -8)
            texture:SetHeight(30)
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
