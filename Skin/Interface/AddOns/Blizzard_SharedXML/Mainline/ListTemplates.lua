local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Color = Aurora.Color

--do --[[ SharedXML\ListTemplates.lua ]]
--end

do --[[ SharedXML\ListTemplates.xml ]]
    -- B223/B220: ListHeaderVisualTemplate has no Left/Middle/Right pieces; its
    -- brown bar is the button's own NormalTexture (common-button-list-
    -- collapseExpand) with the same atlas as an ADD HighlightTexture. Blizzard
    -- never re-sets either (ListHeaderVisualMixin only touches the title and
    -- the CollapseButton), so recolour them once: the flat band the quest log
    -- headers already use (QuestMapFrame.lua, StyleListHeader). The gold +/-
    -- CollapseButton is the affordance and stays.
    function Skin.ListHeaderVisualTemplate(Button)
        local normal = Button:GetNormalTexture()
        if normal then
            local r, g, b = Color.button:GetRGB()
            normal:SetColorTexture(r, g, b, 0.6)
        end
        local highlight = Button:GetHighlightTexture()
        if highlight then
            local r, g, b = Color.highlight:GetRGB()
            highlight:SetColorTexture(r, g, b, 0.25)
        end
    end

    -- Options_ListExpand_* three-slice header. Used by the reputation rows
    -- (Skin/shared/ReputationFrame.lua), the housing blueprint collection and
    -- the CooldownViewer group-buff filter sections. It lived in the
    -- HousingBlueprint skin, which does not load on Forever, so Forever's
    -- reputation headers went unskinned.
    function Skin.ListHeaderThreeSliceTemplate(Frame)
        if Frame.Left then Frame.Left:SetAlpha(0) end
        if Frame.Middle then Frame.Middle:SetAlpha(0) end
        if Frame.Right then Frame.Right:SetAlpha(0) end
    end
end

--function private.SharedXML.ListTemplates()
--end
