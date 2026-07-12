local _, private = ...
if private.shouldSkip() then return end

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Color = Aurora.Color

--[[ Classic-family tooltip backdrop templates (era/TBC/Mists).
    Evidence: wow-ui-source-*/Interface/AddOns/Blizzard_SharedXML/SharedTooltipTemplates.xml
    (L104: TooltipBackdropTemplate = NineSlice child with TooltipDefaultLayout,
    same structure as retail). Full GameTooltip skinning is a later wave; this
    file provides the template functions other skins depend on (for example
    the UIDropDownList MenuBackdrop).
]]

function Skin.TooltipBackdropTemplate(Frame)
    Skin.NineSlicePanelTemplate(Frame.NineSlice)

    local r, g, b = Color.frame:GetRGB()
    Frame:SetBackdropColor(r, g, b, Frame.backdropColorAlpha or 1)
end
function Skin.TooltipBorderBackdropTemplate(Frame)
    Skin.TooltipBackdropTemplate(Frame)
end
