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

    -- Column headers (taint audit 2026-10-06, B170 follow-up): restyled in
    -- place after Blizzard's LayoutColumns, never from the pool's Acquire.
    -- The old Acquire post-hook ran Skin.UIPanelButtonTemplate (backdrop,
    -- fields) on buttons LayoutColumns went on to size and anchor; it was
    -- also installed from a mixin OnLoad hook that never fired for the XML
    -- frame. The headers have no art besides the highlight, so only that
    -- texture is recoloured.
    function Hook.BulletinBoardColumnDisplay_LayoutColumns(self)
        for button in self.columnHeaders:EnumerateActive() do
            if not private.IsSkinned(button) then
                private.SetSkinned(button, true)
                local highlight = button:GetHighlightTexture()
                if highlight then
                    Util.SetHighlightColor(highlight, 0.2)
                end
            end
        end
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

    -- Hide decorative line on ColumnDisplay; headers in place after layout
    local ColumnDisplay = ResidentsTab.ColumnDisplay
    if ColumnDisplay then
        if ColumnDisplay.DecorativeLine then
            ColumnDisplay.DecorativeLine:SetAlpha(0)
        end
        _G.hooksecurefunc(ColumnDisplay, "LayoutColumns", Hook.BulletinBoardColumnDisplay_LayoutColumns)
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

    -- Pending invites: the skin only hides the background (in place), so the
    -- Acquire post-hook stays (taint audit 2026-10-06).
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
