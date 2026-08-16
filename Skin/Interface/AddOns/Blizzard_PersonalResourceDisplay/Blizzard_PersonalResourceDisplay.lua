local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base, Hook, Skin = Aurora.Base, Aurora.Hook, Aurora.Skin
local Util = Aurora.Util

-- Shared helper: skin a StatusBar and strip its parent border frame
local function SkinBar(bar)
    if not bar or (bar.IsForbidden and bar:IsForbidden()) then return end
    if private.IsSkinned(bar) then return end

    Skin.FrameTypeStatusBar(bar)
    private.SetSkinned(bar, true)
end

do --[[ AddOns\Blizzard_PersonalResourceDisplay.lua ]]
    Hook.PersonalResourceDisplayMixin = {}
    function Hook.PersonalResourceDisplayMixin:SetupHealthBar()
        -- Re-skin after Blizzard resets textures/colors in SetupHealthBar
        local healthBar = self.HealthBarsContainer and self.HealthBarsContainer.healthBar
        SkinBar(healthBar)
    end

    function Hook.PersonalResourceDisplayMixin:SetupPowerBar()
        -- Re-skin after Blizzard resets textures/colors in SetupPowerBar
        SkinBar(self.PowerBar)
    end
end

--[[ AddOns\Blizzard_PersonalResourceDisplay.xml ]]
-- Static frame templates are skinned in the registration function below.

function private.AddOns.Blizzard_PersonalResourceDisplay()
    ------------------------------------------------
    -- Hook mixin prototypes via Util.Mixin
    ------------------------------------------------
    Util.Mixin(_G.PersonalResourceDisplayMixin, Hook.PersonalResourceDisplayMixin)

    ------------------------------------------------
    -- Skin the PersonalResourceDisplayFrame
    ------------------------------------------------
    local frame = _G.PersonalResourceDisplayFrame
    if not frame then return end

    -- Skin HealthBarsContainer
    local healthContainer = frame.HealthBarsContainer
    if healthContainer then
        -- Strip the NamePlateFullBorderTemplate border
        local border = healthContainer.border
        if border then
            Base.StripBlizzardTextures(border)
        end

        -- Skin the health bar
        SkinBar(healthContainer.healthBar)
    end

    -- Skin PowerBar
    local powerBar = frame.PowerBar
    if powerBar then
        -- Strip the NamePlateSecondaryBarBorderTemplate border
        if powerBar.Border then
            Base.StripBlizzardTextures(powerBar.Border)
        end

        SkinBar(powerBar)
    end

    -- Skin AlternatePowerBar if present
    local altBar = frame.AlternatePowerBar
    if altBar then
        if altBar.Border then
            Base.StripBlizzardTextures(altBar.Border)
        end

        SkinBar(altBar)
    end
end
