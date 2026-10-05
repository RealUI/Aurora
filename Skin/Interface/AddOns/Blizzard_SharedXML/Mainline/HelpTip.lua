local _, private = ...
if private.shouldSkip() then return end

--[[ Help tips are deliberately left as Blizzard art (2026-10-05).

     They used to be skinned: GlowBoxTemplate backdrop, button skins, and a
     RotateArrow post-hook that resized the arrow from addon code. A login
     taint.log (tracker-widget-taint-rewrite, B168) showed what that costs.
     Blizzard shows help tips from inside its own executions, the world map
     opening among them (Blizzard_WorldMapTemplates.lua:804 -> HelpTip:Show).
     Blizzard's HelpTip code keeps using the frame after Acquire, reads the
     fields the skin wrote, and the rest of that execution runs tainted: the
     map's world-quest POIs then create QuestCache entries under Aurora's
     taint, and the objective tracker inherits it when it reads the same
     cache. The same chain is the likely Aurora side of the map errors in
     known-wow-ui-bugs.md #1. A help tip is a rare tutorial popup; it is not
     worth that. Restyle in place only, or not at all. ]]

function private.FrameXML.HelpTip()
end
