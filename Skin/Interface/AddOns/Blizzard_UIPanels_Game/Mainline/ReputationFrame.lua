local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Color = Aurora.Color

-- Row templates and row-mixin hooks are shared with the Camelot skin and live
-- in Skin\shared\ReputationFrame.lua (D3.1). Only the entry function differs:
-- the ScrollBox anchor and the detail pane.

function private.FrameXML.ReputationFrame()
    local ReputationFrame = _G.ReputationFrame
    ---------------------
    -- ReputationFrame --
    ---------------------

    -- WowStyle1DropdownTemplate; never skinned before, so it kept Blizzard's
    -- gold arrow and border while the panel around it was skinned.
    if ReputationFrame.filterDropdown then
        Skin.DropdownButton(ReputationFrame.filterDropdown)
    end

    Skin.WowScrollBoxList(ReputationFrame.ScrollBox)
    ReputationFrame.ScrollBox:SetPoint("TOPLEFT", _G.CharacterFrame.Inset, 4, -26)

    Skin.MinimalScrollBar(ReputationFrame.ScrollBar)

    ---------------------------
    -- ReputationDetailFrame --
    ---------------------------
    local ReputationDetailFrame = ReputationFrame.ReputationDetailFrame
    Skin.DialogBorderTemplate(ReputationDetailFrame.Border)
    local repDetailBG = ReputationDetailFrame.Border:GetBackdropTexture("bg")
    ReputationDetailFrame.Title:SetPoint("TOPLEFT", repDetailBG, 10, -8)
    ReputationDetailFrame.Title:SetPoint("BOTTOMRIGHT", repDetailBG, "TOPRIGHT", -10, -26)
    ReputationDetailFrame.ScrollingDescription:SetPoint("TOPLEFT", ReputationDetailFrame.Title, "BOTTOMLEFT", 0, -5)
    ReputationDetailFrame.ScrollingDescription:SetPoint("TOPRIGHT", ReputationDetailFrame.Title, "BOTTOMRIGHT", 0, -5)

    ReputationDetailFrame.Divider:SetColorTexture(Color.frame:GetRGB())
    ReputationDetailFrame.Divider:SetHeight(1)

    Skin.UIPanelCloseButton(ReputationDetailFrame.CloseButton)
    Skin.UICheckButtonTemplate(ReputationDetailFrame.MakeInactiveCheckbox)
    Skin.UICheckButtonTemplate(ReputationDetailFrame.AtWarCheckbox)
    Skin.UICheckButtonTemplate(ReputationDetailFrame.WatchFactionCheckbox)
    Skin.UIPanelButtonTemplate(ReputationDetailFrame.ViewRenownButton)

    private.SharedSkins.ReputationRows()
end
