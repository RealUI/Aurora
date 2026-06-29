local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals select type

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

function private.FrameXML.ReadyCheck()
    local ReadyCheckFrame = _G.ReadyCheckFrame
    if not ReadyCheckFrame then return end

    -- Apply Aurora backdrop
    Base.SetBackdrop(ReadyCheckFrame, Color.frame, Util.GetFrameAlpha())

    -- Hide portrait texture
    if _G.ReadyCheckPortrait then
        _G.ReadyCheckPortrait:SetAlpha(0)
    end

    -- Hide border textures (UI-DialogBox art from PortraitFrame template)
    for i = 1, ReadyCheckFrame:GetNumRegions() do
        local region = _G.select(i, ReadyCheckFrame:GetRegions())
        if region and region.GetObjectType and region:GetObjectType() == "Texture" then
            local texture = region:GetTexture()
            if texture and type(texture) == "string" and (texture:find("UI%-DialogBox") or texture:find("UI%-Character")) then
                region:Hide()
            end
        end
    end

    -- Skin Yes and No buttons
    if _G.ReadyCheckFrameYesButton then
        Skin.UIPanelButtonTemplate(_G.ReadyCheckFrameYesButton)
    end
    if _G.ReadyCheckFrameNoButton then
        Skin.UIPanelButtonTemplate(_G.ReadyCheckFrameNoButton)
    end
end
