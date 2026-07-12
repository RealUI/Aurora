local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals select ipairs pairs

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

-- local constants
local CALENDAR_MAX_DAYS_PER_MONTH = 42 -- 6 weeks

-- DayButton constants
local CALENDAR_DAYBUTTON_MAX_VISIBLE_EVENTS = 4

do --[[ AddOns\Blizzard_Calendar.lua ]]
    function Hook.CalendarEventInviteList_UpdateSortButtons(inviteList)
        local criterion, reverse = _G.C_Calendar.EventGetInviteSortCriterion()
        for index, button in pairs(inviteList.sortButtons) do
            local direction = _G[button:GetName().."Direction"];
            if button.criterion == criterion then
                if reverse then
                    Base.SetTexture(direction, "arrowDown")
                else
                    Base.SetTexture(direction, "arrowUp")
                end
            end
        end
    end
    function Hook.CalendarClassButtonContainer_Update()
        for i = 1, _G.MAX_CLASSES do
            local button = _G["CalendarClassButton"..i]
            local buttonIcon = button:GetNormalTexture()
            if buttonIcon:IsDesaturated() then
                buttonIcon._auroraBorder:SetColorTexture(Color.gray:GetRGB())
            else
                buttonIcon._auroraBorder:SetColorTexture(_G.CUSTOM_CLASS_COLORS[button.class]:GetRGB())
            end
        end
    end
end

do --[[ AddOns\Blizzard_Calendar.xml ]]
    -- Calendar Day Templates
    function Skin.CalendarDayButtonTemplate(Button)
        Base.SetBackdrop(Button, Color.black, 0)

        local moreEvents = _G[Button:GetName().."MoreEventsButton"]
        moreEvents:SetSize(14, 7)
        moreEvents:SetPoint("TOPRIGHT", -6, -9)
        Base.SetTexture(moreEvents:GetNormalTexture(), "arrowDown")

        Button:ClearNormalTexture()
        local highlight = Button:GetHighlightTexture()
        Util.SetHighlightColor(highlight, 0.5)
        highlight:ClearAllPoints()
        highlight:SetPoint("TOPLEFT", 1, -1)
        highlight:SetPoint("BOTTOMRIGHT", -1, 1)
    end
    function Skin.CalendarDayEventButtonTemplate(Button)
        local black = Button.black
        black:SetColorTexture(Color.black:GetRGB())
        black:SetPoint("TOPLEFT", -2, 0)
        black:SetPoint("BOTTOMRIGHT", 2, 0)

        local highlight = Button:GetHighlightTexture()
        Util.SetHighlightColor(highlight, 0.2)
        highlight:SetPoint("TOPLEFT", -3, 1)
        highlight:SetPoint("BOTTOMRIGHT", 3, -1)
    end

    -- Calendar Misc Templates
    function Skin.CalendarCloseButtonTemplate(Button)
        Skin.UIPanelCloseButton(Button)
        select(5, Button:GetRegions()):Hide()
    end

    -- Calendar Event Templates
    function Skin.CalendarEventButtonTemplate(Button)
        Skin.UIPanelButtonTemplate(Button)
    end
    function Skin.CalendarEventCloseButtonTemplate(Button)
        Skin.CalendarCloseButtonTemplate(Button)
    end
    function Skin.CalendarEventInviteSortButtonTemplate(Button)
        local arrow = Button:GetRegions()
        arrow:SetSize(10, 5)
        arrow:SetPoint("RIGHT", 2, 0)
    end
    function Skin.CalendarEventInviteListTemplate(Frame)
        Util.HideNineSlice(Frame)
        Skin.WowScrollBoxList(Frame.ScrollBox)
        Skin.MinimalScrollBar(Frame.ScrollBar)

        local name = Frame:GetName()
        Skin.CalendarEventInviteSortButtonTemplate(_G[name.."NameSortButton"])
        Skin.CalendarEventInviteSortButtonTemplate(_G[name.."ClassSortButton"])
        Skin.CalendarEventInviteSortButtonTemplate(_G[name.."StatusSortButton"])
    end

    -- Calendar View Event Templates
    function Skin.CalendarViewEventRSVPButtonTemplate(Button)
        Skin.CalendarEventButtonTemplate(Button)
    end

    -- Calendar Modal Dialog Templates
    function Skin.CalendarModalEventOverlayTemplate(Frame)
        Frame:GetRegions():SetColorTexture(Color.panelBg.r, Color.panelBg.g, Color.panelBg.b, 0.7)
    end

    -- Calendar Class Templates
    function Skin.CalendarClassButtonTemplate(Button)
        Button:GetRegions():Hide()

        local icon = Button:GetNormalTexture()
        icon:SetPoint("TOPLEFT", 1, -1)
        icon:SetPoint("BOTTOMRIGHT", -1, 1)
        Base.SetTexture(icon, "icon"..Button.class)
    end
