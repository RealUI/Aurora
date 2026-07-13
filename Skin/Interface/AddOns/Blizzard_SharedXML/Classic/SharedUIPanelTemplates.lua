local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals tinsert

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

--[[ Classic-family SharedUIPanelTemplates (era/TBC/Mists).
    Evidence: wow-ui-source-*/Interface/AddOns/Blizzard_SharedXML/Classic/SharedUIPanelTemplates.xml
    PortraitFrameTemplate/ButtonFrameTemplate here are the legacy named-texture
    implementation layered over an inert NineSlice base (no PortraitFrameTemplate
    layout in Classic NineSliceLayouts). InsetFrameTemplate, DefaultPanel*, and
    Dialog* do have live NineSlice layouts.
]]

do --[[ SharedXML\SharedUIPanelTemplates.lua ]]
    local resizing = false
    function Hook.PanelTemplates_TabResize(tab, padding, absoluteSize, minWidth, maxWidth, absoluteTextSize)
        if not tab._auroraTabResize or resizing then return end

        resizing = true
        -- TabResize computes sideWidths as 2 * Left:GetWidth(); with the art
        -- hidden this is pure padding around the text. Skins can tune it per
        -- tab via _auroraSideWidth (visible padding = 2*sideWidth - backdrop
        -- insets).
        local left = tab.Left or tab.leftTexture or _G[tab:GetName().."Left"]
        left:SetWidth(tab._auroraSideWidth or 10)
        _G.PanelTemplates_TabResize(tab, padding, absoluteSize, minWidth, maxWidth, absoluteTextSize)
        resizing = false

        -- On the very first show the font string has not rendered yet, so
        -- TabResize measures a stale text width and truncates. Re-run once
        -- on the next frame, after the text has a real width.
        if not tab._auroraResizeRetried then
            tab._auroraResizeRetried = true
            _G.C_Timer.After(0, function()
                if tab:IsVisible() then
                    Hook.PanelTemplates_TabResize(tab, padding, absoluteSize, minWidth, maxWidth, absoluteTextSize)
                end
            end)
        end
    end
    function Hook.PanelTemplates_DeselectTab(tab)
        local text = tab.Text or _G[tab:GetName().."Text"]
        text:SetPoint("CENTER", tab, "CENTER")
    end
    function Hook.PanelTemplates_SelectTab(tab)
        local text = tab.Text or _G[tab:GetName().."Text"]
        text:SetPoint("CENTER", tab, "CENTER")
    end
end

do --[[ SharedXML\SharedUIPanelTemplates.lua - nav buttons ]]
    local function NavButton(Button)
        Skin.FrameTypeButton(Button)
        Button:SetBackdropOption("offsets", {
            left = 5,
            right = 5,
            top = 5,
            bottom = 5,
        })

        local bg = Button:GetBackdropTexture("bg")
        local arrow = Button:CreateTexture(nil, "ARTWORK")
        arrow:SetPoint("TOPLEFT", bg, 8, -5)
        arrow:SetPoint("BOTTOMRIGHT", bg, -8, 5)
        Button._auroraTextures = {arrow}

        return arrow
    end
    function Skin.NavButtonPrevious(Button)
        local arrow = NavButton(Button)
        Base.SetTexture(arrow, "arrowLeft")
    end
    function Skin.NavButtonNext(Button)
        local arrow = NavButton(Button)
        Base.SetTexture(arrow, "arrowRight")
    end
end

