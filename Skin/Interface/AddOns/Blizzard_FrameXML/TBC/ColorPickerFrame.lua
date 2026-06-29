local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals select

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

function private.FrameXML.ColorPickerFrame()
    local ColorPickerFrame = _G.ColorPickerFrame
    if not ColorPickerFrame then return end

    -- Apply Aurora backdrop
    Base.SetBackdrop(ColorPickerFrame, Color.frame, Util.GetFrameAlpha())

    -- Hide border/background textures (UI-DialogBox art)
    for i = 1, ColorPickerFrame:GetNumRegions() do
        local region = _G.select(i, ColorPickerFrame:GetRegions())
        if region and region.GetObjectType and region:GetObjectType() == "Texture" then
            local texture = region:GetTexture()
            if texture and type(texture) == "string" and texture:find("UI%-DialogBox") then
                region:Hide()
            end
        end
    end

    -- Skin OK and Cancel buttons (GameMenuButtonTemplate inherits UIPanelButtonTemplate)
    if _G.ColorPickerOkayButton then
        Skin.UIPanelButtonTemplate(_G.ColorPickerOkayButton)
    end
    if _G.ColorPickerCancelButton then
        Skin.UIPanelButtonTemplate(_G.ColorPickerCancelButton)
    end

    -- Skin opacity slider if present
    local OpacitySliderFrame = _G.OpacitySliderFrame
    if OpacitySliderFrame then
        Base.SetBackdrop(OpacitySliderFrame, Color.frame)
        OpacitySliderFrame:SetBackdropBorderColor(Color.button)
        OpacitySliderFrame:SetBackdropOption("offsets", {
            left = 5,
            right = 5,
            top = 5,
            bottom = 5,
        })

        local thumbTexture = OpacitySliderFrame:GetThumbTexture()
        if thumbTexture then
            thumbTexture:SetAlpha(0)
            thumbTexture:SetSize(16, 8)

            local thumb = _G.CreateFrame("Frame", nil, OpacitySliderFrame)
            thumb:SetPoint("TOPLEFT", thumbTexture, 0, 0)
            thumb:SetPoint("BOTTOMRIGHT", thumbTexture, 0, 0)
            Base.SetBackdrop(thumb, Color.button)
            OpacitySliderFrame._auroraThumb = thumb
        end
    end
end
