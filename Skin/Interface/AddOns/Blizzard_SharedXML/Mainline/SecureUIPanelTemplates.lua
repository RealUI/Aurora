local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals floor

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

--do --[[ FrameXML\SecureUIPanelTemplates.lua ]]
--end

do --[[ FrameXML\SecureUIPanelTemplates.xml ]]
    function Skin.LargeInputBoxTemplate(EditBox)
        Skin.FrameTypeEditBox(EditBox)
        EditBox:SetBackdropOption("offsets", {
            left = 3,
            right = 3,
            top = 2,
            bottom = 6,
        })

        EditBox.Left:Hide()
        EditBox.Right:Hide()
        EditBox.Middle:Hide()
    end

    function Skin.InputBoxTemplate(EditBox)
        Skin.FrameTypeEditBox(EditBox)

        -- This is a slightly fancy way of getting a consistent height from frames of variable height.
        local yOfs = floor(EditBox:GetHeight() / 2 + .5) - 10
        EditBox:SetBackdropOption("offsets", {
            left = -4,
            right = 1,
            top = yOfs,
            bottom = yOfs,
        })

        EditBox.Left:Hide()
        EditBox.Right:Hide()
        EditBox.Middle:Hide()
    end

    function Skin.ScrollFrameTemplate(ScrollFrame)
        if not ScrollFrame.noScrollBar then
            if ScrollFrame.scrollBarTemplate then
                Skin[ScrollFrame.scrollBarTemplate](ScrollFrame.ScrollBar)
            else
                Skin[_G.SCROLL_FRAME_SCROLL_BAR_TEMPLATE](ScrollFrame.ScrollBar)
            end
        end

        Base.SetBackdrop(ScrollFrame, Color.frame)
        ---ScrollFrame.ScrollBar:SetPoint("TOPLEFT", ScrollFrame, "TOPRIGHT", 2, -17)
        ---ScrollFrame.ScrollBar:SetPoint("BOTTOMLEFT", ScrollFrame, "BOTTOMRIGHT", 2, 17)
    end
    function Skin.InputScrollFrameTemplate(ScrollFrame)
        Skin.ScrollFrameTemplate(ScrollFrame)
    end
    function Skin.UIPanelButtonNoTooltipTemplate(Button)
        Skin.FrameTypeButton(Button)
        if Button.Left then
            Button.Left:SetAlpha(0)
            Button.Left:Hide()
            Button.Right:SetAlpha(0)
            Button.Right:Hide()
        end
        if Button.TopLeftCorner then
            Button.TopLeftCorner:SetAlpha(0)
            Button.TopRightCorner:Hide()
            Button.LeftEdge:SetAlpha(0)
            Button.RightEdge:Hide()
            Button.BottomLeftCorner:SetAlpha(0)
            Button.BottomRightCorner:Hide()
            Button.TopEdge:SetAlpha(0)
            Button.BottomEdge:Hide()
        end
        if Button.Middle then
            Button.Middle:SetAlpha(0)
            Button.Middle:Hide()
        end
    end
    function Skin.UIPanelButtonNoTooltipResizeToFitTemplate(Button)
        Skin.UIPanelButtonNoTooltipTemplate(Button)
    end
    function Skin.SelectionFrameTemplate(Frame)
        if private.isVanilla then
            Skin.FrameTypeFrame(Frame)
            Frame.TopLeft:ClearAllPoints()
            Frame.TopRight:ClearAllPoints()
            Frame.BottomLeft:ClearAllPoints()
            Frame.BottomRight:ClearAllPoints()
        else
            Skin.NineSlicePanelTemplate(Frame)
        end

        Skin.UIPanelButtonNoTooltipTemplate(Frame.CancelButton)
        Skin.UIPanelButtonNoTooltipTemplate(Frame.OkayButton)

        local bg = Frame:GetBackdropTexture("bg")
        Util.PositionRelative("BOTTOMRIGHT", bg, "BOTTOMRIGHT", -5, 5, 5, "Left", {
            Frame.CancelButton,
            Frame.OkayButton,
        })
    end
    function Skin.SecureDialogBorderNoCenterTemplate(Frame)
        Base.CreateBackdrop(Frame, private.backdrop, {
            tl = Frame.TopLeftCorner,
            tr = Frame.TopRightCorner,
            bl = Frame.BottomLeftCorner,
            br = Frame.BottomRightCorner,

            t = Frame.TopEdge,
            b = Frame.BottomEdge,
            l = Frame.LeftEdge,
            r = Frame.RightEdge,

            bg = Frame.Bg
        })

        Base.SetBackdrop(Frame, Color.frame, 0)
    end
    function Skin.SecureDialogBorderTemplate(Frame)
        Skin.SecureDialogBorderNoCenterTemplate(Frame)
        Skin.FrameTypeFrame(Frame)
    end
end

--function private.SharedXML.SecureUIPanelTemplates()
--end