do --[[ SharedXML\SharedUIPanelTemplates.xml ]]
    function Skin.UIPanelCloseButtonNoScripts(Button)
        Skin.FrameTypeButton(Button)
        Button:SetBackdropOption("offsets", {
            left = 4,
            right = 11,
            top = 10,
            bottom = 5,
        })

        local bg = Button:GetBackdropTexture("bg")
        local cross = {}
        for i = 1, 2 do
            local line = Button:CreateLine(nil, "ARTWORK")
            line:SetColorTexture(1, 1, 1) -- static: not a theme color
            line:SetThickness(1.2)
            line:Show()
            if i == 1 then
                line:SetStartPoint("TOPLEFT", bg, 3.6, -3)
                line:SetEndPoint("BOTTOMRIGHT", bg, -3, 3)
            else
                line:SetStartPoint("TOPRIGHT", bg, -3, -3)
                line:SetEndPoint("BOTTOMLEFT", bg, 3.6, 3)
            end
            tinsert(cross, line)
        end

        Button._auroraTextures = cross
    end
    function Skin.UIPanelCloseButton(Button)
        Skin.UIPanelCloseButtonNoScripts(Button)
    end
    function Skin.UIPanelCloseButtonDefaultAnchors(Button)
        Skin.UIPanelCloseButton(Button)
        Button:SetPoint("TOPRIGHT", 1.2, 0)
    end

    -- TAINT-SAFE button skin (widget API only — no FrameTypeButton table
    -- writes). For buttons whose OnClick chains into protected calls, e.g.
    -- static popup accept buttons. Same implementation as the Mainline layer.
    function Skin.TaintSafeUIPanelButtonTemplate(Button)
        if not Button then return end
        if Button.ClearNormalTexture then
            Button:ClearNormalTexture()
            Button:ClearPushedTexture()
            Button:ClearDisabledTexture()
            local hl = Button:GetHighlightTexture()
            if hl then hl:Hide() end
        elseif Button.SetNormalTexture then
            Button:SetNormalTexture("")
            Button:SetPushedTexture("")
            Button:SetHighlightTexture("")
            Button:SetDisabledTexture("")
        end
        if Button.Left then Button.Left:SetAlpha(0) end
        if Button.Right then Button.Right:SetAlpha(0) end
        if Button.Middle then Button.Middle:SetAlpha(0) end
        if Button.TopLeftCorner then Button.TopLeftCorner:SetAlpha(0) end
        if Button.TopRightCorner then Button.TopRightCorner:Hide() end
        if Button.LeftEdge then Button.LeftEdge:SetAlpha(0) end
        if Button.RightEdge then Button.RightEdge:Hide() end
        if Button.BottomLeftCorner then Button.BottomLeftCorner:SetAlpha(0) end
        if Button.BottomRightCorner then Button.BottomRightCorner:Hide() end
        if Button.TopEdge then Button.TopEdge:SetAlpha(0) end
        if Button.BottomEdge then Button.BottomEdge:Hide() end
        Button:SetNormalTexture("Interface\\Buttons\\White8x8")
        Button:GetNormalTexture():SetVertexColor(Color.button:GetRGB())
        Button:SetPushedTexture("Interface\\Buttons\\White8x8")
        Button:GetPushedTexture():SetVertexColor(Color.border:GetRGB())
        Button:SetDisabledTexture("Interface\\Buttons\\White8x8")
        Button:GetDisabledTexture():SetVertexColor(Color.border.r, Color.border.g, Color.border.b, 0.5)
        Button:SetHighlightTexture("Interface\\Buttons\\White8x8", "ADD")
        Button:GetHighlightTexture():SetVertexColor(1, 1, 1) -- static: not a theme color
        Button:GetHighlightTexture():SetAlpha(0.25)
        if Button.LeftSeparator then Button.LeftSeparator:Hide() end
        if Button.RightSeparator then Button.RightSeparator:Hide() end
    end

    function Skin.UIPanelButtonNoTooltipTemplate(Button)
        Skin.FrameTypeButton(Button)
        Button.Left:SetAlpha(0)
        Button.Middle:SetAlpha(0)
        Button.Right:SetAlpha(0)
    end
    function Skin.UIPanelButtonTemplate(Button)
        Skin.UIPanelButtonNoTooltipTemplate(Button)
    end
    function Skin.UIPanelDynamicResizeButtonTemplate(Button)
        Skin.UIPanelButtonTemplate(Button)
    end
    function Skin.MagicButtonTemplate(Button)
        Skin.UIPanelButtonTemplate(Button)

        if Button.LeftSeparator then
            Button.LeftSeparator:Hide()
        end
        if Button.RightSeparator then
            Button.RightSeparator:Hide()
        end
    end

    function Skin.UIRadioButtonTemplate(CheckButton)
        Skin.FrameTypeCheckButton(CheckButton)
        CheckButton:SetBackdropOption("offsets", {
            left = 4,
            right = 4,
            top = 4,
            bottom = 4,
        })

        local bg = CheckButton:GetBackdropTexture("bg")
        local check = CheckButton:GetCheckedTexture()
        check:ClearAllPoints()
        check:SetPoint("TOPLEFT", bg, 1, -1)
        check:SetPoint("BOTTOMRIGHT", bg, -1, 1)
        Util.SetHighlightColor(check)
    end
    function Skin.UICheckButtonTemplate(CheckButton)
        Skin.FrameTypeCheckButton(CheckButton)
        CheckButton:SetBackdropOption("offsets", {
            left = 6,
            right = 6,
            top = 6,
            bottom = 6,
        })

        local bg = CheckButton:GetBackdropTexture("bg")
        local check = CheckButton:GetCheckedTexture()
        check:ClearAllPoints()
        check:SetPoint("TOPLEFT", bg, -6, 6)
        check:SetPoint("BOTTOMRIGHT", bg, 6, -6)
        check:SetDesaturated(true)
        check:SetVertexColor(Color.highlight:GetRGB())

        local disabled = CheckButton:GetDisabledCheckedTexture()
        if disabled then
            disabled:SetAllPoints(check)
        end
    end

    -- Classic-wide EditBox enhancements: with the parchment input art gone,
    -- dark-on-dark boxes need a focus cue, and text sits flush against the
    -- backdrop edge without insets. Wraps the core helper (classic clients
    -- only — this file never loads on retail).
    do
        local CoreFrameTypeEditBox = Skin.FrameTypeEditBox
        local function OnFocusGained(self)
            if self.SetBackdropBorderColor then
                self:SetBackdropBorderColor(Color.highlight)
            end
        end
        local function OnFocusLost(self)
            if self.SetBackdropBorderColor then
                self:SetBackdropBorderColor(Color.button)
            end
        end
        function Skin.FrameTypeEditBox(EditBox)
            CoreFrameTypeEditBox(EditBox)

            local left = EditBox:GetTextInsets()
            if left == 0 then
                EditBox:SetTextInsets(5, 5, 0, 0)
            end

            EditBox:HookScript("OnEditFocusGained", OnFocusGained)
            EditBox:HookScript("OnEditFocusLost", OnFocusLost)
        end
    end

    function Skin.InputBoxTemplate(EditBox)
        Skin.FrameTypeEditBox(EditBox)

        -- Consistent height from frames of variable height
        local yOfs = _G.math.floor(EditBox:GetHeight() / 2 + .5) - 10
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
    function Skin.InputBoxInstructionsTemplate(EditBox)
        Skin.InputBoxTemplate(EditBox)
    end
    function Skin.SearchBoxTemplate(EditBox)
        Skin.InputBoxInstructionsTemplate(EditBox)
        if EditBox.Instructions then
            EditBox.Instructions:SetTextColor(Color.gray:GetRGB())
        end
        if EditBox.searchIcon then
            EditBox.searchIcon:SetPoint("LEFT", 3, -1)
        end
    end

    function Skin.HorizontalSliderTemplate(Slider)
        Base.SetBackdrop(Slider, Color.frame)
        Slider:SetBackdropBorderColor(Color.button)
        Slider:SetBackdropOption("offsets", {
            left = 5,
            right = 5,
            top = 5,
            bottom = 5,
        })

        local thumbTexture = Slider:GetThumbTexture()
        thumbTexture:SetAlpha(0)
        thumbTexture:SetSize(8, 16)

        local thumb = _G.CreateFrame("Frame", nil, Slider)
        thumb:SetPoint("TOPLEFT", thumbTexture, 0, 0)
        thumb:SetPoint("BOTTOMRIGHT", thumbTexture, 0, 0)
        Base.SetBackdrop(thumb, Color.button)
        Slider._auroraThumb = thumb
    end
    function Skin.OptionsSliderTemplate(Slider)
        Skin.HorizontalSliderTemplate(Slider)

        -- Blizzard code may reset these backdrops; keep Aurora's colors.
        Slider.backdropColor = Color.frame
        Slider.backdropColorAlpha = Color.frame.a
        Slider.backdropBorderColor = Color.button
    end

    do -- Scroll thumb (same implementation as the Mainline layer; needed
       -- here because flat scroll skins call it on classic clients too)
        local function Hook_Hide(self)
            self._auroraThumb:Hide()
        end
        local function Hook_Show(self)
            self._auroraThumb:Show()
        end
        function Skin.ScrollBarThumb(Texture)
            Texture:SetAlpha(0)
            Texture:SetSize(17, 24)
            _G.hooksecurefunc(Texture, "Hide", Hook_Hide)
            _G.hooksecurefunc(Texture, "Show", Hook_Show)

            local thumb = _G.CreateFrame("Frame", nil, Texture:GetParent())
            thumb:SetPoint("TOPLEFT", Texture, 0, -2)
            thumb:SetPoint("BOTTOMRIGHT", Texture, 0, 2)
            thumb:SetShown(Texture:IsShown())
            Base.SetBackdrop(thumb, Color.button)
            Texture._auroraThumb = thumb
        end
    end

    -- Classic-art variant of the trim scrollbar (Classic\Scroll\
    -- TrimScrollBar.xml): same WowTrimScrollBarMixin parts, but a
    -- Background child frame instead of the trim Backplate texture.
    function Skin.WowClassicScrollBar(EventFrame)
        Skin.VerticalScrollBarTemplate(EventFrame)

        if EventFrame.Background then
            Util.HideFrameTextures(EventFrame.Background)
        end
        local thumb = (EventFrame.Track and EventFrame.Track.Thumb) or EventFrame.Thumb
        if thumb then
            Skin.WowTrimScrollBarThumbScripts(thumb)
        end
        Skin.WowTrimScrollBarStepperScripts(EventFrame.Back)
        Skin.WowTrimScrollBarStepperScripts(EventFrame.Forward)
    end

    function Skin.NineSlicePanelTemplate(Frame)
        Frame._auroraNineSlice = true
        Hook.NineSliceUtil.ApplyLayout(Frame)
    end
    function Skin.DialogBorderNoCenterTemplate(Frame)
        Skin.NineSlicePanelTemplate(Frame)

        local r, g, b = Frame:GetBackdropColor()
        Frame:SetBackdropColor(r, g, b, 0)
    end
    function Skin.DialogBorderTemplate(Frame)
        if Frame.Bg then
            Frame.Center = Frame.Bg
        end
        Skin.DialogBorderNoCenterTemplate(Frame)

        local r, g, b = Frame:GetBackdropColor()
        Frame:SetBackdropColor(r, g, b, Util.GetFrameAlpha())
    end
    function Skin.DialogBorderDarkTemplate(Frame)
        if Frame.Bg then
            Frame.Center = Frame.Bg
        end
        Skin.DialogBorderNoCenterTemplate(Frame)

        local r, g, b = Frame:GetBackdropColor()
        Frame:SetBackdropColor(r, g, b, 0.87)
    end
    function Skin.DialogBorderTranslucentTemplate(Frame)
        if Frame.Bg then
            Frame.Center = Frame.Bg
        end
        Skin.DialogBorderNoCenterTemplate(Frame)

        local r, g, b = Frame:GetBackdropColor()
        Frame:SetBackdropColor(r, g, b, 0.8)
    end
    function Skin.DialogBorderOpaqueTemplate(Frame)
        if Frame.Bg then
            Frame.Center = Frame.Bg
        end
        Skin.DialogBorderNoCenterTemplate(Frame)

        local r, g, b = Frame:GetBackdropColor()
        Frame:SetBackdropColor(r, g, b, 1)
    end
    function Skin.InsetFrameTemplate(Frame)
        Frame.NineSlice.Center = Frame.Bg
        Skin.NineSlicePanelTemplate(Frame.NineSlice)
    end

    function Skin.FlatPanelBackgroundTemplate(Frame)
        Frame.BottomLeft:Hide()
        Frame.BottomRight:Hide()
        Frame.BottomEdge:Hide()
        Frame.TopSection:Hide()
    end
    function Skin.DefaultPanelBaseTemplate(Frame)
        Frame.NineSlice:SetFrameLevel(Frame:GetFrameLevel())
        Skin.NineSlicePanelTemplate(Frame.NineSlice)

        local TitleContainer = Frame.TitleContainer
        if TitleContainer then
            if TitleContainer.TitleBg then
                TitleContainer.TitleBg:Hide()
            end
            TitleContainer:SetHeight(private.FRAME_TITLE_HEIGHT)
            TitleContainer:SetPoint("TOPLEFT", 24, -1)
        end
    end
    function Skin.DefaultPanelTemplate(Frame)
        Frame.NineSlice.Center = Frame.Bg
        Skin.DefaultPanelBaseTemplate(Frame)
        Frame.TopTileStreaks:SetTexture("")
    end
    function Skin.DefaultPanelFlatTemplate(Frame)
        Skin.DefaultPanelBaseTemplate(Frame)
        Skin.FlatPanelBackgroundTemplate(Frame.Bg)
    end

    function Skin.PortraitFrameTemplateNoCloseButton(Frame)
        Skin.FrameTypeFrame(Frame)
        local bg = Frame:GetBackdropTexture("bg")

        Frame.Bg:Hide()

        Frame.TitleBg:Hide()
        Frame.portrait:SetAlpha(0)
        Frame.PortraitFrame:SetTexture("")
        Frame.TopRightCorner:Hide()
        Frame.TopLeftCorner:SetTexture("")
        Frame.TopBorder:SetTexture("")

        -- Inherited from PortraitFrameBaseTemplate; carries a second portrait
        -- and title. No NineSlice layout exists for portrait frames on the
        -- Classic family, so the base NineSlice child is left alone.
        if Frame.PortraitContainer then
            Frame.PortraitContainer:Hide()
        end

        local titleText = Frame.TitleText
        titleText:ClearAllPoints()
        titleText:SetPoint("TOPLEFT", bg)
        titleText:SetPoint("BOTTOMRIGHT", bg, "TOPRIGHT", 0, -private.FRAME_TITLE_HEIGHT)

        -- The base template's TitleContainer is anchored x=58 to -24, which
        -- truncates and off-centers titles on narrow frames (e.g. the 170px
        -- LootFrame); span its text across the full title bar instead.
        if Frame.TitleContainer then
            Frame.TitleContainer:SetHeight(private.FRAME_TITLE_HEIGHT)
            local containerTitle = Frame.TitleContainer.TitleText
            if containerTitle then
                containerTitle:ClearAllPoints()
                containerTitle:SetPoint("TOPLEFT", bg)
                containerTitle:SetPoint("BOTTOMRIGHT", bg, "TOPRIGHT", 0, -private.FRAME_TITLE_HEIGHT)
                containerTitle:SetJustifyH("CENTER")
            end
        end

        Frame.TopTileStreaks:SetTexture("")
        Frame.BotLeftCorner:Hide()
        Frame.BotRightCorner:Hide()
        Frame.BottomBorder:Hide()
        Frame.LeftBorder:Hide()
        Frame.RightBorder:Hide()
    end
    function Skin.PortraitFrameTemplate(Frame)
        Skin.PortraitFrameTemplateNoCloseButton(Frame)
        Skin.UIPanelCloseButton(Frame.CloseButton)
    end

    function Skin.ButtonFrameTemplate(Frame)
        Skin.PortraitFrameTemplate(Frame)

        -- BtnCorner textures have no parentKey in the Classic XML
        local name = Frame:GetName()
        _G[name.."BtnCornerLeft"]:SetAlpha(0)
        _G[name.."BtnCornerRight"]:SetAlpha(0)
        _G[name.."ButtonBottomBorder"]:SetAlpha(0)

        Skin.InsetFrameTemplate(Frame.Inset)
    end
    function Skin.ButtonFrameTemplateMinimizable(Frame)
        Skin.ButtonFrameTemplate(Frame)
    end

    function Skin.PanelTabButtonTemplate(Button)
        Skin.FrameTypeButton(Button)
        Button:SetButtonColor(Color.button, Util.GetFrameAlpha(), false)
        Button:SetBackdropOption("offsets", {
            left = 0,
            right = 0,
            top = 0,
            bottom = 6,
        })

        Button.LeftActive:SetAlpha(0)
        Button.RightActive:SetAlpha(0)
        Button.MiddleActive:SetAlpha(0)
        Button.Left:SetAlpha(0)
        Button.Right:SetAlpha(0)
        Button.Middle:SetAlpha(0)

        Button.LeftHighlight:SetAlpha(0)
        Button.RightHighlight:SetAlpha(0)
        Button.MiddleHighlight:SetAlpha(0)

        local bg = Button:GetBackdropTexture("bg")
        Button.Text:ClearAllPoints()
        Button.Text:SetAllPoints(bg)

        Button._auroraTabResize = true
    end
    function Skin.TabButtonTemplate(Button)
        Button.LeftDisabled:SetAlpha(0)
        Button.MiddleDisabled:SetAlpha(0)
        Button.RightDisabled:SetAlpha(0)
        Button.Left:SetAlpha(0)
        Button.Middle:SetAlpha(0)
        Button.Right:SetAlpha(0)

        Button.HighlightTexture:SetTexture("")
        Button._auroraTabResize = true
    end
    function Skin.PanelTopTabButtonTemplate(Button)
        -- Classic: PanelTopTabButtonTemplate inherits TabButtonTemplate,
        -- not PanelTabButtonTemplate as on Mainline.
        Skin.TabButtonTemplate(Button)
    end
end

function private.SharedXML.SharedUIPanelTemplates()
    _G.hooksecurefunc("PanelTemplates_TabResize", Hook.PanelTemplates_TabResize)
    _G.hooksecurefunc("PanelTemplates_DeselectTab", Hook.PanelTemplates_DeselectTab)
    _G.hooksecurefunc("PanelTemplates_SelectTab", Hook.PanelTemplates_SelectTab)
end
