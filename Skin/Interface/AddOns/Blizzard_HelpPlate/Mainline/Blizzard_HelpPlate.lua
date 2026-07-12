local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Color = Aurora.Color

-- Shared helper: skin a single HelpPlate tile frame
local function SkinTile(tile)
    if not tile or tile._auroraSkinned then return end

    -- Strip decorative border/glow/shadow textures from the Box frame
    local box = tile.Box
    if box then
        Base.StripBlizzardTextures(box)
    end

    tile._auroraSkinned = true
end

--[[ AddOns\Blizzard_HelpPlate.lua ]]
-- HelpPlate.Show creates tiles dynamically from a tilePool.
-- We post-hook HelpPlate.Show via hooksecurefunc to skin
-- each tile after it is acquired and configured.

--[[ AddOns\Blizzard_HelpPlate.xml ]]
-- HelpPlateTile, HelpPlateCanvas, and HelpPlateTooltip are
-- defined in XML. Skinning is applied in the addon registration
-- function below.

function private.AddOns.Blizzard_HelpPlate()
    ------------------------------------------------
    -- Skin the HelpPlateCanvas overlay
    ------------------------------------------------
    local canvas = _G.HelpPlateCanvas
    if canvas then
        Base.SetBackdrop(canvas, Color.frame)
    end

    ------------------------------------------------
    -- Hook HelpPlate.Show to skin dynamically
    -- created callout tiles from the tilePool
    ------------------------------------------------
    _G.hooksecurefunc(_G.HelpPlate, "Show", function()
        -- Iterate all children of HelpPlateCanvas to find tile frames
        -- created by the tilePool during HelpPlate.Show
        local numChildren = canvas:GetNumChildren()
        for i = 1, numChildren do
            local child = _G.select(i, canvas:GetChildren())
            -- Tile frames have a Box child and a Button child
            if child and child.Box then
                SkinTile(child)
            end
        end
    end)
end
