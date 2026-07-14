local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs select

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

--[[ Mists (5.5.4) Dungeon Journal — the Cata-generation journal in a
    modern-hybrid shell. Template names match retail, so this adapts the
    Mainline skin's treatments (icon side tabs, ScrollBox row hooks,
    accordion header strips) with live-drift guards. Evidence:
    wow-ui-source-classic/Interface/AddOns/Blizzard_EncounterJournal/
    Cata/Blizzard_EncounterJournal.{xml,lua}; reference:
    Blizzard_EncounterJournal/Mainline/Blizzard_EncounterJournal.lua.
]]

local function SafeScrollBar(bar)
    if bar and Skin.MinimalScrollBar then
        Skin.MinimalScrollBar(bar)
    end
end

local function SafeScrollBox(box)
    if box and Skin.WowScrollBoxList then
        Skin.WowScrollBoxList(box)
    end
end

do --[[ AddOns\Blizzard_EncounterJournal.lua ]]
    function Hook.EncounterJournal_UpdateButtonState(self)
        if self:GetParent().expanded then
            if self.expandedIcon then self.expandedIcon:SetTextColor(Color.white:GetRGB()) end
            if self.title then self.title:SetTextColor(Color.white:GetRGB()) end
        else
            if self.expandedIcon then self.expandedIcon:SetTextColor(Color.grayLight:GetRGB()) end
            if self.title then self.title:SetTextColor(Color.grayLight:GetRGB()) end
        end
    end
    function Hook.EncounterJournal_SetBullets(object)
        local parent = object:GetParent()
        if parent and parent.Bullets then
            for _, bullet in ipairs(parent.Bullets) do
                if bullet.Text and not bullet._auroraSkinned then
                    bullet._auroraSkinned = true
                    bullet.Text:SetTextColor("p", Color.grayLight:GetRGB())
                end
            end
        end
    end
    local numCreatureButtons = 1
    function Hook.EncounterJournal_ShowCreatures()
        local buttons = _G.EncounterJournal.encounter.info.creatureButtons
        if not buttons then return end
        local creatureButton = buttons[numCreatureButtons]
        while creatureButton do
            creatureButton:ClearNormalTexture()
            creatureButton:ClearHighlightTexture()
            numCreatureButtons = numCreatureButtons + 1
            creatureButton = buttons[numCreatureButtons]
        end
    end
end

