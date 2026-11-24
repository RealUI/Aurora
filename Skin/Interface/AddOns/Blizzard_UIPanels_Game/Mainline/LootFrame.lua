local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals select

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

do --[[ FrameXML\LootFrame.lua ]]
    function Hook.LootFrame_UpdateButton(index)
        local LootFrame = _G.LootFrame
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
        _G[name.."NameFrame"]:Hide()

        local questTexture
        if private.isRetail then
            questTexture = _G[name.."IconQuestTexture"]
        else
            Frame._questTexture = Frame:CreateTexture(nil, "ARTWORK")
            Frame._questTexture:SetTexture(_G.TEXTURE_ITEM_QUEST_BORDER)
            questTexture = Frame._questTexture
        end
        questTexture:SetAllPoints(Frame)
        Base.CropIcon(questTexture)

        --local bg = F.CreateBDFrame(nameFrame, .2)
        --bg:SetPoint("TOPLEFT", Button.icon, "TOPRIGHT", 3, 1)
        --bg:SetPoint("BOTTOMRIGHT", nameFrame, -5, 11)

        local bg = Frame:GetBackdropTexture("bg")
        local nameBG = _G.CreateFrame("Frame", nil, Frame)
        nameBG:SetFrameLevel(Frame:GetFrameLevel())
        nameBG:SetPoint("TOPLEFT", bg, "TOPRIGHT", 1, 0)
        nameBG:SetPoint("RIGHT", 115, 0)
        nameBG:SetPoint("BOTTOM", bg)
        Base.SetBackdrop(nameBG, Color.frame)
        Frame._auroraNameBG = nameBG

        if private.isVanilla then
            Frame:SetNormalTexture("")
            Frame:SetPushedTexture("")
        else
            Frame:ClearNormalTexture()
            Frame:ClearPushedTexture()
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

--[[ B261 Layer 2 (tier A, row A5; AT-D16 a), read from wow-ui-source
    (retail) and wow-ui-source-forever. LootFrameMixin:OnEvent runs Open on
    LOOT_OPENED (Blizzard_UIPanels_Game/Mainline/LootFrame.lua:92-97; Forever
    :127-133), which fills the scroll box (:181; Forever :252), and the
    scroll bar's Update enables or disables both steppers and shows and
    enables the thumb (Blizzard_SharedXML/Shared/Scroll/ScrollBar.lua:238-239,
    :255-256, the same lines on Forever). The same execution then calls
    ShowUIPanel (:198; Forever :270), the secure gate, and ApplySystemAnchor
    (:201; Forever :273) on an Edit Mode system frame. Looting in combat is
    the common case. So nothing of Aurora's may be on the close button, the
    steppers or the thumb, or run on their state.

    Skin.ScrollingFlatPanelTemplate is written out here for this frame, so
    the close button can take the Layer 2 skin and the scroll bar can stay
    Blizzard's. The shared template is not changed. ]]

-- Shape "panel" for ClosePanelButton, drawn by Skin.TaintSafePanelCloseButton
-- (Skin/skin.lua): UIPanelCloseButtonDefaultAnchors
-- (Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.xml:134-157; Forever
-- :134-157, the template at :153 with the Camelot mixin; the button is
-- ScrollingFlatPanelTemplate's, Mainline/ScrollingFlatPanel.xml:14 on Forever), its
-- state textures set in XML only and never re-set by Blizzard's Lua. Its
-- frameLevel is 510 (:134), so its panel at 509 sits far above the
-- frame's own backdrop. The box is the 17x17 the Layer 1 skin drew
-- (Skin.UIPanelCloseButton, offsets 3/4/3/4 of a 24x24 button), placed by
-- moving the panel instead of re-anchoring or resizing the button. On
-- Forever the template's OnLoad makes the button 28x28 at TOPRIGHT 0, 3
-- (Blizzard_SharedXML/Camelot/SharedUIPanelTemplates.lua:1-5), and the
-- function moves the box down by the same 3 for a button with that OnLoad.

function private.FrameXML.LootFrame()
    if private.isClassic then
        _G.hooksecurefunc("LootFrame_UpdateButton", Hook.LootFrame_UpdateButton)
    end

    ---------------
    -- LootFrame --
    ---------------
    local LootFrame = _G.LootFrame
    if private.isRetail then
        -- Skin.ScrollingFlatPanelTemplate (Mainline/ScrollingFlatPanel.lua),
        -- written out without its scroll bar call.
        Skin.DefaultPanelFlatTemplate(LootFrame)
        Skin.TaintSafePanelCloseButton(LootFrame.ClosePanelButton)
        Skin.WowScrollBoxList(LootFrame.ScrollBox)
        -- LootFrame.ScrollBar stays Blizzard's (shape c): its steppers and
        -- its thumb redraw their own atlas on every enable, disable, hover
        -- and press (MinimalScrollBarStepperScriptsMixin:OnButtonStateChanged
        -- and MinimalScrollBarThumbScriptsMixin:OnButtonStateChanged,
        -- Blizzard_SharedXML/Shared/Scroll/MinimalScrollBar.lua:24-26,
        -- :47-52, the same lines on Forever), and grey themselves when
        -- disabled (DesaturateIfDisabled, :10, :33).
        LootFrame.NineSlice:SetBackdropOption("offsets", {
            left = 2,
            right = 2,
            top = 2,
            bottom = 2,
        })
    else
        Skin.ButtonFrameTemplate(LootFrame)
        _G.LootFramePortraitOverlay:Hide()
        select(19, LootFrame:GetRegions()):SetAllPoints(LootFrame.TitleText) -- Items text

        for index = 1, 4 do
            Skin.LootButtonTemplate(_G["LootButton"..index])
        end

        Util.PositionRelative("TOPLEFT", LootFrame, "TOPLEFT", 9, -(private.FRAME_TITLE_HEIGHT + 5), 17, "Down", {
            _G.LootButton1,
            _G.LootButton2,
            _G.LootButton3,
            _G.LootButton4,
        })

        do -- LootFrameUpButton
            Skin.LootNavButton(_G.LootFrameUpButton)
            _G.LootFrameUpButton:SetPoint("BOTTOMLEFT", 10, 10)

            local bg = _G.LootFrameUpButton:GetBackdropTexture("bg")
            local arrow = _G.LootFrameUpButton:CreateTexture(nil, "ARTWORK")
            arrow:SetPoint("TOPLEFT", bg, 5, -8)
            arrow:SetPoint("BOTTOMRIGHT", bg, -5, 8)
            Base.SetTexture(arrow, "arrowUp")
            _G.LootFramePrev:ClearAllPoints()
            _G.LootFramePrev:SetPoint("LEFT", _G.LootFrameUpButton, "RIGHT", 4, 0)
        end
        do -- LootFrameDownButton
            Skin.LootNavButton(_G.LootFrameDownButton)
            _G.LootFrameDownButton:ClearAllPoints()
            _G.LootFrameDownButton:SetPoint("BOTTOMRIGHT", -10, 10)

            local bg = _G.LootFrameDownButton:GetBackdropTexture("bg")
            local arrow = _G.LootFrameDownButton:CreateTexture(nil, "ARTWORK")
            arrow:SetPoint("TOPLEFT", bg, 5, -8)
            arrow:SetPoint("BOTTOMRIGHT", bg, -5, 8)
            Base.SetTexture(arrow, "arrowDown")
            _G.LootFrameNext:ClearAllPoints()
            _G.LootFrameNext:SetPoint("RIGHT", _G.LootFrameDownButton, "LEFT", -4, 0)
        end


        ---------------
        -- GroupLoot --
        ---------------
    end
end
