local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals CreateFrame

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Color = Aurora.Color

do --[[ FrameXML\WarCampaignTemplates.xml ]]
    function Skin.CampaignTooltipTemplate(Frame)
        Skin.FrameTypeFrame(Frame)
        Skin.InternalEmbeddedItemTooltipTemplate(Frame.ItemTooltip)
    end
    function Skin.CampaignHeaderDisplayTemplate(Frame)
        ---@diagnostic disable-next-line: undefined-global
        local clipFrame = CreateFrame("Frame", nil, Frame)
        clipFrame:SetFrameLevel(Frame:GetFrameLevel())
        clipFrame:SetPoint("TOPLEFT", 6, 0)
        clipFrame:SetPoint("TOPRIGHT", -5, 0)
        clipFrame:SetHeight(47)
        clipFrame:SetClipsChildren(true)
        Frame._clipFrame = clipFrame

        local BG = clipFrame:CreateTexture(nil, "BACKGROUND")
        BG:SetAllPoints()
        Frame._auroraBG = BG

        local overlay = clipFrame:CreateTexture(nil, "OVERLAY")
        overlay:SetDesaturated(true)
        overlay:SetAlpha(0.3)
        Frame._auroraOverlay = overlay

        Frame.TopFiligree:Hide()
        --Frame.Text:SetPoint("BOTTOMLEFT", Frame.Background, "LEFT", 43, 0)
        Frame.HighlightTexture:SetAllPoints(clipFrame)
    end
    -- B38: the CollapseButtonTemplate mixin drives its own bare plus/minus
    -- Icon atlas — the legacy Skin.ExpandOrCollapse treatment stacked Aurora's
    -- glyph on top of it, doubling the indicator. Leave the stock icon as the
    -- single expand indicator, matching Skin.QuestLogHeaderTemplate.
    function Skin.CampaignHeaderTemplate(Frame)
        Skin.CampaignHeaderDisplayTemplate(Frame)
    end
    function Skin.CampaignHeaderMinimalTemplate(Button)
        if Button.Background then
            Button.Background:SetAlpha(0)
        end
        if Button.Highlight then
            Button.Highlight:SetColorTexture(1, 1, 1, Color.frame.a) -- static: not a theme color
        end
    end
end

function private.FrameXML.WarCampaignTemplates()
end
