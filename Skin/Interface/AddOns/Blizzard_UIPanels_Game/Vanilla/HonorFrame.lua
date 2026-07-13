local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Util = Aurora.Util

--[[ Era honor tab (CharacterFrame tab 5).
    Evidence: wow-ui-source-era/Interface/AddOns/Blizzard_UIPanels_Game/
    Vanilla/HonorFrame.xml — mostly text stat rows (HK/DK/contribution
    label templates, no chrome of their own) over column art on the root,
    plus the rank progress bar. The rank insignia icon is informational —
    kept.
]]

function private.FrameXML.HonorFrame()
    Util.HideFrameTextures(_G.HonorFrame)

    local bar = _G.HonorFrameProgressBar
    if bar then
        -- strip the bar's own border art BEFORE the backdrop is created
        Util.HideFrameTextures(bar)
        Skin.FrameTypeStatusBar(bar)
    end
end
