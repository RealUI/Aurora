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
        local bg, tl, bl, tr, br = self:GetRegions()
        tl:SetPoint("TOPLEFT", bg)
        bl:SetPoint("BOTTOMLEFT", bg)
        tr:SetPoint("TOPRIGHT", bg)
        br:SetPoint("BOTTOMRIGHT", bg)
    end
    local maxTempIndex = _G.C_ChatInfo.GetNumReservedChatWindows() + 1
    function Hook.FCF_OpenTemporaryWindow(chatType, chatTarget, sourceChatFrame, selectWindow)
        local name = "ChatFrame"..maxTempIndex
        if _G[name] then
            maxTempIndex = maxTempIndex + 1
        end
    end
    function Hook.FCF_SetWindowColor(frame, r, g, b, doNotSave)
        if not frame.SetBackdrop then
            Skin.ChatTabTemplate(_G["ChatFrame"..frame:GetID().."Tab"])
            Skin.FloatingChatFrameTemplate(frame)
        end

        frame:SetBackdropColor(r, g, b)
        frame:SetBackdropBorderColor(r, g, b)

        if private.isRetail then
            frame.buttonFrame:SetBackdropColor(r, g, b)
            frame.buttonFrame:SetBackdropBorderColor(r, g, b)
        end
    end
    function Hook.FCF_SetButtonSide(chatFrame, buttonSide, forceUpdate)
        if buttonSide == "left" then
            chatFrame.buttonFrame:SetPoint("TOPRIGHT", chatFrame.Background, "TOPLEFT", 0, 0)
            chatFrame.buttonFrame:SetPoint("BOTTOMRIGHT", chatFrame.Background, "BOTTOMLEFT", 0, 0)
        elseif buttonSide == "right" then
            chatFrame.buttonFrame:SetPoint("TOPLEFT", chatFrame.Background, "TOPRIGHT", 0, 0)
            chatFrame.buttonFrame:SetPoint("BOTTOMLEFT", chatFrame.Background, "BOTTOMRIGHT", 0, 0)
        end
    end
    function Hook.FCF_CreateMinimizedFrame(chatFrame)
        local minFrame = _G[chatFrame:GetName().."Minimized"]
        Skin.FloatingChatFrameMinimizedTemplate(minFrame)
    end
end

