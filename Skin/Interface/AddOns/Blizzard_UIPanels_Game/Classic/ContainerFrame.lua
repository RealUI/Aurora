local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Base, Hook, Skin = Aurora.Base, Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

--[[ Classic-family ContainerFrame (bags; era/TBC/Mists).
    Evidence: wow-ui-source-*/Interface/AddOns/Blizzard_UIPanels_Game/
    Classic/ContainerFrame.xml (13 ContainerFrames, named UI-Bag-Components
    background pieces + $parentName + $parentCloseButton) and
    Classic/ContainerFrame_Shared.lua (ContainerFrame_Update /
    ContainerFrame_GenerateFrame globals). Hooks adapted from the retail
    skin's classic branches. Item buttons are skinned lazily from the
    ContainerFrame_Update hook (slot counts are dynamic).
]]

local keyColor = Color.Create(0.7254, 0.5490, 0.2235, 0.75)

do --[[ Classic\ContainerFrame_Shared.lua ]]
    local NUM_BAG_SLOTS = _G.NUM_TOTAL_EQUIPPED_BAG_SLOTS or _G.NUM_BAG_SLOTS
    function Hook.ContainerFrame_GenerateFrame(frame, size, id)
        if id > NUM_BAG_SLOTS then
            -- bank bags
            local _, _, _, a = frame:GetBackdropColor()
            Base.SetBackdropColor(frame, Color.grayLight, a)
        elseif id == _G.KEYRING_CONTAINER then
            local _, _, _, a = frame:GetBackdropColor()
            Base.SetBackdropColor(frame, keyColor, a)
        end
    end
    function Hook.ContainerFrame_Update(self)
        local bagID = self:GetID()
        local name = self:GetName()

        for i = 1, self.size do
            local itemButton = _G[name.."Item"..i]
            local slotID = itemButton:GetID()
            -- All modern classic clients (1.15+) use C_Container; the old
            -- flat GetContainerItemInfo global no longer exists.
            local info = _G.C_Container.GetContainerItemInfo(bagID, slotID)
            local quality = info and info.quality
            local link = info and info.hyperlink

            if not itemButton._auroraIconBorder then
                itemButton._isKey = bagID == _G.KEYRING_CONTAINER
                Skin.ContainerFrameItemButtonTemplate(itemButton)

                Hook.SetItemButtonQuality(itemButton, quality, link)
            end

            if link then
                local _, _, _, _, _, _, _, _, _, _, _, itemClassID = _G.C_Item.GetItemInfo(link)
                if itemClassID == _G.LE_ITEM_CLASS_QUESTITEM then
                    itemButton._questTexture:Show()
                    itemButton._auroraIconBorder:SetBackdropBorderColor(1, 1, 0)
                end
            end
        end
    end
end

do --[[ Classic\ContainerFrame.xml ]]
    function Skin.ContainerFrameItemButtonTemplate(ItemButton)
        Skin.FrameTypeItemButton(ItemButton)
        ItemButton:SetBackdropColor(1, 1, 1, 0.75)

        local name = ItemButton:GetName()
        ItemButton._questTexture = _G[name.."IconQuestTexture"]
        ItemButton._questTexture:SetTexture(_G.TEXTURE_ITEM_QUEST_BORDER)
        Base.CropIcon(ItemButton._questTexture)
        Base.CropIcon(ItemButton.NewItemTexture)
        ItemButton.BattlepayItemTexture:SetTexCoord(0.203125, 0.78125, 0.203125, 0.78125)
        ItemButton.BattlepayItemTexture:SetAllPoints()

        ItemButton:SetBackdropOptions({
            bgFile = ItemButton._isKey and [[Interface\ContainerFrame\KeyRing-Bag-Icon]] or [[Interface\PaperDoll\UI-Backpack-EmptySlot]],
            tile = false
        })
        local bg = ItemButton:GetBackdropTexture("bg")
        bg:SetDesaturated(ItemButton._isKey)
        Base.CropIcon(bg)
    end

    function Skin.ContainerFrameTemplate(Frame)
        -- Portrait plus the five named UI-Bag-Components pieces.
        -- ContainerFrame_GenerateFrame re-SetTextures these on every open,
        -- so hide by alpha (survives texture swaps).
        Util.HideFrameTextures(Frame, true)

        Skin.FrameTypeFrame(Frame)
        local bg = Frame:GetBackdropTexture("bg")

        local name = Frame:GetName()
        Skin.UIPanelCloseButton(_G[name.."CloseButton"])

        local title = _G[name.."Name"]
        if title then
            title:ClearAllPoints()
            title:SetPoint("TOPLEFT", bg)
            title:SetPoint("BOTTOMRIGHT", bg, "TOPRIGHT", 0, -private.FRAME_TITLE_HEIGHT)
            title:SetJustifyH("CENTER")
        end
    end
end

function private.FrameXML.ContainerFrame()
    if private.disabled.bags then return end

    _G.hooksecurefunc("ContainerFrame_GenerateFrame", Hook.ContainerFrame_GenerateFrame)
    _G.hooksecurefunc("ContainerFrame_Update", Hook.ContainerFrame_Update)

    local i = 1
    while _G["ContainerFrame"..i] do
        Skin.ContainerFrameTemplate(_G["ContainerFrame"..i])
        i = i + 1
    end
end
