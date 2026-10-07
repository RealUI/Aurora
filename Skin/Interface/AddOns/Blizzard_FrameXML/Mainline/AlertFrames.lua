local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Taint audit 2026-10-06 (B170 follow-up): the AlertContainerMixin:
    AddAlertFrame post-hook is gone. It re-ran Skin[frame._auroraTemplate]
    inside AlertFrameQueueMixin:ShowAlert, after Blizzard had shown the alert.
    The alert skins are now in place and run from their setUpFunction
    post-hooks in AlertFrameSystems.lua, per show where SetUp re-sets art. ]]

--do --[[ FrameXML\AlertFrames.lua ]]
--end

--do --[[ FrameXML\AlertFrames.xml ]]
--end

--function private.FrameXML.AlertFrames()
--end
