local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals pairs

--[[ Core ]]
local Aurora = private.Aurora
local Base, Skin = Aurora.Base, Aurora.Skin
local Color = Aurora.Color

function private.AddOns.Blizzard_HousingHouseSettings()
    ----
    -- HousingHouseSettingsFrame
    ----
    local Frame = _G.HousingHouseSettingsFrame

    Base.SetBackdrop(Frame, Color.frame)

    -- Hide decorative textures
    Frame.Background:SetAlpha(0)
    Frame.WoodHeader:SetAlpha(0)
    Frame.Header:SetAlpha(0)
    Frame.PlantDecoLeft:SetAlpha(0)
    Frame.Spacer:SetAlpha(0)

    if Frame.CloseButton then
        Skin.UIPanelCloseButton(Frame.CloseButton)
    end

    -- HouseOwnerDropdown (WowStyle1DropdownTemplate)
    Skin.WowStyle1ArrowDropdownTemplate(Frame.HouseOwnerDropdown)

    -- PlotAccess and HouseAccess AccessType dropdowns (WowStyle2DropdownTemplate)
    Skin.DropdownButton(Frame.PlotAccess.AccessTypeDropdown)
    Skin.DropdownButton(Frame.HouseAccess.AccessTypeDropdown)

    -- Skin checkboxes in PlotAccess.Options and HouseAccess.Options
    -- Options children are created dynamically in SetupOptions (called from OnLoad, before ADDON_LOADED)
    for _, child in pairs({Frame.PlotAccess.Options:GetChildren()}) do
        if child.Checkbox then
            Skin.FrameTypeCheckButton(child.Checkbox)
        end
    end
    for _, child in pairs({Frame.HouseAccess.Options:GetChildren()}) do
        if child.Checkbox then
            Skin.FrameTypeCheckButton(child.Checkbox)
        end
    end

    -- Buttons
    Skin.UIPanelButtonTemplate(Frame.SaveButton)
    Skin.UIPanelButtonTemplate(Frame.IgnoreListButton)
    Skin.UIPanelButtonTemplate(Frame.AbandonHouseButton)

    ----
    -- AbandonHouseConfirmationDialog
    ----
    local Dialog = _G.AbandonHouseConfirmationDialog

    Skin.FrameTypeFrame(Dialog)
    Skin.FrameTypeButton(Dialog.ConfirmButton)
    Skin.FrameTypeButton(Dialog.CancelButton)
end