end

function private.AddOns.Blizzard_Calendar()
    _G.hooksecurefunc("CalendarEventInviteList_UpdateSortButtons", Hook.CalendarEventInviteList_UpdateSortButtons)
    _G.hooksecurefunc("CalendarClassButtonContainer_Update", Hook.CalendarClassButtonContainer_Update)

    -------------------
    -- CalendarFrame --
    -------------------
    Skin.FrameTypeFrame(_G.CalendarFrame)
    _G.CalendarFrame:SetBackdropOption("offsets", {
        left = 11,
        right = 9,
        top = 0,
        bottom = 3
    })

    local calenderBG = _G.CalendarFrame:GetBackdropTexture("bg")
    _G.CalendarFrameTopLeftTexture:Hide()
    _G.CalendarFrameTopMiddleTexture:Hide()
    _G.CalendarFrameTopRightTexture:Hide()
    _G.CalendarFrameLeftTopTexture:Hide()
    _G.CalendarFrameLeftMiddleTexture:Hide()
    _G.CalendarFrameLeftBottomTexture:Hide()
    _G.CalendarFrameRightTopTexture:Hide()
    _G.CalendarFrameRightMiddleTexture:Hide()
    _G.CalendarFrameRightBottomTexture:Hide()
    _G.CalendarFrameBottomLeftTexture:Hide()
    _G.CalendarFrameBottomMiddleTexture:Hide()
    _G.CalendarFrameBottomRightTexture:Hide()

    for i = 1, 7 do
        _G["CalendarWeekday"..i.."Background"]:SetColorTexture(Color.grayDark:GetRGB())
    end

    _G.CalendarMonthBackground:Hide()
    _G.CalendarYearBackground:Hide()

    Util.SetHighlightColor(_G.CalendarWeekdaySelectedTexture, 0.2)
    _G.CalendarWeekdaySelectedTexture:SetSize(91, 28)

    _G.CalendarTodayFrame:SetScript("OnUpdate", nil)
    Base.CreateBackdrop(_G.CalendarTodayFrame, {
        edgeSize = 4,
        offsets = {
            left = 24,
            right = 24,
            top = 22,
            bottom = 21
        },
    })
    Base.SetBackdropColor(_G.CalendarTodayFrame, Color.highlight, 0)

    _G.CalendarTodayTextureGlow:Hide()
    _G.CalendarTodayTexture:Hide()

    Skin.NavButtonPrevious(_G.CalendarPrevMonthButton)
    Skin.NavButtonNext(_G.CalendarNextMonthButton)

    do -- Filter button
        local button = _G.CalendarFrame.FilterButton
        Skin.FilterButton(button)
        button:ClearAllPoints()
        button:SetPoint("TOPRIGHT", -80, -13)
    end

    Skin.UIPanelCloseButton(_G.CalendarCloseButton)
    _G.CalendarCloseButton:SetPoint("TOPRIGHT", calenderBG, -5, -5)
    Skin.CalendarModalEventOverlayTemplate(_G.CalendarFrameModalOverlay)

    for i = 1, CALENDAR_MAX_DAYS_PER_MONTH do
        local buttonName = "CalendarDayButton"..i
        Skin.CalendarDayButtonTemplate(_G[buttonName])

        local eventButtonPrefix = buttonName.."EventButton"
        for j = 1, CALENDAR_DAYBUTTON_MAX_VISIBLE_EVENTS do
            Skin.CalendarDayEventButtonTemplate(_G[eventButtonPrefix..j])
        end
    end


    ------------------
    -- View Holiday --
    ------------------
    local CalendarViewHolidayFrame = _G.CalendarViewHolidayFrame
    CalendarViewHolidayFrame.Texture:SetAlpha(0)
    Skin.DialogBorderDarkTemplate(CalendarViewHolidayFrame.Border)
    Skin.DialogHeaderTemplate(CalendarViewHolidayFrame.Header)
    Skin.ScrollingFontTemplate(CalendarViewHolidayFrame.ScrollingFont)
    Skin.CalendarEventCloseButtonTemplate(_G.CalendarViewHolidayCloseButton)
    Skin.CalendarModalEventOverlayTemplate(_G.CalendarViewHolidayFrameModalOverlay)


    ---------------
    -- View Raid --
    ---------------
    local CalendarViewRaidFrame = _G.CalendarViewRaidFrame
    Skin.DialogBorderDarkTemplate(CalendarViewRaidFrame.Border)
    Skin.DialogHeaderTemplate(CalendarViewRaidFrame.Header)
    Skin.ScrollingFontTemplate(CalendarViewRaidFrame.ScrollingFont)
    Skin.CalendarEventCloseButtonTemplate(_G.CalendarViewRaidCloseButton)
    Skin.CalendarModalEventOverlayTemplate(_G.CalendarViewRaidFrameModalOverlay)


    ----------------
    -- View Event --
    ----------------
    local CalendarViewEventFrame = _G.CalendarViewEventFrame
    Skin.DialogBorderDarkTemplate(CalendarViewEventFrame.Border)
    Skin.DialogHeaderTemplate(CalendarViewEventFrame.Header)
    Util.HideNineSlice(_G.CalendarViewEventDescriptionContainer)
    Skin.ScrollingFontTemplate(_G.CalendarViewEventDescriptionContainer.ScrollingFont)
    Skin.MinimalScrollBar(_G.CalendarViewEventDescriptionContainer.ScrollBar)
    _G.CalendarViewEventDivider:Hide()
    Skin.CalendarViewEventRSVPButtonTemplate(_G.CalendarViewEventAcceptButton)
    Skin.CalendarViewEventRSVPButtonTemplate(_G.CalendarViewEventTentativeButton)
    Skin.CalendarViewEventRSVPButtonTemplate(_G.CalendarViewEventDeclineButton)
    Skin.CalendarEventButtonTemplate(_G.CalendarViewEventRemoveButton)
    Skin.CalendarEventInviteListTemplate(_G.CalendarViewEventInviteList)
    Skin.CalendarEventCloseButtonTemplate(_G.CalendarViewEventCloseButton)
    Skin.CalendarModalEventOverlayTemplate(_G.CalendarViewEventFrameModalOverlay)


    -----------------------
    -- Create/Edit Event --
    -----------------------
    _G.CalendarCreateEventFrameButtonBackground:Hide()
    Skin.DialogBorderDarkTemplate(_G.CalendarCreateEventFrame.Border)
    Skin.DialogHeaderTemplate(_G.CalendarCreateEventFrame.Header)
    Skin.InputBoxTemplate(_G.CalendarCreateEventTitleEdit)
    Skin.DropdownButton(_G.CalendarCreateEventFrame.EventTypeDropdown)
    Skin.DropdownButton(_G.CalendarCreateEventFrame.HourDropdown)
    Skin.DropdownButton(_G.CalendarCreateEventFrame.MinuteDropdown)
    Skin.DropdownButton(_G.CalendarCreateEventFrame.AMPMDropdown)
    Skin.DropdownButton(_G.CalendarCreateEventFrame.DifficultyOptionDropdown)
    Skin.DropdownButton(_G.CalendarCreateEventFrame.CommunityDropdown)
    _G.CalendarCreateEventDivider:Hide()
    Skin.UICheckButtonTemplate(_G.CalendarCreateEventAutoApproveCheck)
    Skin.UICheckButtonTemplate(_G.CalendarCreateEventLockEventCheck)
    Skin.CalendarEventInviteListTemplate(_G.CalendarCreateEventInviteList)
    Skin.InputBoxTemplate(_G.CalendarCreateEventInviteEdit)
    Skin.UIPanelButtonTemplate(_G.CalendarCreateEventInviteButton)
    Util.HideNineSlice(_G.CalendarCreateEventDescriptionContainer)
    Skin.ScrollingEditBoxTemplate(_G.CalendarCreateEventDescriptionContainer.ScrollingEditBox)
    Skin.MinimalScrollBar(_G.CalendarCreateEventDescriptionContainer.ScrollBar)
    Skin.UIPanelButtonTemplate(_G.CalendarCreateEventMassInviteButton)
    _G.CalendarCreateEventMassInviteButtonBorder:Hide()
    Skin.UIPanelButtonTemplate(_G.CalendarCreateEventRaidInviteButton)
    _G.CalendarCreateEventRaidInviteButtonBorder:Hide()
    Skin.CalendarEventButtonTemplate(_G.CalendarCreateEventCreateButton)
    _G.CalendarCreateEventCreateButtonBorder:Hide()
    Skin.CalendarEventCloseButtonTemplate(_G.CalendarCreateEventCloseButton)
    Skin.CalendarModalEventOverlayTemplate(_G.CalendarCreateEventFrameModalOverlay)
    _G.CalendarCreateEventFrameModalOverlay:SetAllPoints()


    -----------------
    -- Mass Invite --
    -----------------
    _G.CalendarMassInviteFrame:SetPoint("BOTTOMRIGHT", _G.CalendarCreateEventMassInviteButton, "TOPRIGHT", 160, 4)
    Skin.DialogBorderDarkTemplate(_G.CalendarMassInviteFrame.Border)
    Skin.DialogHeaderTemplate(_G.CalendarMassInviteFrame.Header)
    Skin.InputBoxTemplate(_G.CalendarMassInviteMinLevelEdit)
    Skin.InputBoxTemplate(_G.CalendarMassInviteMaxLevelEdit)
    Skin.DropdownButton(_G.CalendarMassInviteFrame.RankDropdown)
    Skin.CalendarEventButtonTemplate(_G.CalendarMassInviteAcceptButton)
    Skin.CalendarCloseButtonTemplate(_G.CalendarMassInviteCloseButton)
    Skin.CalendarModalEventOverlayTemplate(_G.CalendarMassInviteFrameModalOverlay)


    ------------------
    -- Event Picker --
    ------------------
    local CalendarEventPickerFrame = _G.CalendarEventPickerFrame
    Skin.DialogBorderDarkTemplate(CalendarEventPickerFrame.Border)
    _G.CalendarEventPickerFrameButtonBackground:Hide()
    Skin.DialogHeaderTemplate(CalendarEventPickerFrame.Header)
    Skin.WowScrollBoxList(CalendarEventPickerFrame.ScrollBox)
    Skin.MinimalScrollBar(CalendarEventPickerFrame.ScrollBar)
    Skin.CalendarEventButtonTemplate(_G.CalendarEventPickerCloseButton)
    _G.CalendarEventPickerCloseButtonBorder:Hide()


    --------------------
    -- Texture Picker --
    --------------------
    local CalendarTexturePickerFrame = _G.CalendarTexturePickerFrame
    CalendarTexturePickerFrame:ClearAllPoints()
    CalendarTexturePickerFrame:SetPoint("TOPRIGHT", _G.CalendarCreateEventTypeDropDown, "BOTTOMRIGHT", -4, 0)
    Skin.DialogBorderDarkTemplate(CalendarTexturePickerFrame.Border)
    _G.CalendarTexturePickerFrameButtonBackground:Hide()
    Skin.DialogHeaderTemplate(CalendarTexturePickerFrame.Header)
    Skin.WowScrollBoxList(CalendarEventPickerFrame.ScrollBox)
    Skin.MinimalScrollBar(CalendarEventPickerFrame.ScrollBar)
    Skin.CalendarEventButtonTemplate(_G.CalendarTexturePickerCancelButton)
    _G.CalendarTexturePickerCancelButtonBorder:Hide()
    Skin.CalendarEventButtonTemplate(_G.CalendarTexturePickerAcceptButton)
    _G.CalendarTexturePickerAcceptButtonBorder:Hide()


    -------------------
    -- Class Buttons --
    -------------------
    for i = 1, _G.MAX_CLASSES do
        local button = _G["CalendarClassButton"..i]
        Skin.CalendarClassButtonTemplate(button)
        if i == 1 then
            button:SetPoint("TOPLEFT", 5, 0)
        else
            button:SetPoint("TOPLEFT", "CalendarClassButton"..(i-1), "BOTTOMLEFT", 0, -10)
        end
    end

    Base.SetBackdrop(_G.CalendarClassTotalsButton, Color.button)
    local classTotalBG = _G.CalendarClassTotalsButton:GetBackdropTexture("bg")
    classTotalBG:SetPoint("TOPLEFT", 0, 2)
    classTotalBG:SetPoint("BOTTOMRIGHT", 0, -2)
    _G.CalendarClassTotalsButtonBackgroundMiddle:Hide()
    _G.CalendarClassTotalsButtonBackgroundTop:Hide()
    _G.CalendarClassTotalsButtonBackgroundBottom:Hide()
    --_G.CalendarClassTotalsButton:SetPoint("TOPLEFT", "CalendarClassButton".._G.MAX_CLASSES, "BOTTOMLEFT", 0, -10)
end
