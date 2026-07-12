local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals next

--[[ Core ]]
local Aurora = private.Aurora
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color = Aurora.Color

local function GetSafeSenderName(sender)
    if _G.issecretvalue(sender) or _G.issecrettable(sender) then
        return ""
    end

    if _G.type(sender) ~= "string" or sender == "" then
        return ""
    end

    return _G.Ambiguate(sender, "none")
end

local function GetSafeMessageText(message)
    if _G.issecretvalue(message) or _G.issecrettable(message) then
        return nil
    end

    if _G.type(message) ~= "string" or message == "" then
        return nil
    end

    return message
end

local chatBubbleEvents = {
    CHAT_MSG_SAY = "chatBubbles",
    CHAT_MSG_YELL = "chatBubbles",
    CHAT_MSG_MONSTER_SAY = "chatBubbles",
    CHAT_MSG_MONSTER_YELL = "chatBubbles",

    CHAT_MSG_PARTY = "chatBubblesParty",
    CHAT_MSG_PARTY_LEADER = "chatBubblesParty",
    CHAT_MSG_MONSTER_PARTY = "chatBubblesParty",
}

do --[[ FrameXML\Backdrop.lua ]]
    local defaultColor = "ffffffff"
    local function FindChatBubble(msg)
        msg = GetSafeMessageText(msg)
        if not msg then
            return
        end

        local chatbubble
        local chatbubbles = _G.C_ChatBubbles.GetAllChatBubbles()
        for index = 1, #chatbubbles do
            chatbubble = chatbubbles[index]:GetChildren()

            if not chatbubble._auroraName then
                Skin.ChatBubbleTemplate(chatbubble)
            end

            local bubbleText = GetSafeMessageText(chatbubble.String:GetText())
            if bubbleText and bubbleText == msg then
                return chatbubble
            end
        end
    end

    function Hook.ChatBubble_SetName(chatbubble, guid, name)
        local color
        if guid ~= nil and guid ~= "" then
            local _, class = _G.GetPlayerInfoByGUID(guid)
            color = _G.CUSTOM_CLASS_COLORS[class].colorStr
        else
            color = defaultColor
        end
        chatbubble._auroraName:SetFormattedText("|c%s%s|r", color, name)
    end
    function Hook.ChatBubble_OnEvent(self, event, msg, sender, _, _, _, _, _, _, _, _, _, guid)
        if _G.GetCVarBool(chatBubbleEvents[event]) then
            self.elapsed = 0
            self.msg = GetSafeMessageText(msg)
            self.sender = GetSafeSenderName(sender) -- Only show realm if it's not yours
            self.guid = guid
            self:Show()
        end
    end
    function Hook.ChatBubble_OnUpdate(self, elapsed)
        self.elapsed = self.elapsed + elapsed
        local chatbubble = FindChatBubble(self.msg)
        if chatbubble or self.elapsed > 0.3 then
            self:Hide()
            if chatbubble then
                Hook.ChatBubble_SetName(chatbubble, self.guid, self.sender)
            end
        end
    end
end

do --[[ FrameXML\ChatBubbleTemplates.xml ]]
    function Skin.ChatBubbleTemplate(Frame)
        if not Frame._auroraBG then
            local bg = Frame:CreateTexture(nil, "BACKGROUND", nil, -1)
            bg:SetColorTexture(Color.black.r, Color.black.g, Color.black.b, 0.85)
            bg:SetPoint("TOPLEFT", 1, -1)
            bg:SetPoint("BOTTOMRIGHT", -1, 1)
            Frame._auroraBG = bg
        end

        Frame:SetScale(_G.UIParent:GetScale())

        local tail = Frame.Tail
        tail:SetColorTexture(0, 0, 0) -- static: not a theme color
        tail:SetVertexOffset(1, 0, -5)
        tail:SetVertexOffset(2, 16, -5)
        tail:SetVertexOffset(3, 0, -5)
        tail:SetVertexOffset(4, 0, -5)

        local name = Frame:CreateFontString(nil, "BORDER")
        name:SetPoint("TOPLEFT", 5, 5)
        name:SetPoint("BOTTOMRIGHT", Frame, "TOPRIGHT", -5, -5)
        name:SetJustifyH("LEFT")
        name:SetFontObject(_G.Game12Font_o1)
        Frame._auroraName = name
    end
end

function private.FrameXML.ChatBubbleTemplates()
    local bubbleHook = _G.CreateFrame("Frame")
    bubbleHook:SetScript("OnEvent", Hook.ChatBubble_OnEvent)
    bubbleHook:SetScript("OnUpdate", Hook.ChatBubble_OnUpdate)
    bubbleHook:Hide()

    for event in next, chatBubbleEvents do
        bubbleHook:RegisterEvent(event)
    end
end
