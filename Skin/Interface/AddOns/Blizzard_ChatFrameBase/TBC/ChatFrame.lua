local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color = Aurora.Color

do --[[ FrameXML\ChatFrame.lua ]]
    function Hook.ChatFrameEditBoxMixinUpdateHeader(editBox)
        local chatType = editBox:GetAttribute("chatType")
        if not chatType then
            editBox:SetBackdropBorderColor(Color.frame)
            return
        end

        local info = _G.ChatTypeInfo[chatType]
        if chatType == "CHANNEL" then
            local localID = _G.GetChannelName(editBox:GetAttribute("channelTarget") or 0)
            if localID and localID > 0 then
                info = _G.ChatTypeInfo["CHANNEL" .. localID] or info
            end
        end

        if info then
            editBox:SetBackdropBorderColor(info.r, info.g, info.b)
        end
    end
end

do --[[ FrameXML\ChatFrame.xml ]]
    function Skin.ChatFrameEditBoxTemplate(EditBox)
        Skin.FrameTypeEditBox(EditBox)

        local name = EditBox:GetName()
        if name then
            -- Hide left/right/mid border textures
            local left = _G[name .. "Left"]
            if left then left:Hide() end
            local right = _G[name .. "Right"]
            if right then right:Hide() end
            local mid = _G[name .. "Mid"]
            if mid then mid:Hide() end

            -- Hide focus textures (TBC uses FocusLeft/FocusRight/FocusMid or named children)
            local focusLeft = _G[name .. "FocusLeft"] or (EditBox.focusLeft)
            if focusLeft then focusLeft:SetAlpha(0) end
            local focusRight = _G[name .. "FocusRight"] or (EditBox.focusRight)
            if focusRight then focusRight:SetAlpha(0) end
            local focusMid = _G[name .. "FocusMid"] or (EditBox.focusMid)
            if focusMid then focusMid:SetAlpha(0) end
        end

        -- Reposition header text
        if EditBox.header then
            EditBox.header:SetPoint("LEFT", 10, 0)
        end
    end

    function Skin.ChatTabTemplate(Button)
        if not Button then return end

        local name = Button:GetName()
        if not name then return end

        -- Strip tab background textures
        local texturesToHide = {
            "Left", "Middle", "Right",
            "SelectedLeft", "SelectedMiddle", "SelectedRight",
            "HighlightLeft", "HighlightMiddle", "HighlightRight",
        }
        for _, suffix in _G.ipairs(texturesToHide) do
            local tex = _G[name .. suffix] or (Button[suffix])
            if tex and tex.SetAlpha then
                tex:SetAlpha(0)
            end
        end

        -- Also hide the active textures if they exist as parentKeys
        if Button.leftTexture then Button.leftTexture:SetAlpha(0) end
        if Button.middleTexture then Button.middleTexture:SetAlpha(0) end
        if Button.rightTexture then Button.rightTexture:SetAlpha(0) end

        -- Hide the selected/active glow textures
        if Button.leftSelectedTexture then Button.leftSelectedTexture:SetAlpha(0) end
        if Button.middleSelectedTexture then Button.middleSelectedTexture:SetAlpha(0) end
        if Button.rightSelectedTexture then Button.rightSelectedTexture:SetAlpha(0) end

        -- Apply minimal Aurora button styling
        Base.SetBackdrop(Button, Color.button)
        Button:SetBackdropOption("offsets", {
            left = 4,
            right = 4,
            top = 6,
            bottom = 4,
        })
        Base.SetHighlight(Button)
    end
end

function private.FrameXML.ChatFrame()
    if private.disabled.chat then return end
    _G.hooksecurefunc("ChatEdit_UpdateHeader", Hook.ChatFrameEditBoxMixinUpdateHeader)

    -- Skin edit boxes and tabs for each chat frame
    local numFrames = _G.NUM_CHAT_WINDOWS or 7
    for i = 1, numFrames do
        -- Skin the edit box
        local editBox = _G["ChatFrame" .. i .. "EditBox"]
        if editBox then
            Skin.ChatFrameEditBoxTemplate(editBox)
        end

        -- Skin the chat tab
        local tab = _G["ChatFrame" .. i .. "Tab"]
        if tab then
            Skin.ChatTabTemplate(tab)
        end
    end
end
