local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color = Aurora.Color

--[[ Classic-family floating chat windows (era/TBC/Mists share this Classic
    file). Evidence: wow-ui-source-*/Interface/AddOns/Blizzard_ChatFrameBase/
    Classic/FloatingChatFrame.xml — FloatingBorderedFrame region order is
    Background, 4 corners, left/right, bottom/top (same unpack as retail);
    tabs and minimized frames use the classic lowercase parentKeys
    (leftTexture/leftSelectedTexture/leftHighlightTexture, ...).

    Left stock: the round ChatFrame1ButtonFrame icons (chat menu / channel /
    friends micro button — round icon art on an alpha-0.2 layout frame) and
    the scroll-to-bottom overlay.
]]

do --[[ Classic\FloatingChatFrame.lua ]]
    function Hook.FloatingChatFrame_UpdateBackgroundAnchors(self)
        local bg, tl, bl, tr, br = self:GetRegions()
        tl:SetPoint("TOPLEFT", bg)
        bl:SetPoint("BOTTOMLEFT", bg)
        tr:SetPoint("TOPRIGHT", bg)
        br:SetPoint("BOTTOMRIGHT", bg)
    end
    function Hook.FCF_SetWindowColor(frame, r, g, b, doNotSave)
        -- temporary windows (whisper tabs) get skinned lazily on first color
        if not frame.SetBackdrop then
            Skin.ChatTabTemplate(_G["ChatFrame"..frame:GetID().."Tab"])
            Skin.FloatingChatFrameTemplate(frame)
        end

        frame:SetBackdropColor(r, g, b)
        frame:SetBackdropBorderColor(r, g, b)
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

do --[[ Classic\FloatingChatFrame.xml ]]
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
    function Skin.ChatTabTemplate(Button)
        Skin.ChatTabArtTemplate(Button)
        Button:SetHighlightFontObject("GameFontHighlightSmall")
    end
    function Skin.FloatingChatFrameTemplate(ScrollingMessageFrame)
        Skin.ChatFrameTemplate(ScrollingMessageFrame)
        Skin.FloatingBorderedFrame(ScrollingMessageFrame)

        -- NOTE: the minimize button is parented on the chat frame here
        -- (ScrollingMessageFrame.minimizeButton), NOT buttonFrame like
        -- retail — and it's round icon art like the up/down/bottom buttons,
        -- which are all deliberately left stock on classic.

        Hook.FCF_SetButtonSide(ScrollingMessageFrame, _G.FCF_GetButtonSide(ScrollingMessageFrame))
        _G.FloatingChatFrame_UpdateBackgroundAnchors(ScrollingMessageFrame)

        Skin.ChatFrameEditBoxTemplate(ScrollingMessageFrame.editBox)
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

function private.SharedXML.FloatingChatFrame()
    if private.disabled.chat then return end

    _G.hooksecurefunc("FloatingChatFrame_UpdateBackgroundAnchors", Hook.FloatingChatFrame_UpdateBackgroundAnchors)
    _G.hooksecurefunc("FCF_SetWindowColor", Hook.FCF_SetWindowColor)
    _G.hooksecurefunc("FCF_SetButtonSide", Hook.FCF_SetButtonSide)
    _G.hooksecurefunc("FCF_CreateMinimizedFrame", Hook.FCF_CreateMinimizedFrame)

    for i = 1, _G.NUM_CHAT_WINDOWS do
        local name = "ChatFrame"..i
        Skin.ChatTabTemplate(_G[name.."Tab"])
        Skin.FloatingChatFrameTemplate(_G[name])
    end
end
