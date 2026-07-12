local _, private = ...
if private.shouldSkip() then return end

local Aurora = private.Aurora
local Base, Hook, Skin = Aurora.Base, Aurora.Hook, Aurora.Skin
local Util = Aurora.Util

do --[[ AddOns\Blizzard_SharedTalentUI.lua ]]
    -- Skin a single talent button node.
    local function SkinTalentButton(button)
        if not button or button._auroraSkinned then return end
        button._auroraSkinned = true

        -- Crop the ability icon
        if button.Icon then
            Base.CropIcon(button.Icon, button)
        end

        -- Hide the decorative shadow texture
        if button.Shadow then
            button.Shadow:SetAlpha(0)
        end
    end

    Hook.TalentButtonBaseMixin = {}
    function Hook.TalentButtonBaseMixin:OnLoad()
        SkinTalentButton(self)
    end
    function Hook.TalentButtonBaseMixin:UpdateVisualState()
        SkinTalentButton(self)
    end
end

function private.AddOns.Blizzard_SharedTalentUI()
    ------------------------------------
    -- Hook TalentButtonBaseMixin (has OnLoad + UpdateVisualState)
    ------------------------------------
    if _G.TalentButtonBaseMixin then
        Util.Mixin(_G.TalentButtonBaseMixin, Hook.TalentButtonBaseMixin)
    end

    -- Sub-mixins inherit OnLoad/UpdateVisualState from TalentButtonBaseMixin,
    -- so the hooks above already fire for them. No need to double-hook.

    ------------------------------------
    -- Skin the talent frame container
    ------------------------------------
    -- The talent frame is typically ClassTalentFrame from Blizzard_ClassMenu,
    -- but SharedTalentUI provides the base template. We skin any frame that
    -- inherits TalentFrameBaseTemplate when it becomes available.
    -- ClassTalentFrame is created by Blizzard_ClassMenu, not here, so we
    -- hook TalentFrameBaseMixin:OnLoad to catch all derived frames.
    if _G.TalentFrameBaseMixin then
        -- Skin the frame container when it loads.
        _G.hooksecurefunc(_G.TalentFrameBaseMixin, "OnLoad", function(self)
            if self._auroraSkinned then return end
            self._auroraSkinned = true

            Skin.FrameTypeFrame(self)
            Base.StripBlizzardTextures(self)
        end)

        -- Wrap talent node pools as they are lazily created.
        -- AcquireTalentButton calls GetOrCreatePool, so we hook it to
        -- wrap each new sub-pool the first time it appears.
        local skinPoolButton = function(button)
            if not button or button._auroraSkinned then return end
            button._auroraSkinned = true
            if button.Icon then
                Base.CropIcon(button.Icon, button)
            end
            if button.Shadow then
                button.Shadow:SetAlpha(0)
            end
        end

        _G.hooksecurefunc(_G.TalentFrameBaseMixin, "AcquireTalentButton", function(self)
            -- Wrap any unwrapped pools in the collection.
            if self.talentButtonCollection and self.talentButtonCollection.EnumeratePools then
                for pool in self.talentButtonCollection:EnumeratePools() do
                    Util.WrapPoolAcquire(pool, skinPoolButton)
                end
            end
        end)
    end
end
