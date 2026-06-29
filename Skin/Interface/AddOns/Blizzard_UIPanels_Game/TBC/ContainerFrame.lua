local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base, Hook, Skin = Aurora.Base, Aurora.Hook, Aurora.Skin
local Color = Aurora.Color

local keyColor = Color.Create(0.7254, 0.5490, 0.2235, 0.75)
do --[[ FrameXML\ContainerFrame.lua ]]
    local NUM_BAG_SLOTS = _G.NUM_TOTAL_EQUIPPED_BAG_SLOTS or _G.NUM_BAG_SLOTS
    function Hook.ContainerFrame_GenerateFrame(frame, size, id) -- luacheck: ignore 212/size
        if not frame then return end
        if id > NUM_BAG_SLOTS then
            -- bank bags
            local _, _, _, a = frame:GetBackdropColor()
            Base.SetBackdropColor(frame, Color.grayLight, a)
        elseif id == _G.KEYRING_CONTAINER then
            -- key ring
            local _, _, _, a = frame:GetBackdropColor()
            Base.SetBackdropColor(frame, keyColor, a)
        end
    end
    function Hook.ContainerFrame_Update(self)
        if not self then return end
        local bagID = self:GetID()
        local name = self:GetName()

        for i = 1, self.size do
            local itemButton = _G[name.."Item"..i]
            if not itemButton then break end

            local slotID = itemButton:GetID()
            local info = _G.C_Container.GetContainerItemInfo(bagID, slotID)
            local link = info and info.hyperlink

            if not itemButton._auroraIconBorder then
                itemButton._isKey = bagID == _G.KEYRING_CONTAINER
                Skin.ContainerFrameItemButtonTemplate(itemButton)
            end

            if link then
                local GetItemInfo = _G.C_Item and _G.C_Item.GetItemInfo or _G.GetItemInfo
                if GetItemInfo then
                    local _, _, _, _, _, _, _, _, _, _, _, itemClassID = GetItemInfo(link)
                    if itemClassID == _G.LE_ITEM_CLASS_QUESTITEM then
                        if itemButton._questTexture then
                            itemButton._questTexture:Show()
                        end
                        if itemButton._auroraIconBorder then
                            itemButton._auroraIconBorder:SetBackdropBorderColor(1, 1, 0)
                        end
                    end
                end
            end
        end
    end
end

do --[[ FrameXML\ContainerFrame.xml ]]
    function Skin.ContainerFrameItemButtonTemplate(ItemButton)
        if not ItemButton then return end
        if Skin.FrameTypeItemButton then
            Skin.FrameTypeItemButton(ItemButton)
        else
            Skin.FrameTypeButton(ItemButton)
        end
        ItemButton:SetBackdropColor(1, 1, 1, 0.75)

        local name = ItemButton:GetName()
        if name then
            ItemButton._questTexture = _G[name.."IconQuestTexture"]
            if ItemButton._questTexture then
                Base.CropIcon(ItemButton._questTexture)
            end
        end

        if ItemButton.NewItemTexture then
            Base.CropIcon(ItemButton.NewItemTexture)
        end
        if ItemButton.BattlepayItemTexture then
            ItemButton.BattlepayItemTexture:SetTexCoord(0.203125, 0.78125, 0.203125, 0.78125)
            ItemButton.BattlepayItemTexture:SetAllPoints()
        end

        ItemButton:SetBackdropOptions({
            bgFile = ItemButton._isKey and [[Interface\ContainerFrame\KeyRing-Bag-Icon]] or [[Interface\PaperDoll\UI-Backpack-EmptySlot]],
            tile = false
        })
        local bg = ItemButton:GetBackdropTexture("bg")
        if bg then
            bg:SetDesaturated(ItemButton._isKey)
            Base.CropIcon(bg)
        end

        if ItemButton._questTexture then
            ItemButton._questTexture:SetTexture(_G.TEXTURE_ITEM_QUEST_BORDER)
        end
    end
end

function private.FrameXML.ContainerFrame()
    if private.disabled.bags then return end
    _G.hooksecurefunc("ContainerFrame_GenerateFrame", Hook.ContainerFrame_GenerateFrame)
    _G.hooksecurefunc("ContainerFrame_Update", Hook.ContainerFrame_Update)
end
