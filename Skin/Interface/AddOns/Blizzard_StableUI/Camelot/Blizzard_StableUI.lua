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
-- StatusTrackingBar-based exp bar -- which is the usual Camelot trap: retail
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

        -- UI-Quickslot2 ring and the UI-EmptySlot backing, both oversized and
        -- offset so they sit outside the button's own rect.
        local normal = name and _G[name .. "NormalTexture"]
        if normal then
            normal:SetAlpha(0)
        end
        if CheckButton.background then
            CheckButton.background:SetAlpha(0)
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

    function Skin.PetStableLoyaltyLevelTemplate(Frame)
        if not Frame then return end

        -- One UI-HUD-UnitFrame-Target-PortraitOn-Boss-IconRing texture behind
        -- levelText. The ring is chrome; the number is the content.
        for _, region in next, {Frame:GetRegions()} do
            if region:IsObjectType("Texture") then
                region:SetAlpha(0)
            end
        end
    end

    -- PetExpStatusBarTemplate is declared in Blizzard_StatusTrackingBar, which
    -- has no Aurora skin on any flavor, so it is registered here -- the only
    -- surface that instantiates it. Skin.StatusTrackingBarTemplate comes from
    -- Blizzard_ActionBarController\Mainline, which is active on Forever.
    function Skin.PetExpStatusBarTemplate(Frame)
        if not Frame then return end

        if Skin.StatusTrackingBarTemplate and Frame.StatusBar then
            Skin.StatusTrackingBarTemplate(Frame)
        end

        -- The overlay is two halves of UI-MainMenuBar-Dwarf framing the bar.
        -- xpText sits on the same layer and must survive.
        local overlay = Frame.overlay
        if overlay then
            for _, region in next, {overlay:GetRegions()} do
                if region:IsObjectType("Texture") then
                    region:SetAlpha(0)
                end
            end
        end
    end
end

function private.AddOns.Blizzard_StableUI()
    local PetStableFrame = _G.PetStableFrame
    if not PetStableFrame then return end

    Skin.PortraitFrameTemplate(PetStableFrame)

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
        -- Background texture carries no file in XML and is set at runtime, so
        -- it is left to Blizzard.
        if modelScene.PetShadow then
            modelScene.PetShadow:SetAlpha(0)
        end

        -- diet is a PetFrameHappinessTemplate: a single UI-PetHappiness face.
        -- Meaningful art, kept, in line with the PVPRankFrame badges.
    end

    Skin.PetExpStatusBarTemplate(PetStableFrame.expBar)
    Skin.PetStableLoyaltyLevelTemplate(PetStableFrame.loyaltyLevel)

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
