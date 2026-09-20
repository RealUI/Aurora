local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals select next

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util


do --[[ AddOns\Blizzard_InspectUI.lua ]]
    do --[[ InspectPaperDollFrame.lua ]]
        function Hook.InspectPaperDollFrame_OnShow()
            -- Inspected unit's class can be secret in combat (WoW 12); a secret
            -- string throws on concat. Skip the class background when withheld.
            local _, classToken = _G.UnitClass(_G.InspectFrame.unit)
            if not classToken or _G.issecretvalue(classToken) then return end
            _G.InspectPaperDollFrame._classBG:SetAtlas("dressingroom-background-"..classToken)
        end
        function Hook.InspectPaperDollItemSlotButton_Update(button)
            local unit = _G.InspectFrame.unit
            local quality = _G.GetInventoryItemQuality(unit, button:GetID())
            Hook.SetItemButtonQuality(button, quality, _G.GetInventoryItemID(unit, button:GetID()))
        end
    end
    do --[[ InspectPVPFrame.lua ]]
        Hook.InspectPvpTalentSlotMixin = {}
        function Hook.InspectPvpTalentSlotMixin:Update()
            if not self._auroraBG then return end

            local selectedTalentID = _G.C_SpecializationInfo.GetInspectSelectedPvpTalent(_G.INSPECTED_UNIT, self.slotIndex)
            if selectedTalentID then
                local _, _, texture = _G.GetPvpTalentInfoByID(selectedTalentID)
                self.Texture:SetTexture(texture)
                self._auroraBG:SetColorTexture(Color.black:GetRGB())
                self.Texture:SetDesaturated(false)
            else
                self.Texture:Show()
                self._auroraBG:SetColorTexture(Color.gray:GetRGB())
                self.Texture:SetDesaturated(true)
            end
        end
    end
    do --[[ InspectHonorFrame.lua ]]
        function Hook.InspectHonorFrame_Update()
            local xOffset = _G.InspectHonorFrameCurrentPVPRank:GetWidth()/2
            _G.InspectHonorFrameCurrentPVPTitle:SetPoint("TOP", _G.InspectFrame:GetBackdropTexture("bg"), -xOffset, -30)
        end
    end
    -- do --[[ InspectTalentFrame.lua ]]
    --     function Hook.InspectTalentFrameSpec_OnShow(self)
    --         local spec
    --         if _G.INSPECTED_UNIT ~= nil then
    --             spec = _G.GetInspectSpecialization(_G.INSPECTED_UNIT)
    --         end
    --         if spec ~= nil and spec > 0 then
    --             local role1 = _G.GetSpecializationRoleByID(spec)
    --             if role1 ~= nil then
    --                 local _, _, _, icon = _G.GetSpecializationInfoByID(spec)
    --                 self.specIcon:SetTexture(icon)
    --                 Base.SetTexture(self.roleIcon, "icon"..role1)
    --             end
    --         end
    --     end
    -- end
end

do --[[ AddOns\Blizzard_InspectUI.xml ]]
    do --[[ InspectPaperDollFrame.xml ]]
        function Skin.InspectPaperDollItemSlotButtonTemplate(ItemButton)
            Skin.FrameTypeItemButton(ItemButton)
            ItemButton:ClearNormalTexture()

            -- Camelot draws the slot border as a parentKey="BorderFrame" child
            -- holding a UI-Character-Info-GearSlot texture, exactly as its
            -- CharacterFrame slots do. Retail has no BorderFrame and no such
            -- atlas, so both guards are inert there. Kept in step with
            -- Skin\shared\PaperDollFrame.lua -- the same two idioms.
            if ItemButton.BorderFrame then
                ItemButton.BorderFrame:Hide()
            end

            for _, region in next, {ItemButton:GetRegions()} do
                if region:IsObjectType("Texture") then
                    local atlas = region:GetAtlas()
                    if atlas and atlas:find("UI%-Character%-Info%-GearSlot") then
                        region:Hide()
                    end
                end
            end
        end
        function Skin.InspectPaperDollItemSlotButtonLeftTemplate(ItemButton)
            Skin.InspectPaperDollItemSlotButtonTemplate(ItemButton)

            -- $parentFrame is the Char-LeftSlot/RightSlot/BottomSlot art from
            -- Mainline\InspectPaperDollFrame.xml, which Camelot excludes.
            local slotFrame = _G[ItemButton:GetName().."Frame"]
            if slotFrame then
                slotFrame:Hide()
            end
        end
        Skin.InspectPaperDollItemSlotButtonRightTemplate = Skin.InspectPaperDollItemSlotButtonLeftTemplate
        Skin.InspectPaperDollItemSlotButtonBottomTemplate = Skin.InspectPaperDollItemSlotButtonLeftTemplate

        -- InspectFrameModeSideTabTemplate adds a fillToInterior KeyValue and an
        -- OnLoad on top of LargeSideTabButtonTemplate -- the same shape as
        -- CharacterFrameModeSideTabTemplate, so the shared side-tab skin covers
        -- it. Camelot only; retail's InspectFrame has no mode tabs.
        function Skin.InspectFrameModeSideTabTemplate(Frame)
            Skin.LargeSideTabButtonTemplate(Frame)
        end
    end
    do --[[ InspectPVPFrame.xml ]]
        function Skin.InspectPvpTalentSlotTemplate(Button)
            Skin.PvpTalentSlotTemplate(Button)
            Util.Mixin(Button, Hook.InspectPvpTalentSlotMixin)
        end
    end
    do --[[ InspectTalentFrame.xml ]]
        function Skin.InspectTalentButtonTemplate(Button)
            Button._auroraIconBG = Base.CropIcon(Button.icon, Button)
            Button.Slot:Hide()
            Button.border:SetTexture("")
        end
        function Skin.InspectTalentRowTemplate(Frame)
            Skin.InspectTalentButtonTemplate(Frame.talent1)
            Skin.InspectTalentButtonTemplate(Frame.talent2)
            Skin.InspectTalentButtonTemplate(Frame.talent3)
        end
    end
