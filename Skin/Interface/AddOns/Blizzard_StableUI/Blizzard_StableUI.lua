local _, private = ...
if private.shouldSkip() then return end

local Aurora = private.Aurora
local Base, Hook, Skin = Aurora.Base, Aurora.Hook, Aurora.Skin

do --[[ AddOns\Blizzard_StableUI.lua ]]
    -- Skin a stabled pet list entry from the ScrollBox element factory.
    local function SkinStabledPetButton(button)
        if not button or private.IsSkinned(button) then return end
        private.SetSkinned(button, true)

        local portrait = button.Portrait
        if portrait then
            if portrait.Icon then
                Base.CropIcon(portrait.Icon, portrait)
            end
            if portrait.Border then
                portrait.Border:SetAlpha(0)
            end
        end
    end

    -- Hook ScrollBox Update to skin dynamically created stabled pet entries.
    function Hook.StableStabledPetListScrollBoxUpdate(scrollBox)
        for _, child in next, { scrollBox.ScrollTarget:GetChildren() } do
            if child.Portrait then
                SkinStabledPetButton(child)
            end
        end
    end
end

do --[[ AddOns\Blizzard_StableUI.xml ]]
    function Skin.StableActivePetButtonTemplate(Button)
        if private.IsSkinned(Button) then return end
        private.SetSkinned(Button, true)

        if Button.Icon then
            Base.CropIcon(Button.Icon, Button)
        end
        if Button.Border then
            Button.Border:SetAlpha(0)
        end
        if Button.Background then
            Button.Background:SetAlpha(0)
        end
    end

    function Skin.StableStabledPetButtonTemplate(Button)
        if private.IsSkinned(Button) then return end
        private.SetSkinned(Button, true)

        local portrait = Button.Portrait
        if portrait then
            if portrait.Icon then
                Base.CropIcon(portrait.Icon, portrait)
            end
            if portrait.Border then
                portrait.Border:SetAlpha(0)
            end
        end
    end

    function Skin.StablePetAbilityTemplate(Frame)
        if Frame.Icon then
            Base.CropIcon(Frame.Icon, Frame)
        end
    end
end

function private.AddOns.Blizzard_StableUI()
    local StableFrame = _G.StableFrame
    if not StableFrame then return end

    ------------------------------------
    -- Main frame (PortraitFrameTemplate)
    ------------------------------------
    Skin.FrameTypeFrame(StableFrame)

    -- Strip the decorative wood topper
    if StableFrame.Topper then
        StableFrame.Topper:SetAlpha(0)
    end

    ------------------------------------
    -- Action buttons (UIPanelButtonTemplate)
    ------------------------------------
    if StableFrame.StableTogglePetButton then
        Skin.FrameTypeButton(StableFrame.StableTogglePetButton)
    end
    if StableFrame.ReleasePetButton then
        Skin.FrameTypeButton(StableFrame.ReleasePetButton)
    end

    ------------------------------------
    -- Pet model scene
    ------------------------------------
    local modelScene = StableFrame.PetModelScene
    if modelScene then
        -- Strip the inset border inside the model scene
        if modelScene.Inset then
            Base.StripBlizzardTextures(modelScene.Inset)
        end
        -- Strip the shadow overlay
        if modelScene.PetModelSceneShadow then
            Base.StripBlizzardTextures(modelScene.PetModelSceneShadow)
        end
    end

    ------------------------------------
    -- Active pet list (footer area)
    ------------------------------------
    local activePetList = StableFrame.ActivePetList
    if activePetList then
        -- Strip the footer background and gold divider
        if activePetList.ActivePetListBG then
            activePetList.ActivePetListBG:SetAlpha(0)
        end
        if activePetList.ActivePetListBGBar then
            activePetList.ActivePetListBGBar:SetAlpha(0)
        end

        -- Skin the 5 active pet buttons + beast master secondary
        if activePetList.PetButtons then
            for _, petButton in next, activePetList.PetButtons do
                Skin.StableActivePetButtonTemplate(petButton)
            end
        end
        if activePetList.BeastMasterSecondaryPetButton then
            Skin.StableActivePetButtonTemplate(activePetList.BeastMasterSecondaryPetButton)
        end
    end

    ------------------------------------
    -- Stabled pet list (left sidebar)
    ------------------------------------
    local stabledPetList = StableFrame.StabledPetList
    if stabledPetList then
        -- Strip the pet list background atlas
        if stabledPetList.Backgroud then
            stabledPetList.Backgroud:SetAlpha(0)
        end

        -- Strip the inset border
        if stabledPetList.Inset then
            Base.StripBlizzardTextures(stabledPetList.Inset)
        end

        -- Strip the list counter inset border
        if stabledPetList.ListCounter then
            Base.StripBlizzardTextures(stabledPetList.ListCounter)
        end

        -- Hook ScrollBox to skin dynamically created stabled pet entries
        if stabledPetList.ScrollBox then
            _G.hooksecurefunc(stabledPetList.ScrollBox, "Update", Hook.StableStabledPetListScrollBoxUpdate)
        end
    end
end
