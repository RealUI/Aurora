local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals pairs

--[[ Core ]]
local Aurora = private.Aurora
local Base, Hook, Skin = Aurora.Base, Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util


do --[[ AddOns\Blizzard_HousingBulletinBoard\Blizzard_HousingBulletinBoard.lua ]]
    Hook.NeighborhoodRosterEntryMixin = {}
    function Hook.NeighborhoodRosterEntryMixin:Init()
        if private.IsSkinned(self) then
            -- Update alternating backdrop alpha on re-init
            local index = self:GetOrderIndex()
            local alpha = (index % 2 == 0) and 0.15 or 0.25
            Base.SetBackdrop(self, Color.button, alpha)
            return
        end
        private.SetSkinned(self, true)

        -- Hide the Blizzard normal texture (alternating atlas bg)
        if self.NormalTexture then
            self.NormalTexture:SetAlpha(0)
        end

        -- Apply flat backdrop with alternating alpha
        local index = self:GetOrderIndex()
        local alpha = (index % 2 == 0) and 0.15 or 0.25
        Base.SetBackdrop(self, Color.button, alpha)
    end

    Hook.BulletinBoardColumnDisplayMixin = {}
    function Hook.BulletinBoardColumnDisplayMixin:OnLoad()
        -- Wrap the columnHeaders pool so newly created header buttons are skinned
        Util.WrapPoolAcquire(self.columnHeaders, function(button)
            if private.IsSkinned(button) then return end
            private.SetSkinned(button, true)
            Skin.UIPanelButtonTemplate(button)
        end)
    end
end

do --[[ AddOns\Blizzard_HousingBulletinBoard\Blizzard_HousingBulletinBoard.xml ]]
    function Skin.PendingInviteTemplate(Frame)
        if private.IsSkinned(Frame) then return end
        private.SetSkinned(Frame, true)

        -- Hide the background atlas
        if Frame.Background then
            Frame.Background:SetAlpha(0)
        end
    end
end

function private.AddOns.Blizzard_HousingBulletinBoard()
    ----
    -- HousingBulletinBoardFrame (TabSystemOwnerTemplate)
    ----
    local BulletinBoard = _G.HousingBulletinBoardFrame

    Base.SetBackdrop(BulletinBoard, Color.frame)

    -- Hide decorative textures
    BulletinBoard.Border:SetAlpha(0)
    BulletinBoard.Background:SetAlpha(0)
    BulletinBoard.Header:SetAlpha(0)
    BulletinBoard.Footer:SetAlpha(0)

    -- Hide FoliageDecoration child frame regions
    local FoliageDecoration = BulletinBoard.FoliageDecoration
    if FoliageDecoration then
        for _, region in pairs({FoliageDecoration:GetRegions()}) do
            if region:IsObjectType("Texture") then
                region:SetAlpha(0)
            end
        end
    end

    -- GearDropdown (UIPanelIconDropdownButtonTemplate)
    if BulletinBoard.GearDropdown then
        Skin.DropdownButton(BulletinBoard.GearDropdown)
    end

    ----
    -- ResidentsTab (NeighborhoodRosterTemplate)
    ----
    local ResidentsTab = BulletinBoard.ResidentsTab

    -- Hide roster background
    if ResidentsTab.Background then
        ResidentsTab.Background:SetAlpha(0)
    end

    -- ScrollBox / ScrollBar
    if ResidentsTab.ScrollBox then Skin.WowScrollBoxList(ResidentsTab.ScrollBox) end
    if ResidentsTab.ScrollBar then Skin.MinimalScrollBar(ResidentsTab.ScrollBar) end

    -- InviteResidentButton
    Skin.UIPanelButtonTemplate(ResidentsTab.InviteResidentButton)

    -- Hook roster entry Init for dynamic skinning
    _G.hooksecurefunc(_G.NeighborhoodRosterEntryMixin, "Init", Hook.NeighborhoodRosterEntryMixin.Init)

    -- Hook column display OnLoad to wrap the columnHeaders pool
    _G.hooksecurefunc(_G.BulletinBoardColumnDisplayMixin, "OnLoad", Hook.BulletinBoardColumnDisplayMixin.OnLoad)

    -- Hide decorative line on ColumnDisplay
    local ColumnDisplay = ResidentsTab.ColumnDisplay
    if ColumnDisplay and ColumnDisplay.DecorativeLine then
        ColumnDisplay.DecorativeLine:SetAlpha(0)
    end

    ----
    -- HousingInviteResidentFrame (standalone global)
    ----
    local InviteFrame = _G.HousingInviteResidentFrame

    Base.SetBackdrop(InviteFrame, Color.frame)

    -- Hide decorative textures
    InviteFrame.Border:SetAlpha(0)
    InviteFrame.Background:SetAlpha(0)
    InviteFrame.Header:SetAlpha(0)

    -- Hide pending invite background
    if InviteFrame.PendingInviteBackground then
        InviteFrame.PendingInviteBackground:SetAlpha(0)
    end

    -- SendInviteButton
    Skin.UIPanelButtonTemplate(InviteFrame.SendInviteButton)

    -- PlayerSearchBox — skin as SearchBox and hide Common-Input-Border textures
    local SearchBox = InviteFrame.PlayerSearchBox
    if SearchBox then
        Skin.SearchBoxTemplate(SearchBox)
        if SearchBox.LeftBorder then SearchBox.LeftBorder:SetAlpha(0) end
        if SearchBox.RightBorder then SearchBox.RightBorder:SetAlpha(0) end
        if SearchBox.MiddleBorder then SearchBox.MiddleBorder:SetAlpha(0) end
    end

    -- Wrap pendingInvitesPool for dynamic invite entries
    Util.WrapPoolAcquire(InviteFrame.pendingInvitesPool, Skin.PendingInviteTemplate)

    ----
    -- NeighborhoodChangeNameDialog (TranslucentFrameTemplate)
    ----
    local ChangeNameDialog = _G.NeighborhoodChangeNameDialog

    Skin.FrameTypeFrame(ChangeNameDialog)
    Skin.FrameTypeButton(ChangeNameDialog.ConfirmButton)
    Skin.FrameTypeButton(ChangeNameDialog.CancelButton)

    -- NameEditBox (InputBoxInstructionsTemplate)
    if ChangeNameDialog.NameEditBox then
        Skin.FrameTypeEditBox(ChangeNameDialog.NameEditBox)
    end
end
