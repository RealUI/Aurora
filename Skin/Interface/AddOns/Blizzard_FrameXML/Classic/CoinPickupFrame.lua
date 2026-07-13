local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Util = Aurora.Util

--[[ Classic-family coin split popup. Evidence: Blizzard_FrameXML/Classic/
    CoinPickupFrame.xml — same construction as the stack split popup. ]]

function private.FrameXML.CoinPickupFrame()
    Util.HideFrameTextures(_G.CoinPickupFrame)
    Skin.FrameTypeFrame(_G.CoinPickupFrame)

    Skin.UIPanelButtonTemplate(_G.CoinPickupOkayButton)
    Skin.UIPanelButtonTemplate(_G.CoinPickupCancelButton)
end
