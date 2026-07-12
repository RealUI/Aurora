local _, private = ...
if private.shouldSkip() then return end

local Aurora = private.Aurora
local Base, Hook, Skin = Aurora.Base, Aurora.Hook, Aurora.Skin
local Util = Aurora.Util

-- Skin a dynamically acquired option frame (dropdown, slider, or checkbox).
local function SkinOptionFrame(frame)
    if not frame or frame._auroraSkinned then return end
    frame._auroraSkinned = true

    -- Checkbox option: skin the inner CheckButton
    if frame.Button and frame.Button.GetObjectType and frame.Button:GetObjectType() == "CheckButton" then
        Skin.FrameTypeCheckButton(frame.Button)
    end
end

do --[[ AddOns\Blizzard_CustomizationUI.lua ]]
    Hook.CustomizationFrameBaseMixin = {}
    function Hook.CustomizationFrameBaseMixin:UpdateOptionButtons()
        -- Post-hook: skin any newly acquired option frames from the pools.
        -- Dropdowns
        if self.dropdownPool then
            for optionFrame in self.dropdownPool:EnumerateActive() do
                SkinOptionFrame(optionFrame)
            end
        end
        -- Sliders
        if self.sliderPool then
            for optionFrame in self.sliderPool:EnumerateActive() do
                SkinOptionFrame(optionFrame)
            end
        end
        -- Checkboxes (from the FramePoolCollection)
        if self.pools then
            local checkPool = self.pools:GetPool("CustomizationOptionCheckButtonTemplate")
            if checkPool then
                for optionFrame in checkPool:EnumerateActive() do
                    SkinOptionFrame(optionFrame)
                end
            end
        end
    end
end

function private.AddOns.Blizzard_CustomizationUI()
    ------------------------------------
    -- Hook CustomizationFrameBaseMixin
    ------------------------------------
    if _G.CustomizationFrameBaseMixin then
        Util.Mixin(_G.CustomizationFrameBaseMixin, Hook.CustomizationFrameBaseMixin)

        -- Skin the customization frame container when it loads.
        _G.hooksecurefunc(_G.CustomizationFrameBaseMixin, "CustomizationFrameBase_OnLoad", function(self)
            if self._auroraSkinned then return end
            self._auroraSkinned = true

            -- Main frame backdrop
            Skin.FrameTypeFrame(self)

            -- Strip decorative borders
            Base.StripBlizzardTextures(self)

            -- Skin small button controls (camera, zoom, rotate)
            if self.SmallButtons then
                local buttons = {
                    self.SmallButtons.ResetCameraButton,
                    self.SmallButtons.ZoomOutButton,
                    self.SmallButtons.ZoomInButton,
                    self.SmallButtons.RotateLeftButton,
                    self.SmallButtons.RotateRightButton,
                }
                for _, btn in ipairs(buttons) do
                    if btn then
                        Skin.FrameTypeButton(btn)
                    end
                end
            end

            -- Wrap option pools with Util.WrapPoolAcquire
            if self.dropdownPool then
                Util.WrapPoolAcquire(self.dropdownPool, SkinOptionFrame)
            end
            if self.sliderPool then
                Util.WrapPoolAcquire(self.sliderPool, SkinOptionFrame)
            end
            if self.pools then
                local checkPool = self.pools:GetPool("CustomizationOptionCheckButtonTemplate")
                if checkPool then
                    Util.WrapPoolAcquire(checkPool, SkinOptionFrame)
                end
            end
        end)
    end
end
