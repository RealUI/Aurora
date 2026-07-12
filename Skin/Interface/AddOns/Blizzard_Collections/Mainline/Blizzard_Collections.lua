local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals select next

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

do --[[ AddOns\Blizzard_Collections.lua ]]
    do --[[ Blizzard_PetCollection ]]
        local MAX_ACTIVE_PETS = 3

        function Hook.PetJournal_UpdatePetLoadOut()
            for i = 1, MAX_ACTIVE_PETS do
                local loadoutPlate = _G.PetJournal.Loadout["Pet"..i]
                local petID = _G.C_PetJournal.GetPetLoadOutInfo(i)

                if loadoutPlate.iconBorder:IsShown() then
                    local _, _, _, _, rarity = _G.C_PetJournal.GetPetStats(petID)
                    local color = _G.ITEM_QUALITY_COLORS[rarity-1]
                    loadoutPlate._auroraIconBorder:SetColorTexture(color.r, color.g, color.b)
                else
                    loadoutPlate._auroraIconBorder:SetColorTexture(Color.black:GetRGB())
                end
            end
        end
        function Hook.PetJournal_UpdatePetCard(self, forceSceneChange)
            if not self.petID and not self.speciesID then
                self.PetInfo._auroraIconBorder:SetColorTexture(Color.black:GetRGB())
                return
            end

            local _, petType
            if self.petID then
                _, _, _, _, _, _, _, _, _, petType = _G.C_PetJournal.GetPetInfoByPetID(self.petID)
            else
                _, _, petType = _G.C_PetJournal.GetPetInfoBySpeciesID(self.speciesID)
            end

            if self.PetInfo.qualityBorder:IsShown() then
                local _, _, _, _, rarity = _G.C_PetJournal.GetPetStats(self.petID)
                local color = _G.ITEM_QUALITY_COLORS[rarity-1]
                self.PetInfo._auroraIconBorder:SetColorTexture(color.r, color.g, color.b)
            else
                self.PetInfo._auroraIconBorder:SetColorTexture(Color.black:GetRGB())
            end

            self.TypeInfo.typeIcon:SetTexture([[Interface\Icons\Icon_PetFamily_]].._G.PET_TYPE_SUFFIX[petType])
        end
    end
    do --[[ Blizzard_HeirloomCollection ]]
        Hook.HeirloomsMixin = {}
        function Hook.HeirloomsMixin:UpdateButton(button)
            Util.SkinOnce(button, Skin.HeirloomSpellButtonTemplate)

            local _, _, _, _, upgradeLevel = _G.C_Heirloom.GetHeirloomInfo(button.itemID)
            if upgradeLevel == _G.C_Heirloom.GetHeirloomMaxUpgradeLevel(button.itemID) then
                button.levelBackground:SetColorTexture(1, 1, 1, .5) -- static: not a theme color
            else
                button.levelBackground:SetColorTexture(0, 0, 0, .5) -- static: not a theme color
            end
        end
    end
    do --[[ Blizzard_Wardrobe ]]
        local lightVector = _G.CreateVector3D(-1, 1, -1)
        local default = {
            omnidirectional = false,
            point = lightVector,
            ambientIntensity = 1.05,
            ambientColor = Color.Create(1, 1, 1),
            diffuseIntensity=0.5,
            diffuseColor = Color.Create(1, 1, 1),
        }
        local notCollected = {
            omnidirectional = false,
            point = lightVector,
            ambientIntensity = 1,
            ambientColor = Color.Create(0.4, 0.4, 0.4),
            diffuseIntensity=0.5,
            diffuseColor = Color.Create(0.5, 0.5, 0.5),
        }
        local notUsable = {
            omnidirectional = false,
            point = lightVector,
            ambientIntensity = 1,
            ambientColor = Color.Create(0.8, 0.4, 0.4),
            diffuseIntensity=0.5,
            diffuseColor = Color.Create(1, 0, 0),
        }
        Hook.WardrobeItemsCollectionMixin = {}
        function Hook.WardrobeItemsCollectionMixin:UpdateItems()
            for i = 1, self.PAGE_SIZE do
                local model = self.Models[i]
                local visualInfo = model.visualInfo
                if visualInfo then
                    local borderColor
                    if model.TransmogStateTexture:IsShown() then
                        local xmogState = model.TransmogStateTexture:GetAtlas()
                        if xmogState:find("transmogged") then
                            borderColor = _G.TRANSMOGRIFY_FONT_COLOR
                        elseif xmogState:find("current") then
                            borderColor = _G.YELLOW_FONT_COLOR
                        elseif xmogState:find("selected") then
                            borderColor = _G.TRANSMOGRIFY_FONT_COLOR
                        end
                        model.TransmogStateTexture:Hide()

                        self.PendingTransmogFrame:SetPoint("TOPLEFT", model, 2, -3)
                        self.PendingTransmogFrame:SetPoint("BOTTOMRIGHT", model, -1, 2)
                        self.PendingTransmogFrame.TransmogSelectedAnim2:Stop()
                    end

                    if not visualInfo.isCollected then
                        Base.SetBackdropColor(model._auroraBD, Color.frame, 0.3)
                        model:SetLight(true, notCollected)
                    elseif not visualInfo.isUsable then
                        Base.SetBackdropColor(model._auroraBD, Color.red, 0.3)
                        model:SetLight(true, notUsable)
                    else
                        Base.SetBackdropColor(model._auroraBD, Color.button, 0.3)
                        model:SetLight(true, default)
                    end

                    if borderColor then
                        model._auroraBD:SetBackdropBorderColor(borderColor)
                    end
                end
            end
        end

        Hook.WardrobeSetsCollectionMixin = {}
        function Hook.WardrobeSetsCollectionMixin:SetItemFrameQuality(itemFrame)
            if not itemFrame._auroraIconBorder then
                Skin.WardrobeSetsDetailsItemFrameTemplate(itemFrame)
            end

            local quality
            if itemFrame.collected then
                quality = _G.C_TransmogCollection.GetSourceInfo(itemFrame.sourceID).quality
            end
            Hook.SetItemButtonQuality(itemFrame, quality, itemFrame.sourceID)
        end

    end
