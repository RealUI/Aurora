local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Base, Skin = Aurora.Base, Aurora.Skin
local Color = Aurora.Color


do --[[ AddOns\Blizzard_HousingCornerstone\Blizzard_HousingCornerstone.xml ]]
    -- Shared helper for HousingCornerstoneVisitorTemplate-based frames
    local function SkinVisitorTemplate(Frame)
        Base.SetBackdrop(Frame, Color.frame)

        -- Hide decorative textures
        if Frame.Border then Frame.Border:SetAlpha(0) end
        if Frame.Background then Frame.Background:SetAlpha(0) end
        if Frame.Header then Frame.Header:SetAlpha(0) end

        -- GearDropdown (UIPanelIconDropdownButtonTemplate)
        if Frame.GearDropdown then
            Skin.DropdownButton(Frame.GearDropdown)
        end
    end

    function Skin.HousingCornerstoneVisitorTemplate(Frame)
        SkinVisitorTemplate(Frame)
    end
end

function private.AddOns.Blizzard_HousingCornerstone()
    ----
    -- Main Frame (DefaultPanelTemplate + TabSystemOwnerTemplate)
    ----
    local HousingCornerstoneFrame = _G.HousingCornerstoneFrame

    -- DefaultPanelTemplate resolves to ButtonFrameTemplateNoPortrait layout at runtime
    -- (no PortraitFrameMixin, so Skin.PortraitFrameTemplate would fail on SetBorder)
    Skin.DefaultPanelTemplate(HousingCornerstoneFrame)
    Skin.UIPanelCloseButton(HousingCornerstoneFrame.CloseButton)

    -- Skin TabSystem tabs when they are created
    local TabSystem = HousingCornerstoneFrame.TabSystem
    if TabSystem then
        local function SkinTabSystemTabs()
            for _, tab in ipairs({TabSystem:GetChildren()}) do
                if tab.Left and tab.LeftActive and not private.IsSkinned(tab) then
                    private.SetSkinned(tab, true)
                    Skin.TabSystemButtonTemplate(tab)
                end
            end
        end

        -- Hook SetTab to skin tabs after they're created
        if HousingCornerstoneFrame.SetTab then
            _G.hooksecurefunc(HousingCornerstoneFrame, "SetTab", SkinTabSystemTabs)
        end

        -- Skin any tabs that already exist
        SkinTabSystemTabs()
    end

    ----
    -- Purchase Frame
    ----
    local PurchaseFrame = _G.HousingCornerstonePurchaseFrame

    Base.SetBackdrop(PurchaseFrame, Color.frame)

    -- Hide decorative textures
    PurchaseFrame.Border:SetAlpha(0)
    PurchaseFrame.Background:SetAlpha(0)
    PurchaseFrame.Header:SetAlpha(0)
    PurchaseFrame.Footer:SetAlpha(0)

    -- Hide ForSaleSign wood sign
    if PurchaseFrame.ForSaleSign and PurchaseFrame.ForSaleSign.WoodSign then
        PurchaseFrame.ForSaleSign.WoodSign:SetAlpha(0)
    end

    -- Buy button
    Skin.UIPanelButtonTemplate(PurchaseFrame.BuyButton)

    ----
    -- Visitor Frame (HousingCornerstoneVisitorTemplate)
    ----
    local VisitorFrame = _G.HousingCornerstoneVisitorFrame

    Skin.HousingCornerstoneVisitorTemplate(VisitorFrame)

    ----
    -- House Info Frame (HousingCornerstoneVisitorTemplate)
    ----
    local HouseInfoFrame = _G.HousingCornerstoneHouseInfoFrame

    Skin.HousingCornerstoneVisitorTemplate(HouseInfoFrame)

    ----
    -- MoveHouseConfirmationDialog (TranslucentFrameTemplate)
    ----
    local MoveDialog = _G.MoveHouseConfirmationDialog

    Skin.FrameTypeFrame(MoveDialog)
    Skin.FrameTypeButton(MoveDialog.ConfirmButton)
    Skin.FrameTypeButton(MoveDialog.CancelButton)

    ----
    -- ImportHouseConfirmationDialog (TranslucentFrameTemplate)
    ----
    local ImportDialog = _G.ImportHouseConfirmationDialog

    Skin.FrameTypeFrame(ImportDialog)
    Skin.FrameTypeButton(ImportDialog.ConfirmButton)
    Skin.FrameTypeButton(ImportDialog.CancelButton)
end
