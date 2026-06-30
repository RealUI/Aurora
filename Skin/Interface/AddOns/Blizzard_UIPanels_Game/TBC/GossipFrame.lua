local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals select type

--[[ Core ]]
local Aurora = private.Aurora
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

do --[[ FrameXML\GossipFrame.lua ]]
    Hook.GossipSharedQuestButtonMixin = {}
    function Hook.GossipSharedQuestButtonMixin:UpdateTitleForQuest(questID, titleText, isIgnored, isTrivial) -- luacheck: ignore questID
        if isIgnored then
            self:SetFormattedText(private.IGNORED_QUEST_DISPLAY, titleText)
        elseif isTrivial then
            self:SetFormattedText(private.TRIVIAL_QUEST_DISPLAY, titleText)
        else
            self:SetFormattedText(private.NORMAL_QUEST_DISPLAY, titleText)
        end
    end
end

do --[[ FrameXML\GossipFrame.xml ]]
    function Skin.GossipTitleButtonTemplate(Button)
        if not Button then return end
        local highlight = Button:GetHighlightTexture()
        if highlight then
            local r, g, b = Color.highlight:GetRGB()
            highlight:SetColorTexture(r, g, b, 0.2)
        end
    end
    function Skin.GossipTitleActiveQuestButtonTemplate(Button)
        if not Button then return end
        Util.Mixin(Button, Hook.GossipSharedQuestButtonMixin)
        Skin.GossipTitleButtonTemplate(Button)
    end
    function Skin.GossipTitleAvailableQuestButtonTemplate(Button)
        if not Button then return end
        Util.Mixin(Button, Hook.GossipSharedQuestButtonMixin)
        Skin.GossipTitleButtonTemplate(Button)
    end
    function Skin.GossipTitleOptionButtonTemplate(Button)
        if not Button then return end
        Skin.GossipTitleButtonTemplate(Button)
    end
    function Skin.GossipGreetingTextTemplate(Frame) -- luacheck: ignore Frame
    end
end

function private.FrameXML.GossipFrame()
    local GossipFrame = _G.GossipFrame
    if not GossipFrame then return end

    -----------------
    -- GossipFrame --
    -----------------

    -- Apply ButtonFrameTemplate skinning (backdrop, portrait hide, border strip, close button)
    Skin.ButtonFrameTemplate(GossipFrame)

    -- Hide the gossip background texture
    local bg = _G.GossipFrameBg
    if bg then
        bg:Hide()
    end

    -- Hide portrait texture (named global)
    if _G.GossipFramePortrait then
        _G.GossipFramePortrait:SetAlpha(0)
    end

    -- Strip any remaining border textures by name
    local borderNames = {
        "GossipFrameTopLeft", "GossipFrameTopRight",
        "GossipFrameBottomLeft", "GossipFrameBottomRight",
        "GossipFrameTop", "GossipFrameBottom",
        "GossipFrameLeft", "GossipFrameRight",
    }
    for _, name in _G.ipairs(borderNames) do
        local region = _G[name]
        if region and region.Hide then
            region:Hide()
        end
    end

    -- Skin the GreetingPanel
    local GreetingPanel = GossipFrame.GreetingPanel
    if GreetingPanel then
        -- Hide the material textures from GossipFramePanelTemplate
        local name = GreetingPanel:GetName()
        if name then
            local matNames = {
                name .. "MaterialTopLeft", name .. "MaterialTopRight",
                name .. "MaterialBotLeft", name .. "MaterialBotRight",
            }
            for _, matName in _G.ipairs(matNames) do
                local mat = _G[matName]
                if mat then
                    mat:Hide()
                end
            end
        end

        -- Also hide material textures by iterating regions
        for i = 1, GreetingPanel:GetNumRegions() do
            local region = select(i, GreetingPanel:GetRegions())
            if region and region.GetObjectType and region:GetObjectType() == "Texture" then
                local drawLayer = region:GetDrawLayer()
                if drawLayer == "BORDER" then
                    region:Hide()
                end
            end
        end

        -- Skin goodbye button
        local GoodbyeButton = GreetingPanel.GoodbyeButton
        if GoodbyeButton then
            Skin.UIPanelButtonTemplate(GoodbyeButton)
        end

        -- Skin the scroll box (hide any background art)
        local ScrollBox = GreetingPanel.ScrollBox
        if ScrollBox then
            -- Position within the backdrop area
            local backdrop = GossipFrame:GetBackdropTexture("bg")
            if backdrop then
                ScrollBox:SetPoint("TOPLEFT", backdrop, 4, -(private.FRAME_TITLE_HEIGHT + 5))
                ScrollBox:SetPoint("BOTTOMRIGHT", backdrop, -23, 29)
            end
        end

        -- Skin the scroll bar (trim scroll bar)
        local ScrollBar = GreetingPanel.ScrollBar
        if ScrollBar then
            -- Hide scroll bar track background textures if present
            if ScrollBar.Background then
                ScrollBar.Background:Hide()
            end
            if ScrollBar.Track and ScrollBar.Track.Background then
                ScrollBar.Track.Background:Hide()
            end
        end
    end

    -- Skin close button (in case ButtonFrameTemplate didn't catch it)
    local closeButton = _G.GossipFrameCloseButton or GossipFrame.CloseButton
    if closeButton then
        Skin.UIPanelCloseButton(closeButton)
    end

    -- Skin the NPC name frame text background
    local NameFrame = GossipFrame.NameFrame
    if NameFrame then
        for i = 1, NameFrame:GetNumRegions() do
            local region = select(i, NameFrame:GetRegions())
            if region and region.GetObjectType and region:GetObjectType() == "Texture" then
                region:Hide()
            end
        end
    end

    -- Skin FriendshipStatusBar background if present
    local FriendshipStatusBar = GossipFrame.FriendshipStatusBar
    if FriendshipStatusBar then
        if FriendshipStatusBar.Background then
            FriendshipStatusBar.Background:Hide()
        end
    end
end
