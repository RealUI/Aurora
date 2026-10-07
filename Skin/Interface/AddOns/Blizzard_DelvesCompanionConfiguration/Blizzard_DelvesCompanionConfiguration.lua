local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base, Hook, Skin = Aurora.Base, Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

-- Shared helper: skin a single CompanionConfigListButton (curio/role option)
local function SkinListButton(button)
    if not button or private.IsSkinned(button) then return end

    if button.Icon then
        Base.CropIcon(button.Icon)
    end

    -- Strip the curio icon border overlay
    if button.Border then
        button.Border:SetAlpha(0)
    end

    private.SetSkinned(button, true)
end

-- Shared helper: skin a CompanionConfigSlot's OptionsList dropdown panel
local function SkinOptionsList(optionsList)
    if not optionsList or private.IsSkinned(optionsList) then return end

    -- Strip the Top/Middle/Bottom background atlas textures
    Base.StripBlizzardTextures(optionsList)

    -- Apply a flat backdrop to the options list
    Base.SetBackdrop(optionsList, Color.frame)

    -- Wrap the ScrollBox so dynamically created list buttons are skinned
    local scrollBox = optionsList.ScrollBox
    if scrollBox then
        _G.ScrollUtil.AddAcquiredFrameCallback(scrollBox, function(o, frame)
            SkinListButton(frame)
        end, optionsList)

        -- Skin any already-existing frames
        scrollBox:ForEachFrame(function(frame)
            SkinListButton(frame)
        end)
    end

    private.SetSkinned(optionsList, true)
end

-- Shared helper: skin a CompanionConfigSlot (role/trinket slot button)
local function SkinConfigSlot(slot)
    if not slot or private.IsSkinned(slot) then return end

    -- Strip the decorative shadow texture behind the slot
    if slot.Shadow then
        slot.Shadow:SetAlpha(0)
    end

    -- Skin the options list dropdown
    SkinOptionsList(slot.OptionsList)

    private.SetSkinned(slot, true)
end

do --[[ AddOns\Blizzard_DelvesCompanionConfiguration.lua ]]
    Hook.CompanionConfigSlotTemplateMixin = {}
    function Hook.CompanionConfigSlotTemplateMixin:OnLoad()
        -- Post-hook: skin the slot and its OptionsList after the
        -- ScrollBox view is initialised in the original OnLoad.
        SkinConfigSlot(self)
    end
end

--[[ AddOns\Blizzard_DelvesCompanionConfiguration.xml ]]
-- CompanionConfigSlotTemplate, CompanionConfigListTemplate,
-- CompanionConfigListButtonTemplate, and the main
-- DelvesCompanionConfigurationFrame are defined in XML.
-- Skinning is applied in the addon registration function below.

