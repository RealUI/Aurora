local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals select type

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

function private.FrameXML.StackSplitFrame()
    local StackSplitFrame = _G.StackSplitFrame
    if not StackSplitFrame then return end

    -- Apply Aurora backdrop
    Base.SetBackdrop(StackSplitFrame, Color.frame, Util.GetFrameAlpha())

    -- Hide border textures (UI-StackSplit art)
    for i = 1, StackSplitFrame:GetNumRegions() do
        local region = _G.select(i, StackSplitFrame:GetRegions())
        if region and region.GetObjectType and region:GetObjectType() == "Texture" then
            local texture = region:GetTexture()
            if texture and type(texture) == "string" and texture:find("UI%-StackSplit") then
                region:Hide()
            end
        end
    end

    -- Skin OK and Cancel buttons
    if _G.StackSplitOkayButton then
        Skin.UIPanelButtonTemplate(_G.StackSplitOkayButton)
    end
    if _G.StackSplitCancelButton then
        Skin.UIPanelButtonTemplate(_G.StackSplitCancelButton)
    end

    -- Skin the split slider
    local slider = StackSplitFrame.slider or _G.StackSplitFrameSlider
    if slider then
        Base.SetBackdrop(slider, Color.frame)
        slider:SetBackdropBorderColor(Color.button)
        slider:SetBackdropOption("offsets", {
            left = 5,
            right = 5,
            top = 5,
            bottom = 5,
        })

        local thumbTexture = slider:GetThumbTexture()
        if thumbTexture then
            thumbTexture:SetAlpha(0)
            thumbTexture:SetSize(16, 8)

            local thumb = _G.CreateFrame("Frame", nil, slider)
            thumb:SetPoint("TOPLEFT", thumbTexture, 0, 0)
            thumb:SetPoint("BOTTOMRIGHT", thumbTexture, 0, 0)
            Base.SetBackdrop(thumb, Color.button)
            slider._auroraThumb = thumb
        end
    end
end
