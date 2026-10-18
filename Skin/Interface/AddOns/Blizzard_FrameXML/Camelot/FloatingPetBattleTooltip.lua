local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin

-- Forever 70450 replaces FloatingPetBattleTooltip.lua/.xml with Camelot
-- copies ([Game] lines, [ExcludeLoadGameType camelot] on the base), so the
-- Mainline skin no longer loads there. The frames keep their names and
-- keys -- the Camelot BattlePetTooltipTemplate only trims the stat rows
-- down to Name -- so this mirrors Mainline\FloatingPetBattleTooltip.lua.
-- Mainline\BattlePetTooltip.lua still loads on Forever and calls
-- Skin.BattlePetTooltipTemplate, which is defined here for it.

--do --[[ FrameXML\FloatingPetBattleTooltip.lua ]]
--end

do --[[ FrameXML\FloatingPetBattleTooltip.xml ]]
    function Skin.BattlePetTooltipTemplate(Frame)
        Skin.TooltipBorderedFrameTemplate(Frame)
    end
end

function private.FrameXML.FloatingPetBattleTooltip()
    if private.disabled.tooltips then return end

    Skin.SharedPetBattleAbilityTooltipTemplate(_G.FloatingPetBattleAbilityTooltip)
    Skin.UIPanelCloseButton(_G.FloatingPetBattleAbilityTooltip.CloseButton)

    Skin.BattlePetTooltipTemplate(_G.FloatingBattlePetTooltip)
    _G.FloatingBattlePetTooltip.Delimiter:SetHeight(1)
    Skin.UIPanelCloseButton(_G.FloatingBattlePetTooltip.CloseButton)
end
