local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals select

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Util = Aurora.Util

do --[[ FrameXML\LootFrame.lua ]]
    function Hook.LootFrame_UpdateButton(index)
        local LootFrame = _G.LootFrame
        if not LootFrame then return end

        local numLootItems = LootFrame.numLootItems
        --Logic to determine how many items to show per page
        local numLootToShow = _G.LOOTFRAME_NUMBUTTONS
        if LootFrame.AutoLootTable then
            numLootItems = #LootFrame.AutoLootTable
        end
        if numLootItems > _G.LOOTFRAME_NUMBUTTONS then
            numLootToShow = numLootToShow - 1 -- make space for the page buttons
        end

        local button = _G["LootButton"..index]
        if not button then return end

        local slot = (numLootToShow * (LootFrame.page - 1)) + index

        if slot <= numLootItems then
            local _, quality, isQuestItem, isActive
            if LootFrame.AutoLootTable then
                local entry = LootFrame.AutoLootTable[slot]
                if not entry.hide then
                    isQuestItem = entry.isQuestItem
                    quality = entry.quality
                end
            else
                _, _, _, _, quality, _, isQuestItem, _, isActive = _G.GetLootSlotInfo(slot)
            end

            local questTexture = button._questTexture
            if not questTexture then return end

            if isQuestItem then
                button._auroraIconBorder:SetBackdropBorderColor(1, 1, 0)
                questTexture:Show()

                if isActive then
                    questTexture:SetTexture(_G.TEXTURE_ITEM_QUEST_BANG)
                else
                    questTexture:SetTexture(_G.TEXTURE_ITEM_QUEST_BORDER)
                end
            else
                Hook.SetItemButtonQuality(button, quality)
                questTexture:Hide()
            end
        end
    end
end

do --[[ FrameXML\LootFrame.xml ]]
    function Skin.LootButtonTemplate(Frame)
        Skin.FrameTypeItemButton(Frame)

        local name = Frame:GetName()
        if name then
            local nameFrame = _G[name.."NameFrame"]
            if nameFrame then
                nameFrame:Hide()
            end
        end

        Frame._questTexture = Frame:CreateTexture(nil, "ARTWORK")
        Frame._questTexture:SetTexture(_G.TEXTURE_ITEM_QUEST_BORDER)
        local questTexture = Frame._questTexture
        questTexture:SetAllPoints(Frame)
        Base.CropIcon(questTexture)

        local bg = Frame:GetBackdropTexture("bg")
        if bg then
            local nameBG = _G.CreateFrame("Frame", nil, Frame)
            nameBG:SetFrameLevel(Frame:GetFrameLevel())
            nameBG:SetPoint("TOPLEFT", bg, "TOPRIGHT", 1, 0)
            nameBG:SetPoint("RIGHT", 115, 0)
            nameBG:SetPoint("BOTTOM", bg)
            Base.SetBackdrop(nameBG, Aurora.Color.frame)
            Frame._auroraNameBG = nameBG
        end

        if Frame.SetNormalTexture then
            Frame:SetNormalTexture("")
        end
        if Frame.SetPushedTexture then
            Frame:SetPushedTexture("")
        end
    end

    function Skin.LootNavButton(Button)
        Skin.FrameTypeButton(Button)
        Button:SetBackdropOption("offsets", {
            left = 5,
            right = 5,
            top = 5,
            bottom = 5,
        })
    end
end

function private.FrameXML.LootFrame()
    _G.hooksecurefunc("LootFrame_UpdateButton", Hook.LootFrame_UpdateButton)

    ---------------
    -- LootFrame --
    ---------------
    local LootFrame = _G.LootFrame
    if not LootFrame then return end

    Skin.ButtonFrameTemplate(LootFrame)

    if _G.LootFramePortraitOverlay then
        _G.LootFramePortraitOverlay:Hide()
    end

    -- "Items" text region (region index 19 in Classic LootFrame)
    local titleText = LootFrame.TitleText
    if titleText then
        local region = select(19, LootFrame:GetRegions())
        if region and region.SetAllPoints then
            region:SetAllPoints(titleText)
        end
    end

    for index = 1, 4 do
        local button = _G["LootButton"..index]
        if button then
            Skin.LootButtonTemplate(button)
        end
    end

    Util.PositionRelative("TOPLEFT", LootFrame, "TOPLEFT", 9, -(private.FRAME_TITLE_HEIGHT + 5), 17, "Down", {
        _G.LootButton1,
        _G.LootButton2,
        _G.LootButton3,
        _G.LootButton4,
    })

    do -- LootFrameUpButton
        local upButton = _G.LootFrameUpButton
        if upButton then
            Skin.LootNavButton(upButton)
            upButton:SetPoint("BOTTOMLEFT", 10, 10)

            local bg = upButton:GetBackdropTexture("bg")
            if bg then
                local arrow = upButton:CreateTexture(nil, "ARTWORK")
                arrow:SetPoint("TOPLEFT", bg, 5, -8)
                arrow:SetPoint("BOTTOMRIGHT", bg, -5, 8)
                Base.SetTexture(arrow, "arrowUp")
            end

            local prev = _G.LootFramePrev
            if prev then
                prev:ClearAllPoints()
                prev:SetPoint("LEFT", upButton, "RIGHT", 4, 0)
            end
        end
    end

    do -- LootFrameDownButton
        local downButton = _G.LootFrameDownButton
        if downButton then
            Skin.LootNavButton(downButton)
            downButton:ClearAllPoints()
            downButton:SetPoint("BOTTOMRIGHT", -10, 10)

            local bg = downButton:GetBackdropTexture("bg")
            if bg then
                local arrow = downButton:CreateTexture(nil, "ARTWORK")
                arrow:SetPoint("TOPLEFT", bg, 5, -8)
                arrow:SetPoint("BOTTOMRIGHT", bg, -5, 8)
                Base.SetTexture(arrow, "arrowDown")
            end

            local next = _G.LootFrameNext
            if next then
                next:ClearAllPoints()
                next:SetPoint("RIGHT", downButton, "LEFT", -4, 0)
            end
        end
    end
end
