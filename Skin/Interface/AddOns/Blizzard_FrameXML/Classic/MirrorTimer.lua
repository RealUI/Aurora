local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Util = Aurora.Util

--[[ Classic-family mirror timers (breath/fatigue/feign bars). Evidence:
    Blizzard_FrameXML/Classic/MirrorTimer.xml — MirrorTimer1-3 frames with
    ornate border regions around a $parentStatusBar child. ]]

function private.FrameXML.MirrorTimer()
    for i = 1, 3 do
        local timer = _G["MirrorTimer"..i]
        if timer then
            Util.HideFrameTextures(timer)
            local bar = _G["MirrorTimer"..i.."StatusBar"]
            if bar then
                Skin.FrameTypeStatusBar(bar)
            end
        end
    end
end
