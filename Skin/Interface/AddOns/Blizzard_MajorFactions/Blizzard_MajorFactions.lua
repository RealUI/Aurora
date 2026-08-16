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

function private.AddOns.Blizzard_MajorFactions()
    ------------------------------------
    -- Renown toast (MajorFactionsRenownToast)
    -- Inherits MajorFactionCelebrationBannerTemplate (DIALOG strata)
    ------------------------------------
    local renownToast = _G.MajorFactionsRenownToast
    if renownToast then
        Skin.FrameTypeFrame(renownToast)

        -- Strip decorative border textures from the celebration banner
        if renownToast.TopBorder then
            renownToast.TopBorder:SetAlpha(0)
        end
        if renownToast.GlowLineBottom then
            renownToast.GlowLineBottom:SetAlpha(0)
        end

        -- Crop the reward icon
        if renownToast.RewardIcon then
            Base.CropIcon(renownToast.RewardIcon, renownToast)
        end

        -- Crop the top faction icon from the banner template
        if renownToast.TopIcon then
            Base.CropIcon(renownToast.TopIcon, renownToast)
        end
    end

    ------------------------------------
    -- Unlock toast (MajorFactionUnlockToast)
    -- Inherits MajorFactionCelebrationBannerTemplate (DIALOG strata)
    ------------------------------------
    local unlockToast = _G.MajorFactionUnlockToast
    if unlockToast then
        Skin.FrameTypeFrame(unlockToast)

        -- Strip decorative border textures from the celebration banner
        if unlockToast.TopBorder then
            unlockToast.TopBorder:SetAlpha(0)
        end
        if unlockToast.GlowLineBottom then
            unlockToast.GlowLineBottom:SetAlpha(0)
        end

        -- Crop the top faction icon from the banner template
        if unlockToast.TopIcon then
            Base.CropIcon(unlockToast.TopIcon, unlockToast)
        end
    end
end
