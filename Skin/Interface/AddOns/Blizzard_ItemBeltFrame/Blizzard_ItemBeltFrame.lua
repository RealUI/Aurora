local _, private = ...
if private.shouldSkip() then return end

local Aurora = private.Aurora
local Base = Aurora.Base
local Util = Aurora.Util

-- Skin a single item belt button acquired from the pool.
-- Each button inherits HUDInventoryButtonTemplate with:
--   Icon (texture), BG (atlas background), IconMask, NormalTexture (atlas border),
--   HighlightTexture, PushedTexture, HotKey, Count, Cooldown
local function SkinBeltButton(button)
    if not button or private.IsSkinned(button) then return end
    private.SetSkinned(button, true)

    -- Crop the item icon
    Base.CropIcon(button.Icon, button)

    -- Strip decorative atlas textures (border, background)
    if button.BG then
        button.BG:SetAlpha(0)
    end
    local normalTex = button:GetNormalTexture()
    if normalTex then
        normalTex:SetAlpha(0)
    end
end

function private.AddOns.Blizzard_ItemBeltFrame()
    local frame = _G.ItemBeltFrame
    if not frame then return end

    -- Wrap the item button pool so dynamically acquired buttons are skinned
    if frame.itemButtonPool then
        Util.WrapPoolAcquire(frame.itemButtonPool, SkinBeltButton)
    end

    -- Skin any buttons already active in the pool
    if frame.itemButtonPool and frame.itemButtonPool.EnumerateActive then
        for button in frame.itemButtonPool:EnumerateActive() do
            SkinBeltButton(button)
        end
    end
end
