local _, private = ...
if private.shouldSkip() then return end

local Aurora = private.Aurora
local Base, Hook, Skin = Aurora.Base, Aurora.Hook, Aurora.Skin
local Util = Aurora.Util

-- Strip GenericTraitFrame-specific decorative textures.
-- Defined at file scope so both the Hook and the registration function
-- can reference it.
local function StripGenericTraitDecorations(frame)
    -- Background atlas tile
    if frame.Background then
        frame.Background:SetAlpha(0)
    end
    -- BorderOverlay atlas (used when useNewNineSlice is true)
    if frame.BorderOverlay then
        frame.BorderOverlay:SetAlpha(0)
    end
    -- NineSlice panel (used when useNewNineSlice is false)
    if frame.NineSlice then
        Base.StripBlizzardTextures(frame.NineSlice)
    end
    -- Inset frame template decorative borders
    if frame.Inset then
        Base.StripBlizzardTextures(frame.Inset)
    end
    -- Header title divider atlas
    if frame.Header and frame.Header.TitleDivider then
        frame.Header.TitleDivider:SetAlpha(0)
    end
    -- Currency background atlas
    if frame.Currency and frame.Currency.CurrencyBackground then
        frame.Currency.CurrencyBackground:SetAlpha(0)
    end
end

do --[[ AddOns\Blizzard_GenericTraitUI.lua ]]
    -- GenericTraitFrame inherits TalentFrameBaseTemplate. The SharedTalentUI
    -- skin already hooks TalentButtonBaseMixin (Init, UpdateVisualState) for
    -- icon cropping and TalentFrameBaseMixin:OnLoad for FrameTypeFrame +
    -- StripBlizzardTextures + pool wrapping. This skin handles
    -- GenericTraitFrame-specific decorative elements that ApplyLayout sets up
    -- dynamically (Background, BorderOverlay, NineSlice, Header, Inset,
    -- Currency).

    Hook.GenericTraitFrameMixin = {}
    function Hook.GenericTraitFrameMixin:ApplyLayout()
        -- ApplyLayout dynamically sets Background, BorderOverlay, NineSlice
        -- atlases based on the tree's layout options. Re-strip after each
        -- layout application.
        StripGenericTraitDecorations(self)
    end
end

function private.AddOns.Blizzard_GenericTraitUI()
    ------------------------------------
    -- Hook GenericTraitFrameMixin
    ------------------------------------
    if _G.GenericTraitFrameMixin then
        Util.Mixin(_G.GenericTraitFrameMixin, Hook.GenericTraitFrameMixin)
    end

    ------------------------------------
    -- Skin the GenericTraitFrame instance
    ------------------------------------
    local frame = _G.GenericTraitFrame
    if frame then
        if not private.IsSkinned(frame) then
            private.SetSkinned(frame, true)
            Skin.FrameTypeFrame(frame)
        end

        StripGenericTraitDecorations(frame)

        -- CloseButton
        if frame.CloseButton then
            Skin.UIPanelCloseButton(frame.CloseButton)
        end
    end
end
