local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

-- [[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base

-- Shared helper: skin a single aura button (buff, debuff, or temp enchant)
local function SkinAuraButton(button)
    if not button or button._auroraSkinned then return end
    if button.IsForbidden and button:IsForbidden() then return end
    if button.isAuraAnchor then return end

    -- Crop the icon texture to remove built-in borders
    if button.Icon then
        Base.CropIcon(button.Icon)
    end

    -- Strip the TempEnchant border texture. DebuffBorder is left alone
    -- because Blizzard toggles its visibility and atlas at runtime via
    -- AuraUtil.SetAuraBorderAtlas — hiding it would break dispel-type
    -- colouring.
    if button.TempEnchantBorder then
        button.TempEnchantBorder:SetTexture("")
    end

    button._auroraSkinned = true
end

--[[ AddOns\Blizzard_BuffFrame.lua ]]
-- No Hook table — we use hooksecurefunc exclusively for this
-- taint-sensitive addon. Never replace methods on BuffFrameMixin
-- or AuraFrameMixin.

--[[ AddOns\Blizzard_BuffFrame.xml ]]
-- Aura button templates are skinned dynamically via hooksecurefunc
-- hooks on AuraFrame_OnLoad and UpdateAuraButtons.

function private.AddOns.Blizzard_BuffFrame()
    -- AuraFrameMixin is the modern (Mainline) buff/debuff system.
    -- TBC Classic uses the legacy buff frame with individually-named buttons.
    if not _G.AuraFrameMixin then
        -- TBC Classic: skin legacy buff buttons directly
        local function SkinLegacyBuffButtons()
            for i = 1, _G.BUFF_MAX_DISPLAY or 40 do
                local button = _G["BuffButton"..i]
                SkinAuraButton(button)
            end
            for i = 1, _G.DEBUFF_MAX_DISPLAY or 16 do
                local button = _G["DebuffButton"..i]
                SkinAuraButton(button)
            end
            for i = 1, _G.NUM_TEMP_ENCHANT_FRAMES or 3 do
                local button = _G["TempEnchant"..i]
                SkinAuraButton(button)
            end
        end
        SkinLegacyBuffButtons()
        -- Hook BuffFrame_UpdateAllBuffAnchors to catch newly created buttons
        if _G.BuffFrame_UpdateAllBuffAnchors then
            _G.hooksecurefunc("BuffFrame_UpdateAllBuffAnchors", SkinLegacyBuffButtons)
        end
        return
    end

    ------------------------------------------------
    -- Hook AuraFrameMixin:AuraFrame_OnLoad to skin
    -- the initial batch of aura buttons created via
    -- CreateFrame("BUTTON", ..., "AuraButtonTemplate").
    ------------------------------------------------
    _G.hooksecurefunc(_G.AuraFrameMixin, "AuraFrame_OnLoad", function(self)
        if not self or (self.IsForbidden and self:IsForbidden()) then return end

        if self.auraFrames then
            for _, auraFrame in _G.ipairs(self.auraFrames) do
                SkinAuraButton(auraFrame)
            end
        end
    end)

    ------------------------------------------------
    -- Hook AuraFrameMixin:UpdateAuraButtons to catch
    -- newly shown buttons and apply skinning. This
    -- covers buttons that may not have been skinned
    -- during AuraFrame_OnLoad (e.g. late additions).
    ------------------------------------------------
    _G.hooksecurefunc(_G.AuraFrameMixin, "UpdateAuraButtons", function(self)
        if not self or (self.IsForbidden and self:IsForbidden()) then return end

        if self.auraFrames then
            for _, auraFrame in _G.ipairs(self.auraFrames) do
                SkinAuraButton(auraFrame)
            end
        end
    end)

    ------------------------------------------------
    -- Do not skin ExternalDefensivesFrame itself.
    -- Blizzard keeps this container visible when the
    -- feature is enabled, so a backdrop becomes a
    -- permanently visible bar with no active auras.
    ------------------------------------------------
    local externalDefensives = _G.ExternalDefensivesFrame

    ------------------------------------------------
    -- Skin any already-created aura buttons on
    -- BuffFrame and DebuffFrame (if they loaded
    -- before us).
    ------------------------------------------------
    local function SkinExistingAuraFrames(frame)
        if not frame or (frame.IsForbidden and frame:IsForbidden()) then return end
        if frame.auraFrames then
            for _, auraFrame in _G.ipairs(frame.auraFrames) do
                SkinAuraButton(auraFrame)
            end
        end
    end

    SkinExistingAuraFrames(_G.BuffFrame)
    SkinExistingAuraFrames(_G.DebuffFrame)
    SkinExistingAuraFrames(externalDefensives)
end
