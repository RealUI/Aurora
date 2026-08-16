local _, private = ...
if private.shouldSkip() then return end

local Aurora = private.Aurora
local _, Hook, Skin = Aurora.Base, Aurora.Hook, Aurora.Skin
local Util = Aurora.Util

-- Strip RemixArtifactFrame-specific decorative textures.
-- The SharedTalentUI skin already handles TalentFrameBaseTemplate-level
-- skinning (FrameTypeFrame, StripBlizzardTextures, pool wrapping, icon
-- cropping via TalentButtonBaseMixin hooks). This function targets the
-- RemixArtifactFrame-specific overlays that sit on top of the talent tree.
local function StripRemixArtifactDecorations(frame)
    -- BorderOverlay atlas (ui-frame-legionartifact-border)
    if frame.BorderContainer and frame.BorderContainer.BorderOverlay then
        frame.BorderContainer.BorderOverlay:SetAlpha(0)
    end

    -- Model overlay textures
    if frame.Model then
        if frame.Model.BackgroundVignette then
            frame.Model.BackgroundVignette:SetAlpha(0)
        end
        if frame.Model.BackgroundFront then
            frame.Model.BackgroundFront:SetAlpha(0)
        end
        if frame.Model.BackgroundFrontSides then
            frame.Model.BackgroundFrontSides:SetAlpha(0)
        end
    end

    -- ButtonsParent overlay textures (created dynamically in OnLoad)
    if frame.ButtonsParent and frame.ButtonsParent.Overlay then
        local overlay = frame.ButtonsParent.Overlay
        if overlay.BackgroundVignetteTop then
            overlay.BackgroundVignetteTop:SetAlpha(0)
        end
        if overlay.BackgroundFrontTop then
            overlay.BackgroundFrontTop:SetAlpha(0)
        end
        if overlay.BackgroundFrontSides then
            overlay.BackgroundFrontSides:SetAlpha(0)
        end
    end

    -- Currency background atlas
    if frame.Currency and frame.Currency.CurrencyBackground then
        frame.Currency.CurrencyBackground:SetAlpha(0)
    end
end

do --[[ AddOns\Blizzard_RemixArtifactUI.lua ]]
    -- RemixArtifactFrame inherits TalentFrameBaseTemplate. The SharedTalentUI
    -- skin already hooks TalentButtonBaseMixin (Init, UpdateVisualState) for
    -- icon cropping and TalentFrameBaseMixin:OnLoad for FrameTypeFrame +
    -- StripBlizzardTextures + pool wrapping. This skin handles
    -- RemixArtifactFrame-specific decorative elements.

    Hook.RemixArtifactFrameMixin = {}
    function Hook.RemixArtifactFrameMixin:RefreshBackground()
        -- RefreshBackground dynamically sets the Background atlas based on
        -- the artifact's textureKit. Re-strip after each refresh.
        StripRemixArtifactDecorations(self)
    end
end

function private.AddOns.Blizzard_RemixArtifactUI()
    ------------------------------------
    -- Hook RemixArtifactFrameMixin
    ------------------------------------
    if _G.RemixArtifactFrameMixin then
        Util.Mixin(_G.RemixArtifactFrameMixin, Hook.RemixArtifactFrameMixin)
    end

    ------------------------------------
    -- Skin the RemixArtifactFrame instance
    ------------------------------------
    local frame = _G.RemixArtifactFrame
    if not frame then return end

    if not private.IsSkinned(frame) then
        private.SetSkinned(frame, true)
        Skin.FrameTypeFrame(frame)
    end

    StripRemixArtifactDecorations(frame)

    -- CloseButton
    if frame.CloseButton then
        Skin.UIPanelCloseButton(frame.CloseButton)
    end

    -- CommitConfigControls action buttons
    if frame.CommitConfigControls then
        if frame.CommitConfigControls.CommitButton then
            Skin.FrameTypeButton(frame.CommitConfigControls.CommitButton)
        end
        if frame.CommitConfigControls.UndoButton then
            Skin.FrameTypeButton(frame.CommitConfigControls.UndoButton)
        end
    end
end
