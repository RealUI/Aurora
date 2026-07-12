local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color = Aurora.Color
-- local Util = Aurora.Util

do --[[ AddOns\Blizzard_TokenUI\Blizzard_TokenUI.xml ]]
    function Skin.TokenButtonTemplate(Button)
        local stripe = Button.Stripe
        stripe:SetPoint("TOPLEFT", 1, 1)
        stripe:SetPoint("BOTTOMRIGHT", -1, -1)

        Button.Icon.bg = Base.CropIcon(Button.Icon, Button)

        Button.CategoryLeft:SetAlpha(0)
        Button.CategoryRight:SetAlpha(0)
        Button.CategoryMiddle:SetAlpha(0)
        Skin.FrameTypeButton(Button)

        Button.ExpandIcon:SetTexture("")
        local minus = Button:CreateTexture(nil, "ARTWORK")
        minus:SetSize(7, 1)
        minus:SetPoint("LEFT", 8, 0)
        minus:SetColorTexture(1, 1, 1) -- static: not a theme color
        minus:Hide()
        Button._auroraMinus = minus

        local plus = Button:CreateTexture(nil, "ARTWORK")
        plus:SetSize(1, 7)
        plus:SetPoint("LEFT", 11, 0)
        plus:SetColorTexture(1, 1, 1) -- static: not a theme color
        plus:Hide()
        Button._auroraPlus = plus
        if not Button._auroraSkinned then
            Button._auroraSkinned = true
        end
    end
    function Skin.BackpackTokenTemplate(Button)
        Base.CropIcon(Button.Icon, Button)
        Button.Count:SetPoint("RIGHT", Button.Icon, "LEFT", -2, 0)
    end

    local function SecureUpdateCollapse(texture, atlas)
        if not atlas then
            local parent = texture:GetParent()
            if parent:IsCollapsed() then
                texture:SetAtlas('Soulbinds_Collection_CategoryHeader_Expand')
            else
                texture:SetAtlas('Soulbinds_Collection_CategoryHeader_Collapse')
            end
        end
    end
    local function SecureUpdateCurrencyScrollBoxEntries(entry)
        if not entry._auroraSkinned then
            if entry.Right then
                Base.SetBackdrop(entry, Color.button)
                SecureUpdateCollapse(entry.Right)
                SecureUpdateCollapse(entry.HighlightRight)
                _G.hooksecurefunc(entry.Right, 'SetAtlas', SecureUpdateCollapse)
                _G.hooksecurefunc(entry.HighlightRight, 'SetAtlas', SecureUpdateCollapse)
            end
            local icon = entry.Content and entry.Content.CurrencyIcon
            if icon then
                Base.CropIcon(icon)
            end
            entry._auroraSkinned = true
        end
    end
    function Hook.UpdateCurrencyScrollBox(frame)
        frame:ForEachFrame(SecureUpdateCurrencyScrollBoxEntries)
    end
end

function private.FrameXML.Blizzard_TokenUI()
    local TokenFrame = _G.TokenFrame
    Skin.WowScrollBoxList(TokenFrame.ScrollBox)
    _G.hooksecurefunc(TokenFrame.ScrollBox, 'Update', Hook.UpdateCurrencyScrollBox)
    Hook.UpdateCurrencyScrollBox(TokenFrame.ScrollBox)
    TokenFrame.ScrollBox:SetPoint("TOPLEFT", _G.CharacterFrame.Inset, 4, -35)
    Skin.DropdownButton(TokenFrame.filterDropdown)
    TokenFrame.filterDropdown:ClearAllPoints()
    TokenFrame.filterDropdown:SetPoint("TOPLEFT", 18,  -30)
    TokenFrame.CurrencyTransferLogToggleButton:SetPoint("TOPRIGHT", -10, -30)

    local TokenFramePopup = _G.TokenFramePopup
    Skin.SecureDialogBorderTemplate(TokenFramePopup.Border)
    TokenFramePopup:SetSize(175, 90)
    local titleText = TokenFramePopup.Title
    titleText:ClearAllPoints()
    titleText:SetPoint("TOPLEFT")
    titleText:SetPoint("BOTTOMRIGHT", TokenFramePopup, "TOPRIGHT", 0, -private.FRAME_TITLE_HEIGHT)
    Skin.UICheckButtonTemplate(TokenFramePopup.InactiveCheckbox)
    TokenFramePopup.InactiveCheckbox:SetPoint("TOPLEFT", TokenFramePopup, 24, -26)
    Skin.UICheckButtonTemplate(TokenFramePopup.BackpackCheckbox)
    TokenFramePopup.BackpackCheckbox:SetPoint("TOPLEFT", TokenFramePopup.InactiveCheckbox, "BOTTOMLEFT", 0, -8)
    Skin.UIPanelButtonTemplate(TokenFramePopup.CurrencyTransferToggleButton)
    TokenFramePopup.CurrencyTransferToggleButton:SetPoint("TOPLEFT", TokenFramePopup.BackpackCheckbox, "BOTTOMLEFT", 0, -8)
    Skin.UIPanelCloseButton(TokenFramePopup["$parent.CloseButton"])

    local CurrencyTransferMenu = _G.CurrencyTransferMenu
    Skin.DialogBorderNoCenterTemplate(CurrencyTransferMenu.NineSlice)
    Skin.UIPanelButtonTemplate(CurrencyTransferMenu.Content.AmountSelector.MaxQuantityButton)
    Skin.InputBoxTemplate(CurrencyTransferMenu.Content.AmountSelector.InputBox)
    Skin.UIPanelButtonTemplate(CurrencyTransferMenu.Content.ConfirmButton)
    Skin.UIPanelButtonTemplate(CurrencyTransferMenu.Content.CancelButton)
    Skin.UIPanelCloseButton(CurrencyTransferMenu.CloseButton)
    Skin.DropdownButton(CurrencyTransferMenu.Content.SourceSelector.Dropdown)
end
