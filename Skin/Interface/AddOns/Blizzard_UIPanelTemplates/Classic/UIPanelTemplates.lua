local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Util = Aurora.Util

--[[ Classic-family UIPanelTemplates. Evidence: wow-ui-source-classic/
    Interface/AddOns/Blizzard_UIPanelTemplates/Classic/UIPanelTemplates.xml
    L1009: EtherealFrameTemplate = PortraitFrameTemplate + Transmogrify
    corner/edge overlay art + an UNNAMED purple tint over the title bg —
    instances (ReforgingUI, ItemUpgradeUI on Mists) also pile on their own
    unnamed body tints, so the whole frame is alpha-swept BEFORE the
    backdrop. Callers must SetAlpha(1) any content/state textures that
    need to survive (taxi-map pattern). The retail skin's tiled
    EtherealLines flourish is skipped (its region indexing is
    retail-specific).
]]

do --[[ Blizzard_UIPanelTemplates\Classic\UIPanelTemplates.xml ]]
    function Skin.EtherealFrameTemplate(Frame)
        Util.HideFrameTextures(Frame, true)
        Skin.PortraitFrameTemplate(Frame)
    end
end