function private.AddOns.Blizzard_DelvesCompanionConfiguration()
    ------------------------------------------------
    -- Hook mixin prototypes via Util.Mixin
    ------------------------------------------------
    Util.Mixin(_G.CompanionConfigSlotTemplateMixin, Hook.CompanionConfigSlotTemplateMixin)

    ------------------------------------------------
    -- Skin the main configuration frame
    ------------------------------------------------
    local frame = _G.DelvesCompanionConfigurationFrame
    if not frame then return end

    -- NOTE: Do NOT SetScript the companion portrait's OnEnter. Aurora replaced
    -- it with a pcall wrapper to swallow a secret GetHeight() in
    -- GameTooltip_AddWidgetSet (GameTooltip.lua:607). The replacement made
    -- every portrait hover run Blizzard's OnEnter under Aurora's taint, so
    -- SetOwner, the widget set and the shared UI-widget pool it acquires from
    -- all ran tainted, and a tainted execution is exactly what receives the
    -- secret height (the GameTooltip_AddWidgetSet note in
    -- SharedTooltipTemplates.lua). The tooltip skin is taint-safe since B94,
    -- so the secure OnEnter should not see the secret. Removed 2026-10-06
    -- (taint audit, B170 follow-up; same class as QuestMapLogTitleButton_OnEnter).

    -- Strip the InsetFrameTemplate and DialogBorderTemplate decorative textures
    Base.StripBlizzardTextures(frame)

    -- Apply Aurora styling after stripping Blizzard textures so backdrop regions
    -- are not removed by StripBlizzardTextures.
    Skin.FrameTypeFrame(frame)

    -- Strip the companion background atlas
    if frame.Background then
        frame.Background:SetAlpha(0)
    end

    -- Skin the DialogBorder NineSlice instead of removing it.
    if frame.Border then
        Skin.DialogBorderTemplate(frame.Border)
    end

    ------------------------------------------------
    -- Close button
    ------------------------------------------------
    if frame.CloseButton then
        Skin.UIPanelCloseButton(frame.CloseButton)
    end

    ------------------------------------------------
    -- Abilities button (UIPanelButtonTemplate)
    ------------------------------------------------
    if frame.CompanionConfigShowAbilitiesButton then
        Skin.UIPanelButtonTemplate(frame.CompanionConfigShowAbilitiesButton)
    end

    ------------------------------------------------
    -- Skin the three config slots (if already loaded)
    ------------------------------------------------
    SkinConfigSlot(frame.CompanionCombatRoleSlot)
    SkinConfigSlot(frame.CompanionCombatTrinketSlot)
    SkinConfigSlot(frame.CompanionUtilityTrinketSlot)

    ------------------------------------------------
    -- Skin the Ability List frame (separate UIPanel)
    ------------------------------------------------
    local abilityList = _G.DelvesCompanionAbilityListFrame
    if abilityList then
        Base.StripBlizzardTextures(abilityList)
        Skin.FrameTypeFrame(abilityList)

        -- Strip the ability list background atlas
        if abilityList.CompanionAbilityListBackground then
            abilityList.CompanionAbilityListBackground:SetAlpha(0)
        end

        -- PortraitFrameTemplate parts: StripBlizzardTextures only reaches the
        -- frame's own regions and the NineSlice, so the portrait ring and the
        -- close button keep their Blizzard art unless handled here.
        if abilityList.PortraitContainer then
            abilityList.PortraitContainer:Hide()
        end
        if abilityList.TitleContainer then
            abilityList.TitleContainer:SetHeight(private.FRAME_TITLE_HEIGHT)
            abilityList.TitleContainer:SetPoint("TOPLEFT", 24, -1)
        end
        if abilityList.CloseButton then
            Skin.UIPanelCloseButton(abilityList.CloseButton)
        end

        -- Role dropdown (WowStyle1DropdownTemplate)
        if abilityList.DelvesCompanionRoleDropdown then
            Skin.DropdownButton(abilityList.DelvesCompanionRoleDropdown)
        end

        -- Skin paging control buttons. FrameTypeButton clears the normal/pushed/
        -- disabled textures, so the plain page arrows need the Nav skins that put
        -- Aurora's arrow back - otherwise both buttons render as empty boxes.
        local pagingControls = abilityList.DelvesCompanionAbilityListPagingControls
        if pagingControls then
            if pagingControls.NextPageButton then
                Skin.NavButtonNext(pagingControls.NextPageButton)
            end
            if pagingControls.PrevPageButton then
                Skin.NavButtonPrevious(pagingControls.PrevPageButton)
            end
        end

        -- Hook InstantiateTalentButton to crop ability icons as they are created
        _G.hooksecurefunc(_G.DelvesCompanionAbilityListFrameMixin, "InstantiateTalentButton", function(self, nodeID, nodeInfo)
            -- Skin any newly created ability buttons
            if self.buttons then
                for _, button in ipairs(self.buttons) do
                    if not private.IsSkinned(button) then
                        if button.Icon then
                            Base.CropIcon(button.Icon)
                        end
                        private.SetSkinned(button, true)
                    end
                end
            end
        end)
    end
end