end

do --[[ AddOns\Blizzard_Collections.xml ]]
    do --[[ Blizzard_CollectionTemplates ]]
        function Skin.CollectionsProgressBarTemplate(StatusBar)
            Skin.FrameTypeStatusBar(StatusBar)

            StatusBar.border:Hide()
            select(3, StatusBar:GetRegions()):Hide()
        end
        function Skin.CollectionsSpellButtonTemplate(CheckButton)
            Base.CropIcon(CheckButton.iconTexture, CheckButton)
            CheckButton.iconTexture:ClearAllPoints()
            CheckButton.iconTexture:SetPoint("TOPLEFT", 4, -4)
            CheckButton.iconTexture:SetPoint("BOTTOMRIGHT", -4, 4)

            Base.CropIcon(CheckButton.iconTextureUncollected)
            CheckButton.iconTextureUncollected:SetAllPoints(CheckButton.iconTexture)
            CheckButton.slotFrameUncollectedInnerGlow:SetTexture("")

            CheckButton.slotFrameCollected:SetTexture("")
            CheckButton.slotFrameUncollected:SetTexture("")

            CheckButton.cooldown:SetAllPoints(CheckButton.iconTexture)
            CheckButton.cooldownWrapper.slotFavorite:SetPoint("TOPLEFT", -10, 8)

            CheckButton:GetPushedTexture():SetAllPoints(CheckButton.iconTexture)
            Base.CropIcon(CheckButton:GetPushedTexture())

            CheckButton:GetHighlightTexture():SetAllPoints(CheckButton.iconTexture)
            Base.CropIcon(CheckButton:GetHighlightTexture())

            CheckButton:GetCheckedTexture():SetAllPoints(CheckButton.iconTexture)
            Base.CropIcon(CheckButton:GetCheckedTexture())
        end
        function Skin.CollectionsBackgroundTemplate(Frame)
            Skin.InsetFrameTemplate(Frame)

            Frame.BackgroundTile:Hide()

            Frame.ShadowCornerTopLeft:Hide()
            Frame.ShadowCornerTopRight:Hide()
            Frame.ShadowCornerBottomLeft:Hide()
            Frame.ShadowCornerBottomRight:Hide()
            Frame.ShadowCornerTop:Hide()
            Frame.ShadowCornerLeft:Hide()
            Frame.ShadowCornerRight:Hide()
            Frame.ShadowCornerBottom:Hide()

            Frame.OverlayShadowTopLeft:Hide()
            Frame.OverlayShadowTopRight:Hide()
            Frame.OverlayShadowBottomLeft:Hide()
            Frame.OverlayShadowBottomRight:Hide()
            Frame.OverlayShadowTop:Hide()
            Frame.OverlayShadowLeft:Hide()
            Frame.OverlayShadowRight:Hide()
            Frame.OverlayShadowBottom:Hide()

            -- Frame.BGCornerFilagreeBottomLeft:Hide()
            -- Frame.BGCornerFilagreeBottomRight:Hide()
            Frame.BGCornerTopLeft:SetAlpha(0)
            Frame.BGCornerTopRight:SetAlpha(0)
            Frame.BGCornerBottomLeft:Hide()
            Frame.BGCornerBottomRight:Hide()
            -- Frame.ShadowLineTop:Hide()
            -- Frame.ShadowLineBottom:Hide()
        end
        function Skin.CollectionsPrevPageButton(Button)
            Skin.NavButtonPrevious(Button)
        end
        function Skin.CollectionsNextPageButton(Button)
            Skin.NavButtonNext(Button)
        end
        function Skin.CollectionsPagingFrameTemplate(Frame)
            Skin.CollectionsPrevPageButton(Frame.PrevPageButton)
            Skin.CollectionsNextPageButton(Frame.NextPageButton)
        end
    end
    do --[[ Blizzard_Collections ]]
        function Skin.CollectionsJournalTab(Button)
            Skin.PanelTabButtonTemplate(Button)
        end
    end
    do --[[ Blizzard_MountCollection ]]
        function Skin.MountEquipmentButtonTemplate(Button)
            Base.SetBackdrop(Button, Color.frame)
            local bg = Button:GetRegions()
            bg:SetTexCoord(0.20289855072464, 0.79710144927536, 0.20289855072464, 0.79710144927536)
            bg:SetAllPoints()

            Base.CropIcon(Button:GetPushedTexture())
            Base.CropIcon(Button:GetHighlightTexture())
        end
        function Skin.MountListButtonTemplate(Button)
            Button.background:Hide()
            Base.SetBackdrop(Button, Color.frame)
            Button:SetBackdropOption("offsets", {
                left = 0,
                right = 0,
                top = 1,
                bottom = 1,
            })

            Base.CropIcon(Button.icon, Button)
            Button.iconBorder:Hide()

            local bg = Button:GetBackdropTexture("bg")
            Button.selectedTexture:SetTexCoord(0.00956937799043, 0.99043062200957, 0.04347826086957, 0.95652173913043)
            Button.selectedTexture:SetPoint("TOPLEFT", bg, 1, -1)
            Button.selectedTexture:SetPoint("BOTTOMRIGHT", bg, -1, 1)

            Base.CropIcon(Button.DragButton.ActiveTexture)
            Base.CropIcon(Button.DragButton:GetHighlightTexture())

            local highlight = Button:GetHighlightTexture()
            highlight:SetTexCoord(0.00956937799043, 0.99043062200957, 0.04347826086957, 0.95652173913043)
            highlight:SetPoint("TOPLEFT", bg, 1, -1)
            highlight:SetPoint("BOTTOMRIGHT", bg, -1, 1)
        end
    end
    do --[[ Blizzard_PetCollection ]]
        Skin["ExpBar-Divider"] = function(Texture)
            Texture:SetColorTexture(Color.button:GetRGB())
            Texture:SetSize(1, 11)
        end
        function Skin.CompanionListButtonTemplate(Button)
            Button.background:Hide()
            Base.SetBackdrop(Button, Color.frame)
            Button:SetBackdropOption("offsets", {
                left = 0,
                right = 0,
                top = 1,
                bottom = 1,
            })

            Button._auroraIconBorder = Base.CropIcon(Button.icon, Button)
            Button.iconBorder:SetAlpha(0)

            local bg = Button:GetBackdropTexture("bg")
            Button.selectedTexture:SetTexCoord(0.00956937799043, 0.99043062200957, 0.04347826086957, 0.95652173913043)
            Button.selectedTexture:SetPoint("TOPLEFT", bg, 1, -1)
            Button.selectedTexture:SetPoint("BOTTOMRIGHT", bg, -1, 1)

            local dragButton = Button.dragButton
            Base.CropIcon(dragButton.ActiveTexture)
            dragButton.levelBG:SetColorTexture(0, 0, 0, 0.5) -- static: not a theme color
            dragButton.levelBG:SetPoint("TOPLEFT", dragButton, "BOTTOMLEFT", 1, 13)
            dragButton.levelBG:SetPoint("BOTTOMRIGHT", -1, 1)
            dragButton.level:SetPoint("CENTER", dragButton.levelBG)
            Base.CropIcon(dragButton:GetHighlightTexture())

            local highlight = Button:GetHighlightTexture()
            highlight:SetTexCoord(0.00956937799043, 0.99043062200957, 0.04347826086957, 0.95652173913043)
            highlight:SetPoint("TOPLEFT", bg, 1, -1)
            highlight:SetPoint("BOTTOMRIGHT", bg, -1, 1)
        end
        function Skin.CompanionLoadOutSpellTemplate(CheckButton)
            CheckButton:GetRegions():Hide()
            Base.CropIcon(CheckButton.icon, CheckButton)
            Base.CropIcon(CheckButton.selected)
            Base.CropIcon(CheckButton:GetPushedTexture())
            Base.CropIcon(CheckButton:GetHighlightTexture())
            Base.CropIcon(CheckButton:GetCheckedTexture())
        end
        function Skin.CompanionLoadOutTemplate(Button)
            Button:GetRegions():Hide()

            Button._auroraIconBorder = Base.CropIcon(Button.icon, Button)
            Button.iconBorder:SetAlpha(0)
            Button.qualityBorder:SetAlpha(0)

            Button.levelBG:SetColorTexture(0, 0, 0, 0.5) -- static: not a theme color
            Button.levelBG:SetPoint("TOPLEFT", Button.icon, "BOTTOMLEFT", 0, 12)
            Button.levelBG:SetPoint("BOTTOMRIGHT", Button.icon)
            Button.level:SetPoint("CENTER", Button.levelBG)

            local healthFrame = Button.healthFrame
            Skin.FrameTypeStatusBar(healthFrame.healthBar)
            local left, right, mid, bg = healthFrame.healthBar:GetRegions()
            left:Hide()
            right:Hide()
            mid:Hide()
            bg:Hide()

            Skin.CompanionLoadOutSpellTemplate(Button.spell1)
            Skin.CompanionLoadOutSpellTemplate(Button.spell2)
            Skin.CompanionLoadOutSpellTemplate(Button.spell3)

            local xpBar = Button.xpBar
            Skin.FrameTypeStatusBar(xpBar)
            local regions = {xpBar:GetRegions()}
            regions[2]:Hide() -- Left
            regions[3]:Hide() -- Right
            regions[4]:Hide() -- Middle

            for i = 5, 11 do
                Skin["ExpBar-Divider"](regions[i])
            end

            regions[12]:Hide() -- BGMiddle

            local setHighlight = Button.setButton:GetRegions()
            Base.CropIcon(setHighlight)
            setHighlight:SetAllPoints(Button.icon)

            Base.CropIcon(Button.dragButton:GetHighlightTexture())
        end
        function Skin.PetCardSpellButtonTemplate(Button)
            Base.CropIcon(Button.icon, Button)
        end
        function Skin.PetSpellSelectButtonTemplate(CheckButton)
            Base.CropIcon(CheckButton.icon, CheckButton)
            Base.CropIcon(CheckButton:GetPushedTexture())
            Base.CropIcon(CheckButton:GetHighlightTexture())
            Base.CropIcon(CheckButton:GetCheckedTexture())
        end
    end
    do --[[ Blizzard_ToyBox ]]
        function Skin.ToySpellButtonTemplate(CheckButton)
            Skin.CollectionsSpellButtonTemplate(CheckButton)
        end
    end
    do --[[ Blizzard_HeirloomCollection ]]
        function Skin.HeirloomSpellButtonTemplate(CheckButton)
            Skin.CollectionsSpellButtonTemplate(CheckButton)

            CheckButton.levelBackground:ClearAllPoints()
            CheckButton.levelBackground:SetPoint("TOPLEFT", CheckButton.iconTexture, "BOTTOMLEFT", 0, 12)
            CheckButton.levelBackground:SetPoint("BOTTOMRIGHT", CheckButton.iconTexture)
            CheckButton.levelBackground:SetColorTexture(0, 0, 0, 0.5) -- static: not a theme color
            CheckButton.level:ClearAllPoints()
            CheckButton.level:SetPoint("CENTER", CheckButton.levelBackground)
        end
    end
    do --[[ Blizzard_Wardrobe ]]
        function Skin.WardrobeItemsModelTemplate(DressUpModel)
            local bg, _, _, highlight = DressUpModel:GetRegions()
            bg:Hide()
            DressUpModel.Border:Hide()

            local bd = _G.CreateFrame("Frame", nil, DressUpModel)
            bd:SetPoint("TOPLEFT")
            bd:SetPoint("BOTTOMRIGHT", 2, -2)
            Base.SetBackdrop(bd, Color.button, 0.3)
            DressUpModel._auroraBD = bd

            highlight:SetTexCoord(.03, .97, .03, .97)
            highlight:SetPoint("TOPLEFT", 0, 0)
            highlight:SetPoint("BOTTOMRIGHT", 1, -1)
        end
        function Skin.WardrobeSetsScrollFrameButtonTemplate(Frame)
            Frame.Background:Hide()
            Base.SetBackdrop(Frame, Color.frame)
            Frame:SetBackdropOption("offsets", {
                left = 0,
                right = 0,
                top = 1,
                bottom = 1,
            })

            Base.CropIcon(Frame.IconFrame.Icon, Frame.IconFrame)

            local bg = Frame:GetBackdropTexture("bg")
            Frame.SelectedTexture:SetTexCoord(0.00956937799043, 0.99043062200957, 0.04347826086957, 0.95652173913043)
            Frame.SelectedTexture:SetPoint("TOPLEFT", bg, 1, -1)
            Frame.SelectedTexture:SetPoint("BOTTOMRIGHT", bg, -1, 1)

            Frame.HighlightTexture:SetTexCoord(0.00956937799043, 0.99043062200957, 0.04347826086957, 0.95652173913043)
            Frame.HighlightTexture:SetPoint("TOPLEFT", bg, 1, -1)
            Frame.HighlightTexture:SetPoint("BOTTOMRIGHT", bg, -1, 1)
        end
        function Skin.WardrobeSetsDetailsItemFrameTemplate(Frame)
            Frame.IconBorder:Hide()
            Base.CropIcon(Frame.Icon)

            local bg = _G.CreateFrame("Frame", nil, Frame)
            bg:SetFrameLevel(Frame:GetFrameLevel() - 1)
            bg:SetPoint("TOPLEFT", Frame.Icon, -1, 1)
            bg:SetPoint("BOTTOMRIGHT", Frame.Icon, 1, -1)
            Base.SetBackdrop(bg, Color.black, 0.3)
            Frame._auroraIconBorder = bg
        end
    end

    do --[[ Blizzard_HeirloomCollection ]]
        -- local NO_CLASS_FILTER = 0
        -- local NO_SPEC_FILTER = 0
        Hook.WarbandSceneJounalMixin = {}
        function Hook.WarbandSceneJounalMixin:OnLoad()
            _G.print("WarbandSceneJounalMixin:OnLoad")
        end
        function Hook.WarbandSceneJounalMixin:OnShow()
            _G.print("WarbandSceneJounalMixin:OnShow")
        end
        function Hook.WarbandSceneJounalMixin:OnEvent()
            _G.print("WarbandSceneJounalMixin:OnEvent")
        end
    end