do --[[ SharedXML\FloatingChatFrame.xml ]]
    function Skin.FloatingBorderedFrame(Frame)
        local bg, tl, bl, tr, br, l, r, b, t = Frame:GetRegions()
        Base.CreateBackdrop(Frame, private.backdrop, {
            bg = bg,

            l = l,
            r = r,
            t = t,
            b = b,

            tl = tl,
            tr = tr,
            bl = bl,
            br = br,

            borderLayer = "BACKGROUND",
            borderSublevel = -7,
        })
        Base.SetBackdrop(Frame, Color.frame, 0.3)
    end
    function Skin.ChatTabArtTemplate(Button)
        if private.isRetail then
            Button.Left:SetAlpha(0)
            Button.Right:SetAlpha(0)
            Button.Middle:SetAlpha(0)

            Button.ActiveLeft:SetAlpha(0)
            Button.ActiveMiddle:SetAlpha(0)
            Button.ActiveRight:SetAlpha(0)

            Button.HighlightLeft:SetAlpha(0)
            Button.HighlightMiddle:SetAlpha(0)
            Button.HighlightRight:SetAlpha(0)
        else
            Button.leftTexture:SetAlpha(0)
            Button.middleTexture:SetAlpha(0)
            Button.rightTexture:SetAlpha(0)

            Button.leftSelectedTexture:SetAlpha(0)
            Button.middleSelectedTexture:SetAlpha(0)
            Button.rightSelectedTexture:SetAlpha(0)

            Button.leftHighlightTexture:SetAlpha(0)
            Button.middleHighlightTexture:SetAlpha(0)
            Button.rightHighlightTexture:SetAlpha(0)
        end
    end
    function Skin.ChatTabTemplate(Button)
        Skin.ChatTabArtTemplate(Button)
        Button:SetHighlightFontObject("GameFontHighlightSmall")
    end
    function Skin.FloatingChatFrameTemplate(ScrollingMessageFrame)
        Skin.ChatFrameTemplate(ScrollingMessageFrame)
        Skin.FloatingBorderedFrame(ScrollingMessageFrame)

        local buttonFrame = ScrollingMessageFrame.buttonFrame
        if private.isRetail then
            Skin.FloatingBorderedFrame(buttonFrame)
        end

        local minimizeButton = buttonFrame.minimizeButton
        Skin.ChatFrameButton(minimizeButton)
        local bg = minimizeButton:GetBackdropTexture("bg")
        minimizeButton:SetPoint("TOP", buttonFrame, 0, -3)
        local line = minimizeButton:CreateTexture(nil, "ARTWORK")
        line:SetPoint("TOPLEFT", bg, "BOTTOMLEFT", 3, 6)
        line:SetPoint("BOTTOMRIGHT", bg, -3, 3)
        line:SetColorTexture(1, 1, 1) -- static: not a theme color

        --[[
        local bottomButton = ScrollingMessageFrame.ScrollToBottomButton
        bottomButton:SetPoint("BOTTOMRIGHT", ScrollingMessageFrame.ResizeButton, "TOPRIGHT", -5, 0)
        Skin.ChatFrameButton(bottomButton)
        bg = bottomButton:GetBackdropTexture("bg")
        local arrow = bottomButton:CreateTexture(nil, "ARTWORK")
        arrow:SetPoint("TOPLEFT", bg, 3, -3)
        arrow:SetPoint("BOTTOMRIGHT", bg, -3, 5)
        Base.SetTexture(arrow, "arrowDown")

        local bottom = bottomButton:CreateTexture(nil, "ARTWORK")
        bottom:SetPoint("TOPLEFT", bg, "BOTTOMLEFT", 3, 5)
        bottom:SetPoint("BOTTOMRIGHT", bg, -3, 3)
        bottom:SetColorTexture(1, 1, 1)
        ]]

        Hook.FCF_SetButtonSide(ScrollingMessageFrame, _G.FCF_GetButtonSide(ScrollingMessageFrame))
        _G.FloatingChatFrame_UpdateBackgroundAnchors(ScrollingMessageFrame)

        Skin.ChatFrameEditBoxTemplate(ScrollingMessageFrame.editBox)
        if private.isRetail then
            ScrollingMessageFrame.editBox:SetPoint("TOPLEFT", ScrollingMessageFrame, "BOTTOMLEFT", 0, -5)
            ScrollingMessageFrame.editBox:SetPoint("RIGHT", ScrollingMessageFrame.ScrollBar)
        end
    end
    function Skin.FloatingChatFrameMinimizedTemplate(Button)
        Button:SetSize(172, 23)
        Button.leftTexture:Hide()
        Button.rightTexture:Hide()
        Button.middleTexture:Hide()
        Button.leftHighlightTexture:Hide()
        Button.rightHighlightTexture:Hide()
        Button.middleHighlightTexture:Hide()

        Skin.FrameTypeFrame(Button)
        Base.SetHighlight(Button)

        local MaximizeButton = _G[Button:GetName().."MaximizeButton"]
        MaximizeButton:SetSize(17, 17)
        Skin.ChatFrameButton(MaximizeButton)
        local box1 = MaximizeButton:CreateTexture(nil, "ARTWORK", nil, 0)
        box1:SetPoint("TOPLEFT", 6, -3)
        box1:SetPoint("BOTTOMRIGHT", -3, 6)
        box1:SetColorTexture(Color.gray:GetRGB())

        local box2 = MaximizeButton:CreateTexture(nil, "ARTWORK", nil, 2)
        box2:SetPoint("TOPLEFT", 3, -6)
        box2:SetPoint("BOTTOMRIGHT", -6, 3)
        box2:SetColorTexture(Color.white:GetRGB())
    end

    function Skin.ChatFrameButton(Button, texture)
        Skin.FrameTypeButton(Button)
        Button:SetBackdropOption("offsets", {
            left = 5,
            right = 5,
            top = 5,
            bottom = 5,
        })


        if texture then
            local bg = Button:GetBackdropTexture("bg")
            local icon = Button:CreateTexture(nil, "ARTWORK")
            icon:SetPoint("TOPLEFT", bg, 3, -3)
            icon:SetPoint("BOTTOMRIGHT", bg, -3, 3)
            icon:SetTexture(texture)
        end
    end
end

