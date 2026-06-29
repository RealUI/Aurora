local _, private = ...
if private.shouldSkip() then return end

local Aurora = private.Aurora
local Base = Aurora.Base

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

-- Nameplate health/cast bars are managed by the restricted nameplate system.
-- Base.SetBackdrop writes BackdropMixin functions and _backdropInfo directly
-- onto the bar frame.  Those direct writes taint the bar; on the next nameplate
-- reuse cycle, CompactUnitFrame_UpdateHealPrediction reads GetMinMaxValues()
-- in a tainted context and gets a "secret number value" error.  The hooks
-- installed by Skin.FrameTypeStatusBar also fire during CompactUnitFrame_UpdateAll
-- and can propagate the taint into GetScaledRect() via the widget layout path.
-- Skip bar skinning entirely for nameplates to keep those frames clean.
local SkinBar = private.nop  --luacheck: ignore 231

-- Skin a single aura icon frame (NameplateAuraItemTemplate)
local function SkinAuraIcon(auraFrame)
    if not auraFrame then return end
    if auraFrame.IsForbidden and auraFrame:IsForbidden() then return end
    if auraFrame._auroraSkinned then return end

    if auraFrame.Icon then
        Base.CropIcon(auraFrame.Icon)
    end
    auraFrame._auroraSkinned = true
end

-- Walk all visible children of an aura list frame and crop their icons
local function SkinAuraList(listFrame)
    if not listFrame then return end
    if listFrame.IsForbidden and listFrame:IsForbidden() then return end

    local children = { listFrame:GetChildren() }
    for _, child in next, children do
        SkinAuraIcon(child)
    end
end

-- Skin all aura frames on a unit frame
local function SkinAuras(unitFrame)
    local aurasFrame = unitFrame.AurasFrame
    if not aurasFrame then return end
    if aurasFrame.IsForbidden and aurasFrame:IsForbidden() then return end

    SkinAuraList(aurasFrame.DebuffListFrame)
    SkinAuraList(aurasFrame.BuffListFrame)
    SkinAuraList(aurasFrame.CrowdControlListFrame)

    -- LossOfControlFrame has a single AuraItemFrame child
    local locFrame = aurasFrame.LossOfControlFrame
    if locFrame and locFrame.AuraItemFrame then
        SkinAuraIcon(locFrame.AuraItemFrame)
    end
end

-- Skin a single nameplate unit frame (the UnitFrame child of the base nameplate)
local function SkinUnitFrame(unitFrame)
    if not unitFrame then return end
    if unitFrame.IsForbidden and unitFrame:IsForbidden() then return end
    if unitFrame._auroraSkinned then return end
    unitFrame._auroraSkinned = true

    -- Health bar
    local healthContainer = unitFrame.HealthBarsContainer
    if healthContainer then
        -- Strip the NamePlateFullBorderTemplate border textures
        local border = healthContainer.border
        if border then
            Base.StripBlizzardTextures(border)
        end

        SkinBar(healthContainer.healthBar)
    end

    -- Cast bar
    SkinBar(unitFrame.castBar)

    -- Aura icons (initial pass — dynamic auras are re-skinned via RefreshAuras hook)
    SkinAuras(unitFrame)
end

--------------------------------------------------------------------------------
-- Hooks — SAFETY: all hooks use hooksecurefunc exclusively
--------------------------------------------------------------------------------

-- We hook OnNamePlateAdded on the driver mixin to skin each nameplate as
-- it is assigned a unit. This fires for both normal and forbidden plates.
-- SAFETY: hooksecurefunc only — never replace the original function.
-- SAFETY: IsForbidden() check — skip forbidden nameplates silently.
-- SAFETY: No SetAttribute calls anywhere.

--------------------------------------------------------------------------------
-- Registration
--------------------------------------------------------------------------------

function private.AddOns.Blizzard_NamePlates()
    -- NamePlateDriverMixin and NamePlateAurasMixin are the modern (Mainline)
    -- nameplate system. TBC Classic uses a different nameplate framework.
    if not _G.NamePlateDriverMixin then return end

    ------------------------------------------------
    -- Hook NamePlateDriverMixin:OnNamePlateAdded
    -- Fires after the driver acquires a UnitFrame and calls SetUnit.
    -- SAFETY: hooksecurefunc — does not taint the secure call chain.
    ------------------------------------------------
    _G.hooksecurefunc(_G.NamePlateDriverMixin, "OnNamePlateAdded", function(self, namePlateUnitToken)
        local namePlateFrameBase = self:GetNamePlateForUnit(namePlateUnitToken)
        if not namePlateFrameBase then return end

        -- SAFETY: skip forbidden nameplates silently
        if namePlateFrameBase.IsForbidden and namePlateFrameBase:IsForbidden() then return end

        local unitFrame = namePlateFrameBase.UnitFrame
        SkinUnitFrame(unitFrame)
    end)

    ------------------------------------------------
    -- Hook aura refresh to skin dynamically acquired aura icons.
    -- The aura pool releases and re-acquires frames on every refresh,
    -- so we re-skin after each RefreshAuras call.
    ------------------------------------------------
    if _G.NamePlateAurasMixin then
        _G.hooksecurefunc(_G.NamePlateAurasMixin, "RefreshAuras", function(self)
            if self.IsForbidden and self:IsForbidden() then return end

            SkinAuraList(self.DebuffListFrame)
            SkinAuraList(self.BuffListFrame)
            SkinAuraList(self.CrowdControlListFrame)
        end)

        _G.hooksecurefunc(_G.NamePlateAurasMixin, "RefreshLossOfControl", function(self)
            if self.IsForbidden and self:IsForbidden() then return end

            local locFrame = self.LossOfControlFrame
            if locFrame and locFrame.AuraItemFrame then
                SkinAuraIcon(locFrame.AuraItemFrame)
            end
        end)
    end

    ------------------------------------------------
    -- Hook class nameplate bar setup to skin class-specific power bars
    -- (DK runes, Druid combo, Mage arcane charges, etc.)
    ------------------------------------------------
    _G.hooksecurefunc(_G.NamePlateDriverMixin, "SetClassNameplateBar", function(self, frame)
        if frame then
            SkinBar(frame)
        end
    end)

    if _G.NamePlateDriverMixin.SetClassNameplateManaBar then
        _G.hooksecurefunc(_G.NamePlateDriverMixin, "SetClassNameplateManaBar", function(self, frame)
            if frame then
                SkinBar(frame)
            end
        end)
    end

    if _G.NamePlateDriverMixin.SetClassNameplateAlternatePowerBar then
        _G.hooksecurefunc(_G.NamePlateDriverMixin, "SetClassNameplateAlternatePowerBar", function(self, frame)
            if frame then
                SkinBar(frame)
            end
        end)
    end

    ------------------------------------------------
    -- Skin any nameplates that already exist (in case addon loads late)
    ------------------------------------------------
    local driverFrame = _G.NamePlateDriverFrame
    if driverFrame and driverFrame.ForEachNamePlate then
        driverFrame:ForEachNamePlate(function(namePlateFrameBase)
            if namePlateFrameBase.IsForbidden and namePlateFrameBase:IsForbidden() then return end
            local unitFrame = namePlateFrameBase.UnitFrame
            if unitFrame then
                SkinUnitFrame(unitFrame)
                SkinAuras(unitFrame)
            end
        end)
    end
end
