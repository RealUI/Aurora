local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color = Aurora.Color

do --[[ SharedXML\FloatingChatFrame.lua ]]
    function Hook.FloatingChatFrame_UpdateBackgroundAnchors(self)
        if not self then return end
        local bg = self.Background
        if not bg then return end

        -- Reanchor the corner/edge textures to match the background
        local name = self:GetName()
        if not name then return end

        local tl = _G[name .. "TopLeftTexture"]
        local bl = _G[name .. "BottomLeftTexture"]
        local tr = _G[name .. "TopRightTexture"]
        local br = _G[name .. "BottomRightTexture"]

        if tl then tl:SetPoint("TOPLEFT", bg) end
        if bl then bl:SetPoint("BOTTOMLEFT", bg) end
        if tr then tr:SetPoint("TOPRIGHT", bg) end
        if br then br:SetPoint("BOTTOMRIGHT", bg) end
    end

    function Hook.FCF_SetWindowColor(frame, r, g, b)
        if not frame then return end
        if not frame.SetBackdrop then
            -- Frame hasn't been skinned yet — skin it now
            local name = frame:GetName()
            if name then
                local tab = _G[name .. "Tab"]
                if tab then
                    Skin.ChatTabTemplate(tab)
                end
            end
            Skin.FloatingChatFrameTemplate(frame)
        end

        if frame.SetBackdropColor then
            frame:SetBackdropColor(r, g, b)
            frame:SetBackdropBorderColor(r, g, b)
        end
    end

    function Hook.FCF_CreateMinimizedFrame(chatFrame)
        if not chatFrame then return end
        local name = chatFrame:GetName()
        if not name then return end

        local minFrame = _G[name .. "Minimized"]
        if minFrame then
            Skin.FloatingChatFrameMinimizedTemplate(minFrame)
        end
    end

    function Hook.FCF_OpenTemporaryWindow()
        -- Temporary windows are skinned via FCF_SetWindowColor hook
        -- when Blizzard calls FCF_SetWindowColor on the new frame
    end
end

do --[[ SharedXML\FloatingChatFrame.xml ]]
    function Skin.FloatingBorderedFrame(Frame)
        if not Frame then return end
        local name = Frame:GetName()
        if not name then return end

        -- Hide all the border/background textures from CHAT_FRAME_TEXTURES
        local texturesToHide = {
            "Background",
            "TopLeftTexture", "BottomLeftTexture",
            "TopRightTexture", "BottomRightTexture",
            "LeftTexture", "RightTexture",
            "BottomTexture", "TopTexture",
        }
        for _, suffix in _G.ipairs(texturesToHide) do
            local tex = _G[name .. suffix]
            if tex and tex.SetAlpha then
                tex:SetAlpha(0)
            end
        end

        -- Apply Aurora backdrop
        Base.SetBackdrop(Frame, Color.frame, 0.3)
    end

    function Skin.FloatingChatFrameTemplate(ScrollingMessageFrame)
        if not ScrollingMessageFrame then return end

        -- Apply bordered frame skin (hides Blizzard border textures, adds Aurora backdrop)
        Skin.FloatingBorderedFrame(ScrollingMessageFrame)

        -- Skin the edit box using the shared template from ChatFrame.lua
        local editBox = ScrollingMessageFrame.editBox
        if editBox then
            Skin.ChatFrameEditBoxTemplate(editBox)
        end

        -- Skin the minimize button if present
        local minimizeButton = ScrollingMessageFrame.minimizeButton
        if minimizeButton then
            Skin.FrameTypeButton(minimizeButton)
        end

        -- Update background anchors
        if _G.FloatingChatFrame_UpdateBackgroundAnchors then
            Hook.FloatingChatFrame_UpdateBackgroundAnchors(ScrollingMessageFrame)
        end
    end

    function Skin.FloatingChatFrameMinimizedTemplate(Button)
        if not Button then return end

        -- Hide the minimized frame textures
        if Button.leftTexture then Button.leftTexture:Hide() end
        if Button.rightTexture then Button.rightTexture:Hide() end
        if Button.middleTexture then Button.middleTexture:Hide() end

        -- Hide highlight textures
        if Button.leftHighlightTexture then Button.leftHighlightTexture:Hide() end
        if Button.rightHighlightTexture then Button.rightHighlightTexture:Hide() end
        if Button.middleHighlightTexture then Button.middleHighlightTexture:Hide() end

        -- Apply Aurora frame skin and highlight
        Skin.FrameTypeFrame(Button)
        Base.SetHighlight(Button)
    end
end

function private.SharedXML.FloatingChatFrame()
    if private.disabled.chat then return end

    -- Hook FloatingChatFrame_UpdateBackgroundAnchors if it exists
    if _G.FloatingChatFrame_UpdateBackgroundAnchors then
        _G.hooksecurefunc("FloatingChatFrame_UpdateBackgroundAnchors", Hook.FloatingChatFrame_UpdateBackgroundAnchors)
    end

    -- Hook FCF_SetWindowColor to apply Aurora colors on window color changes
    if _G.FCF_SetWindowColor then
        _G.hooksecurefunc("FCF_SetWindowColor", Hook.FCF_SetWindowColor)
    end

    -- Hook FCF_CreateMinimizedFrame to skin dynamically created minimized frames
    if _G.FCF_CreateMinimizedFrame then
        _G.hooksecurefunc("FCF_CreateMinimizedFrame", Hook.FCF_CreateMinimizedFrame)
    end

    -- Skin all existing chat frame tabs and floating chat frames
    local numFrames = (_G.NUM_CHAT_WINDOWS or 7)
    for i = 1, numFrames do
        local name = "ChatFrame" .. i

        -- Skin the tab
        local tab = _G[name .. "Tab"]
        if tab then
            Skin.ChatTabTemplate(tab)
        end

        -- Skin the floating chat frame
        local frame = _G[name]
        if frame then
            Skin.FloatingChatFrameTemplate(frame)
        end
    end
end
