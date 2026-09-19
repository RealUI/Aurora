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
    function Hook.ContainerFrameFilterIcon_SetAtlas(self, atlas)
        self:SetTexture(_G.BAG_FILTER_ICONS[atlas])
    end

    local NUM_BAG_SLOTS = _G.NUM_TOTAL_EQUIPPED_BAG_SLOTS or _G.NUM_BAG_SLOTS
    function Hook.ContainerFrame_GenerateFrame(frame, size, id)
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
        local bagID = self:GetID()
        local name = self:GetName()

        if private.isRetail and bagID == 0 then
            _G.BagItemSearchBox:ClearAllPoints()
            _G.BagItemSearchBox:SetPoint("TOPLEFT", self, 20, -35)
            _G.BagItemAutoSortButton:ClearAllPoints()
            _G.BagItemAutoSortButton:SetPoint("TOPRIGHT", self, -16, -31)
        end

        for i = 1, self.size do
            local itemButton = _G[name.."Item"..i]
            local slotID, _ = itemButton:GetID()
            local quality, link
            if private.isVanilla then
                _, _, _, quality, _, _, link = _G.GetContainerItemInfo(bagID, slotID)
            else
                local info = _G.C_Container.GetContainerItemInfo(bagID, slotID);
                quality = info and info.quality;
                link = info and info.hyperlink;
            end

            if not itemButton._auroraIconBorder then
                itemButton._isKey = bagID == _G.KEYRING_CONTAINER
                Skin.ContainerFrameItemButtonTemplate(itemButton)

                Hook.SetItemButtonQuality(itemButton, quality, link)
            end

            if link then
                local _, _, _, _, _, _, _, _, _, _, _, itemClassID = _G.C_Item.GetItemInfo(link)
                -- LE_ITEM_CLASS_QUESTITEM no longer exists (zero hits in
                -- the 12.0.7 tree); the comparison was silently nil == id.
                if itemClassID == _G.Enum.ItemClass.Questitem then
                    itemButton._questTexture:Show()
                    itemButton._auroraIconBorder:SetBackdropBorderColor(1, 1, 0)
                end
            end
        end
    end
end

