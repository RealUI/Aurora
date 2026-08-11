local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals _G

--[[ Core ]]
local Aurora = private.Aurora
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color = Aurora.Color

do --[[ SharedXML\ChatFrame.lua ]]
    function Hook.ChatFrameEditBoxMixinUpdateHeader(editBox)
        local chatType = editBox:GetAttribute("chatType")
        if not chatType then
            editBox:SetBackdropBorderColor(Color.frame)
            return
        end

        local info = _G.ChatTypeInfo[chatType]
        if chatType == "CHANNEL" then
            local channeleditBox = _G.ChatFrameUtil.GetActiveWindow();
            local localID, channelName = _G.GetChannelName(channeleditBox:GetChannelTarget())
            if channelName then
                info = _G.ChatTypeInfo["CHANNEL"..localID]
            end
        end

        editBox:SetBackdropBorderColor(info.r, info.g, info.b)
    end
end

do --[[ SharedXML\ChatFrame.xml ]]
    function Skin.ChatFrameTemplate(ScrollingMessageFrame)
        if private.isRetail then
            Skin.MinimalScrollBar(ScrollingMessageFrame.ScrollBar)
        end
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
        if editBox and editBox.UpdateHeader and not editBox._auroraHeaderHooked then
            editBox._auroraHeaderHooked = true
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
