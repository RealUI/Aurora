local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin

--do --[[ FrameXML\VoiceToggleButton.lua ]]
--end

do --[[ FrameXML\VoiceToggleButton.xml ]]
    function Skin.VoiceToggleButtonTemplate(Button)
        Skin.PropertyButtonTemplate(Button)
        Skin.FrameTypeButton(Button)

        Button:SetSize(23, 23)
        Button.Icon:SetPoint("CENTER", 0, 1)
    end
    function Skin.ToggleVoiceDeafenButtonTemplate(Button)
        Skin.VoiceToggleButtonTemplate(Button)
    end
    function Skin.ToggleVoiceMuteButtonTemplate(Button)
        Skin.VoiceToggleButtonTemplate(Button)
    end
end

--function private.FrameXML.VoiceToggleButton()
--end
