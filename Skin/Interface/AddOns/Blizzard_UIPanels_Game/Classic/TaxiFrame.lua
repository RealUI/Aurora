local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Util = Aurora.Util

--[[ Classic-family flight master (era/TBC/Mists).
    Evidence: Classic/TaxiFrame.xml — border art around the TaxiRouteMap
    (the map itself is content and fills the panel; like the world map, the
    stripped panel is left borderless).
]]

function private.FrameXML.TaxiFrame()
    Util.HideFrameTextures(_G.TaxiFrame, true)
    Skin.UIPanelCloseButton(_G.TaxiCloseButton)
end
