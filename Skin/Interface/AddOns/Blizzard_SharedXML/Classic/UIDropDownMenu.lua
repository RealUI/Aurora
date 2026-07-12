local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals type

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

--[[ Classic-family legacy UIDropDownMenu (era/TBC/Mists).
    Evidence: wow-ui-source-*/Interface/AddOns/Blizzard_SharedXML/Classic/UIDropDownMenu.xml
    and Classic/UIDropDownMenuTemplates.xml.
    Deltas vs the retail (Mainline) skin this was adapted from:
    - three DropDownList frames are predefined (retail: two)
    - each list predefines Button1-Button8 (retail: Button1 only)
    - the list dressing is $parentBackdrop (BACKDROP_DARK_DIALOG_32_32) and
      $parentMenuBackdrop (TooltipBackdropTemplate) - no .Border child
]]

-- Mirrors for UIDROPDOWNMENU_MAXLEVELS and UIDROPDOWNMENU_MAXBUTTONS; set by
-- the registration function from what the client's XML actually predefined
-- (era: 3 lists with 8 buttons each) so all classic flavors stay correct.
local skinnedLevels, skinnedButtons = 0, 0

do --[[ SharedXML\Classic\UIDropDownMenu.lua ]]
    function Hook.UIDropDownMenu_CreateFrames(level, index)
        while level > skinnedLevels do
            skinnedLevels = skinnedLevels + 1
            local listFrameName = "DropDownList"..skinnedLevels
            Skin.UIDropDownListTemplate(_G[listFrameName])
            for i = 1, skinnedButtons do
                Skin.UIDropDownMenuButtonTemplate(_G[listFrameName.."Button"..i])
            end
        end

        while index > skinnedButtons do
            skinnedButtons = skinnedButtons + 1
            for i = 1, skinnedLevels do
                local listFrameName = "DropDownList"..i
                Skin.UIDropDownMenuButtonTemplate(_G[listFrameName.."Button"..skinnedButtons])
            end
        end
    end
    function Hook.UIDropDownMenu_AddButton(info, level)
        if not level then level = 1 end

        local listFrameName = "DropDownList"..level
        local listFrame = _G[listFrameName]
        local index = listFrame.numButtons

        local menuButtonName = listFrameName.."Button"..index
        local menuButton = _G[menuButtonName]

        local checkBox = menuButton._auroraCheckBox
        if not checkBox then return end

        if not info.notCheckable then
            local check = checkBox.check

            checkBox:Show()
            check:SetTexCoord(0, 1, 0, 1)
            check:SetDesaturated(true)
            check:SetVertexColor(Color.highlight:GetRGB())
            if info.isNotRadio then
                checkBox:SetSize(12, 12)
                checkBox:SetPoint("LEFT")
                check:SetTexture([[Interface\Buttons\UI-CheckBox-Check]])
                check:SetSize(20, 20)
                check:SetAlpha(1)
            else
                checkBox:SetSize(8, 8)
                checkBox:SetPoint("LEFT", 4, 0)
                check:SetTexture(private.textures.plain)
                check:SetSize(6, 6)
                check:SetAlpha(0.6)
            end

            local checked = info.checked
            if type(checked) == "function" then
                checked = checked(menuButton)
            end

            if checked then
                check:Show()
            else
                check:Hide()
            end

            _G[menuButtonName.."UnCheck"]:Hide()
        else
            checkBox:Hide()
        end
    end
    function Hook.UIDropDownMenu_SetIconImage(icon, texture, info)
        if texture:find("Divider") then
            icon:SetColorTexture(1, 1, 1, .2) -- static: not a theme color
            icon:SetHeight(1)
        end
    end
    function Hook.UIDropDownMenuButton_OnClick(self)
        if not self._auroraCheckBox then return end

        if self.checked then
            self._auroraCheckBox.check:Show()
        else
            self._auroraCheckBox.check:Hide()
        end

        _G[self:GetName().."UnCheck"]:Hide()
    end

    function Hook.UIDropDownMenu_SetWidth(frame, width, padding)
        if frame.SetBackdropOption then
            local offsets = frame:GetBackdropOption("offsets")
            frame:SetBackdropOption("offsets", {
                left = offsets.left,
                right = 20,
                top = offsets.top,
                bottom = offsets.bottom,
            })
        end
    end

    function Hook.UIDropDownMenu_DisableDropDown(dropDown)
        if dropDown.Button.GetButtonColor then
            local _, disabledColor = dropDown.Button:GetButtonColor()
            Base.SetBackdropColor(dropDown, disabledColor)
        end
    end
    function Hook.UIDropDownMenu_EnableDropDown(dropDown)
        if dropDown.Button.GetButtonColor then
            Base.SetBackdropColor(dropDown, (dropDown.Button:GetButtonColor()))
        end
    end
end