-- DIAGNOSTIC (2026-08-18, delve tracker taint): chat-skin bisect harness.
-- The chat skin is force-disabled in aurora.lua (KNOWN ISSUE 2026-08-17: it
-- taints the EditMode-managed chat frames and breaks the objective tracker in
-- delves). Setting AuroraConfig.chatBisect to a "lo-hi" string lifts that
-- disable for the session and applies only the components numbered lo..hi
-- below, so the tainting write can be pinned by bisection. Set from in-game via
--   /run RealUI.SetAuroraConfigValue("chatBisect", "1-10") ReloadUI()
-- and clear with
--   /run RealUI.SetAuroraConfigValue("chatBisect", nil) ReloadUI()
-- Component numbers are FIXED (do not renumber; keep in sync with
-- Mainline/ChatFrame.lua, which owns component 10):
--    1 = hook FloatingChatFrame_UpdateBackgroundAnchors (region re-anchoring
--        on every background update of an EditMode-managed chat frame)
--    2 = hook FCF_SetWindowColor — PRIME SUSPECT: skins late/temporary
--        windows via Skin.FloatingChatFrameTemplate → Base.CreateBackdrop
--        (frame-table writes on EditMode-managed chat frames)
--    3 = hook FCF_SetButtonSide (buttonFrame re-anchoring)
--    4 = hook FCF_CreateMinimizedFrame (minimized-frame skin)
--    5 = creation-time Skin.ChatTabTemplate on ChatFrame1..N tabs
--    6 = creation-time Skin.FloatingChatFrameTemplate on ChatFrame1..N
--        (Base.CreateBackdrop frame-table writes at login)
--    7 = Skin.ChatFrameButton on ChatFrameMenuButton
--    8 = Skin.VoiceToggleButtonTemplate on ChatFrameChannelButton
--    9 = retail voice buttons (ChatFrameChannelButton anchor + deafen/mute)
--   10 = editBox UpdateHeader hooks (Mainline/ChatFrame.lua)
-- NOT numbered: Blizzard_QuickJoin/QuickJoinToast.lua is also gated on
-- private.disabled.chat and re-enables whole whenever chatBisect is active —
-- if even "0-0" still errors, that file is the remaining suspect.
-- Local copy of the fontBisect range parser (Skin/api.lua FontBisectSkips),
-- inverted: returns true when the numbered component should be applied.
-- Remove the harness once the tainting write is identified.
local function ChatBisectEnables(index)
    local range = _G.AuroraConfig and _G.AuroraConfig.chatBisect
    if _G.type(range) ~= "string" then return true end

    local lo, hi = range:match("^(%d+)%-(%d+)$")
    if not lo then return true end

    return index >= _G.tonumber(lo) and index <= _G.tonumber(hi)
end
private.ChatBisectEnables = ChatBisectEnables

function private.SharedXML.FloatingChatFrame()
    if private.disabled.chat then return end

    if ChatBisectEnables(1) then
        _G.hooksecurefunc("FloatingChatFrame_UpdateBackgroundAnchors", Hook.FloatingChatFrame_UpdateBackgroundAnchors)
    end
    if ChatBisectEnables(2) then
        _G.hooksecurefunc("FCF_SetWindowColor", Hook.FCF_SetWindowColor)
    end
    if ChatBisectEnables(3) then
        _G.hooksecurefunc("FCF_SetButtonSide", Hook.FCF_SetButtonSide)
    end
    if ChatBisectEnables(4) then
        _G.hooksecurefunc("FCF_CreateMinimizedFrame", Hook.FCF_CreateMinimizedFrame)
    end

    for i = 1, _G.Constants.ChatFrameConstants.MaxChatWindows do
        local name = "ChatFrame"..i
        if ChatBisectEnables(5) then
            Skin.ChatTabTemplate(_G[name.."Tab"])
        end
        if ChatBisectEnables(6) then
            Skin.FloatingChatFrameTemplate(_G[name])
        end
    end

    if ChatBisectEnables(7) then
        Skin.ChatFrameButton(_G.ChatFrameMenuButton, [[Interface\GossipFrame\ChatBubbleGossipIcon]])
    end
    if ChatBisectEnables(8) then
        Skin.VoiceToggleButtonTemplate(_G.ChatFrameChannelButton)
    end
    if private.isRetail and ChatBisectEnables(9) then
        _G.ChatFrameChannelButton:SetPoint("TOP", _G.ChatFrame1ButtonFrame, 0, -3)
        Skin.ToggleVoiceDeafenButtonTemplate(_G.ChatFrameToggleVoiceDeafenButton)
        Skin.ToggleVoiceMuteButtonTemplate(_G.ChatFrameToggleVoiceMuteButton)
    end
end
