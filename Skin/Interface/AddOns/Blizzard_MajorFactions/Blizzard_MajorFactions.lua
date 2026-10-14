local _, private = ...
if private.shouldSkip() then return end

local Aurora = private.Aurora
local Base, Hook, Skin = Aurora.Base, Aurora.Hook, Aurora.Skin

do --[[ AddOns\Blizzard_MajorFactions.lua ]]
    -- Skin a faction button acquired from the ScrollBox element factory.
    local function SkinFactionButton(button)
        if not button or private.IsSkinned(button) then return end
        private.SetSkinned(button, true)

        -- UnlockedState: skin the faction crest icon and watch checkbox
        local unlocked = button.UnlockedState
        if unlocked then
            if unlocked.Icon then
                Base.CropIcon(unlocked.Icon, unlocked)
            end
            if unlocked.WatchFactionButton then
                Skin.FrameTypeCheckButton(unlocked.WatchFactionButton)
            end
        end
    end

    -- Hook ScrollBox Update to skin dynamically created faction buttons.
    function Hook.MajorFactionListScrollBoxUpdate(scrollBox)
        for _, child in next, { scrollBox.ScrollTarget:GetChildren() } do
            SkinFactionButton(child)
        end
    end
end

do --[[ AddOns\Blizzard_MajorFactions.xml ]]
    function Skin.MajorFactionButtonTemplate(Button)
        if private.IsSkinned(Button) then return end
        private.SetSkinned(Button, true)

        local unlocked = Button.UnlockedState
        if unlocked then
            if unlocked.Icon then
                Base.CropIcon(unlocked.Icon, unlocked)
            end
            if unlocked.WatchFactionButton then
                Skin.FrameTypeCheckButton(unlocked.WatchFactionButton)
            end
        end
    end
end

-- MajorFactionCelebrationBannerTemplate (renown and unlock toasts, DIALOG
-- strata). The frame is only 128x128; the visible panel is its ToastBG,
-- 275x240 and centred 10px above the frame's centre, and the title, icons and
-- text are laid out on that panel. So the Aurora backdrop takes ToastBG's
-- geometry and ToastBG is hidden. Hide, not SetAlpha(0), for everything the
-- banner's ShowAnim fades in (ToastBG, TopBorder, GlowLineBottom, the reward
-- ring): the animation sets alpha, and no Blizzard code shows them.
local function SkinCelebrationBanner(toast)
    Skin.FrameTypeFrame(toast)
    toast:SetBackdropOption("offsets", {
        left = -74,
        right = -74,
        top = -66,
        bottom = -46,
    })

    for _, key in next, { "ToastBG", "TopBorder", "GlowLineBottom" } do
        if toast[key] then
            toast[key]:Hide()
        end
    end

    if toast.TopIcon then
        Base.CropIcon(toast.TopIcon, toast)
    end
end

function private.AddOns.Blizzard_MajorFactions()
    local renownToast = _G.MajorFactionsRenownToast
    if renownToast then
        SkinCelebrationBanner(renownToast)

        -- Square reward icon; its round ring goes with the round mask
        if renownToast.RewardIcon then
            Base.CropIcon(renownToast.RewardIcon, renownToast)
        end
        if renownToast.RewardIconRing then
            renownToast.RewardIconRing:Hide()
        end
    end

    local unlockToast = _G.MajorFactionUnlockToast
    if unlockToast then
        SkinCelebrationBanner(unlockToast)
    end
end
