local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals select type

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

function private.FrameXML.DressUpFrames()
    local DressUpFrame = _G.DressUpFrame
    if not DressUpFrame then return end

    -- Apply Aurora backdrop
    Base.SetBackdrop(DressUpFrame, Color.frame, Util.GetFrameAlpha())

    -- Hide portrait texture
    if _G.DressUpFramePortrait then
        _G.DressUpFramePortrait:SetAlpha(0)
    end

    -- Hide border/background textures (UI-DressUpFrame art from ButtonFrameTemplate)
    for i = 1, DressUpFrame:GetNumRegions() do
        local region = _G.select(i, DressUpFrame:GetRegions())
        if region and region.GetObjectType and region:GetObjectType() == "Texture" then
            local texture = region:GetTexture()
            if texture and type(texture) == "string" and texture:find("UI%-DressUpFrame") then
                region:Hide()
            end
        end
    end

    -- Skin close button (ButtonFrameTemplate provides DressUpFrameCloseButton)
    if _G.DressUpFrameCloseButton then
        Skin.UIPanelCloseButton(_G.DressUpFrameCloseButton)
    end

    -- Skin Cancel button
    if _G.DressUpFrameCancelButton then
        Skin.UIPanelButtonTemplate(_G.DressUpFrameCancelButton)
    end

    -- Skin Reset button
    if DressUpFrame.ResetButton then
        Skin.UIPanelButtonTemplate(DressUpFrame.ResetButton)
    elseif _G.DressUpFrameResetButton then
        Skin.UIPanelButtonTemplate(_G.DressUpFrameResetButton)
    end
end
