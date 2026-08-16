local _, private = ...
if private.shouldSkip() then return end

local Aurora = private.Aurora
local Base, Hook, Skin = Aurora.Base, Aurora.Hook, Aurora.Skin

do --[[ AddOns\Blizzard_AlliedRacesUI.lua ]]
    -- Skin a racial ability entry from the ability pool.
    local function SkinAbilityButton(button)
        if not button or private.IsSkinned(button) then return end
        private.SetSkinned(button, true)

        if button.Icon then
            Base.CropIcon(button.Icon, button)
        end
    end

    -- Hook SetupAbilityPool to skin each ability entry as it is created.
    function Hook.AlliedRacesFrameMixinSetupAbilityPool(self, index, racialAbility)
        -- The ability button was just acquired and configured; skin it.
        if self.lastAbility then
            SkinAbilityButton(self.lastAbility)
        end
    end
end

function private.AddOns.Blizzard_AlliedRacesUI()
    local AlliedRacesFrame = _G.AlliedRacesFrame
    if not AlliedRacesFrame then return end

    ------------------------------------
    -- Main frame (ButtonFrameTemplate)
    ------------------------------------
    Skin.FrameTypeFrame(AlliedRacesFrame)

    -- Strip decorative background and banner atlas textures
    if AlliedRacesFrame.FrameBackground then
        AlliedRacesFrame.FrameBackground:SetAlpha(0)
    end
    if AlliedRacesFrame.Banner then
        AlliedRacesFrame.Banner:SetAlpha(0)
    end

    ------------------------------------
    -- Model scene
    ------------------------------------
    local ModelScene = AlliedRacesFrame.ModelScene
    if ModelScene then
        -- Strip the model background overlay atlas
        if ModelScene.ModelBackground then
            ModelScene.ModelBackground:SetAlpha(0)
        end
        -- The BackgroundOverlay key has a zero-width space in the XML source
        for _, region in next, { ModelScene:GetRegions() } do
            local atlas = region.GetAtlas and region:GetAtlas()
            if atlas == "AlliedRace-UnlockingFrame-ModelFrame" then
                region:SetAlpha(0)
            end
        end
    end

    ------------------------------------
    -- Race info frame
    ------------------------------------
    local RaceInfoFrame = AlliedRacesFrame.RaceInfoFrame
    if RaceInfoFrame then
        -- Strip the scroll frame decorative textures
        local ScrollFrame = RaceInfoFrame.ScrollFrame
        if ScrollFrame then
            Base.StripBlizzardTextures(ScrollFrame)
        end
    end

    ------------------------------------
    -- Hook ability pool for dynamic skinning
    ------------------------------------
    _G.hooksecurefunc(AlliedRacesFrame, "SetupAbilityPool", Hook.AlliedRacesFrameMixinSetupAbilityPool)
end
