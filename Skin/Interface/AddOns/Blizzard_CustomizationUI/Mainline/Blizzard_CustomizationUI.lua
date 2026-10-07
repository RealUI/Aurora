local _, private = ...
if private.shouldSkip() then return end

local Aurora = private.Aurora
local Base, Hook, Skin = Aurora.Base, Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

-- A flat box on an existing 32x32 checkbox state texture, inset 7px with
-- vertex offsets so the region keeps its size and anchors.
local function SetCheckBox(texture, r, g, b, a)
    texture:SetColorTexture(r, g, b, a)
    texture:SetVertexOffset(1, 7, -7)
    texture:SetVertexOffset(2, 7, 7)
    texture:SetVertexOffset(3, -7, -7)
    texture:SetVertexOffset(4, -7, 7)
end

-- Skin a pooled option frame (dropdown, slider, or checkbox).
-- Taint audit 2026-10-06 (B170 follow-up): in place only. The pools are no
-- longer wrapped (their Acquire post-hooks ran mid-UpdateOptionButtons, before
-- Blizzard's SetupOption and Layout), and the checkbox no longer gets
-- Skin.FrameTypeCheckButton (backdrop frame, highlight scripts, fields): the
-- existing Normal / Pushed / Highlight textures become the flat box and
-- Blizzard's check mark stays.
local function SkinOptionFrame(frame)
    if not frame or private.IsSkinned(frame) then return end
    private.SetSkinned(frame, true)

    -- Checkbox option: restyle the inner CheckButton's own textures
    local button = frame.Button
    if button and button.GetObjectType and button:GetObjectType() == "CheckButton" then
        local r, g, b = Color.button:GetRGB()
        SetCheckBox(button:GetNormalTexture(), r, g, b, 0.3)
        SetCheckBox(button:GetPushedTexture(), r, g, b, 0.3)
        SetCheckBox(button:GetHighlightTexture(), Color.highlight.r, Color.highlight.g, Color.highlight.b, 0.25)
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
            if private.IsSkinned(self) then return end
            private.SetSkinned(self, true)

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

            -- Option pools: skinned in place by the UpdateOptionButtons
            -- post-hook above, after Blizzard's setup and layout, not from
            -- the pools' Acquire (taint audit 2026-10-06).
        end)
    end
end
