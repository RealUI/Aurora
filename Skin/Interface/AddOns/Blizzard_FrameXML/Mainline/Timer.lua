local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Util = Aurora.Util

do --[[ FrameXML\Timer.lua ]]
    function Hook.StartTimer_SetGoTexture(timer)
        Util.SkinOnce(timer, Skin.StartTimerBar)
    end
end

do --[[ FrameXML\Timer.xml ]]
    function Skin.StartTimerBar(Frame)
        Skin.FrameTypeStatusBar(Frame.bar)
        local bg, border = Frame.bar:GetRegions()
        bg:Hide()
        border:Hide()
    end
end

function private.FrameXML.Timer()
    _G.hooksecurefunc("StartTimer_SetGoTexture", Hook.StartTimer_SetGoTexture)
end
