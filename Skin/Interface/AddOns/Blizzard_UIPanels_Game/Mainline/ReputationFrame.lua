local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals next type

--[[ Core ]]
local Aurora = private.Aurora
local Base, Hook, Skin = Aurora.Base, Aurora.Hook, Aurora.Skin
local Color = Aurora.Color

do --[[ FrameXML\ReputationFrame.lua ]]
    function Hook.ReputationFrame_OnShow(self)
        -- The TOPRIGHT anchor for ReputationBar1 is set in C code
        _G.ReputationBar1:SetPoint("TOPRIGHT", -34, -(private.FRAME_TITLE_HEIGHT + 22))
    end
    function Hook.ReputationFrame_SetRowType(factionRow, isChild, isHeader, hasRep)
        if isHeader then
            factionRow:SetBackdrop(false)
        else
            factionRow:SetBackdrop(true)
        end
    end
    function Hook.ReputationFrame_InitReputationRow(factionRow, elementData)
        local _, _, _, _, _, _, atWarWith = _G.GetFactionInfo(elementData.index)

        local bd = factionRow._bdFrame or factionRow
        if atWarWith then
            Base.SetBackdropColor(bd, Color.red)
        else
            Base.SetBackdropColor(bd, Color.button)
        end

        if elementData.index == _G.GetSelectedFaction() then
            if _G.ReputationDetailFrame:IsShown() then
                bd:SetBackdropBorderColor(Color.highlight)
            end
        end
    end

    local hasShown = false
    function Hook.ReputationFrame_Update(self)
        if not hasShown then
            hasShown = true
            _G.ReputationFrame:Hide()
            _G.ReputationFrame:Show()
            return
        end

        for i = 1, _G.NUM_FACTIONS_DISPLAYED do
            local factionRow = _G["ReputationBar"..i]
            if factionRow.index then
                local _, _, _, _, _, _, atWarWith = _G.GetFactionInfo(factionRow.index)

                local bd = factionRow._bdFrame or factionRow
                if atWarWith then
                    Base.SetBackdropColor(bd, Color.red)
                else
                    Base.SetBackdropColor(bd, Color.button)
                end

                if factionRow.index == _G.C_Reputation.GetSelectedFaction() then
                    if _G.ReputationDetailFrame:IsShown() then
                        bd:SetBackdropBorderColor(Color.highlight)
                    end
                end
            end
        end

        Hook.ReputationFrame_OnShow(self)
    end
end

do --[[ FrameXML\ReputationFrame.xml ]]
    local function OnEnter(button)
        (button._bdFrame or button):SetBackdropBorderColor(Color.highlight)
    end
    local function OnLeave(button)
        if (_G.C_Reputation.GetSelectedFaction() ~= button.index) or (not _G.ReputationDetailFrame:IsShown()) then
            local _, _, _, _, _, _, atWarWith = _G.C_Reputation.GetFactionInfo(button.index)
            if atWarWith then
                (button._bdFrame or button):SetBackdropBorderColor(Color.red)
            else
                (button._bdFrame or button):SetBackdropBorderColor(Color.button)
            end
        end
    end

    function Skin.ReputationBarTemplate(Button)
        Skin.FrameTypeButton(Button, OnEnter, OnLeave)
        Button:SetBackdropOption("offsets", {
            left = 30,
            right = 10,
            top = 0,
            bottom = 0,
        })

        local Container = Button.Container
        Container.Background:SetAlpha(0)

        Skin.ExpandOrCollapse(Container.ExpandOrCollapseButton)

        local ReputationBar = Container.ReputationBar
        Skin.FrameTypeStatusBar(ReputationBar)
        ReputationBar:ClearAllPoints()
        ReputationBar:SetPoint("TOPRIGHT", -3, -2)
        ReputationBar:SetPoint("BOTTOMLEFT", Button, "BOTTOMRIGHT", -102, 2)

        ReputationBar.AtWarHighlight2:SetAlpha(0)
        ReputationBar.AtWarHighlight1:SetAlpha(0)

        ReputationBar.LeftTexture:Hide()
        ReputationBar.RightTexture:Hide()

        ReputationBar.Highlight2:SetAlpha(0)
        ReputationBar.Highlight1:SetAlpha(0)
    end
end

function private.FrameXML.ReputationFrame()
    local ReputationFrame = _G.ReputationFrame
    ---------------------
    -- ReputationFrame --
    ---------------------

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

    if _G.ReputationFrame_OnShow then
        _G.hooksecurefunc("ReputationFrame_OnShow", Hook.ReputationFrame_OnShow)
    end
    if _G.ReputationFrame_SetRowType then
        _G.hooksecurefunc("ReputationFrame_SetRowType", Hook.ReputationFrame_SetRowType)
    end
    if _G.ReputationFrame_InitReputationRow then
        _G.hooksecurefunc("ReputationFrame_InitReputationRow", Hook.ReputationFrame_InitReputationRow)
    end
    if _G.ReputationFrame_Update then
        _G.hooksecurefunc("ReputationFrame_Update", Hook.ReputationFrame_Update)
    end

    local maxRows = _G.NUM_FACTIONS_DISPLAYED or 0
    for i = 1, maxRows do
        local factionRow = _G["ReputationBar"..i]
        if factionRow and not factionRow._auroraSkinned then
            Skin.ReputationBarTemplate(factionRow)
            factionRow._auroraSkinned = true
        end
    end
end
