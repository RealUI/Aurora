local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals next

--[[ Core ]]
local Aurora = private.Aurora
local Base, Skin = Aurora.Base, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

-- Camelot's hunter stable is the vanilla PetStableFrame, not retail's
-- StableFrame: Blizzard_StableUI's TOC loads [Game]\Blizzard_StableUI.xml for
-- every gametype, and the Camelot copy declares a wholly different frame tree.
-- The two share no names at all, so the retail body moved to
-- Mainline\Blizzard_StableUI.lua and this stands beside it rather than
-- branching inside one file.
--
-- It is not the classic skin either. Blizzard_UIPanels_Game\Classic\PetStable.lua
-- targets the era sheet: hard-coded artwork regions, $parentNormalTexture rings
-- and a global PetStablePurchaseButton. Camelot keeps the vanilla *names* and
-- rebuilds the panel on modern templates -- PortraitFrameTemplate, a ModelScene
-- with a ModelSceneControlFrameTemplate, SmallMoneyFrameTemplate, a
-- ColoredProgressBar exp bar -- which is the usual Camelot trap: retail
-- vocabulary under classic names.

do --[[ AddOns\Blizzard_StableUI.xml ]]
    function Skin.PetStableSlotTemplate(CheckButton)
        if private.IsSkinned(CheckButton) then return end
        private.SetSkinned(CheckButton, true)

        local name = CheckButton:GetName()

        -- $parentIconTexture is on BORDER with no file; the mixin fills it.
        local icon = name and _G[name .. "IconTexture"]
        if icon then
            Base.CropIcon(icon, CheckButton)
        end

        -- Slot frames since 70450: stabled / current / locked atlases the
        -- mixin toggles per slot state, so alpha rather than Hide. lockIcon
        -- and genericPetIcon carry the state and stay.
        for _, key in next, {"unlockedBackground", "currentBackground", "lockedBackground"} do
            if CheckButton[key] then
                CheckButton[key]:SetAlpha(0)
            end
        end

        Base.SetBackdrop(CheckButton, Color.button)

        local pushed = CheckButton:GetPushedTexture()
        if pushed then
            pushed:SetTexture("")
        end
        local highlight = CheckButton:GetHighlightTexture()
        if highlight then
            highlight:ClearAllPoints()
            highlight:SetAllPoints(CheckButton)
            Util.SetHighlightColor(highlight, 0.2)
        end
        local checked = CheckButton:GetCheckedTexture()
        if checked then
            checked:ClearAllPoints()
            checked:SetAllPoints(CheckButton)
            Util.SetHighlightColor(checked, 0.5)
        end
    end
end

function private.AddOns.Blizzard_StableUI()
    local PetStableFrame = _G.PetStableFrame
    if not PetStableFrame then return end

    Skin.PortraitFrameTemplate(PetStableFrame)

    -- 70450 panel chrome: subheader and footer plates (both declared
    -- parentKey="Background", so only the globals reach both), the footer's
    -- inside-frame border and the two horizontal dividers.
    for _, texture in next, {
        _G.TopBackground,
        _G.BottomBackground,
        PetStableFrame.insideFrameBottom,
        PetStableFrame.TopDividerFrame and PetStableFrame.TopDividerFrame.horzDivider,
        PetStableFrame.BottomDividerFrame and PetStableFrame.BottomDividerFrame.horzDivider,
    } do
        texture:SetAlpha(0)
    end

    ----====#####################====----
    --            Pet slots            --
    ----====#####################====----
    Skin.PetStableSlotTemplate(_G.PetStableCurrentPet)

    -- Two stabled slots on 1.60.1, but counted rather than assumed: the slot
    -- count is what the stable purchase button buys.
    local i = 1
    while _G["PetStableStabledPet" .. i] do
        Skin.PetStableSlotTemplate(_G["PetStableStabledPet" .. i])
        i = i + 1
    end

    Skin.UIPanelButtonTemplate(PetStableFrame.purchaseButton)

    ----====#####################====----
    --            ModelScene           --
    ----====#####################====----
    local modelScene = PetStableFrame.modelScene
    if modelScene then
        if modelScene.Inset then
            Skin.InsetFrameTemplate(modelScene.Inset)
        end
        if modelScene.ControlFrame and Skin.ModelSceneControlFrameTemplate then
            Skin.ModelSceneControlFrameTemplate(modelScene.ControlFrame)
        end
        if modelScene.PetModelSceneShadow then
            Util.HideFrameTextures(modelScene.PetModelSceneShadow, true)
        end

        -- PetShadow is a perks-char-shadow drop shadow under the model. The
        -- Background (ui-stables-pet-model-bg) is the scene's backdrop, the
        -- content behind the pet, so it is left to Blizzard.
        if modelScene.PetShadow then
            modelScene.PetShadow:SetAlpha(0)
        end

        -- diet is a PetFrameHappinessTemplate: a single UI-PetHappiness face.
        -- Meaningful art, kept, in line with the PVPRankFrame badges.
    end

    -- PetExpColoredProgressBarTemplate since 70450; loyalty is plain text now.
    Skin.ColoredProgressBarTemplate(PetStableFrame.expBar)

    ----====#####################====----
    --          Money frames           --
    ----====#####################====----
    -- Skin.SmallMoneyFrameTemplate is a nop -- the coin sheets are left stock
    -- on every flavor. Only PetStableMoneyFrame carries extra chrome: a
    -- ContainerFrameCurrencyBorderTemplate three-slice behind the coins.
    local MoneyFrame = _G.PetStableMoneyFrame
    if MoneyFrame and MoneyFrame.Border then
        Util.HideFrameTextures(MoneyFrame.Border, true)
    end
end