end

function private.AddOns.Blizzard_InspectUI()
    local InspectFrame = _G.InspectFrame
    ----====####################====----
    --       Blizzard_InspectUI       --
    ----====####################====----
    Skin.ButtonFrameTemplate(InspectFrame)
    -- WoW Forever (Camelot Blizzard_InspectUI.xml) has no InspectFrameTab3, so
    -- the tab list is built from what exists rather than assumed.
    local tabs = {}
    for i = 1, 3 do
        local tab = _G["InspectFrameTab" .. i]
        if tab then
            Skin.PanelTabButtonTemplate(tab)
            tabs[#tabs + 1] = tab
        end
    end
    Util.PositionRelative("TOPLEFT", InspectFrame, "BOTTOMLEFT", 20, -1, 1, "Right", tabs)

    -- Camelot moves navigation to side tabs, as it does on the character panel:
    -- InspectUITabs (InspectFrame.ModeTabs) holding InspectFrameModeTab1-2,
    -- Character and Guild. The two PanelTabButtons above still exist but are
    -- declared hidden. Built from what exists rather than a fixed count.
    for i = 1, 2 do
        local modeTab = _G["InspectFrameModeTab" .. i]
        if modeTab then
            Skin.InspectFrameModeSideTabTemplate(modeTab)
        end
    end

    ----====#####################====----
    --      InspectPaperDollFrame      --
    ----====#####################====----
    -- Camelot moved this to InspectPaperDollFrameMixin:OnShow and deleted the
    -- global, so hooksecurefunc by name throws "is not a function" -- which
    -- aborted the whole skin before the slot loop, leaving the panel skinned
    -- and everything inside it stock. Blizzard left three call sites behind
    -- (Camelot\Blizzard_InspectUI.lua:153 among them), so the global's absence
    -- is their bug, not a rename Aurora should follow; the HookScript below
    -- covers Forever on its own.
    if type(_G.InspectPaperDollFrame_OnShow) == "function" then
        _G.hooksecurefunc("InspectPaperDollFrame_OnShow", Hook.InspectPaperDollFrame_OnShow)
    end

    local InspectPaperDollFrame = _G.InspectPaperDollFrame
    InspectPaperDollFrame:HookScript("OnShow", Hook.InspectPaperDollFrame_OnShow)

    Skin.UIPanelButtonTemplate(InspectPaperDollFrame.ViewButton)

    local InspectPaperDollItemsFrame = _G.InspectPaperDollItemsFrame
    -- Camelot reparents InspectTalents from InspectPaperDollItemsFrame up to
    -- InspectPaperDollFrame. Same button, same template, different owner.
    Skin.UIPanelButtonTemplate(InspectPaperDollItemsFrame.InspectTalents
        or InspectPaperDollFrame.InspectTalents)

    local bg = InspectFrame.NineSlice:GetBackdropTexture("bg")
    local classBG = InspectPaperDollFrame:CreateTexture(nil, "BORDER")
    classBG:SetAtlas("dressingroom-background-"..private.charClass.token)
    classBG:SetPoint("TOPLEFT", bg)
    classBG:SetPoint("BOTTOM", bg)
    classBG:SetPoint("RIGHT", InspectFrame.Inset, 4, 0)
    InspectPaperDollFrame._classBG = classBG

    local settings = private.CLASS_BACKGROUND_SETTINGS[private.charClass.token] or private.CLASS_BACKGROUND_SETTINGS["DEFAULT"];
    classBG:SetDesaturation(settings.desaturation)
    classBG:SetAlpha(settings.alpha)

    _G.InspectModelFrame:DisableDrawLayer("BACKGROUND")
    _G.InspectModelFrame.BackgroundOverlay:Hide()
    _G.InspectModelFrame:DisableDrawLayer("OVERLAY")

    local EquipmentSlots = {
        "InspectHeadSlot", "InspectNeckSlot", "InspectShoulderSlot", "InspectBackSlot", "InspectChestSlot", "InspectShirtSlot", "InspectTabardSlot", "InspectWristSlot",
        "InspectHandsSlot", "InspectWaistSlot", "InspectLegsSlot", "InspectFeetSlot", "InspectFinger0Slot", "InspectFinger1Slot", "InspectTrinket0Slot", "InspectTrinket1Slot"
    }
    -- Camelot restores the ranged slot, as it does on the character panel.
    local WeaponSlots = {
        "InspectMainHandSlot", "InspectSecondaryHandSlot", "InspectRangedSlot"
    }

    local slotsPerSide, prevSlot = 8
    for i = 1, #EquipmentSlots do
        local button = _G[EquipmentSlots[i]]
        local isLeftSide = button.IsLeftSide or i <= slotsPerSide

        -- The retail layout below rebuilds both columns against
        -- InspectFrame.Inset. Camelot lays the panel out itself and gets the
        -- same treatment the character sheet does: skin in place, re-anchor
        -- nothing. See Skin\shared\PaperDollFrame.lua.
        if not private.isForever then
            button:ClearAllPoints()
            if i % slotsPerSide == 1 then
                if isLeftSide then
                    button:SetPoint("TOPLEFT", InspectFrame.Inset, 4, 22)
                else
                    button:SetPoint("TOPRIGHT", InspectFrame.Inset, -4, 22)
                end
            else
                button:SetPoint("TOPLEFT", prevSlot, "BOTTOMLEFT", 0, -6)
            end
        end

        if isLeftSide then
            Skin.InspectPaperDollItemSlotButtonLeftTemplate(button)
        elseif isLeftSide == false then
            Skin.InspectPaperDollItemSlotButtonRightTemplate(button)
        end

        prevSlot = button
    end

    for i = 1, #WeaponSlots do
        local button = _G[WeaponSlots[i]]
        if button then
            if i == 1 and not private.isForever then
                -- main hand
                button:SetPoint("BOTTOMLEFT", 130, 8)
            end

            -- Retail's last region is the Char-Slot-Bottom-Left backing art,
            -- which Camelot's template does not carry; picking by index there
            -- would hide whichever region happens to be last instead. The
            -- Camelot border is handled by atlas in the slot skin.
            if not private.isForever then
                _G.select(button:GetNumRegions(), button:GetRegions()):Hide()
            end

            Skin.InspectPaperDollItemSlotButtonBottomTemplate(button)
        end
    end

    ----====#####################====----
    --         InspectPVPFrame         --
    ----====#####################====----
    local InspectPVPFrame = _G.InspectPVPFrame
    InspectPVPFrame.BG:SetTexCoord(0.00390625, 0.3115234375, 0.34375, 0.87890625)
    InspectPVPFrame.BG:SetDesaturated(true)
    InspectPVPFrame.BG:SetBlendMode("ADD")
    InspectPVPFrame.BG:SetAllPoints(bg)

    InspectPVPFrame.RatedBG:SetPoint("TOPLEFT", InspectPVPFrame, 8, -124)
    InspectPVPFrame.Slots[1]:SetPoint("TOPRIGHT", InspectPVPFrame, -46, -124)
    for i = 1, #InspectPVPFrame.Slots do
        Skin.InspectPvpTalentSlotTemplate(InspectPVPFrame.Slots[i])
    end

    ----====####################====----
    --       InspectTalentFrame       --
    ----====####################====----
    -- _G.hooksecurefunc("InspectTalentFrameSpec_OnShow", Hook.InspectTalentFrameSpec_OnShow)

    -- local InspectTalentFrame = _G.InspectTalentFrame
    -- local talentBG, talentTile = InspectTalentFrame:GetRegions()
    -- talentBG:Hide()
    -- talentTile:Hide()

    -- local InspectSpec = InspectTalentFrame.InspectSpec
    -- InspectSpec:HookScript("OnShow", Hook.InspectTalentFrameSpec_OnShow)
    -- InspectSpec.ring:Hide()
    -- Base.CropIcon(InspectSpec.specIcon, InspectSpec)

    -- local InspectTalents = InspectTalentFrame.InspectTalents
    -- Skin.InspectTalentRowTemplate(InspectTalents.tier1)
    -- Skin.InspectTalentRowTemplate(InspectTalents.tier2)
    -- Skin.InspectTalentRowTemplate(InspectTalents.tier3)
    -- Skin.InspectTalentRowTemplate(InspectTalents.tier4)
    -- Skin.InspectTalentRowTemplate(InspectTalents.tier5)
    -- Skin.InspectTalentRowTemplate(InspectTalents.tier6)
    -- Skin.InspectTalentRowTemplate(InspectTalents.tier7)

    ----====#####################====----
    --        InspectGuildFrame        --
    ----====#####################====----
    --local InspectGuildFrame = _G.InspectGuildFrame
    _G.InspectGuildFrameBG:Hide()
end
