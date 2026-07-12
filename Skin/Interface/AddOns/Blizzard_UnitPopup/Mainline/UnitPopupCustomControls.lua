local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Util = Aurora.Util
local Hook = Aurora.Hook

--do --[[ FrameXML\UnitPopupCustomControls.lua ]]
--end

do --[[ FrameXML\UnitPopupCustomControls.xml ]]
    Hook.UnitPopupVoiceLevelsMixin = {}
    function Hook.UnitPopupVoiceLevelsMixin:OnLoad()
        Skin.UnitPopupVoiceSliderTemplate(self.Slider)
        Skin.UnitPopupVoiceToggleButtonTemplate(self.Toggle)
     end

    function Skin.UnitPopupVoiceToggleButtonTemplate(Button)
        Skin.VoiceToggleButtonTemplate(Button)
    end
    function Skin.UnitPopupVoiceSliderTemplate(Slider)
        Skin.UnitPopupSliderTemplate(Slider)
    end
end

function private.FrameXML.UnitPopupCustomControls()
    Util.Mixin(_G.UnitPopupVoiceLevelsMixin, Hook.UnitPopupVoiceLevelsMixin)
end
