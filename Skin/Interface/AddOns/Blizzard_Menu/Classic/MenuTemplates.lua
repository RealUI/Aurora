local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Color = Aurora.Color

--[[ Classic-family modern Menu styles (era/TBC/Mists).
    Evidence: wow-ui-source-*/Interface/AddOns/Blizzard_Menu/Classic/MenuTemplates.lua
    MenuStyle1Mixin:Generate uses atlas "common-dropdown-classic-bg",
    MenuStyle2Mixin uses "common-dropdown-classic-b-bg" (identical names on
    era/TBC/Mists trees). Context menus (MenuUtil.CreateContextMenu — e.g.
    the unit popup) render through these styles on all classic clients.

    TAINT NOTE (from the Mainline MenuVariants skin): do NOT Base.SetBackdrop
    the style frame — menu clicks dispatch through it and table writes taint
    the click context. Recoloring the Blizzard-created background texture via
    the widget API is safe.
]]

local menuBackgroundAtlas = {
    ["common-dropdown-classic-bg"] = true,
    ["common-dropdown-classic-b-bg"] = true,
}

local function RecolorMenuBackground(self)
    for _, region in ipairs({ self:GetRegions() }) do
        if region:IsObjectType("Texture") and menuBackgroundAtlas[region:GetAtlas()] then
            region:SetColorTexture(Color.frame.r, Color.frame.g, Color.frame.b, Color.frame.a)
        end
    end
end

function private.AddOns.Blizzard_Menu()
    if _G.MenuStyle1Mixin then
        _G.hooksecurefunc(_G.MenuStyle1Mixin, "Generate", RecolorMenuBackground)
    end
    if _G.MenuStyle2Mixin then
        _G.hooksecurefunc(_G.MenuStyle2Mixin, "Generate", RecolorMenuBackground)
    end
end
