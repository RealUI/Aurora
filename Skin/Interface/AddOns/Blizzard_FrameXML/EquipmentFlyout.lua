local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color = Aurora.Color

do --[[ FrameXML\EquipmentFlyout.lua ]]
    function Hook.EquipmentFlyout_CreateButton()
        Skin.EquipmentFlyoutButtonTemplate(_G.EquipmentFlyoutFrame.buttons[#_G.EquipmentFlyoutFrame.buttons])
    end
    function Hook.EquipmentFlyoutPopoutButton_SetReversed(self, isReversed)
        if self._auroraArrow and self:GetParent().verticalFlyout then
            if isReversed then
                Base.SetTexture(self._auroraArrow, "arrowUp")
            else
                Base.SetTexture(self._auroraArrow, "arrowDown")
            end
        else
            if isReversed then
                Base.SetTexture(self._auroraArrow, "arrowLeft")
            else
                Base.SetTexture(self._auroraArrow, "arrowRight")
            end
        end
    end
end

do --[[ FrameXML\EquipmentFlyout.xml ]]
    function Skin.EquipmentFlyoutButtonTemplate(ItemButton)
        Skin.FrameTypeItemButton(ItemButton)
    end
    function Skin.EquipmentFlyoutPopoutButtonTemplate(Button)
        local tex = Button:GetNormalTexture()
        Base.SetTexture(tex, "arrowRight")
        tex:SetVertexColor(Color.highlight:GetRGB())
        Button._auroraArrow = tex

        Button:ClearHighlightTexture()
    end
end

function private.FrameXML.EquipmentFlyout()
    -- EquipmentFlyout_CreateButton is available on both Mainline and Classic
    if _G.EquipmentFlyout_CreateButton then
        _G.hooksecurefunc("EquipmentFlyout_CreateButton", Hook.EquipmentFlyout_CreateButton)
    end
    if _G.EquipmentFlyoutPopoutButton_SetReversed then
        _G.hooksecurefunc("EquipmentFlyoutPopoutButton_SetReversed", Hook.EquipmentFlyoutPopoutButton_SetReversed)
    end

    if not _G.EquipmentFlyoutFrame then return end

    local highlight = _G.EquipmentFlyoutFrameHighlight
    if highlight then
        highlight:SetTexCoord(0.125, 0.65625, 0.125, 0.65625)
        highlight:ClearAllPoints()
        highlight:SetPoint("TOPLEFT", 3, -3)
        highlight:SetPoint("BOTTOMRIGHT", -3, 3)
    end

    local buttonFrame = _G.EquipmentFlyoutFrame.buttonFrame
    if buttonFrame then
        if buttonFrame.bg1 then
            buttonFrame.bg1:SetAlpha(0)
        end
        buttonFrame:DisableDrawLayer("ARTWORK")

        local bd = _G.CreateFrame("Frame", nil, buttonFrame)
        bd:SetPoint("TOPLEFT")
        bd:SetPoint("BOTTOMRIGHT", 3, -1)
        bd:SetFrameLevel(buttonFrame:GetFrameLevel())
        Skin.FrameTypeFrame(bd)

        -- NavigationFrame is Mainline-only (equipment set pagination)
        local NavigationFrame = _G.EquipmentFlyoutFrame.NavigationFrame
        if NavigationFrame then
            Skin.FrameTypeFrame(NavigationFrame)
            NavigationFrame:SetPoint("TOPLEFT", bd, "BOTTOMLEFT", 0, 1)
            NavigationFrame:SetPoint("TOPRIGHT", bd, "BOTTOMRIGHT", 0, 1)
            if NavigationFrame.BottomBackground then
                NavigationFrame.BottomBackground:Hide()
            end
            if NavigationFrame.PrevButton then
                Skin.NavButtonPrevious(NavigationFrame.PrevButton)
            end
            if NavigationFrame.NextButton then
                Skin.NavButtonNext(NavigationFrame.NextButton)
            end
        end
    end
end
