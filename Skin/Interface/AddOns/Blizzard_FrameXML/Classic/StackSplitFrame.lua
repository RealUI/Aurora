local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Util = Aurora.Util

--[[ Classic-family stack split popup (shift-click). Evidence:
    Blizzard_FrameXML/Classic/StackSplitFrame.xml — art frame + left/right
    repeat-arrows (kept, small round art) + Okay/Cancel. ]]

function private.FrameXML.StackSplitFrame()
    Util.HideFrameTextures(_G.StackSplitFrame)
    Skin.FrameTypeFrame(_G.StackSplitFrame)

    Skin.UIPanelButtonTemplate(_G.StackSplitOkayButton)
    Skin.UIPanelButtonTemplate(_G.StackSplitCancelButton)
end
