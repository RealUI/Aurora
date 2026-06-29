local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals next type tinsert hooksecurefunc

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

do -- BlizzWTF: These are not templates, but they should be
    do -- ExpandOrCollapse
        local function Hook_SetHighlightTexture(self, texture)
            if self.settingHighlight then return end
            self.settingHighlight = true
            self:ClearHighlightTexture()
            self.settingHighlight = nil
        end
        local function Hook_SetPushedTexture(self, texture)
            self:GetPushedTexture():SetAlpha(0)
        end
        local function Hook_SetNormalTexture(self, texture)
            self:GetNormalTexture():SetAlpha(0)

            if type(texture) == "string" then
                texture = texture:lower()
            else
                if texture == 130838 then
                    texture = "plus"
                elseif texture == 130821 then
                    texture = "minus"
                end
            end

            if texture and texture ~= "" then
                if texture:find("plus") or texture:find("closed") then
                    self._plus:Show()
                elseif texture:find("minus") or texture:find("open") then
                    self._plus:Hide()
                end
                self:SetBackdrop(true)
            else
                self:SetBackdrop(false)
            end
        end
        function Skin.ExpandOrCollapse(Button)
            if not Button then return end
            if Button:GetNormalTexture() then
                Button:GetNormalTexture():SetAlpha(0)
            end
            Skin.FrameTypeButton(Button)

            local bg = Button:GetBackdropTexture("bg")
            local minus = Button:CreateTexture(nil, "OVERLAY")
            minus:SetColorTexture(1, 1, 1) -- static: not a theme color
            minus:SetSize(9, 1)
            minus:SetPoint("TOPLEFT", bg, 2, -6)
            Button._minus = minus

            local plus = Button:CreateTexture(nil, "OVERLAY")
            plus:SetColorTexture(1, 1, 1) -- static: not a theme color
            plus:SetSize(1, 9)
            plus:SetPoint("TOPLEFT", bg, 6, -2)
            Button._plus = plus

            Button._auroraTextures = {
                minus,
                plus
            }
            _G.hooksecurefunc(Button, "SetNormalTexture", Hook_SetNormalTexture)
            _G.hooksecurefunc(Button, "SetPushedTexture", Hook_SetPushedTexture)
            _G.hooksecurefunc(Button, "SetNormalAtlas", Hook_SetNormalTexture)
            _G.hooksecurefunc(Button, "SetPushedAtlas", Hook_SetPushedTexture)
            _G.hooksecurefunc(Button, "SetHighlightTexture", Hook_SetHighlightTexture)
        end
    end

    do -- Nav buttons
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
            if not Button then return end
            local arrow = NavButton(Button)
            Base.SetTexture(arrow, "arrowLeft")
        end
        function Skin.NavButtonNext(Button)
            if not Button then return end
            local arrow = NavButton(Button)
            Base.SetTexture(arrow, "arrowRight")
        end
    end

    do -- Scroll thumb
        local function Hook_Hide(self)
            self._auroraThumb:Hide()
        end
        local function Hook_Show(self)
            self._auroraThumb:Show()
        end
        function Skin.ScrollBarThumb(Texture)
            if not Texture then return end
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
end

do --[[ SharedXML\SharedUIPanelTemplates.lua ]]
    do --[[ SharedUIPanelTemplates ]]
        local resizing = false
        function Hook.PanelTemplates_TabResize(tab, padding, absoluteSize, minWidth, maxWidth, absoluteTextSize)
            if not tab or not tab._auroraTabResize or resizing then return end

            resizing = true
            local left = tab.Left or tab.leftTexture or (tab:GetName() and _G[tab:GetName().."Left"])
            if left then
                left:SetWidth(10)
            end
            _G.PanelTemplates_TabResize(tab, padding, absoluteSize, minWidth, maxWidth, absoluteTextSize)
            resizing = false
        end
        function Hook.PanelTemplates_DeselectTab(tab)
            if not tab then return end
            local text = tab.Text or (tab:GetName() and _G[tab:GetName().."Text"])
            if text then
                text:SetPoint("CENTER", tab, "CENTER")
            end
        end
        function Hook.PanelTemplates_SelectTab(tab)
            if not tab then return end
            local text = tab.Text or (tab:GetName() and _G[tab:GetName().."Text"])
            if text then
                text:SetPoint("CENTER", tab, "CENTER")
            end
        end
    end
end

