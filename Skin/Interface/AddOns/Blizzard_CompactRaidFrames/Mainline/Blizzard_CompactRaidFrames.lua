local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals next

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
-- local Util = Aurora.Util

do --[[ AddOns\Blizzard_CompactRaidFrames.xml ]]
    function Skin.CRFManagerFilterButtonTemplate(Button)
        Skin.FrameTypeButton(Button)
        Button:SetBackdropOption("offsets", {
            left = 2,
            right = 2,
            top = 2,
            bottom = 2,
        })
        if  Button.Background then
            Button.Background:Hide()
        end
        Button.TopEdge:Hide()
        Button.TopLeftCorner:Hide()
        Button.TopRightCorner:Hide()
        Button.BottomEdge:Hide()
        Button.BottomLeftCorner:Hide()
        Button.BottomRightCorner:Hide()
        Button.LeftEdge:Hide()
        Button.RightEdge:Hide()
        if Button.Text then
            local bg = Button:GetBackdropTexture("bg")
            Button.Text:SetPoint("CENTER", bg, 0, 0)
            Button.selectedHighlight:SetColorTexture(1, 1, 0, 0.3) -- static: not a theme color
            Button.selectedHighlight:SetPoint("TOPLEFT", bg, 1, -1)
            Button.selectedHighlight:SetPoint("BOTTOMRIGHT", bg, -1, 1)
        end
    end
    Skin.CRFManagerFilterRoleButtonTemplate = Skin.CRFManagerFilterButtonTemplate
    Skin.CRFManagerFilterGroupButtonTemplate = Skin.CRFManagerFilterButtonTemplate
    Skin.CRFManagerTooltipTemplate = Skin.CRFManagerFilterButtonTemplate

    function Skin.CRFManagerRaidIconButtonTemplate(Button)
        Button:SetSize(24, 24)
        Button:SetPoint(Button:GetPoint())
        Button:GetNormalTexture()
        Button:SetSize(24, 24)
    end
end

function private.AddOns.Blizzard_CompactRaidFrames()
    ----====#################################====----
    -- Blizzard_CompactRaidFrameReservationManager --
    ----====#################################====----

    ----====########################====----
    -- Blizzard_CompactRaidFrameContainer --
    ----====########################====----

    ----====############%%########====----
    -- Blizzard_CompactRaidFrameManager --
    ----====############%%########====----
    local CompactRaidFrameManager = _G.CompactRaidFrameManager
    CompactRaidFrameManager:DisableDrawLayer("ARTWORK")
    Skin.FrameTypeFrame(CompactRaidFrameManager)

    local toggleButtonForward = CompactRaidFrameManager.toggleButtonForward
    toggleButtonForward:SetPoint("RIGHT", -1, 0)
    toggleButtonForward:SetScript("OnMouseDown", private.nop)
    toggleButtonForward:SetScript("OnMouseUp", private.nop)

    local arrowForward = toggleButtonForward:GetNormalTexture()
    arrowForward:ClearAllPoints()
    arrowForward:SetPoint("TOPLEFT", 3, -5)
    arrowForward:SetPoint("BOTTOMRIGHT", -3, 5)
    Base.SetTexture(arrowForward, "arrowRight")


    local toggleButtonBack = CompactRaidFrameManager.toggleButtonBack
    toggleButtonBack:SetPoint("RIGHT", -1, 0)
    toggleButtonBack:SetScript("OnMouseDown", private.nop)
    toggleButtonBack:SetScript("OnMouseUp", private.nop)

    local arrowBack = toggleButtonBack:GetNormalTexture()
    arrowBack:ClearAllPoints()
    arrowBack:SetPoint("TOPLEFT", 3, -5)
    arrowBack:SetPoint("BOTTOMRIGHT", -3, 5)
    Base.SetTexture(arrowBack, "arrowLeft")

    local displayFrame = CompactRaidFrameManager.displayFrame
    local displayFrameName = displayFrame:GetName()
    displayFrame:GetRegions():Hide()
    local optionsButton = _G[displayFrameName.."OptionsButton"]
    Skin.UIPanelInfoButton(optionsButton)

    local filterOptions = displayFrame.filterOptions
    Skin.CRFManagerFilterRoleButtonTemplate(filterOptions["filterRoleTank"])
    Skin.CRFManagerFilterRoleButtonTemplate(filterOptions.filterRoleHealer)
    Skin.CRFManagerFilterRoleButtonTemplate(filterOptions.filterRoleDamager)
    for i = 1, 8 do
        Skin.CRFManagerFilterRoleButtonTemplate(filterOptions["filterGroup"..i])
    end

    Skin.CRFManagerTooltipTemplate(displayFrame.editMode)
    Skin.CRFManagerTooltipTemplate(displayFrame.settings)
    Skin.CRFManagerTooltipTemplate(displayFrame.hiddenModeToggle)

    local icons = {displayFrame.raidMarkers:GetChildren()}
    for i, icon in next, icons do
        Skin.CRFManagerRaidIconButtonTemplate(icon)
    end

    Skin.CRFManagerTooltipTemplate(displayFrame.rolePollButton)
    Skin.CRFManagerTooltipTemplate(displayFrame.readyCheckButton)
    Skin.CRFManagerTooltipTemplate(displayFrame.countdownButton)
    Skin.CRFManagerTooltipTemplate(displayFrame.difficulty)
    Skin.UICheckButtonTemplate(displayFrame.everyoneIsAssistButton)

end
