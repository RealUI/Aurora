local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color = Aurora.Color

--[[ Classic-family chat frame base (era/TBC/Mists share this Classic file).
    Evidence: wow-ui-source-*/Interface/AddOns/Blizzard_ChatFrameBase/
    Classic/ChatFrame.xml — the 1.15+ editbox already carries the
    retail-style focus textures (focusLeft/Right/Mid parentKeys) alongside
    the named $parentLeft/Right/Mid border art. The channel-target API here
    is ChatEdit_GetChannelTarget (no ChatFrameUtil on classic).
]]

do --[[ Classic\ChatFrame.lua ]]
    -- Recolor the Aurora editbox border to the active chat type's color
    function Hook.ChatEdit_UpdateHeader(editBox)
        if not editBox.SetBackdropBorderColor then return end

        local chatType = editBox:GetAttribute("chatType")
        if not chatType then
            editBox:SetBackdropBorderColor(Color.frame)
            return
        end

        local info = _G.ChatTypeInfo[chatType]
        if chatType == "CHANNEL" then
            local localID, channelName = _G.GetChannelName(_G.ChatEdit_GetChannelTarget(editBox))
            if channelName then
                info = _G.ChatTypeInfo["CHANNEL"..localID]
            end
        end

        if info then
            editBox:SetBackdropBorderColor(info.r, info.g, info.b)
        end
    end
end

do --[[ Classic\ChatFrame.xml ]]
    function Skin.ChatFrameTemplate(ScrollingMessageFrame) -- luacheck: ignore
        -- no permanent scrollbar on the classic chat frame
    end
    function Skin.ChatFrameEditBoxTemplate(EditBox)
        Skin.FrameTypeEditBox(EditBox)

        local name = EditBox:GetName()
        _G[name.."Left"]:Hide()
        _G[name.."Right"]:Hide()
        _G[name.."Mid"]:Hide()

        -- The wow-ui-source dump has focus textures on this template, but
        -- the live 1.15.8 client does not attach them — guard everything.
        for _, key in ipairs({"focusLeft", "focusRight", "focusMid"}) do
            local texture = EditBox[key] or _G[name..key:gsub("^f", "F")]
            if texture then
                texture:SetAlpha(0)
            end
        end

        EditBox.header:SetPoint("LEFT", 10, 0)
    end
end

function private.SharedXML.ChatFrame()
    if private.disabled.chat then return end
    _G.hooksecurefunc("ChatEdit_UpdateHeader", Hook.ChatEdit_UpdateHeader)
end
