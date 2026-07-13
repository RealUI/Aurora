local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin

--[[ Classic-family color picker + opacity flyout. Evidence:
    Blizzard_FrameXML/Classic/ColorPickerFrame.xml — the root is a
    ColorSelect widget: NO region sweep here (the color wheel/value slider
    are texture regions); only the dialog-header art is stripped by name.
]]

function private.FrameXML.ColorPickerFrame()
    Skin.FrameTypeFrame(_G.ColorPickerFrame)
    if _G.ColorPickerFrameHeader then
        _G.ColorPickerFrameHeader:SetTexture("")
    end

    Skin.UIPanelButtonTemplate(_G.ColorPickerCancelButton)
    Skin.UIPanelButtonTemplate(_G.ColorPickerOkayButton)

    if _G.OpacityFrame then
        Skin.FrameTypeFrame(_G.OpacityFrame)
    end
end
