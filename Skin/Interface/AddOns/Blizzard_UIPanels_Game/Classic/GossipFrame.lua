local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals select ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

--[[ Classic-family GossipFrame (era/TBC/Mists).
    Evidence: wow-ui-source-*/Interface/AddOns/Blizzard_UIPanels_Game/
    Classic/GossipFrame.xml (root L34: ButtonFrameTemplate) and
    Shared/GossipFrameShared.lua. Modern pooled ScrollBox rows
    (GossipSharedTitleButtonMixin); the parchment is the named
    GossipFrameBg texture (the panel's Material* textures are never
    assigned on classic). Title buttons use the virtual QuestFontLeft
    style and era's *_QUEST_DISPLAY formats are plain "%s", so quest
    titles are forced white via inline escapes in the mixin hook and
    option rows via fontstring color (see the QuestFrame lessons).
]]

do --[[ Shared\GossipFrameShared.lua ]]
    local whiteFormat = "|c"..Color.white.colorStr.."%s|r"
    local grayFormat = "|c"..Color.grayLight.colorStr.."%s|r"

    Hook.GossipSharedQuestButtonMixin = {}
    function Hook.GossipSharedQuestButtonMixin:UpdateTitleForQuest(questID, titleText, isIgnored, isTrivial)
        if isIgnored or isTrivial then
            self:SetFormattedText(grayFormat, titleText)
        else
            self:SetFormattedText(whiteFormat, titleText)
        end
    end
end

do --[[ Classic\GossipFrame.xml ]]
    function Skin.GossipTitleButtonTemplate(Button)
        local highlight = Button:GetHighlightTexture()
        highlight:SetBlendMode("BLEND")
        Util.SetHighlightColor(highlight, 0.2)

        local text = Button:GetFontString()
        if text then
            text:SetTextColor(Color.white:GetRGB())
        end
    end
end

local function GossipScrollBoxCallback(owner, frame)
    if private.IsSkinned(frame) then return end
    private.SetSkinned(frame, true)

    if frame:IsObjectType("Button") then
        Skin.GossipTitleButtonTemplate(frame)
    end
end

function private.FrameXML.GossipFrame()
    local GossipFrame = _G.GossipFrame

    Skin.ButtonFrameTemplate(GossipFrame)

    -- TWO textures are named "GossipFrameBg": the ButtonFrameTemplate's Bg
    -- (handled by the template skin) and the frame's own QuestBG parchment.
    -- The _G lookup resolves to the wrong one, so hide by name match.
    -- Aurora's backdrop pieces are unnamed and unaffected.
    for i = 1, select("#", GossipFrame:GetRegions()) do
        local region = select(i, GossipFrame:GetRegions())
        if region:IsObjectType("Texture") and region:GetName() == "GossipFrameBg" then
            region:SetTexture("")
        end
    end

    -- Each CreateFromMixins derivation COPIES UpdateTitleForQuest before we
    -- can hook its source table, so every layer must be hooked separately.
    -- Era templates bind the base mixin; anniversary derives TWICE and its
    -- templates bind Gossip(Available|Active)QuestButtonMixin from
    -- Blizzard's Classic\GossipFrame.lua.
    for _, mixinName in ipairs({"GossipSharedQuestButtonMixin", "GossipSharedAvailableQuestButtonMixin", "GossipSharedActiveQuestButtonMixin", "GossipAvailableQuestButtonMixin", "GossipActiveQuestButtonMixin"}) do
        local mixin = _G[mixinName]
        if mixin and mixin.UpdateTitleForQuest then
            _G.hooksecurefunc(mixin, "UpdateTitleForQuest",
                Hook.GossipSharedQuestButtonMixin.UpdateTitleForQuest)
        end
    end

    local GreetingPanel = GossipFrame.GreetingPanel
    Skin.UIPanelButtonTemplate(GreetingPanel.GoodbyeButton)
    Skin.WowScrollBoxList(GreetingPanel.ScrollBox)
    Skin.WowTrimScrollBar(GreetingPanel.ScrollBar)

    _G.ScrollUtil.AddAcquiredFrameCallback(GreetingPanel.ScrollBox, GossipScrollBoxCallback, GossipFrame, true)
end