do --[[ SharedXML\SharedUIPanelTemplates.xml ]]
    function Skin.UIPanelCloseButton(Button)
        if not Button then return end
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

    function Skin.UIPanelButtonTemplate(Button)
        if not Button then return end
        Skin.UIPanelButtonNoTooltipTemplate(Button)
    end
    function Skin.UIPanelButtonNoTooltipTemplate(Button)
        if not Button then return end
        Skin.FrameTypeButton(Button)
        if Button.Left then
            Button.Left:SetAlpha(0)
            Button.Left:Hide()
            Button.Right:SetAlpha(0)
            Button.Right:Hide()
        end
        if Button.Middle then
            Button.Middle:SetAlpha(0)
            Button.Middle:Hide()
        end
    end

    function Skin.UIRadioButtonTemplate(CheckButton)
        if not CheckButton then return end
        Skin.FrameTypeCheckButton(CheckButton)
        CheckButton:SetBackdropOption("offsets", {
            left = 4,
            right = 4,
            top = 4,
            bottom = 4,
        })

        local bg = CheckButton:GetBackdropTexture("bg")
        local check = CheckButton:GetCheckedTexture()
        if check and bg then
            check:ClearAllPoints()
            check:SetPoint("TOPLEFT", bg, 1, -1)
            check:SetPoint("BOTTOMRIGHT", bg, -1, 1)
            Util.SetHighlightColor(check)
        end
    end

    function Skin.UICheckButtonTemplate(CheckButton)
        if not CheckButton then return end
        Skin.FrameTypeCheckButton(CheckButton)
        CheckButton:SetBackdropOption("offsets", {
            left = 6,
            right = 6,
            top = 6,
            bottom = 6,
        })

        local bg = CheckButton:GetBackdropTexture("bg")
        local check = CheckButton:GetCheckedTexture()
        if check and bg then
            check:ClearAllPoints()
            check:SetPoint("TOPLEFT", bg, -6, 6)
            check:SetPoint("BOTTOMRIGHT", bg, 6, -6)
            check:SetDesaturated(true)
            check:SetVertexColor(Color.highlight:GetRGB())
        end

        local disabled = CheckButton:GetDisabledCheckedTexture()
        if disabled and check then
            disabled:SetAllPoints(check)
        end
    end

    function Skin.GlowBoxArrowTemplate(Frame, direction)
        if not Frame then return end
        direction = direction or "Down"
        local parent = Frame:GetParent()
        if not parent or not parent.info then
            if direction == "Left" or direction == "Right" then
                Frame:SetSize(21, 53)
            else
                Frame:SetSize(53, 21)
            end

            if Frame.Arrow then
                Base.SetTexture(Frame.Arrow, "arrow"..direction)
            end
        end
        if Frame.Arrow then
            Frame.Arrow:SetAllPoints()
            Frame.Arrow:SetVertexColor(1, 1, 0) -- static: not a theme color
        end
        if Frame.Glow then
            Frame.Glow:Hide()
        end
    end

    function Skin.GlowBoxTemplate(Frame)
        if not Frame then return end

        if Frame.BG then Frame.BG:Hide() end

        if Frame.GlowTopLeft then Frame.GlowTopLeft:Hide() end
        if Frame.GlowTopRight then Frame.GlowTopRight:Hide() end
        if Frame.GlowBottomLeft then Frame.GlowBottomLeft:Hide() end
        if Frame.GlowBottomRight then Frame.GlowBottomRight:Hide() end

        if Frame.GlowTop then Frame.GlowTop:Hide() end
        if Frame.GlowBottom then Frame.GlowBottom:Hide() end
        if Frame.GlowLeft then Frame.GlowLeft:Hide() end
        if Frame.GlowRight then Frame.GlowRight:Hide() end

        if Frame.ShadowTopLeft then Frame.ShadowTopLeft:Hide() end
        if Frame.ShadowTopRight then Frame.ShadowTopRight:Hide() end
        if Frame.ShadowBottomLeft then Frame.ShadowBottomLeft:Hide() end
        if Frame.ShadowBottomRight then Frame.ShadowBottomRight:Hide() end

        if Frame.ShadowTop then Frame.ShadowTop:Hide() end
        if Frame.ShadowBottom then Frame.ShadowBottom:Hide() end
        if Frame.ShadowLeft then Frame.ShadowLeft:Hide() end
        if Frame.ShadowRight then Frame.ShadowRight:Hide() end

        Base.SetBackdrop(Frame, Color.yellow:Lightness(-0.8), 0.75)
        Frame:SetBackdropBorderColor(Color.yellow)
    end

    function Skin.InsetFrameTemplate(Frame)
        if not Frame then return end
        if Frame.Bg then
            Frame.Bg:Hide()
        end
        if Frame.InsetBorderTopLeft then Frame.InsetBorderTopLeft:Hide() end
        if Frame.InsetBorderTopRight then Frame.InsetBorderTopRight:Hide() end
        if Frame.InsetBorderBottomLeft then Frame.InsetBorderBottomLeft:Hide() end
        if Frame.InsetBorderBottomRight then Frame.InsetBorderBottomRight:Hide() end
        if Frame.InsetBorderTop then Frame.InsetBorderTop:Hide() end
        if Frame.InsetBorderBottom then Frame.InsetBorderBottom:Hide() end
        if Frame.InsetBorderLeft then Frame.InsetBorderLeft:Hide() end
        if Frame.InsetBorderRight then Frame.InsetBorderRight:Hide() end
    end

    function Skin.PortraitFrameTemplate(Frame)
        if not Frame then return end
        Base.SetBackdrop(Frame, Color.frame, Util.GetFrameAlpha())

        -- Hide the portrait
        local name = Frame:GetName()
        if name then
            local portrait = _G[name.."Portrait"] or Frame.portrait
            if portrait then
                portrait:SetAlpha(0)
            end
        elseif Frame.portrait then
            Frame.portrait:SetAlpha(0)
        end

        -- Strip border textures by iterating regions
        for i = 1, Frame:GetNumRegions() do
            local region = _G.select(i, Frame:GetRegions())
            if region and region.GetObjectType and region:GetObjectType() == "Texture" then
                local texture = region:GetTexture()
                if texture and type(texture) == "string" then
                    local lower = texture:lower()
                    if lower:find("ui%-character") or lower:find("portraitframe")
                        or lower:find("ui%-dialogbox") or lower:find("framepiece") then
                        region:Hide()
                    end
                end
            end
        end

        -- Hide named border textures if present (TBC PortraitFrame template pieces)
        if name then
            local borderPieces = {
                "TopLeft", "TopRight", "BottomLeft", "BottomRight",
                "Top", "Bottom", "Left", "Right",
            }
            for _, piece in _G.ipairs(borderPieces) do
                local region = _G[name..piece]
                if region and region.Hide then
                    region:Hide()
                end
            end
        end

        -- Skin close button
        local closeButton = Frame.CloseButton
            or (name and _G[name.."CloseButton"])
        if closeButton then
            Skin.UIPanelCloseButton(closeButton)
        end
    end

    function Skin.ButtonFrameTemplate(Frame)
        if not Frame then return end
        Skin.PortraitFrameTemplate(Frame)

        -- Hide additional ButtonFrame border pieces
        local name = Frame:GetName()
        if name then
            local btnPieces = {
                "BtnCornerLeft", "BtnCornerRight", "ButtonBottomBorder",
            }
            for _, piece in _G.ipairs(btnPieces) do
                local region = _G[name..piece]
                if region and region.SetAlpha then
                    region:SetAlpha(0)
                end
            end
        end

        -- Skin the inset
        if Frame.Inset then
            Skin.InsetFrameTemplate(Frame.Inset)
        end
    end

    function Skin.PanelTabButtonTemplate(Tab)
        if not Tab then return end
        Skin.FrameTypeButton(Tab)
        Tab:SetButtonColor(Color.button, Util.GetFrameAlpha(), false)
        Tab:SetBackdropOption("offsets", {
            left = 0,
            right = 0,
            top = 0,
            bottom = 6,
        })

        -- Hide tab border textures
        local name = Tab:GetName()
        if name then
            -- TBC Classic tabs use Left/Middle/Right naming
            local left = _G[name.."Left"] or Tab.Left or Tab.leftTexture
            local middle = _G[name.."Middle"] or Tab.Middle or Tab.middleTexture
            local right = _G[name.."Right"] or Tab.Right or Tab.rightTexture
            if left then left:SetAlpha(0) end
            if middle then middle:SetAlpha(0) end
            if right then right:SetAlpha(0) end

            -- Also hide active variants if they exist
            local leftActive = _G[name.."LeftActive"]
            local middleActive = _G[name.."MiddleActive"]
            local rightActive = _G[name.."RightActive"]
            if leftActive then leftActive:SetAlpha(0) end
            if middleActive then middleActive:SetAlpha(0) end
            if rightActive then rightActive:SetAlpha(0) end

            -- Hide highlight variants
            local leftHighlight = _G[name.."LeftHighlight"]
            local middleHighlight = _G[name.."MiddleHighlight"]
            local rightHighlight = _G[name.."RightHighlight"]
            if leftHighlight then leftHighlight:SetAlpha(0) end
            if middleHighlight then middleHighlight:SetAlpha(0) end
            if rightHighlight then rightHighlight:SetAlpha(0) end
        else
            if Tab.Left then Tab.Left:SetAlpha(0) end
            if Tab.Middle then Tab.Middle:SetAlpha(0) end
            if Tab.Right then Tab.Right:SetAlpha(0) end
            if Tab.LeftActive then Tab.LeftActive:SetAlpha(0) end
            if Tab.RightActive then Tab.RightActive:SetAlpha(0) end
            if Tab.MiddleActive then Tab.MiddleActive:SetAlpha(0) end
        end

        -- Reposition text
        local bg = Tab:GetBackdropTexture("bg")
        local text = Tab.Text or (name and _G[name.."Text"])
        if text and bg then
            text:ClearAllPoints()
            text:SetAllPoints(bg)
        end

        Tab._auroraTabResize = true
    end

    function Skin.DialogBorderTemplate(Frame)
        if not Frame then return end
        Base.SetBackdrop(Frame, Color.frame, Util.GetFrameAlpha())
    end

    function Skin.DialogBorderDarkTemplate(Frame)
        if not Frame then return end
        Base.SetBackdrop(Frame, Color.frame, 0.87)
    end
end

function private.SharedXML.SharedUIPanelTemplates()
    _G.hooksecurefunc("PanelTemplates_TabResize", Hook.PanelTemplates_TabResize)
    _G.hooksecurefunc("PanelTemplates_DeselectTab", Hook.PanelTemplates_DeselectTab)
    _G.hooksecurefunc("PanelTemplates_SelectTab", Hook.PanelTemplates_SelectTab)
end
