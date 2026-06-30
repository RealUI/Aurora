local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Color, Util = Aurora.Color, Aurora.Util

-- TBC Classic Anniversary unit frame skin.
-- This registers on private.AddOns.Blizzard_UnitFrame, a completely separate
-- dispatch path from the flat Blizzard_UnitFrame.lua file's
-- private.FrameXML.CompactUnitFrame hook. Both coexist: the FrameXML hook fires
-- at Aurora init time, this AddOns hook fires on the addon's ADDON_LOADED event.
function private.AddOns.Blizzard_UnitFrame()
    -- PlayerFrame: hide Blizzard art textures before applying the backdrop.
    if _G.PlayerFrameTexture then
        _G.PlayerFrameTexture:Hide()
    end
    if _G.PlayerFrameBackground then
        _G.PlayerFrameBackground:Hide()
    end
    if _G.PlayerFrame then
        Base.SetBackdrop(_G.PlayerFrame, Color.frame, Util.GetFrameAlpha())
    end

    -- TargetFrame: hide Blizzard art texture before applying the backdrop.
    if _G.TargetFrameTextureFrameTexture then
        _G.TargetFrameTextureFrameTexture:Hide()
    end
    if _G.TargetFrame then
        Base.SetBackdrop(_G.TargetFrame, Color.frame, Util.GetFrameAlpha())
    end

    -- PetFrame: hide Blizzard art texture before applying the backdrop.
    if _G.PetFrameTexture then
        _G.PetFrameTexture:Hide()
    end
    if _G.PetFrame then
        Base.SetBackdrop(_G.PetFrame, Color.frame, Util.GetFrameAlpha())
    end
end
