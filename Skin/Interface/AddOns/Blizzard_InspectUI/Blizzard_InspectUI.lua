local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals select

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util


do --[[ AddOns\Blizzard_InspectUI.lua ]]
    do --[[ InspectPaperDollFrame.lua ]]
        function Hook.InspectPaperDollFrame_OnShow()
            local _, classToken = _G.UnitClass(_G.InspectFrame.unit)
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
        end
        function Skin.InspectPaperDollItemSlotButtonLeftTemplate(ItemButton)
            Skin.InspectPaperDollItemSlotButtonTemplate(ItemButton)
            _G[ItemButton:GetName().."Frame"]:Hide()
        end
        Skin.InspectPaperDollItemSlotButtonRightTemplate = Skin.InspectPaperDollItemSlotButtonLeftTemplate
        Skin.InspectPaperDollItemSlotButtonBottomTemplate = Skin.InspectPaperDollItemSlotButtonLeftTemplate
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
    if not InspectFrame then return end
    ----====####################====----
    --       Blizzard_InspectUI       --
    ----====####################====----
    Skin.ButtonFrameTemplate(InspectFrame)
    Skin.PanelTabButtonTemplate(_G.InspectFrameTab1)
    Skin.PanelTabButtonTemplate(_G.InspectFrameTab2)
    if _G.InspectFrameTab3 then
        Skin.PanelTabButtonTemplate(_G.InspectFrameTab3)
    end
    Util.PositionRelative("TOPLEFT", InspectFrame, "BOTTOMLEFT", 20, -1, 1, "Right", {
        _G.InspectFrameTab1,
        _G.InspectFrameTab2,
        _G.InspectFrameTab3,
    })

    ----====#####################====----
    --      InspectPaperDollFrame      --
    ----====#####################====----
    if _G.InspectPaperDollFrame_OnShow then
        _G.hooksecurefunc("InspectPaperDollFrame_OnShow", Hook.InspectPaperDollFrame_OnShow)
    end

    local InspectPaperDollFrame = _G.InspectPaperDollFrame
    if InspectPaperDollFrame then
        InspectPaperDollFrame:HookScript("OnShow", Hook.InspectPaperDollFrame_OnShow)

        -- ViewButton is Mainline-only (Dressing Room integration)
        if InspectPaperDollFrame.ViewButton then
            Skin.UIPanelButtonTemplate(InspectPaperDollFrame.ViewButton)
        end
    end

    local InspectPaperDollItemsFrame = _G.InspectPaperDollItemsFrame
    if InspectPaperDollItemsFrame and InspectPaperDollItemsFrame.InspectTalents then
        Skin.UIPanelButtonTemplate(InspectPaperDollItemsFrame.InspectTalents)
    end

    -- Class background atlas — modern pattern (may not exist in TBC)
    if InspectFrame.NineSlice and InspectFrame.NineSlice.GetBackdropTexture then
        local bg = InspectFrame.NineSlice:GetBackdropTexture("bg")
        if bg and InspectPaperDollFrame then
            local classBG = InspectPaperDollFrame:CreateTexture(nil, "BORDER")
            classBG:SetAtlas("dressingroom-background-"..private.charClass.token)
            classBG:SetPoint("TOPLEFT", bg)
            classBG:SetPoint("BOTTOM", bg)
            if InspectFrame.Inset then
                classBG:SetPoint("RIGHT", InspectFrame.Inset, 4, 0)
            end
            InspectPaperDollFrame._classBG = classBG

            local settings = private.CLASS_BACKGROUND_SETTINGS[private.charClass.token] or private.CLASS_BACKGROUND_SETTINGS["DEFAULT"];
            classBG:SetDesaturation(settings.desaturation)
            classBG:SetAlpha(settings.alpha)
        end
    end

    if _G.InspectModelFrame then
        _G.InspectModelFrame:DisableDrawLayer("BACKGROUND")
        if _G.InspectModelFrame.BackgroundOverlay then
            _G.InspectModelFrame.BackgroundOverlay:Hide()
        end
        _G.InspectModelFrame:DisableDrawLayer("OVERLAY")
    end

    local EquipmentSlots = {
        "InspectHeadSlot", "InspectNeckSlot", "InspectShoulderSlot", "InspectBackSlot", "InspectChestSlot", "InspectShirtSlot", "InspectTabardSlot", "InspectWristSlot",
        "InspectHandsSlot", "InspectWaistSlot", "InspectLegsSlot", "InspectFeetSlot", "InspectFinger0Slot", "InspectFinger1Slot", "InspectTrinket0Slot", "InspectTrinket1Slot"
    }
    local WeaponSlots = {
        "InspectMainHandSlot", "InspectSecondaryHandSlot"
    }

    local slotsPerSide, prevSlot = 8
    for i = 1, #EquipmentSlots do
        local button = _G[EquipmentSlots[i]]
        if button then
            button:ClearAllPoints()
            local isLeftSide = button.IsLeftSide or i <= slotsPerSide

            if i % slotsPerSide == 1 then
                if isLeftSide then
                    if InspectFrame.Inset then
                        button:SetPoint("TOPLEFT", InspectFrame.Inset, 4, 22)
                    end
                else
                    if InspectFrame.Inset then
                        button:SetPoint("TOPRIGHT", InspectFrame.Inset, -4, 22)
                    end
                end
            else
                if prevSlot then
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
    end

    for i = 1, #WeaponSlots do
        local button = _G[WeaponSlots[i]]
        if button then
            if i == 1 then
                -- main hand
                button:SetPoint("BOTTOMLEFT", 130, 8)
            end

            _G.select(button:GetNumRegions(), button:GetRegions()):Hide()
            Skin.InspectPaperDollItemSlotButtonBottomTemplate(button)
        end
    end

    ----====#####################====----
    --         InspectPVPFrame         --
    ----====#####################====----
    -- InspectPVPFrame with Slots is Mainline-only (PVP talent inspect)
    local InspectPVPFrame = _G.InspectPVPFrame
    if InspectPVPFrame then
        if InspectPVPFrame.BG then
            local bg = InspectFrame.NineSlice and InspectFrame.NineSlice:GetBackdropTexture("bg")
            if bg then
                InspectPVPFrame.BG:SetTexCoord(0.00390625, 0.3115234375, 0.34375, 0.87890625)
                InspectPVPFrame.BG:SetDesaturated(true)
                InspectPVPFrame.BG:SetBlendMode("ADD")
                InspectPVPFrame.BG:SetAllPoints(bg)
            end
        end

        if InspectPVPFrame.RatedBG then
            InspectPVPFrame.RatedBG:SetPoint("TOPLEFT", InspectPVPFrame, 8, -124)
        end
        if InspectPVPFrame.Slots then
            if InspectPVPFrame.Slots[1] then
                InspectPVPFrame.Slots[1]:SetPoint("TOPRIGHT", InspectPVPFrame, -46, -124)
            end
            for i = 1, #InspectPVPFrame.Slots do
                Skin.InspectPvpTalentSlotTemplate(InspectPVPFrame.Slots[i])
            end
        end
    end

    ----====####################====----
    --       InspectTalentFrame       --
    ----====####################====----

    ----====#####################====----
    --        InspectGuildFrame        --
    ----====#####################====----
    if _G.InspectGuildFrameBG then
        _G.InspectGuildFrameBG:Hide()
    end
end
