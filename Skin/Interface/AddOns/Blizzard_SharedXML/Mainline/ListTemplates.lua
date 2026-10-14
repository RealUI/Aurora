local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin

--do --[[ SharedXML\ListTemplates.lua ]]
--end

do --[[ SharedXML\ListTemplates.xml ]]
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
