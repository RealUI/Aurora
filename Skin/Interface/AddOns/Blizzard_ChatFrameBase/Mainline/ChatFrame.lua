local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals _G

--[[ Core ]]
local Aurora = private.Aurora
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color = Aurora.Color

-- B261 (task 5.2): chat edit boxes whose UpdateHeader is hooked. Was
-- `_auroraHeaderHooked` on the Blizzard edit box. The edit boxes belong to
-- the chat frames, which are never released; weak keys all the same.
local headerHooked = _G.setmetatable({}, {__mode = "k"})

do --[[ SharedXML\ChatFrame.lua ]]
    function Hook.ChatFrameEditBoxMixinUpdateHeader(editBox)
        local chatType = editBox:GetAttribute("chatType")
        if not chatType then
            editBox:SetBackdropBorderColor(Color.frame)
            return
        end

        local info = _G.ChatTypeInfo[chatType]
        if chatType == "CHANNEL" then
            -- The channel belongs to the edit box being updated, not to whichever
            -- one happens to be focused: ChatFrameUtil.GetActiveWindow() returns
            -- ACTIVE_CHAT_EDIT_BOX, which is nil whenever UpdateHeader runs outside
            -- a user-opened edit box (UPDATE_CHAT_WINDOWS -> UpdateDefaultChatTarget
            -- at login, for a window whose default target is a channel).
            local localID, channelName = _G.GetChannelName(editBox:GetChannelTarget())
            if channelName then
                info = _G.ChatTypeInfo["CHANNEL"..localID]
            end
        end

        editBox:SetBackdropBorderColor(info.r, info.g, info.b)
    end
end

do --[[ SharedXML\ChatFrame.xml ]]
    --[[ B261 (tier A, row A4; a secret-value row), read from wow-ui-source
        (retail) and wow-ui-source-forever. The chat frame's scroll bar is a
        MinimalScrollBar (Blizzard_ChatFrameBase/Mainline/ChatFrame.xml:5, both
        trees). ScrollingMessageFrameMixin:RefreshDisplay sets each visible
        line's text, which can be secret (Blizzard_SharedXML/ScrollingMessageFrame.lua:643),
        then calls the display-refreshed callbacks (:666), and the one
        ScrollUtil.InitScrollingMessageFrameWithScrollBar registers updates the
        bar (Blizzard_SharedXML/Shared/Scroll/ScrollUtil.lua:166-194), whose
        Update enables or disables both steppers and the thumb
        (Shared/Scroll/ScrollBar.lua:238-239, :255-256). The same lines on
        Forever. That runs on every chat line, in combat.
        Shape c, stock: like the loot window's bar, the steppers and the thumb
        redraw their own atlas on every enable, disable, hover and press and
        desaturate when disabled (Shared/Scroll/MinimalScrollBar.lua:10,
        :24-26, :33, :47-52), so a Layer 2 form would fight Blizzard's art on
        every state change. Skin.MinimalScrollBar is no longer called here, so
        nothing of Aurora's is on the bar; the shared template is not changed.
        Blizzard keeps the bar at alpha 0 until the cursor is over the chat
        frame (Blizzard_ChatFrameBase/Mainline/ChatFrameOverrides.lua:42-45). ]]
    function Skin.ChatFrameTemplate(ScrollingMessageFrame) -- luacheck: ignore
    end
    function Skin.ChatFrameEditBoxTemplate(EditBox)
        Skin.FrameTypeEditBox(EditBox)

        local name = EditBox:GetName()
        _G[name.."Left"]:Hide()
        _G[name.."Right"]:Hide()
        _G[name.."Mid"]:Hide()
        if private.isRetail then
            EditBox.focusLeft:SetAlpha(0)
            EditBox.focusRight:SetAlpha(0)
            EditBox.focusMid:SetAlpha(0)
        end
        EditBox.header:SetPoint("LEFT", 10, 0)
    end
end

function private.SharedXML.ChatFrame()
    if private.disabled.chat then return end

    -- Blizzard calls editBox:UpdateHeader() (mixin method); the surviving
    -- ChatEdit_UpdateHeader global is a deprecation alias that never fires.
    -- Mixin methods are copied onto frames at creation, so hook both:
    -- existing editbox instances, and the mixin table for frames created
    -- later (temporary chat windows).
    local function HookEditBox(editBox)
        if editBox and editBox.UpdateHeader and not headerHooked[editBox] then
            headerHooked[editBox] = true
            _G.hooksecurefunc(editBox, "UpdateHeader", Hook.ChatFrameEditBoxMixinUpdateHeader)
        end
    end

    if _G.ChatFrameEditBoxMixin then
        _G.hooksecurefunc(_G.ChatFrameEditBoxMixin, "UpdateHeader", Hook.ChatFrameEditBoxMixinUpdateHeader)

        local maxWindows = (_G.Constants and _G.Constants.ChatFrameConstants
            and _G.Constants.ChatFrameConstants.MaxChatWindows)
            or _G.NUM_CHAT_WINDOWS or 10
        for i = 1, maxWindows do
            HookEditBox(_G["ChatFrame"..i.."EditBox"])
        end
    else
        _G.hooksecurefunc("ChatEdit_UpdateHeader", Hook.ChatFrameEditBoxMixinUpdateHeader)
    end

    --[[
    local AddMessage = {}
    local function FixClassColors(frame, message, ...) -- 3174
        if type(message) == "string" and message:find("|cff") then -- type check required for shitty addons that pass nil or non-string values
            for classToken, classColor in next, _G.RAID_CLASS_COLORS do
                local color = _G.CUSTOM_CLASS_COLORS[classToken]
                message = color and message:gsub(classColor.colorStr, color.colorStr) or message -- color check required for Warmup, maybe others
            end
        end
        return AddMessage[frame](frame, message, ...)
    end

    for i = 1, _G.Constants.ChatFrameConstants.MaxChatWindows do
        local frame = _G["ChatFrame"..i]
        AddMessage[frame] = frame.AddMessage
        frame.AddMessage = FixClassColors
    end
    ]]
end