do --[[ SharedXML\Classic\UIDropDownMenuTemplates.xml ]]
    function Skin.UIDropDownMenuButtonTemplate(Button)
        local listFrame = Button:GetParent()
        local name = Button:GetName()

        local highlight = _G[name.."Highlight"]
        highlight:ClearAllPoints()
        highlight:SetPoint("LEFT", listFrame, 6, 0)
        highlight:SetPoint("RIGHT", listFrame, -6, 0)
        highlight:SetPoint("TOP", 0, 0)
        highlight:SetPoint("BOTTOM", 0, 0)
        Util.SetHighlightColor(highlight, .2)

        local checkBox = _G.CreateFrame("Frame", nil, Button)
        checkBox:SetFrameLevel(Button:GetFrameLevel())
        Base.SetBackdrop(checkBox, Color.button)
        Button._auroraCheckBox = checkBox

        local check = _G[name.."Check"]
        check:SetDesaturated(true)
        check:SetVertexColor(Color.highlight:GetRGB())
        check:ClearAllPoints()
        check:SetPoint("CENTER", checkBox)
        checkBox.check = check

        local arrow = _G[name.."ExpandArrow"]
        arrow:SetSize(5, 10)
        arrow:SetPoint("RIGHT", -2, 0)
        Base.SetTexture(arrow:GetNormalTexture(), "arrowRight")

        Button:HookScript("OnClick", Hook.UIDropDownMenuButton_OnClick)
    end
    function Skin.UIDropDownListTemplate(Button)
        local name = Button:GetName()

        -- BACKDROP_DARK_DIALOG_32_32 dressing
        local backdrop = _G[name.."Backdrop"]
        if backdrop then
            Base.SetBackdrop(backdrop, Color.frame, 0.87)
        end

        local menuBackdrop = _G[name.."MenuBackdrop"]
        if menuBackdrop then
            Skin.TooltipBackdropTemplate(menuBackdrop)
        end

        local numButtons = 0
        while _G[name.."Button"..(numButtons + 1)] do
            numButtons = numButtons + 1
            Skin.UIDropDownMenuButtonTemplate(_G[name.."Button"..numButtons])
        end
        return numButtons
    end
    function Skin.UIDropDownMenuTemplate(Frame)
        local rightOfs = -105
        if _G.Round(Frame:GetWidth()) > 40 then
            -- Adjust offset when the frame is wider than the default
            rightOfs = 20
        end

        Base.SetBackdrop(Frame, Color.button)
        Frame:SetBackdropOption("offsets", {
            left = 21,
            right = rightOfs,
            top = 5,
            bottom = 9,
        })
        Frame._auroraWidth = nil

        Frame.Left:SetAlpha(0)
        Frame.Middle:SetAlpha(0)
        Frame.Right:SetAlpha(0)

        local Button = Frame.Button
        Skin.FrameTypeButton(Button)
        Button:SetBackdropOption("offsets", {
            left = 2,
            right = 4,
            top = 4,
            bottom = 2,
        })

        local bg = Frame:GetBackdropTexture("bg")
        Frame.Text:ClearAllPoints()
        Frame.Text:SetPoint("LEFT", bg, 3, 0)
        Frame.Text:SetPoint("RIGHT", bg, -20, 0)

        bg = Button:GetBackdropTexture("bg")
        local arrow = Button:CreateTexture(nil, "ARTWORK")
        arrow:SetPoint("TOPLEFT", bg, 3, -6)
        arrow:SetPoint("BOTTOMRIGHT", bg, -3, 5)
        Base.SetTexture(arrow, "arrowDown")
        Button._auroraTextures = {arrow}
    end
    function Skin.LargeUIDropDownMenuTemplate(Frame)
        Base.SetBackdrop(Frame, Color.frame)
        Frame:SetBackdropBorderColor(Color.button)
        Frame:SetBackdropOption("offsets", {
            left = 4,
            right = 4,
            top = 2,
            bottom = 7,
        })

        Skin.FrameTypeButton(Frame.Button)
        Frame.Button:SetBackdropOption("offsets", {
            left = 4,
            right = 0,
            top = 1,
            bottom = 2,
        })

        local bg = Frame.Button:GetBackdropTexture("bg")
        local arrow = Frame.Button:CreateTexture(nil, "ARTWORK")
        arrow:SetPoint("TOPLEFT", bg, 4, -8)
        arrow:SetPoint("BOTTOMRIGHT", bg, -4, 7)
        Base.SetTexture(arrow, "arrowDown")
        Frame.Button._auroraTextures = {arrow}

        Frame.Left:Hide()
        Frame.Right:Hide()
        Frame.Middle:Hide()
    end
end

function private.SharedXML.UIDropDownMenu()
    _G.hooksecurefunc("UIDropDownMenu_CreateFrames", Hook.UIDropDownMenu_CreateFrames)
    _G.hooksecurefunc("UIDropDownMenu_AddButton", Hook.UIDropDownMenu_AddButton)
    _G.hooksecurefunc("UIDropDownMenu_SetIconImage", Hook.UIDropDownMenu_SetIconImage)
    _G.hooksecurefunc("UIDropDownMenu_SetWidth", Hook.UIDropDownMenu_SetWidth)
    _G.hooksecurefunc("UIDropDownMenu_DisableDropDown", Hook.UIDropDownMenu_DisableDropDown)
    _G.hooksecurefunc("UIDropDownMenu_EnableDropDown", Hook.UIDropDownMenu_EnableDropDown)

    while _G["DropDownList"..(skinnedLevels + 1)] do
        skinnedLevels = skinnedLevels + 1
        skinnedButtons = Skin.UIDropDownListTemplate(_G["DropDownList"..skinnedLevels])
    end
end