end

function private.AddOns.Blizzard_Collections()
    --local r, g, b = C.r, C.g, C.b

    ----====####################====----
    --  Blizzard_CollectionTemplates  --
    ----====####################====----


    ----====####################====----
    --      Blizzard_Collections      --
    ----====####################====----
    local CollectionsJournal = _G.CollectionsJournal
    Skin.PortraitFrameTemplate(CollectionsJournal)

    Skin.CollectionsJournalTab(_G.CollectionsJournalTab1)
    Skin.CollectionsJournalTab(_G.CollectionsJournalTab2)
    Skin.CollectionsJournalTab(_G.CollectionsJournalTab3)
    Skin.CollectionsJournalTab(_G.CollectionsJournalTab4)
    if _G.CollectionsJournalTab5 then
        Skin.CollectionsJournalTab(_G.CollectionsJournalTab5)
    end
    if _G.CollectionsJournalTab6 then
        Skin.CollectionsJournalTab(_G.CollectionsJournalTab6)
    end
    Util.PositionRelative("TOPLEFT", CollectionsJournal, "BOTTOMLEFT", 20, -1, 1, "Right", {
        _G.CollectionsJournalTab1,
        _G.CollectionsJournalTab2,
        _G.CollectionsJournalTab3,
        _G.CollectionsJournalTab4,
        _G.CollectionsJournalTab5,
        _G.CollectionsJournalTab6,
    })
    ----====####################====----
    --    Blizzard_MountCollection    --
    ----====####################====----
    local MountJournal = _G.MountJournal

    Skin.UIPanelSpellButtonFrameTemplate(MountJournal.SummonRandomFavoriteSpellFrame.Button)

    local ToggleFlyoutButton = MountJournal.ToggleDynamicFlightFlyoutButton
    Skin.FrameTypeButton(ToggleFlyoutButton)
    ToggleFlyoutButton.Border:SetAlpha(0)
    _G.hooksecurefunc(ToggleFlyoutButton, "UpdateBorderShadow", function(self)
        self.BorderShadow:Hide()
    end)
    _G.hooksecurefunc(ToggleFlyoutButton, "UpdateArrowShown", function(self)
        self.Arrow:Hide()
    end)

    local DynamicFlightFlyoutPopup = MountJournal.DynamicFlightFlyoutPopup
    Skin.FrameTypeFrame(DynamicFlightFlyoutPopup)
    DynamicFlightFlyoutPopup.Background:Hide()
    Skin.FrameTypeButton(DynamicFlightFlyoutPopup.OpenDynamicFlightSkillTreeButton)
    Skin.FrameTypeButton(DynamicFlightFlyoutPopup.DynamicFlightModeButton)
    Base.CropIcon(DynamicFlightFlyoutPopup.DynamicFlightModeButton.texture, DynamicFlightFlyoutPopup.DynamicFlightModeButton)

    Skin.InsetFrameTemplate(MountJournal.LeftInset)

    local BottomLeftInset = MountJournal.BottomLeftInset
    Skin.InsetFrameTemplate(BottomLeftInset)
    Skin.MountEquipmentButtonTemplate(BottomLeftInset.SlotButton)
    BottomLeftInset.SlotButton:SetPoint("LEFT", 23, 5)
    BottomLeftInset.Background:Hide()
    BottomLeftInset.BackgroundOverlay:Hide()
    select(4, BottomLeftInset:GetRegions()):Hide()

    Skin.InsetFrameTemplate(MountJournal.RightInset)
    Skin.SearchBoxTemplate(MountJournal.searchBox)
    Skin.FilterButton(MountJournal.FilterDropdown)
    Skin.InsetFrameTemplate3(MountJournal.MountCount)

    local MountDisplay = MountJournal.MountDisplay
    MountDisplay.YesMountsTex:SetAlpha(0)
    MountDisplay.NoMountsTex:SetAlpha(0)
    MountDisplay.ShadowOverlay:Hide()
    Base.CropIcon(MountDisplay.InfoButton.Icon, MountDisplay.InfoButton)
    Skin.ModelSceneControlFrameTemplateLeftButtonTemplate(MountDisplay.ModelScene.ControlFrame.rotateLeftButton)
    Skin.ModelSceneControlFrameTemplateRightButtonTemplate(MountDisplay.ModelScene.ControlFrame.rotateRightButton)
    Skin.UICheckButtonTemplate(MountDisplay.ModelScene.TogglePlayer)

    Skin.WowScrollBoxList(MountJournal.ScrollBox)
    Skin.MinimalScrollBar(MountJournal.ScrollBar)
    Skin.MagicButtonTemplate(MountJournal.MountButton)


    ----====####################====----
    --     Blizzard_PetCollection     --
    ----====####################====----
    local PetJournal = _G.PetJournal
    _G.hooksecurefunc("PetJournal_UpdatePetLoadOut", Hook.PetJournal_UpdatePetLoadOut)
    _G.hooksecurefunc("PetJournal_UpdatePetCard", Hook.PetJournal_UpdatePetCard)

    Skin.InsetFrameTemplate3(PetJournal.PetCount)
    Skin.MainHelpPlateButton(PetJournal.MainHelpButton)
    PetJournal.MainHelpButton:SetPoint("TOPLEFT", PetJournal, "TOPLEFT", -15, 15)

    Skin.UIPanelSpellButtonFrameTemplate(PetJournal.HealPetSpellFrame.Button)
    Skin.UIPanelSpellButtonFrameTemplate(PetJournal.SummonRandomPetSpellFrame.Button)

    Skin.InsetFrameTemplate(PetJournal.LeftInset)
    Skin.InsetFrameTemplate(PetJournal.PetCardInset)
    Skin.InsetFrameTemplate(PetJournal.RightInset)
    Skin.SearchBoxTemplate(PetJournal.searchBox)
    Skin.FilterButton(PetJournal.FilterDropdown)
    Skin.WowScrollBoxList(PetJournal.ScrollBox)
    Skin.MinimalScrollBar(PetJournal.ScrollBar)

    PetJournal.loadoutBorder:DisableDrawLayer("ARTWORK")
    _G.PetJournalLoadoutBorderSlotHeaderBG:Hide()
    _G.PetJournalLoadoutBorderSlotHeaderF:Hide()
    _G.PetJournalLoadoutBorderSlotHeaderLeft:Hide()
    _G.PetJournalLoadoutBorderSlotHeaderRight:Hide()

    Skin.CompanionLoadOutTemplate(PetJournal.Loadout.Pet1)
    Skin.CompanionLoadOutTemplate(PetJournal.Loadout.Pet2)
    Skin.CompanionLoadOutTemplate(PetJournal.Loadout.Pet3)

    local PetCard = PetJournal.PetCard
    _G.PetJournalPetCardBG:Hide()
    PetCard.AbilitiesBG1:SetAlpha(0)
    PetCard.AbilitiesBG2:SetAlpha(0)
    PetCard.AbilitiesBG3:SetAlpha(0)

    local PetInfo = PetCard.PetInfo
    PetInfo._auroraIconBorder = Base.CropIcon(PetInfo.icon, PetInfo)
    PetInfo.qualityBorder:SetAlpha(0)

    PetInfo.levelBG:SetColorTexture(0, 0, 0, 0.5) -- static: not a theme color
    PetInfo.levelBG:SetPoint("TOPLEFT", PetInfo.icon, "BOTTOMLEFT", 0, 12)
    PetInfo.levelBG:SetPoint("BOTTOMRIGHT", PetInfo.icon)

    Base.CropIcon(PetCard.TypeInfo.typeIcon, PetCard.TypeInfo)

    local healthBar = PetCard.HealthFrame.healthBar
    Skin.FrameTypeStatusBar(healthBar)
    local left, right, mid, bg = healthBar:GetRegions()
    left:Hide()
    right:Hide()
    mid:Hide()
    bg:Hide()

    for i = 1, 6 do
        Skin.PetCardSpellButtonTemplate(PetCard["spell"..i])
    end

    local xpBar = PetCard.xpBar
    Skin.FrameTypeStatusBar(xpBar)
    local regions = {xpBar:GetRegions()}
    regions[2]:Hide() -- Left
    regions[3]:Hide() -- Right
    regions[4]:Hide() -- Middle

    for i = 5, 11 do
        Skin["ExpBar-Divider"](regions[i])
    end

    regions[12]:Hide() -- BGMiddle


    Skin.MagicButtonTemplate(PetJournal.FindBattleButton)
    Skin.MagicButtonTemplate(PetJournal.SummonButton)

    local spellSelect = PetJournal.SpellSelect
    spellSelect.BgEnd:Hide()
    spellSelect.BgTiled:Hide()
    Skin.FrameTypeFrame(spellSelect)
    spellSelect:SetBackdropOption("offsets", {
        left = -3,
        right = -3,
        top = 1,
        bottom = 1,
    })
    Skin.PetSpellSelectButtonTemplate(spellSelect.Spell1)
    Skin.PetSpellSelectButtonTemplate(spellSelect.Spell2)

    if not private.disabled.tooltips then
        Skin.SharedPetBattleAbilityTooltipTemplate(_G.PetJournalPrimaryAbilityTooltip)
        Skin.SharedPetBattleAbilityTooltipTemplate(_G.PetJournalSecondaryAbilityTooltip)
    end


    ----====#####################====----
    --         Blizzard_ToyBox         --
    ----====#####################====----
    local ToyBox = _G.ToyBox

    Skin.CollectionsProgressBarTemplate(ToyBox.progressBar)
    Skin.SearchBoxTemplate(ToyBox.searchBox)
    Skin.FilterButton(ToyBox.FilterDropdown)

    local iconsFrame = ToyBox.iconsFrame
    Skin.CollectionsBackgroundTemplate(iconsFrame)

    for i = 1, 18 do
        Skin.ToySpellButtonTemplate(iconsFrame["spellButton"..i])
    end

    Skin.CollectionsPagingFrameTemplate(ToyBox.PagingFrame)


    ----====#####################====----
    --   Blizzard_HeirloomCollection   --
    ----====#####################====----
    local HeirloomsJournal = _G.HeirloomsJournal
    Util.Mixin(HeirloomsJournal, Hook.HeirloomsMixin)

    Skin.CollectionsProgressBarTemplate(HeirloomsJournal.progressBar)
    Skin.SearchBoxTemplate(HeirloomsJournal.SearchBox)
    Skin.DropdownButton(HeirloomsJournal.FilterDropdown)
    Skin.DropdownButton(HeirloomsJournal.ClassDropdown)

    Skin.CollectionsBackgroundTemplate(HeirloomsJournal.iconsFrame)
    Skin.CollectionsPagingFrameTemplate(HeirloomsJournal.PagingFrame)


    ----====#####################====----
    --        Blizzard_Wardrobe        --
    ----====#####################====----

    -----------------------------
    -- WardrobeCollectionFrame --
    -----------------------------
    local WardrobeCollectionFrame = _G.WardrobeCollectionFrame
    Skin.PanelTopTabButtonTemplate(WardrobeCollectionFrame.ItemsTab)
    Skin.PanelTopTabButtonTemplate(WardrobeCollectionFrame.SetsTab)

    Skin.SearchBoxTemplate(WardrobeCollectionFrame.searchBox)
    Skin.CollectionsProgressBarTemplate(WardrobeCollectionFrame.progressBar)
    Skin.FilterButton(WardrobeCollectionFrame.FilterButton)
    Skin.DropdownButton(WardrobeCollectionFrame.ClassDropdown)

    -- Items
    local ItemsCollectionFrame = WardrobeCollectionFrame.ItemsCollectionFrame
    Util.Mixin(ItemsCollectionFrame, Hook.WardrobeItemsCollectionMixin)

    Skin.CollectionsBackgroundTemplate(ItemsCollectionFrame)
    Skin.CollectionsPagingFrameTemplate(ItemsCollectionFrame.PagingFrame)
    Skin.DropdownButton(ItemsCollectionFrame.WeaponDropdown)

    local Models = ItemsCollectionFrame.Models
    for i = 1, #Models do
        Skin.WardrobeItemsModelTemplate(Models[i])
    end

    -- Sets
    local SetsCollectionFrame = WardrobeCollectionFrame.SetsCollectionFrame
    Util.Mixin(SetsCollectionFrame, Hook.WardrobeSetsCollectionMixin)
    Skin.InsetFrameTemplate(SetsCollectionFrame.LeftInset)
    Skin.CollectionsBackgroundTemplate(SetsCollectionFrame.RightInset)
    Skin.WowScrollBoxList(SetsCollectionFrame.ListContainer.ScrollBox)
    Skin.MinimalScrollBar(SetsCollectionFrame.ListContainer.ScrollBar)


    local DetailsFrame = SetsCollectionFrame.DetailsFrame
    DetailsFrame.ModelFadeTexture:Hide()
    Skin.DropdownButton(DetailsFrame.VariantSetsDropdown)

    ----====########################%%%########====----
    --        Blizzard_WarbandSceneCollection        --
    ----====########################%%%########====----

    local WarbandSceneJournal = _G.WarbandSceneJournal
    Util.Mixin(WarbandSceneJournal, Hook.WarbandSceneJounalMixin)
    Skin.UICheckButtonTemplate(WarbandSceneJournal.IconsFrame.Icons.Controls.ShowOwned.Checkbox)
    WarbandSceneJournal.IconsFrame.Icons.Controls.ShowOwned.Checkbox:SetSize(24, 24)
    Skin.CollectionsBackgroundTemplate(WarbandSceneJournal.IconsFrame)
    Skin.CollectionsPagingFrameTemplate(WarbandSceneJournal.IconsFrame.Icons.Controls.PagingControls)
end