do --[[ FrameXML\ContainerFrame.xml ]]
    function Skin.ContainerFrameHelpBoxTemplate(Frame)
        Skin.GlowBoxFrame(Frame, "Right")
    end

    function Skin.ContainerFrameItemButtonTemplate(ItemButton)
        Skin.FrameTypeItemButton(ItemButton)
        ItemButton:SetBackdropColor(1, 1, 1, 0.75)

        local name = ItemButton:GetName()
        ItemButton._questTexture = _G[name.."IconQuestTexture"]
        Base.CropIcon(ItemButton._questTexture)
        Base.CropIcon(ItemButton.NewItemTexture)
        ItemButton.BattlepayItemTexture:SetTexCoord(0.203125, 0.78125, 0.203125, 0.78125)
        ItemButton.BattlepayItemTexture:SetAllPoints()

        if private.isRetail then
            Base.CropIcon(ItemButton.icon)
        else
            ItemButton:SetBackdropOptions({
                bgFile = ItemButton._isKey and [[Interface\ContainerFrame\KeyRing-Bag-Icon]] or [[Interface\PaperDoll\UI-Backpack-EmptySlot]],
                tile = false
            })
            local bg = ItemButton:GetBackdropTexture("bg")
            bg:SetDesaturated(ItemButton._isKey)
            Base.CropIcon(bg)

            ItemButton._questTexture:SetTexture(_G.TEXTURE_ITEM_QUEST_BORDER)
        end
    end
    function Skin.ContainerFrameTemplate(Frame)
        local bg

        if not Frame then
            if private.isDev then
                _G.print("ReportError: Frame is nil in ContainerFrameTemplate - Report to Aurora developers.")
            end
            return
        end
        Skin.PortraitFrameFlatTemplate(Frame)
        bg = Frame.NineSlice:GetBackdropTexture("bg")

        for _, itemButton in ipairs(Frame.Items) do
            Skin.ContainerFrameItemButtonTemplate(itemButton)
        end

        _G.hooksecurefunc(Frame.FilterIcon.Icon, "SetAtlas", Hook.ContainerFrameFilterIcon_SetAtlas)

        Frame.PortraitButton:Hide()
        Frame.FilterIcon:ClearAllPoints()
        Frame.FilterIcon:SetPoint("TOPLEFT", bg, 5, -5)
        Frame.FilterIcon:SetSize(17, 17)
        Frame.FilterIcon.Icon:SetAllPoints()

        Base.CropIcon(Frame.FilterIcon.Icon, Frame.FilterIcon)

        -- ClickableTitleFrame was removed from ContainerFrameTemplate and has
        -- been throwing here -- silently, behind the skin pcall -- which cost
        -- every bag after the first its skin. It is a deletion, not a rename:
        -- it was an invisible click region widened to the full title bar, and
        -- bags now drag at frame level (ContainerFrameTemplate is movable +
        -- enableMouse with ContainerFrameMixin:OnDragStart). The visible title
        -- strip is already positioned by Skin.PortraitFrameBaseTemplate, via
        -- the Skin.PortraitFrameFlatTemplate call at the top of this function.
        --
        -- Do not "restore" this by pointing it at Frame.TitleContainer: that
        -- frame carries TitleText, so re-anchoring it to the background would
        -- move the bag title 24px left, which the old code never did.
    end
    -- Called by ContainerFrameBackpackTemplate below but never defined, on any
    -- flavor -- the bag money frame has been killing that skin function since
    -- it was written. It only surfaced once the removed ClickableTitleFrame
    -- line above stopped throwing first. ContainerMoneyFrameTemplate inherits
    -- SmallMoneyFrameTemplate, which Aurora deliberately no-ops, so delegate
    -- rather than no-op here: if money frames ever get skinned, bags follow.
    -- Resolved at call time because the MoneyFrame skin file may load later.
    function Skin.ContainerMoneyFrameTemplate(Frame)
        if Frame and Skin.SmallMoneyFrameTemplate then
            Skin.SmallMoneyFrameTemplate(Frame)
        end
    end
    function Skin.ContainerFrameBackpackTemplate(Frame)
        if not Frame then
            if private.isDev then
                _G.print("[Aurora-Dev]: Frame is nil in ContainerFrameBackpackTemplate - Report to Aurora developers.")
            end
            return
        end
        Skin.ContainerFrameTemplate(Frame)
        Skin.ContainerMoneyFrameTemplate(Frame.MoneyFrame)
    end
end

function private.FrameXML.ContainerFrame()
    if private.disabled.bags then return end
    _G.hooksecurefunc("ContainerFrame_GenerateFrame", Hook.ContainerFrame_GenerateFrame)

    Skin.ContainerFrameBackpackTemplate(_G.ContainerFrame1)

    if private.isRetail then
        Skin.BagSearchBoxTemplate(_G.BagItemSearchBox)
        _G.BagItemSearchBox:SetWidth(120)

        local autoSort = _G.BagItemAutoSortButton
        autoSort:SetSize(26, 26)
        autoSort:SetNormalTexture([[Interface\Icons\INV_Pet_Broom]])
        autoSort:GetNormalTexture():SetTexCoord(.13, .92, .13, .92)

        autoSort:SetPushedTexture([[Interface\Icons\INV_Pet_Broom]])
        autoSort:GetPushedTexture():SetTexCoord(.08, .87, .08, .87)

        local iconBorder = autoSort:CreateTexture(nil, "BACKGROUND")
        iconBorder:SetPoint("TOPLEFT", autoSort, -1, 1)
        iconBorder:SetPoint("BOTTOMRIGHT", autoSort, 1, -1)
        iconBorder:SetColorTexture(0, 0, 0) -- static: not a theme color
    else
        _G.hooksecurefunc("ContainerFrame_Update", Hook.ContainerFrame_Update)
    end
end
