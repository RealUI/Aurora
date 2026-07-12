local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals CreateFrame

--[[ Core ]]
local Aurora = private.Aurora
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color = Aurora.Color
local Util = Aurora.Util

do --[[ FrameXML\WarCampaignTemplates.lua ]]
    Hook.CampaignCollapseButtonMixin = {}
    function Hook.CampaignCollapseButtonMixin:UpdateCollapsedState(isCollapsed)
        if isCollapsed then
            self:SetNormalTexture("Plus")
        else
            self:SetNormalTexture("Minus")
        end

        self:ClearPushedTexture()
    end
end

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
    function Skin.CampaignHeaderTemplate(Frame)
        Skin.CampaignHeaderDisplayTemplate(Frame)
        Skin.ExpandOrCollapse(Frame.CollapseButton)
        Frame.CollapseButton:SetBackdropOption("offsets", {
            left = 3,
            right = 3,
            top = 3,
            bottom = 3,
        })
        Util.Mixin(Frame.CollapseButton, Hook.CampaignCollapseButtonMixin)
        Frame.CollapseButton:UpdateCollapsedState(Frame:IsCollapsed())
    end
    function Skin.CampaignHeaderMinimalTemplate(Button)
        Skin.ExpandOrCollapse(Button.CollapseButton)
        Button.CollapseButton:SetBackdropOption("offsets", {
            left = 3,
            right = 3,
            top = 3,
            bottom = 3,
        })

        if Button.Background then
            Button.Background:SetAlpha(0)
        end
        if Button.Highlight then
            Button.Highlight:SetColorTexture(1, 1, 1, Color.frame.a) -- static: not a theme color
        end

        Util.Mixin(Button.CollapseButton, Hook.CampaignCollapseButtonMixin)
        Button.CollapseButton:UpdateCollapsedState(Button:IsCollapsed())
    end
end

function private.FrameXML.WarCampaignTemplates()
end