do --[[ AddOns\Blizzard_EncounterJournal.xml ]]
    -- ornate EJ split buttons (difficulty, loot filters): art layouts
    -- vary — sweep, backdrop, white text
    function Skin.EJButtonTemplate(Button)
        if not Button then return end
        for i = 1, _G.select("#", Button:GetRegions()) do
            local region = _G.select(i, Button:GetRegions())
            if region:GetObjectType() == "Texture" then
                region:SetAlpha(0)
            end
        end
        Skin.FrameTypeButton(Button)
        local text = Button.GetFontString and Button:GetFontString()
        if text then
            text:SetTextColor(Color.white:GetRGB())
        end
    end

    -- side tabs: Cata anatomy = plate state textures + an OVERLAY icon
    -- pair Blizzard SWAPS on selection (EncounterJournal_SetTab shows
    -- selected/hides unselected). Treatment: plates cleared; `selected`
    -- becomes a LIGHT GRAY chosen-plate on a lower sublayer; a SetTab
    -- hook re-shows the icon; hover = darker gray pinned to the icon.
    function Skin.EncounterTabTemplate(Button)
        if not Button then return end
        Button:ClearNormalTexture()
        Button:ClearPushedTexture()
        Button:ClearDisabledTexture()

        if Button.selected and Button.unselected then
            Button.selected:SetColorTexture(0.75, 0.75, 0.75, 0.4)
            Button.selected:SetDrawLayer("ARTWORK")
            Button.selected:ClearAllPoints()
            Button.selected:SetPoint("TOPLEFT", Button.unselected, -3, 3)
            Button.selected:SetPoint("BOTTOMRIGHT", Button.unselected, 3, -3)
        end

        local highlight = Button:GetHighlightTexture()
        if highlight then
            highlight:SetBlendMode("BLEND")
            highlight:SetColorTexture(0.35, 0.35, 0.35, 0.6)
            -- the hit rect spans the old plate; the visible icon is the
            -- right-anchored overlay — pin the hover to it
            if Button.unselected then
                highlight:ClearAllPoints()
                highlight:SetPoint("TOPLEFT", Button.unselected, -3, 3)
                highlight:SetPoint("BOTTOMRIGHT", Button.unselected, 3, -3)
            end
        end
    end
    function Hook.EncounterJournal_SetTab()
        local info = _G.EncounterJournal.encounter.info
        for _, key in ipairs({"overviewTab", "lootTab", "bossTab", "modelTab"}) do
            local tab = info[key]
            if tab and tab.unselected then
                -- Blizzard hides the icon on the chosen tab (it expects
                -- the selected-icon variant to replace it) — our chosen
                -- plate needs the icon back
                tab.unselected:Show()
            end
        end
    end

    function Skin.EncounterBossButtonTemplate(Button)
        Skin.FrameTypeButton(Button)
        Button:SetBackdropOption("offsets", {
            left = 0,
            right = 0,
            top = 5,
            bottom = 5,
        })
        if Button.text then
            Button.text:SetTextColor(Color.white:GetRGB())
        end
    end

    -- accordion header (abilities + overview pools share the template)
    local paperPieces = {
        "eLeftUp", "eRightUp", "eLeftDown", "eRightDown",
        "cLeftUp", "cRightUp", "cLeftDown", "cRightDown",
        "eMidUp", "eMidDown", "cMidUp", "cMidDown",
    }
    function Skin.EncounterInfoTemplate(Frame)
        if Frame._auroraSkinned then return end
        Frame._auroraSkinned = true

        local button = Frame.button
        if button then
            Base.SetBackdrop(button, Color.button)
            for _, key in ipairs(paperPieces) do
                if button[key] then
                    button[key]:SetTexture("")
                end
            end
            local name = button:GetName()
            if name then
                for _, suffix in ipairs({"HighlightLeft", "HighlightRight", "HighlightMid"}) do
                    if _G[name..suffix] then
                        _G[name..suffix]:SetTexture("")
                    end
                end
            end
            if button.title then
                button.title:SetTextColor(Color.white:GetRGB())
            end
            if button.expandedIcon then
                button.expandedIcon:SetTextColor(Color.white:GetRGB())
            end
            if button.abilityIcon then
                Base.CropIcon(button.abilityIcon)
            end
        end

        if Frame.descriptionBG then Frame.descriptionBG:SetTexture("") end
        if Frame.descriptionBGBottom then Frame.descriptionBGBottom:SetTexture("") end
        if Frame.description then
            Frame.description:SetTextColor(Color.grayLight:GetRGB())
        end
        if Frame.overviewDescription and Frame.overviewDescription.Text then
            Frame.overviewDescription.Text:SetTextColor("p", Color.grayLight:GetRGB())
        end
    end

    function Hook.EncounterJournal_ToggleHeaders()
        for _, prefix in ipairs({
            "EncounterJournalInfoHeader",
            "EncounterJournalOverviewInfoHeader",
        }) do
            local index = 1
            local header = _G[prefix..index]
            while header do
                Skin.EncounterInfoTemplate(header)
                index = index + 1
                header = _G[prefix..index]
            end
        end
    end

    -- instance-select grid rows (Mainline treatment: crop the painting
    -- inside a backdrop)
    function Hook.EJInstanceSelectScrollUpdate(frame)
        frame:ForEachFrame(function(child)
            if child._auroraSkinned then return end
            child._auroraSkinned = true
            local bgImage = child.bgImage
            if bgImage then
                bgImage:SetAlpha(0.6)
                bgImage:SetTexCoord(0.01953125, 0.66015625, 0.0390625, 0.7109375)
                bgImage:SetPoint("TOPLEFT", 1, -1)
                bgImage:SetPoint("BOTTOMRIGHT", -1, 1)
            end
            Skin.FrameTypeButton(child)
        end)
    end
    function Hook.EJBossesScrollBoxScrollUpdate(frame)
        frame:ForEachFrame(function(child)
            if child._auroraSkinned then return end
            child._auroraSkinned = true
            Skin.EncounterBossButtonTemplate(child)
        end)
    end
    -- loot rows
    function Hook.EJLootScrollUpdate(frame)
        frame:ForEachFrame(function(child)
            if child._auroraSkinned then return end
            child._auroraSkinned = true
            if child.icon then
                Base.CropIcon(child.icon)
            end
            for _, key in ipairs({"boss", "slot", "armorType"}) do
                if child[key] then
                    child[key]:SetTextColor(Color.gray:GetRGB())
                end
            end
            if child.bossTexture then child.bossTexture:SetTexture("") end
            if child.bosslessTexture then child.bosslessTexture:SetTexture("") end
        end)
    end
