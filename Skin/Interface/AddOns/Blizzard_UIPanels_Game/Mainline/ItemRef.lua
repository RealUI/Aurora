local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin

--do --[[ FrameXML\ItemRef.lua ]]
--end

--do --[[ FrameXML\ItemRef.xml ]]
--end

function private.FrameXML.ItemRef()
    if private.disabled.tooltips then return end

    -- B94: same taint-safe path as GameTooltip and the main shopping tooltips.
    -- Falls back to the old route if Blizzard_GameTooltip's skin has not run
    -- yet, since these two files are triggered by different addons loading.
    local ApplyTaintSafe = private.ApplyTaintSafeTooltipSkin
    if ApplyTaintSafe then
        ApplyTaintSafe(_G.ItemRefShoppingTooltip1)
        ApplyTaintSafe(_G.ItemRefShoppingTooltip2)
    else
        Skin.ShoppingTooltipTemplate(_G.ItemRefShoppingTooltip1)
        Skin.ShoppingTooltipTemplate(_G.ItemRefShoppingTooltip2)
    end

    Skin.GameTooltipTemplate(_G.ItemRefTooltip)
    if private.isRetail then
        Skin.UIPanelCloseButton(_G.ItemRefTooltip.CloseButton)
    else
        Skin.UIPanelCloseButton(_G.ItemRefCloseButton)
    end
end
