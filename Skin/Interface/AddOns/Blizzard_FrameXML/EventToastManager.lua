local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Hook = Aurora.Hook

do --[[ FrameXML\EventToastManager.lua ]]
    Hook.EventToastManagerFrameMixin = {}
    function Hook.EventToastManagerFrameMixin:DisplayToast()
        self.BlackBG:SetAlpha(0)
        self.GLine:SetAlpha(0)
        self.GLine2:SetAlpha(0)
    end
end

--do --[[ FrameXML\EventToastManager.xml ]]
--end

function private.FrameXML.EventToastManager()
    local Util = Aurora.Util
    Util.Mixin(_G.EventToastManagerFrame, Hook.EventToastManagerFrameMixin)
end
