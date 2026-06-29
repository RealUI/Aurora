local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base, Skin = Aurora.Base, Aurora.Skin

--do --[[ FrameXML\GhostFrame.lua ]]
--end

--do --[[ FrameXML\GhostFrame.xml ]]
--end

function private.FrameXML.GhostFrame()
    if not _G.GhostFrame then return end
    Skin.UIPanelLargeSilverButton(_G.GhostFrame)
    if _G.GhostFrameContentsFrameIcon and _G.GhostFrameContentsFrame then
        Base.CropIcon(_G.GhostFrameContentsFrameIcon, _G.GhostFrameContentsFrame)
    end
end
