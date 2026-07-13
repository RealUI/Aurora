local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin

--[[ Classic-family money display (era/TBC/Mists; retail resolves Mainline/).
    The coin icons here are slices of the UI-MoneyIcons SHEET (texcoords) —
    Base.CropIcon would destroy the slice, so unlike retail nothing is
    cropped. Both templates are deliberate no-ops kept as dispatch targets
    for callers (popups, trainer, quest rewards).
]]

do --[[ Classic\MoneyFrame.xml ]]
    Skin.SmallMoneyFrameTemplate = private.nop
    Skin.SmallDenominationTemplate = private.nop
end
