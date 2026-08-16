local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base, Hook, Skin = Aurora.Base, Aurora.Hook, Aurora.Skin
local Color = Aurora.Color

do --[[ AddOns\Blizzard_HouseList.lua ]]
    Hook.HouseEntryTemplateMixin = {}
    function Hook.HouseEntryTemplateMixin:Expand()
        if self._auroraBackdrop then
            Color.highlight:SetBackdropBorderColor(self._auroraBackdrop)
        end
    end
    function Hook.HouseEntryTemplateMixin:Collapse()
        if self._auroraBackdrop then
            Color.button:SetBackdropBorderColor(self._auroraBackdrop)
        end
    end
end

do --[[ AddOns\Blizzard_HouseList.xml ]]
    function Skin.HouseEntryTemplate(Button)
        if private.IsSkinned(Button) then return end
        private.SetSkinned(Button, true)

        Base.SetBackdrop(Button, Color.button, 0.2)

        -- Hide decorative atlas textures
        if Button.Background then Button.Background:SetAlpha(0) end
        if Button.PlusMinusBack then Button.PlusMinusBack:SetAlpha(0) end

        -- Skin the visit button
        if Button.VisitHouseButton then
            Skin.UIPanelButtonTemplate(Button.VisitHouseButton)
        end

        -- Apply expand/collapse hooks
        _G.hooksecurefunc(Button, "Expand", Hook.HouseEntryTemplateMixin.Expand)
        _G.hooksecurefunc(Button, "Collapse", Hook.HouseEntryTemplateMixin.Collapse)
    end
end

function private.AddOns.Blizzard_HouseList()
    local HouseListFrame = _G.HouseListFrame

    ----
    -- Main Frame
    ----
    Base.SetBackdrop(HouseListFrame, Color.frame)

    -- Hide decorative atlas textures
    if HouseListFrame.Background then HouseListFrame.Background:SetAlpha(0) end
    if HouseListFrame.WoodHeader then HouseListFrame.WoodHeader:SetAlpha(0) end
    if HouseListFrame.DecorativeFoliage then HouseListFrame.DecorativeFoliage:SetAlpha(0) end

    ----
    -- ScrollBox / ScrollBar
    ----
    if HouseListFrame.ScrollBox then Skin.WowScrollBoxList(HouseListFrame.ScrollBox) end
    if HouseListFrame.ScrollBar then Skin.MinimalScrollBar(HouseListFrame.ScrollBar) end

    ----
    -- Hook HouseEntryTemplateMixin:Init to skin entries created by ScrollBox element initializer
    ----
    _G.hooksecurefunc(_G.HouseEntryTemplateMixin, "Init", function(self)
        Skin.HouseEntryTemplate(self)
    end)
end
