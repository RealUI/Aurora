local _, private = ...
if private.shouldSkip() then return end

local Aurora = private.Aurora
local Base, Hook = Aurora.Base, Aurora.Hook
local Color = Aurora.Color

do --[[ AddOns\Blizzard_CovenantToasts.lua ]]
    -- CovenantRenownToastMixin:SetupRewardVisuals dynamically sets the
    -- RewardIcon texture. Hook it to crop the icon each time it changes.
    Hook.CovenantRenownToastMixin = {}
    function Hook.CovenantRenownToastMixin:SetupRewardVisuals()
        if self.RewardIcon and self.RewardIcon:IsShown() then
            Base.CropIcon(self.RewardIcon)
        end
    end
end

function private.AddOns.Blizzard_CovenantToasts()
    ------------------------------------------------
    -- CovenantChoiceToast
    -- Inherits CovenantCelebrationBannerTemplate
    -- Children: ToastBG, Stars1, Stars2, HeaderText, CovenantName
    -- Banner base: GlowLineTop, GlowLineTopAdditive, IconSwirlModelScene, Icon.Tex
    ------------------------------------------------
    local choiceToast = _G.CovenantChoiceToast
    if choiceToast and not private.IsSkinned(choiceToast) then
        private.SetSkinned(choiceToast, true)

        -- Strip decorative atlas textures
        if choiceToast.ToastBG then
            choiceToast.ToastBG:SetAlpha(0)
        end
        if choiceToast.GlowLineTop then
            choiceToast.GlowLineTop:SetAlpha(0)
        end
        if choiceToast.GlowLineTopAdditive then
            choiceToast.GlowLineTopAdditive:SetAlpha(0)
        end

        -- Apply backdrop to the toast frame
        Base.SetBackdrop(choiceToast, Color.frame)
    end

    ------------------------------------------------
    -- CovenantRenownToast
    -- Inherits CovenantCelebrationBannerTemplate
    -- Children: ToastBG, Stars1, Stars2, RenownLabel, RewardIcon,
    --           RewardIconMask, RewardIconRing, RewardDescription,
    --           GlowLineTopBottom, RewardIconMouseOver
    -- Banner base: GlowLineTop, GlowLineTopAdditive, IconSwirlModelScene, Icon.Tex
    ------------------------------------------------
    local renownToast = _G.CovenantRenownToast
    if renownToast and not private.IsSkinned(renownToast) then
        private.SetSkinned(renownToast, true)

        -- Strip decorative atlas textures
        if renownToast.ToastBG then
            renownToast.ToastBG:SetAlpha(0)
        end
        if renownToast.GlowLineTop then
            renownToast.GlowLineTop:SetAlpha(0)
        end
        if renownToast.GlowLineTopAdditive then
            renownToast.GlowLineTopAdditive:SetAlpha(0)
        end
        if renownToast.GlowLineTopBottom then
            renownToast.GlowLineTopBottom:SetAlpha(0)
        end

        -- Apply backdrop to the toast frame
        Base.SetBackdrop(renownToast, Color.frame)

        -- Crop the reward icon (dynamically set via SetupRewardVisuals)
        if renownToast.RewardIcon then
            Base.CropIcon(renownToast.RewardIcon)
        end

        -- Hook SetupRewardVisuals to re-crop the icon when it changes
        if _G.CovenantRenownToastMixin then
            _G.hooksecurefunc(_G.CovenantRenownToastMixin, "SetupRewardVisuals", Hook.CovenantRenownToastMixin.SetupRewardVisuals)
        end
    end
end
