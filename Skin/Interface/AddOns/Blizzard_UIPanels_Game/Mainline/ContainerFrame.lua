local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

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
        -- Only ContainerFrame1 is skinned at load. ContainerFrame2..N and
        -- ContainerFrameCombinedBags are generated lazily, and this hook is
        -- where they first exist -- Blizzard routes all three through it
        -- (ContainerFrame.lua:207, :277, :290). Without this they were never
        -- skinned at all, and the recolour below then called GetBackdropColor
        -- on a frame with no Aurora backdrop: nil, which is the error Forever
        -- hit on the keyring (KEYRING_CONTAINER is Enum.BagIndex.Keyring there,
        -- so that branch is reachable, where on retail it is not).
        if not private.IsSkinned(frame) then
            private.SetSkinned(frame, true)
            Skin.ContainerFrameTemplate(frame)
        else
            private.SkinContainerItems(frame)
        end

        if not frame.GetBackdropColor then return end

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

        -- Prefer the parentKey. Only ContainerFrame1's item buttons are
        -- declared in XML and named; every other bag builds its buttons from
        -- frame.itemButtonPool (ContainerFrame.lua:1052) with no name at all,
        -- so GetName() is nil there and the $parent lookup threw. The buttons
        -- carry IconQuestTexture directly either way. The global form is kept
        -- as a fallback for the classic templates, which do name it.
        local name = ItemButton:GetName()
        ItemButton._questTexture = ItemButton.IconQuestTexture
            or (name and _G[name.."IconQuestTexture"])
        Base.CropIcon(ItemButton._questTexture)
        Base.CropIcon(ItemButton.NewItemTexture)

        local BattlepayItemTexture = ItemButton.BattlepayItemTexture
        if BattlepayItemTexture then
            BattlepayItemTexture:SetTexCoord(0.203125, 0.78125, 0.203125, 0.78125)
            BattlepayItemTexture:SetAllPoints()
        end

        -- An empty slot draws its background *through the icon*:
        -- SetItemButtonTexture_Base falls back to emptyBackgroundAtlas
        -- (bags-item-slot64, a rounded tile) and calls icon:SetAtlas, which
        -- carries its own texcoords and so undoes Base.CropIcon. That is what
        -- left the bag grid looking round-cornered. A filled slot takes
        -- icon:SetTexture instead, which does not touch texcoords, so only the
        -- atlas path needs handling.
        --
        -- Hide it rather than crop it: the rounding is inside the atlas art, so
        -- cropping only trims it, and Aurora's own backdrop already *is* the
        -- empty slot. Alpha rather than Hide, because Blizzard drives the
        -- icon's shown state itself (icon:SetShown(texture ~= nil)).
        --
        -- Hiding the icon also exposes the backdrop, and the white above was
        -- only ever safe because a filled icon covered it completely. So the
        -- empty state has to drive the backdrop colour as well: black at the
        -- frame alpha when empty (what Skin.FrameTypeItemButton starts with),
        -- white when an item is in the slot.
        local icon = ItemButton.icon
        if icon and not ItemButton._auroraEmptySlotHooked then
            ItemButton._auroraEmptySlotHooked = true

            local function SetEmpty(isEmpty)
                icon:SetAlpha(isEmpty and 0 or 1)
                if isEmpty then
                    ItemButton:SetBackdropColor(Color.black.r, Color.black.g,
                                                Color.black.b, Color.frame.a)
                else
                    ItemButton:SetBackdropColor(1, 1, 1, 0.75) -- static: matches the unskinned icon tint
                end
            end

            _G.hooksecurefunc(icon, "SetAtlas", function()
                SetEmpty(true)
            end)
            _G.hooksecurefunc(icon, "SetTexture", function(self, texture)
                SetEmpty(not texture)
                if texture then
                    Base.CropIcon(self)
                end
            end)

            -- Slots that were already empty when this ran will not see either
            -- hook until their next update, so settle the current state too.
            SetEmpty(icon:GetAtlas() ~= nil or icon:GetTexture() == nil)
        end

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
    -- Item buttons come from frame.itemButtonPool and frame.Items grows as the
    -- bag does, so this runs on every GenerateFrame rather than once per frame.
    function private.SkinContainerItems(Frame)
        for _, itemButton in ipairs(Frame.Items or {}) do
            if not private.IsSkinned(itemButton) then
                Skin.ContainerFrameItemButtonTemplate(itemButton)
                -- Marked only after the skin completes. Setting it first meant
                -- a throw part-way left the button half-skinned and then
                -- permanently skipped on every later pass.
                private.SetSkinned(itemButton, true)
            end
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

        private.SkinContainerItems(Frame)

        -- ContainerFrameMixin:UpdateItemSlots clears and re-acquires every
        -- button from itemButtonPool, and it runs on bag changes without
        -- ContainerFrame_GenerateFrame being called again -- which is why the
        -- combined bag kept showing unskinned slots while the individual bags
        -- came out right. Hook it per frame (Mixin() copies the method at
        -- creation, so the mixin table is the wrong target).
        if Frame.UpdateItemSlots and not Frame._auroraItemSlotsHooked then
            Frame._auroraItemSlotsHooked = true
            _G.hooksecurefunc(Frame, "UpdateItemSlots", private.SkinContainerItems)
        end

        -- PortraitButton is a DropdownButton -- the "Click for Bag Settings"
        -- affordance -- not decoration. Hiding it leaves the tooltip working
        -- (ContainerFramePortraitButtonRouterTemplate still catches the mouse)
        -- while the click does nothing, which is what Forever was showing.
        -- Left alone there; retail's look is long-settled and unverified, so
        -- this is deliberately not changed for it. See the note in tasks.md.
        if not private.isForever then
            Frame.PortraitButton:Hide()
        end

        -- ContainerFrameCombinedBags inherits PortraitFrameFlatTemplate rather
        -- than ContainerFrameTemplate and declares no FilterIcon.
        local FilterIcon = Frame.FilterIcon
        if FilterIcon then
            _G.hooksecurefunc(FilterIcon.Icon, "SetAtlas", Hook.ContainerFrameFilterIcon_SetAtlas)

            FilterIcon:ClearAllPoints()
            FilterIcon:SetPoint("TOPLEFT", bg, 5, -5)
            FilterIcon:SetSize(17, 17)
            FilterIcon.Icon:SetAllPoints()

            Base.CropIcon(FilterIcon.Icon, FilterIcon)
        end

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
