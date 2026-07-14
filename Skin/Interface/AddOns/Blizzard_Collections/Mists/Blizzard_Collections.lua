local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs select

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

--[[ Mists (5.5.4) Collections journal — Cata-generation shell with
    retail-modern guts (ScrollBox lists, modern filter dropdowns, model
    scenes). Mount/Pet/ToyBox/Heirloom panes adapted from the Mainline
    skin with live-drift guards; the Wardrobe tab (unique Mists layout,
    580-line diff vs retail) is STOCK first pass. Evidence:
    wow-ui-source-classic/Interface/AddOns/Blizzard_Collections/
    {Classic,Shared}/*.xml; reference: Blizzard_Collections/Mainline/.
]]

local function SafeScrollBar(bar)
    if not bar then return end
    if bar.Track and Skin.WowTrimScrollBar then
        -- live classic WowTrimScrollBar hybrid (handled by the shared skin)
        Skin.WowTrimScrollBar(bar)
    elseif Skin.MinimalScrollBar then
        Skin.MinimalScrollBar(bar)
    end
end

local function SafeScrollBox(box)
    if box and Skin.WowScrollBoxList then
        Skin.WowScrollBoxList(box)
    end
end

-- the icon-page background (parchment + ornate corners) is an
-- InsetFrameTemplate-family frame: art lives on its regions AND its
-- NineSlice child
local function SkinIconsFrame(frame)
    if not frame then return end
    Util.HideFrameTextures(frame, true)
    if frame.NineSlice then
        Util.HideFrameTextures(frame.NineSlice, true)
    end
    for i = 1, _G.select("#", frame:GetChildren()) do
        local child = _G.select(i, frame:GetChildren())
        if child:GetObjectType() == "Frame" and not child:GetName() then
            Util.HideFrameTextures(child, true)
        end
    end
end

local function SkinPagingFrame(paging)
    if not paging then return end
    local prev = paging.PrevPageButton or paging.prevPageButton
    local nextButton = paging.NextPageButton or paging.nextPageButton
    if prev then Skin.NavButtonPrevious(prev) end
    if nextButton then Skin.NavButtonNext(nextButton) end
end

local function HookScrollBoxRows(box, skinFunc)
    if not (box and box.ForEachFrame) then return end
    local function SkinRows()
        box:ForEachFrame(function(row)
            if not row._auroraSkinned then
                row._auroraSkinned = true
                skinFunc(row)
            end
        end)
    end
    SkinRows()
    if box.Update then
        _G.hooksecurefunc(box, "Update", SkinRows)
    end
end

do --[[ Blizzard_CollectionTemplates ]]
    function Skin.CollectionsSpellButtonTemplate(CheckButton)
        if CheckButton.iconTexture then
            Base.CropIcon(CheckButton.iconTexture, CheckButton)
            CheckButton.iconTexture:ClearAllPoints()
            CheckButton.iconTexture:SetPoint("TOPLEFT", 4, -4)
            CheckButton.iconTexture:SetPoint("BOTTOMRIGHT", -4, 4)
        end
        if CheckButton.iconTextureUncollected then
            Base.CropIcon(CheckButton.iconTextureUncollected)
            if CheckButton.iconTexture then
                CheckButton.iconTextureUncollected:SetAllPoints(CheckButton.iconTexture)
            end
        end
        if CheckButton.slotFrameUncollectedInnerGlow then
            CheckButton.slotFrameUncollectedInnerGlow:SetTexture("")
        end
        if CheckButton.slotFrameCollected then
            CheckButton.slotFrameCollected:SetTexture("")
        end
        if CheckButton.slotFrameUncollected then
            CheckButton.slotFrameUncollected:SetTexture("")
        end
        if CheckButton.cooldown and CheckButton.iconTexture then
            CheckButton.cooldown:SetAllPoints(CheckButton.iconTexture)
        end

        local pushed = CheckButton:GetPushedTexture()
        if pushed then
            if CheckButton.iconTexture then pushed:SetAllPoints(CheckButton.iconTexture) end
            Base.CropIcon(pushed)
        end
        local highlight = CheckButton:GetHighlightTexture()
        if highlight then
            if CheckButton.iconTexture then highlight:SetAllPoints(CheckButton.iconTexture) end
            Base.CropIcon(highlight)
        end
        local checked = CheckButton:GetCheckedTexture()
        if checked then
            if CheckButton.iconTexture then checked:SetAllPoints(CheckButton.iconTexture) end
            Base.CropIcon(checked)
        end
    end
    function Skin.CollectionsProgressBarTemplate(StatusBar)
        Skin.FrameTypeStatusBar(StatusBar)
        if StatusBar.border then
            StatusBar.border:Hide()
        end
        if StatusBar.text then
            StatusBar.text:SetTextColor(Color.white:GetRGB())
        end
    end
    function Skin.CollectionsJournalTab(Button)
        Skin.PanelTabButtonTemplate(Button)
    end
end

do --[[ Blizzard_MountCollection ]]
    function Skin.MountListButtonTemplate(Button)
        if Button.background then
            Button.background:Hide()
        end
        Base.SetBackdrop(Button, Color.frame)
        Button:SetBackdropOption("offsets", {
            left = 0,
            right = 0,
            top = 1,
            bottom = 1,
        })

        if Button.icon then
            Base.CropIcon(Button.icon, Button)
        end
        if Button.iconBorder then
            Button.iconBorder:Hide()
        end

        local bg = Button:GetBackdropTexture("bg")
        if Button.selectedTexture and bg then
            Button.selectedTexture:SetTexCoord(0.00956937799043, 0.99043062200957, 0.04347826086957, 0.95652173913043)
            Button.selectedTexture:SetPoint("TOPLEFT", bg, 1, -1)
            Button.selectedTexture:SetPoint("BOTTOMRIGHT", bg, -1, 1)
        end
        if Button.DragButton then
            if Button.DragButton.ActiveTexture then
                Base.CropIcon(Button.DragButton.ActiveTexture)
            end
            local dragHighlight = Button.DragButton:GetHighlightTexture()
            if dragHighlight then
                Base.CropIcon(dragHighlight)
            end
        end

        local highlight = Button:GetHighlightTexture()
        if highlight and bg then
            highlight:SetTexCoord(0.00956937799043, 0.99043062200957, 0.04347826086957, 0.95652173913043)
            highlight:SetPoint("TOPLEFT", bg, 1, -1)
            highlight:SetPoint("BOTTOMRIGHT", bg, -1, 1)
        end
    end
end

do --[[ Blizzard_PetCollection (Shared with retail) ]]
    function Skin.CompanionListButtonTemplate(Button)
        if Button.background then
            Button.background:Hide()
        end
        Base.SetBackdrop(Button, Color.frame)
        Button:SetBackdropOption("offsets", {
            left = 0,
            right = 0,
            top = 1,
            bottom = 1,
        })

        if Button.icon then
            Button._auroraIconBorder = Base.CropIcon(Button.icon, Button)
        end
        if Button.iconBorder then
            Button.iconBorder:SetAlpha(0)
        end

        local bg = Button:GetBackdropTexture("bg")
        if Button.selectedTexture and bg then
            Button.selectedTexture:SetTexCoord(0.00956937799043, 0.99043062200957, 0.04347826086957, 0.95652173913043)
            Button.selectedTexture:SetPoint("TOPLEFT", bg, 1, -1)
            Button.selectedTexture:SetPoint("BOTTOMRIGHT", bg, -1, 1)
        end

        local dragButton = Button.dragButton
        if dragButton then
            if dragButton.ActiveTexture then
                Base.CropIcon(dragButton.ActiveTexture)
            end
            if dragButton.levelBG then
                dragButton.levelBG:SetColorTexture(0, 0, 0, 0.5) -- static: not a theme color
            end
            local dragHighlight = dragButton:GetHighlightTexture()
            if dragHighlight then
                Base.CropIcon(dragHighlight)
            end
        end

        local highlight = Button:GetHighlightTexture()
        if highlight and bg then
            highlight:SetTexCoord(0.00956937799043, 0.99043062200957, 0.04347826086957, 0.95652173913043)
            highlight:SetPoint("TOPLEFT", bg, 1, -1)
            highlight:SetPoint("BOTTOMRIGHT", bg, -1, 1)
        end
    end
    function Skin.CompanionLoadOutTemplate(Button)
        if Button.icon then
            Button._auroraIconBorder = Base.CropIcon(Button.icon, Button)
        end
        if Button.iconBorder then Button.iconBorder:SetAlpha(0) end
        if Button.qualityBorder then Button.qualityBorder:SetAlpha(0) end
        if Button.levelBG then
            Button.levelBG:SetColorTexture(0, 0, 0, 0.5) -- static: not a theme color
        end
        if Button.healthFrame and Button.healthFrame.healthBar then
            Skin.FrameTypeStatusBar(Button.healthFrame.healthBar)
        end
        if Button.xpBar then
            Skin.FrameTypeStatusBar(Button.xpBar)
        end
    end
    function Hook.PetJournal_UpdatePetLoadOut()
        for i = 1, 3 do
            local loadoutPlate = _G.PetJournal.Loadout["Pet"..i]
            if loadoutPlate and loadoutPlate._auroraIconBorder and loadoutPlate.iconBorder then
                local petID = _G.C_PetJournal.GetPetLoadOutInfo(i)
                if petID and loadoutPlate.iconBorder:IsShown() then
                    local _, _, _, _, rarity = _G.C_PetJournal.GetPetStats(petID)
                    local color = rarity and _G.ITEM_QUALITY_COLORS[rarity - 1]
                    if color then
                        loadoutPlate._auroraIconBorder:SetColorTexture(color.r, color.g, color.b)
                    end
                else
                    loadoutPlate._auroraIconBorder:SetColorTexture(Color.black:GetRGB())
                end
            end
        end
    end
end

-- pane globals from the dump (MountJournal etc.) may be ABSENT on live —
-- identify panes among CollectionsJournal's children by distinctive keys
local function FindPane(globalName, matcher)
    if _G[globalName] then return _G[globalName] end
    local parent = _G.CollectionsJournal
    if not parent then return end
    for i = 1, _G.select("#", parent:GetChildren()) do
        local child = _G.select(i, parent:GetChildren())
        if matcher(child) then
            return child
        end
    end
end

function private.AddOns.Blizzard_Collections()
    local CollectionsJournal = _G.CollectionsJournal
    if not CollectionsJournal then return end

    Skin.PortraitFrameTemplate(CollectionsJournal)

    local tabs = {}
    for i = 1, 6 do
        local tab = _G["CollectionsJournalTab"..i]
        if tab then
            Skin.CollectionsJournalTab(tab)
            tabs[#tabs + 1] = tab
        end
    end
    if Util.PositionRelative and #tabs > 0 then
        Util.PositionRelative("TOPLEFT", CollectionsJournal, "BOTTOMLEFT", 20, -1, 1, "Right", tabs)
    end

    ----====####################====----
    --    Blizzard_MountCollection    --
    ----====####################====----
    local MountJournal = FindPane("MountJournal", function(c) return c.MountDisplay ~= nil end)
    if MountJournal then
        for _, key in ipairs({"LeftInset", "BottomLeftInset", "RightInset"}) do
            if MountJournal[key] then
                Skin.InsetFrameTemplate(MountJournal[key])
            end
        end
        local BottomLeft = MountJournal.BottomLeftInset
        if BottomLeft then
            if BottomLeft.Background then BottomLeft.Background:Hide() end
            if BottomLeft.BackgroundOverlay then BottomLeft.BackgroundOverlay:Hide() end
            if BottomLeft.SlotButton then
                local pushed = BottomLeft.SlotButton:GetPushedTexture()
                if pushed then Base.CropIcon(pushed) end
                local highlight = BottomLeft.SlotButton:GetHighlightTexture()
                if highlight then Base.CropIcon(highlight) end
                if BottomLeft.SlotButton.ItemIcon then
                    Base.CropIcon(BottomLeft.SlotButton.ItemIcon)
                end
            end
        end

        if MountJournal.searchBox and Skin.SearchBoxTemplate then
            Skin.SearchBoxTemplate(MountJournal.searchBox)
        end
        if MountJournal.FilterDropdown and Skin.FilterButton then
            Skin.FilterButton(MountJournal.FilterDropdown)
        end
        if MountJournal.MountCount then
            Util.HideFrameTextures(MountJournal.MountCount, true)
            Base.SetBackdrop(MountJournal.MountCount, Color.frame, Color.frame.a)
        end

        -- summon random favorite: icon slot in the top-left
        local summon = MountJournal.SummonRandomFavoriteButton
        if summon and summon.texture then
            Base.CropIcon(summon.texture, summon)
        end

        local MountDisplay = MountJournal.MountDisplay
        if MountDisplay then
            -- the red ornate display backdrop is a plain region
            Util.HideFrameTextures(MountDisplay, true)
            if MountDisplay.ShadowOverlay then
                Util.HideFrameTextures(MountDisplay.ShadowOverlay)
            end
            if MountDisplay.InfoButton and MountDisplay.InfoButton.Icon then
                Base.CropIcon(MountDisplay.InfoButton.Icon, MountDisplay.InfoButton)
            end
            local scene = MountDisplay.ModelScene
            if scene then
                -- the red ornate backdrop is on the scene (models are
                -- actors, not regions — sweep is safe)
                Util.HideFrameTextures(scene, true)
                if scene.TogglePlayer then
                    Skin.UICheckButtonTemplate(scene.TogglePlayer)
                end
                if scene.RotateLeftButton and Skin.ModelSceneControlFrameTemplateLeftButtonTemplate then
                    Skin.ModelSceneControlFrameTemplateLeftButtonTemplate(scene.RotateLeftButton)
                    Skin.ModelSceneControlFrameTemplateRightButtonTemplate(scene.RotateRightButton)
                end
            end
        end

        SafeScrollBox(MountJournal.ScrollBox)
        SafeScrollBar(MountJournal.ScrollBar)
        HookScrollBoxRows(MountJournal.ScrollBox, Skin.MountListButtonTemplate)

        if MountJournal.MountButton then
            Skin.MagicButtonTemplate(MountJournal.MountButton)
        end
    end

    ----====####################====----
    --     Blizzard_PetCollection     --
    ----====####################====----
    local PetJournal = FindPane("PetJournal", function(c) return c.PetCard ~= nil end)
    if PetJournal then
        if _G.PetJournal_UpdatePetLoadOut then
            _G.hooksecurefunc("PetJournal_UpdatePetLoadOut", Hook.PetJournal_UpdatePetLoadOut)
        end

        for _, key in ipairs({"LeftInset", "PetCardInset", "RightInset"}) do
            if PetJournal[key] then
                Skin.InsetFrameTemplate(PetJournal[key])
            end
        end
        if PetJournal.PetCount then
            Util.HideFrameTextures(PetJournal.PetCount, true)
            Base.SetBackdrop(PetJournal.PetCount, Color.frame, Color.frame.a)
        end
        if PetJournal.searchBox and Skin.SearchBoxTemplate then
            Skin.SearchBoxTemplate(PetJournal.searchBox)
        end
        if PetJournal.FilterDropdown and Skin.FilterButton then
            Skin.FilterButton(PetJournal.FilterDropdown)
        end
        SafeScrollBox(PetJournal.ScrollBox)
        SafeScrollBar(PetJournal.ScrollBar)
        HookScrollBoxRows(PetJournal.ScrollBox, Skin.CompanionListButtonTemplate)

        if PetJournal.loadoutBorder then
            PetJournal.loadoutBorder:DisableDrawLayer("ARTWORK")
        end
        for _, name in ipairs({
            "PetJournalLoadoutBorderSlotHeaderBG", "PetJournalLoadoutBorderSlotHeaderF",
            "PetJournalLoadoutBorderSlotHeaderLeft", "PetJournalLoadoutBorderSlotHeaderRight",
        }) do
            if _G[name] then
                _G[name]:Hide()
            end
        end
        if PetJournal.Loadout then
            for i = 1, 3 do
                local pet = PetJournal.Loadout["Pet"..i]
                if pet then
                    Skin.CompanionLoadOutTemplate(pet)
                    -- locked-slot plates (ghost-pet art + ornate frame):
                    -- sweep everything but the pet icon
                    for j = 1, _G.select("#", pet:GetRegions()) do
                        local region = _G.select(j, pet:GetRegions())
                        if region:GetObjectType() == "Texture" and region ~= pet.icon
                            and region ~= pet.levelBG then
                            region:SetAlpha(0)
                        end
                    end
                    if pet.helpFrame then
                        Util.HideFrameTextures(pet.helpFrame, true)
                        Base.SetBackdrop(pet.helpFrame, Color.frame, Color.frame.a)
                    end
                end
            end
        end

        local PetCard = PetJournal.PetCard
        if PetCard then
            if _G.PetJournalPetCardBG then
                _G.PetJournalPetCardBG:Hide()
            end
            for i = 1, 3 do
                if PetCard["AbilitiesBG"..i] then
                    PetCard["AbilitiesBG"..i]:SetAlpha(0)
                end
            end
            if PetCard.PetInfo and PetCard.PetInfo.icon then
                PetCard.PetInfo._auroraIconBorder = Base.CropIcon(PetCard.PetInfo.icon, PetCard.PetInfo)
                if PetCard.PetInfo.qualityBorder then
                    PetCard.PetInfo.qualityBorder:SetAlpha(0)
                end
                if PetCard.PetInfo.levelBG then
                    PetCard.PetInfo.levelBG:SetColorTexture(0, 0, 0, 0.5) -- static: not a theme color
                end
            end
            if PetCard.HealthFrame and PetCard.HealthFrame.healthBar then
                Skin.FrameTypeStatusBar(PetCard.HealthFrame.healthBar)
            end
            if PetCard.xpBar then
                Skin.FrameTypeStatusBar(PetCard.xpBar)
            end
            for i = 1, 6 do
                local spell = PetCard["spell"..i]
                if spell and spell.icon then
                    Base.CropIcon(spell.icon, spell)
                end
            end
        end

        if PetJournal.FindBattleButton then
            Skin.MagicButtonTemplate(PetJournal.FindBattleButton)
        end
        if PetJournal.SummonButton then
            Skin.MagicButtonTemplate(PetJournal.SummonButton)
        end
    end

    ----====####################====----
    --        Blizzard_ToyBox         --
    ----====####################====----
    local ToyBox = FindPane("ToyBox", function(c)
        return c.iconsFrame ~= nil and c.UpdateButton == nil
    end)
    if ToyBox then
        if ToyBox.searchBox and Skin.SearchBoxTemplate then
            Skin.SearchBoxTemplate(ToyBox.searchBox)
        end
        if ToyBox.FilterDropdown and Skin.FilterButton then
            Skin.FilterButton(ToyBox.FilterDropdown)
        end
        if ToyBox.progressBar then
            Skin.CollectionsProgressBarTemplate(ToyBox.progressBar)
        end
        SkinPagingFrame(ToyBox.PagingFrame or ToyBox.pagingFrame)
        SkinIconsFrame(ToyBox.iconsFrame)
        for i = 1, 18 do
            local button = _G["ToySpellButton"..i]
            if button then
                Skin.CollectionsSpellButtonTemplate(button)
            end
        end
    end

    ----====####################====----
    --  Blizzard_HeirloomCollection   --
    ----====####################====----
    local Heirlooms = FindPane("HeirloomsJournal", function(c)
        return c.iconsFrame ~= nil and c.UpdateButton ~= nil
    end)
    if Heirlooms then
        if Heirlooms.SearchBox and Skin.SearchBoxTemplate then
            Skin.SearchBoxTemplate(Heirlooms.SearchBox)
        end
        if Heirlooms.FilterDropdown and Skin.FilterButton then
            Skin.FilterButton(Heirlooms.FilterDropdown)
        end
        if Heirlooms.ClassDropdown then
            Skin.DropdownButton(Heirlooms.ClassDropdown)
        elseif Heirlooms.classDropDown then
            -- legacy UIDropDownMenu variant
            Skin.UIDropDownMenuTemplate(Heirlooms.classDropDown)
        elseif _G.HeirloomsJournalClassDropDown then
            Skin.UIDropDownMenuTemplate(_G.HeirloomsJournalClassDropDown)
        end
        if Heirlooms.progressBar then
            Skin.CollectionsProgressBarTemplate(Heirlooms.progressBar)
        end
        SkinPagingFrame(Heirlooms.PagingFrame or Heirlooms.pagingFrame)
        SkinIconsFrame(Heirlooms.iconsFrame)
        if Heirlooms.UpdateButton then
            _G.hooksecurefunc(Heirlooms, "UpdateButton", function(self, button)
                if not button._auroraSkinned then
                    button._auroraSkinned = true
                    Skin.CollectionsSpellButtonTemplate(button)
                    if button.levelBackground then
                        button.levelBackground:SetColorTexture(0, 0, 0, 0.5) -- static: not a theme color
                    end
                end
            end)
        end
    end

    ----====####################====----
    --       Blizzard_Wardrobe        --
    ----====####################====----
    local Wardrobe = _G.WardrobeCollectionFrame
        or FindPane("WardrobeCollectionFrame", function(c) return c.ItemsCollectionFrame ~= nil end)
    if Wardrobe then
        -- page parchment + ornate corners
        SkinIconsFrame(Wardrobe)
        for _, key in ipairs({"ItemsTab", "SetsTab"}) do
            local tab = Wardrobe[key]
            if tab then
                if Skin.PanelTopTabButtonTemplate then
                    Skin.PanelTopTabButtonTemplate(tab)
                end
                -- bordered plate under the text
                Skin.FrameTypeButton(tab)
                tab:SetBackdropOption("offsets", {
                    left = 3,
                    right = 3,
                    top = 6,
                    bottom = 2,
                })
            end
        end
        if Wardrobe.SearchBox and Skin.SearchBoxTemplate then
            Skin.SearchBoxTemplate(Wardrobe.SearchBox)
        end
        if Wardrobe.FilterButton and Skin.FilterButton then
            Skin.FilterButton(Wardrobe.FilterButton)
        end
        local progress = Wardrobe.progressBar
        if progress then
            for _, key in ipairs({
                "barBackground", "barBorderLeft", "barBorderRight", "barBorderCenter",
            }) do
                if progress[key] then
                    progress[key]:SetAlpha(0)
                end
            end
            Skin.FrameTypeStatusBar(progress)
        end

        local Items = Wardrobe.ItemsCollectionFrame
        if Items then
            SkinIconsFrame(Items)
            SkinPagingFrame(Items.PagingFrame or Items.pagingFrame)
            if Items.WeaponDropdown then
                Skin.DropdownButton(Items.WeaponDropdown)
            end
            -- model cards + round slot buttons stock first pass (readable)
        end
        local Sets = Wardrobe.SetsCollectionFrame
        if Sets then
            SkinIconsFrame(Sets)
            local list = Sets.ListContainer
            if list then
                SafeScrollBox(list.ScrollBox)
                SafeScrollBar(list.ScrollBar)
                HookScrollBoxRows(list.ScrollBox, function(row)
                    if row.Background then row.Background:Hide() end
                    Base.SetBackdrop(row, Color.frame)
                    row:SetBackdropOption("offsets", {
                        left = 0,
                        right = 0,
                        top = 1,
                        bottom = 1,
                    })
                    if row.IconFrame and row.IconFrame.Icon then
                        Base.CropIcon(row.IconFrame.Icon, row.IconFrame)
                    end
                    local bg = row:GetBackdropTexture("bg")
                    if row.SelectedTexture and bg then
                        row.SelectedTexture:SetTexCoord(0.00956937799043, 0.99043062200957, 0.04347826086957, 0.95652173913043)
                        row.SelectedTexture:SetPoint("TOPLEFT", bg, 1, -1)
                        row.SelectedTexture:SetPoint("BOTTOMRIGHT", bg, -1, 1)
                    end
                    if row.HighlightTexture and bg then
                        row.HighlightTexture:SetTexCoord(0.00956937799043, 0.99043062200957, 0.04347826086957, 0.95652173913043)
                        row.HighlightTexture:SetPoint("TOPLEFT", bg, 1, -1)
                        row.HighlightTexture:SetPoint("BOTTOMRIGHT", bg, -1, 1)
                    end
                end)
            end
        end
        if Wardrobe.SetsTransmogFrame then
            SkinIconsFrame(Wardrobe.SetsTransmogFrame)
            SkinPagingFrame(Wardrobe.SetsTransmogFrame.PagingFrame)
        end
    end
end
