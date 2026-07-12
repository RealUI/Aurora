local _, private = ...
if private.shouldSkip() then return end

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin

--[[ Classic-family CharacterFrameTabButtonTemplate (era/TBC/Mists).
    Evidence: wow-ui-source-*/Interface/AddOns/Blizzard_FrameXML/Classic/CharacterFrameTemplates.xml
    Old-style bottom tab: six $parent-named textures (no parentKeys) plus a
    named highlight texture. PanelTemplates_TabResize runs from the tab's own
    OnShow/OnEvent scripts — never resize the tab from the skin; the
    _auroraTabResize flag lets Aurora's PanelTemplates_TabResize hook adjust.
]]

function Skin.CharacterFrameTabButtonTemplate(Button)
    local name = Button:GetName()

    _G[name.."LeftDisabled"]:SetAlpha(0)
    _G[name.."MiddleDisabled"]:SetAlpha(0)
    _G[name.."RightDisabled"]:SetAlpha(0)
    _G[name.."Left"]:SetAlpha(0)
    _G[name.."Middle"]:SetAlpha(0)
    _G[name.."Right"]:SetAlpha(0)

    _G[name.."HighlightTexture"]:SetTexture("")
    Button._auroraTabResize = true
end
