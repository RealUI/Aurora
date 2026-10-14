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
    -- TopBorder and GlowLineBottom: Hide, not SetAlpha(0). The banner's ShowAnim
    -- fades both to alpha 1, and no Blizzard code shows them.
    local renownToast = _G.MajorFactionsRenownToast
    if renownToast then
        Skin.FrameTypeFrame(renownToast)
        -- The frame is 128 wide; its RewardDescription is 256. Widen the
        -- backdrop to the text, not the frame.
        renownToast:SetBackdropOption("offsets", {
            left = -74,
            right = -74,
            top = 0,
            bottom = 0,
        })

        -- Strip decorative border textures from the celebration banner
        if renownToast.TopBorder then
            renownToast.TopBorder:Hide()
        end
        if renownToast.GlowLineBottom then
            renownToast.GlowLineBottom:Hide()
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
        -- 12.1.5 fixes FactionName at 220 wide (long names wrap) on a 128-wide
        -- frame, so the name ran past both sides of the backdrop.
        unlockToast:SetBackdropOption("offsets", {
            left = -56,
            right = -56,
            top = 0,
            bottom = 0,
        })

        -- Strip decorative border textures from the celebration banner
        if unlockToast.TopBorder then
            unlockToast.TopBorder:Hide()
        end
        if unlockToast.GlowLineBottom then
            unlockToast.GlowLineBottom:Hide()
        end

        -- Crop the top faction icon from the banner template
        if unlockToast.TopIcon then
            Base.CropIcon(unlockToast.TopIcon, unlockToast)
        end
    end
end
