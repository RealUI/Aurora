local _, private = ...
if private.shouldSkip() then return end

local Aurora = private.Aurora
local Base, Hook, Skin = Aurora.Base, Aurora.Hook, Aurora.Skin
local Color = Aurora.Color

do --[[ AddOns\Blizzard_RuneforgeUI.lua ]]
    -- Skin a power list element (RuneforgePowerTemplate button).
    local function SkinPowerButton(button)
        if not button or private.IsSkinned(button) then return end
        private.SetSkinned(button, true)

        if button.Icon then
            Base.CropIcon(button.Icon, button)
        end
        if button.Border then
            button.Border:SetAlpha(0)
        end
    end

    -- Hook the paged power list LayoutList to skin dynamically created power entries.
    function Hook.RuneforgePowerListLayoutList(powerList)
        if powerList.elements then
            for _, element in next, powerList.elements do
                SkinPowerButton(element)
            end
        end
    end
end

function private.AddOns.Blizzard_RuneforgeUI()
    local RuneforgeFrame = _G.RuneforgeFrame
    if not RuneforgeFrame then return end

    ------------------------------------
    -- Main frame
    ------------------------------------
    Skin.FrameTypeFrame(RuneforgeFrame)

    -- Strip the decorative background smoke atlas
    if RuneforgeFrame.Background then
        RuneforgeFrame.Background:SetAlpha(0)
    end

    -- Close button
    if RuneforgeFrame.CloseButton then
        if RuneforgeFrame.CloseButton.CustomBorder then
            RuneforgeFrame.CloseButton.CustomBorder:SetAlpha(0)
        end
    end

    ------------------------------------
    -- Crafting frame
    ------------------------------------
    local CraftingFrame = RuneforgeFrame.CraftingFrame
    if CraftingFrame then
        -- Strip the decorative runecarving frame atlas textures
        local AnimWrapper = CraftingFrame.AnimWrapper
        if AnimWrapper then
            if AnimWrapper.AnimationBacking then
                AnimWrapper.AnimationBacking:SetAlpha(0)
            end
            if AnimWrapper.Background then
                AnimWrapper.Background:SetAlpha(0)
            end
            if AnimWrapper.RuneLitBackground then
                AnimWrapper.RuneLitBackground:SetAlpha(0)
            end
        end

        -- Base item slot icon
        local BaseItemSlot = CraftingFrame.BaseItemSlot
        if BaseItemSlot then
            if BaseItemSlot.icon then
                Base.CropIcon(BaseItemSlot.icon, BaseItemSlot)
            end
            if BaseItemSlot.SelectingTexture then
                BaseItemSlot.SelectingTexture:SetAlpha(0)
            end
            if BaseItemSlot.SelectedTexture then
                BaseItemSlot.SelectedTexture:SetAlpha(0)
            end
        end

        -- Upgrade item slot icon
        local UpgradeItemSlot = CraftingFrame.UpgradeItemSlot
        if UpgradeItemSlot then
            if UpgradeItemSlot.icon then
                Base.CropIcon(UpgradeItemSlot.icon, UpgradeItemSlot)
            end
            if UpgradeItemSlot.Background then
                UpgradeItemSlot.Background:SetAlpha(0)
            end
        end

        -- Power slot icon
        local PowerSlot = CraftingFrame.PowerSlot
        if PowerSlot then
            if PowerSlot.Icon then
                Base.CropIcon(PowerSlot.Icon, PowerSlot)
            end
        end

        -- Modifier frame — skin both modifier slots
        local ModifierFrame = CraftingFrame.ModifierFrame
        if ModifierFrame then
            local slots = { ModifierFrame.FirstSlot, ModifierFrame.SecondSlot }
            for _, slot in next, slots do
                if slot then
                    if slot.icon then
                        Base.CropIcon(slot.icon, slot)
                    end
                end
            end

            -- Strip the modifier selector background atlas
            local Selector = ModifierFrame.Selector
            if Selector and Selector.Background then
                Selector.Background:SetAlpha(0)
            end
        end

        -- Power frame (popup power list panel)
        local PowerFrame = CraftingFrame.PowerFrame
        if PowerFrame then
            -- Strip the power menu background atlas
            if PowerFrame.Background then
                PowerFrame.Background:SetAlpha(0)
            end
            Base.SetBackdrop(PowerFrame, Color.frame)

            -- Hook the paged power list to skin dynamically created entries
            local PowerList = PowerFrame.PowerList
            if PowerList then
                _G.hooksecurefunc(PowerList, "LayoutList", Hook.RuneforgePowerListLayoutList)
                -- Skin any elements that already exist
                Hook.RuneforgePowerListLayoutList(PowerList)
            end
        end
    end

    ------------------------------------
    -- Create frame (craft button area)
    ------------------------------------
    local CreateFrame = RuneforgeFrame.CreateFrame
    if CreateFrame then
        if CreateFrame.CraftItemButton then
            Skin.FrameTypeButton(CreateFrame.CraftItemButton)
        end
    end
end