end

function private.AddOns.Blizzard_EncounterJournal()
    local EncounterJournal = _G.EncounterJournal
    if not EncounterJournal then return end

    for _, name in ipairs({
        "EncounterJournal_UpdateButtonState", "EncounterJournal_SetBullets",
        "EncounterJournal_ToggleHeaders", "EncounterJournal_ShowCreatures",
        "EncounterJournal_SetTab",
    }) do
        if _G[name] then
            _G.hooksecurefunc(name, Hook[name])
        end
    end

    Skin.PortraitFrameTemplate(EncounterJournal)
    for _, key in ipairs({
        "InsetBorderBottomLeft", "InsetBorderBottomRight",
        "InsetBorderBottom", "InsetBorderLeft", "InsetBorderRight",
    }) do
        if EncounterJournal[key] then
            EncounterJournal[key]:SetAlpha(0)
        end
    end
    if EncounterJournal.inset then
        Skin.InsetFrameTemplate(EncounterJournal.inset)
    end

    if EncounterJournal.searchBox and Skin.SearchBoxTemplate then
        Skin.SearchBoxTemplate(EncounterJournal.searchBox)
    end
    local searchResults = EncounterJournal.searchResults
    if searchResults then
        Util.HideFrameTextures(searchResults, true)
        Skin.FrameTypeFrame(searchResults)
        if _G.EncounterJournalSearchResultsCloseButton then
            Skin.UIPanelCloseButton(_G.EncounterJournalSearchResultsCloseButton)
        end
        SafeScrollBox(searchResults.ScrollBox)
        SafeScrollBar(searchResults.ScrollBar)
    end

    -- instance select (landing page)
    local instanceSelect = EncounterJournal.instanceSelect
    if instanceSelect then
        if instanceSelect.bg then
            instanceSelect.bg:SetAlpha(0)
        end
        if instanceSelect.ExpansionDropdown then
            Skin.DropdownButton(instanceSelect.ExpansionDropdown)
        end
        SafeScrollBox(instanceSelect.ScrollBox)
        SafeScrollBar(instanceSelect.ScrollBar)
        if instanceSelect.ScrollBox and instanceSelect.ScrollBox.ForEachFrame then
            Hook.EJInstanceSelectScrollUpdate(instanceSelect.ScrollBox)
            if instanceSelect.ScrollBox.Update then
                _G.hooksecurefunc(instanceSelect.ScrollBox, "Update", Hook.EJInstanceSelectScrollUpdate)
            end
        end
    end
    -- bottom dungeon/raid grid tabs (flattened tabs need a real gap)
    Skin.EJButtonTemplate(EncounterJournal.dungeonsTab)
    Skin.EJButtonTemplate(EncounterJournal.raidsTab)
    if EncounterJournal.dungeonsTab and EncounterJournal.raidsTab then
        EncounterJournal.raidsTab:ClearAllPoints()
        EncounterJournal.raidsTab:SetPoint("LEFT", EncounterJournal.dungeonsTab, "RIGHT", 5, 0)
    end

    -- encounter pane
    local encounter = EncounterJournal.encounter
    if encounter then
        local instance = encounter.instance
        if instance then
            -- loreBG (instance painting) is content — kept
            if instance.titleBG then
                instance.titleBG:SetAlpha(0)
            end
            SafeScrollBar(instance.LoreScrollBar)
            if instance.LoreScrollingFont and instance.LoreScrollingFont.SetTextColor then
                instance.LoreScrollingFont:SetTextColor(Color.grayLight)
            end
        end

        local info = encounter.info
        if info then
            info:DisableDrawLayer("BACKGROUND")
            if info.leftShadow then info.leftShadow:SetAlpha(0) end
            if info.rightShadow then info.rightShadow:SetAlpha(0) end
            if info.encounterTitle then
                info.encounterTitle:SetTextColor(Color.white:GetRGB())
            end
            if info.instanceTitle then
                info.instanceTitle:SetTextColor(Color.white:GetRGB())
            end
            -- instanceButton.icon is a SHEET slice — CropIcon would show
            -- the wrong region (wood plank); the ornate ring is BOTH the
            -- normal and the hover texture
            if info.instanceButton then
                if info.instanceButton.ClearNormalTexture then
                    info.instanceButton:ClearNormalTexture()
                end
                if info.instanceButton.ClearHighlightTexture then
                    info.instanceButton:ClearHighlightTexture()
                end
            end

            Skin.EncounterTabTemplate(info.overviewTab)
            Skin.EncounterTabTemplate(info.lootTab)
            Skin.EncounterTabTemplate(info.bossTab)
            Skin.EncounterTabTemplate(info.modelTab)

            SafeScrollBox(info.BossesScrollBox)
            SafeScrollBar(info.BossesScrollBar)
            if info.BossesScrollBox and info.BossesScrollBox.ForEachFrame then
                Hook.EJBossesScrollBoxScrollUpdate(info.BossesScrollBox)
                if info.BossesScrollBox.Update then
                    _G.hooksecurefunc(info.BossesScrollBox, "Update", Hook.EJBossesScrollBoxScrollUpdate)
                end
            end

            Skin.EJButtonTemplate(info.difficulty)
            Skin.EJButtonTemplate(info.reset)

            if info.detailsScroll then
                if info.detailsScroll.child and info.detailsScroll.child.description then
                    info.detailsScroll.child.description:SetTextColor(Color.grayLight:GetRGB())
                end
                SafeScrollBar(info.detailsScroll.ScrollBar)
            end
            if info.overviewScroll then
                local child = info.overviewScroll.child
                if child then
                    if child.loreDescription then
                        child.loreDescription:SetTextColor(Color.grayLight:GetRGB())
                    end
                    if child.header then
                        child.header:SetAlpha(0)
                    end
                    if child.overviewDescription and child.overviewDescription.Text then
                        child.overviewDescription.Text:SetTextColor("p", Color.grayLight:GetRGB())
                    end
                end
                SafeScrollBar(info.overviewScroll.ScrollBar)
            end

            local loot = info.LootContainer
            if loot then
                Skin.EJButtonTemplate(loot.filter)
                Skin.EJButtonTemplate(loot.slotFilter)
                Skin.EJButtonTemplate(loot.classClearFilter)
                SafeScrollBox(loot.ScrollBox)
                SafeScrollBar(loot.ScrollBar)
                if loot.ScrollBox and loot.ScrollBox.ForEachFrame then
                    Hook.EJLootScrollUpdate(loot.ScrollBox)
                    if loot.ScrollBox.Update then
                        _G.hooksecurefunc(loot.ScrollBox, "Update", Hook.EJLootScrollUpdate)
                    end
                end
            end

            if info.model and info.model.dungeonBG then
                info.model.dungeonBG:SetAlpha(0)
            end
        end
    end

    -- item tooltip
    local Tooltip = _G.EncounterJournalTooltip
    if Tooltip then
        Base.SetBackdrop(Tooltip, Color.frame, Color.frame.a)
        for _, key in ipairs({"Item1", "Item2"}) do
            local item = Tooltip[key]
            if item and item.icon then
                Base.CropIcon(item.icon)
            end
        end
    end
end
