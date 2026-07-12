local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs next pairs select

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

do --[[ AddOns\Blizzard_Transmog.lua ]]
    -- Skin template for the wardrobe collection tabs (Items / Sets / Custom Sets / Situations)
    function Skin.TransmogWardrobeCollectionTabTemplate(Button)
        Skin.TabSystemButtonTemplate(Button)
        if Button.SelectedHighlight then
            Button.SelectedHighlight:SetAlpha(0)
        end
    end

    function Skin.TransmogAppearanceSlotTemplate(Button)
        if Button._auroraSkinned then
            return
        end

        Button._auroraSkinned = true

        Base.SetBackdrop(Button, Color.button)
        Button:SetBackdropOption("offsets", {
            left = 7,
            right = 7,
            top = 7,
            bottom = 7,
        })

        Button.Border:SetAlpha(0)
    end

    function Skin.TransmogIllusionSlotTemplate(Button)
        if Button._auroraSkinned then
            return
        end

        Button._auroraSkinned = true

        Base.SetBackdrop(Button, Color.button)
        Button:SetBackdropOption("offsets", {
            left = 6,
            right = 6,
            top = 6,
            bottom = 6,
        })

        Button.Border:SetAlpha(0)
    end
end

function private.AddOns.Blizzard_Transmog()
    ----====#####################====----
    --          TransmogFrame           --
    ----====#####################====----
    local TransmogFrame = _G.TransmogFrame

    Skin.PortraitFrameTemplate(TransmogFrame)

    -- Help button
    if TransmogFrame.HelpPlateButton then
        Skin.MainHelpPlateButton(TransmogFrame.HelpPlateButton)
    end

    ----====#####################====----
    --       OutfitCollection           --
    ----====#####################====----
    local OutfitCollection = TransmogFrame.OutfitCollection
    if OutfitCollection then
        -- Hide decorative backgrounds and gradients
        if OutfitCollection.Background then OutfitCollection.Background:SetAlpha(0) end
        if OutfitCollection.GradientTop then OutfitCollection.GradientTop:SetAlpha(0) end
        if OutfitCollection.GradientBottom then OutfitCollection.GradientBottom:SetAlpha(0) end
        if OutfitCollection.DividerBar then OutfitCollection.DividerBar:SetAlpha(0) end

        -- Show Equipped Gear spell frame
        if OutfitCollection.ShowEquippedGearSpellFrame then
            Skin.UIPanelSpellButtonFrameTemplate(OutfitCollection.ShowEquippedGearSpellFrame.Button)
        end

        -- Outfit List scroll area
        local OutfitList = OutfitCollection.OutfitList
        if OutfitList then
            if OutfitList.DividerTop then OutfitList.DividerTop:SetAlpha(0) end
            if OutfitList.DividerBottom then OutfitList.DividerBottom:SetAlpha(0) end
            if OutfitList.ScrollBox then Skin.WowScrollBoxList(OutfitList.ScrollBox) end
            if OutfitList.ScrollBar then Skin.MinimalScrollBar(OutfitList.ScrollBar) end
        end

        -- Purchase Outfit button (tertiary style)
        if OutfitCollection.PurchaseOutfitButton then
            Skin.UIPanelButtonTemplate(OutfitCollection.PurchaseOutfitButton)
        end

        -- Save outfit button
        if OutfitCollection.SaveOutfitButton then
            Skin.UIPanelButtonTemplate(OutfitCollection.SaveOutfitButton)
        end

        -- Money frame background
        if OutfitCollection.MoneyFrame and OutfitCollection.MoneyFrame.Background then
            OutfitCollection.MoneyFrame.Background:SetAlpha(0)
        end
    end

    ----====#####################====----
    --   OutfitPopup (IconSelector)     --
    ----====#####################====----
    if TransmogFrame.OutfitPopup then
        Skin.IconSelectorPopupFrameTemplate(TransmogFrame.OutfitPopup)
    end

    ----====#####################====----
    --       CharacterPreview           --
    ----====#####################====----
    local CharacterPreview = TransmogFrame.CharacterPreview
    if CharacterPreview then
        -- Hide the location background art
        if CharacterPreview.Background then CharacterPreview.Background:SetAlpha(0) end

        -- Flat dark background for the character preview area
        if not CharacterPreview._auroraBackground then
            local bg = CharacterPreview:CreateTexture(nil, "BACKGROUND", nil, -8)
            bg:SetColorTexture(Color.panelBg:GetRGBA())
            bg:SetAllPoints(CharacterPreview)
            CharacterPreview._auroraBackground = bg
        end

        -- Hide gradient overlays
        if CharacterPreview.Gradients then
            if CharacterPreview.Gradients.GradientLeft then CharacterPreview.Gradients.GradientLeft:SetAlpha(0) end
            if CharacterPreview.Gradients.GradientRight then CharacterPreview.Gradients.GradientRight:SetAlpha(0) end
        end

        -- Clear All Pending (undo) button
        if CharacterPreview.ClearAllPendingButton then
            Skin.UIPanelButtonTemplate(CharacterPreview.ClearAllPendingButton)
        end

        -- Model scene rotate controls
        if CharacterPreview.ModelScene and CharacterPreview.ModelScene.ControlFrame then
            Skin.ModelSceneControlFrameTemplateLeftButtonTemplate(CharacterPreview.ModelScene.ControlFrame.rotateLeftButton)
            Skin.ModelSceneControlFrameTemplateRightButtonTemplate(CharacterPreview.ModelScene.ControlFrame.rotateRightButton)
        end

        if CharacterPreview.CharacterAppearanceSlotFramePool then
            Util.WrapPoolAcquire(CharacterPreview.CharacterAppearanceSlotFramePool, Skin.TransmogAppearanceSlotTemplate)
        end
        if CharacterPreview.CharacterIllusionSlotFramePool then
            Util.WrapPoolAcquire(CharacterPreview.CharacterIllusionSlotFramePool, Skin.TransmogIllusionSlotTemplate)
        end

        -- "Hide Unassigned Slots" checkbox
        if CharacterPreview.HideIgnoredToggle and CharacterPreview.HideIgnoredToggle.Checkbox then
            Skin.UICheckButtonTemplate(CharacterPreview.HideIgnoredToggle.Checkbox)
        end
    end

    ----====#####################====----
    --      WardrobeCollection          --
    ----====#####################====----
    local WardrobeCollection = TransmogFrame.WardrobeCollection
    if WardrobeCollection then
        -- Hide the wardrobe background
        if WardrobeCollection.Background then WardrobeCollection.Background:SetAlpha(0) end

        -- Skin the tab buttons (Items / Sets / Custom Sets / Situations)
        if WardrobeCollection.TabHeaders then
            local function SkinWardrobeTab(tab)
                if tab and not tab._auroraSkinned then
                    tab._auroraSkinned = true
                    Skin.TransmogWardrobeCollectionTabTemplate(tab)
                end
            end

            for _, tab in ipairs({WardrobeCollection.TabHeaders:GetChildren()}) do
                SkinWardrobeTab(tab)
            end

            -- Hook tab creation for dynamically added tabs
            if WardrobeCollection.TabHeaders.tabPool then
                _G.hooksecurefunc(WardrobeCollection.TabHeaders.tabPool, "Acquire", function(pool)
                    for tab in pool:EnumerateActive() do
                        SkinWardrobeTab(tab)
                    end
                end)
            end
        end

        -- TabContent area (the frame under the tabs)
        local TabContent = WardrobeCollection.TabContent
        if TabContent then
            -- Hide the decorative border and background
            if TabContent.Background then TabContent.Background:SetAlpha(0) end
            if TabContent.Border then TabContent.Border:SetAlpha(0) end

            ----
            -- ItemsFrame (Items tab)
            ----
            local ItemsFrame = TabContent.ItemsFrame
            if ItemsFrame then
                -- Filter / Search
                if ItemsFrame.FilterButton then Skin.FilterButton(ItemsFrame.FilterButton) end
                if ItemsFrame.SearchBox then Skin.SearchBoxNineSliceTemplate(ItemsFrame.SearchBox) end

                -- Weapon dropdown
                if ItemsFrame.WeaponDropdown then Skin.DropdownButton(ItemsFrame.WeaponDropdown) end

                -- Divider line (decorative, thin)
                if ItemsFrame.Divider then ItemsFrame.Divider:SetAlpha(0) end

                -- Secondary appearance toggle checkbox
                if ItemsFrame.SecondaryAppearanceToggle and ItemsFrame.SecondaryAppearanceToggle.Checkbox then
                    Skin.UICheckButtonTemplate(ItemsFrame.SecondaryAppearanceToggle.Checkbox)
                end
            end

            ----
            -- SetsFrame (Sets tab)
            ----
            local SetsFrame = TabContent.SetsFrame
            if SetsFrame then
                if SetsFrame.FilterButton then Skin.FilterButton(SetsFrame.FilterButton) end
                if SetsFrame.SearchBox then Skin.SearchBoxNineSliceTemplate(SetsFrame.SearchBox) end
            end

            ----
            -- CustomSetsFrame (Custom Sets tab)
            ----
            local CustomSetsFrame = TabContent.CustomSetsFrame
            if CustomSetsFrame then
                if CustomSetsFrame.NewCustomSetButton then
                    Skin.UIPanelButtonTemplate(CustomSetsFrame.NewCustomSetButton)
                end
            end

            ----
            -- SituationsFrame (Situations tab)
            ----
            local SituationsFrame = TabContent.SituationsFrame
            if SituationsFrame then
                -- Defaults button
                if SituationsFrame.DefaultsButton then
                    Skin.UIPanelButtonTemplate(SituationsFrame.DefaultsButton)
                end

                -- Enabled toggle checkbox
                if SituationsFrame.EnabledToggle and SituationsFrame.EnabledToggle.Checkbox then
                    Skin.UICheckButtonTemplate(SituationsFrame.EnabledToggle.Checkbox)
                end

                -- Apply button
                if SituationsFrame.ApplyButton then
                    Skin.UIPanelButtonTemplate(SituationsFrame.ApplyButton)
                end

                -- Situations container background
                if SituationsFrame.Situations and SituationsFrame.Situations.Background then
                    SituationsFrame.Situations.Background:SetAlpha(0)
                end

                -- Skin situation dropdowns as they are created
                if SituationsFrame.SituationFramePool then
                    _G.hooksecurefunc(SituationsFrame.SituationFramePool, "Acquire", function(pool)
                        for frame in pool:EnumerateActive() do
                            if not frame._auroraSkinned then
                                frame._auroraSkinned = true
                                if frame.Dropdown then
                                    Skin.DropdownButton(frame.Dropdown)
                                end
                            end
                        end
                    end)
                end
            end
        end
    end
end
