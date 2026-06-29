local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals next select

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

do --[[ FrameXML\UIPanelTemplates.lua ]]
    function Hook.SquareButton_SetIcon(self, name)
        if not self or not self.GetBackdropTexture then return end
        name = name:upper()

        local bg = self:GetBackdropTexture("bg")
        if not bg then return end

        if name == "LEFT" then
            self.icon:SetPoint("TOPLEFT", bg, 8, -4)
            self.icon:SetPoint("BOTTOMRIGHT", bg, -8, 4)
            Base.SetTexture(self.icon, "arrowLeft")
        elseif name == "RIGHT" then
            self.icon:SetPoint("TOPLEFT", bg, 8, -4)
            self.icon:SetPoint("BOTTOMRIGHT", bg, -8, 4)
            Base.SetTexture(self.icon, "arrowRight")
        elseif name == "UP" then
            self.icon:SetPoint("TOPLEFT", bg, 4, -8)
            self.icon:SetPoint("BOTTOMRIGHT", bg, -4, 8)
            Base.SetTexture(self.icon, "arrowUp")
        elseif name == "DOWN" then
            self.icon:SetPoint("TOPLEFT", bg, 4, -8)
            self.icon:SetPoint("BOTTOMRIGHT", bg, -4, 8)
            Base.SetTexture(self.icon, "arrowDown")
        end
    end
end

do --[[ FrameXML\UIPanelTemplates.xml ]]
    function Skin.BagSearchBoxTemplate(EditBox)
        if not EditBox then return end
        Skin.SearchBoxTemplate(EditBox)
    end

    function Skin.GameMenuButtonTemplate(Button)
        if not Button then return end
        Skin.UIPanelButtonTemplate(Button)
    end

    function Skin.UIPanelSquareButton(Button, direction)
        if not Button then return end
        Skin.FrameTypeButton(Button)
        Button:SetBackdropOption("offsets", {
            left = 2,
            right = 2,
            top = 2,
            bottom = 2,
        })

        if direction then
            Hook.SquareButton_SetIcon(Button, direction)
        end
    end

    function Skin.UIPanelLargeSilverButton(Button)
        if not Button then return end
        local buttonName = Button:GetName()
        if buttonName then
            local left = _G[buttonName.."Left"]
            if left then left:Hide() end
            local right = _G[buttonName.."Right"]
            if right then right:Hide() end
            local middle = _G[buttonName.."Middle"]
            if middle then middle:Hide() end
        end
        for i = 3, 6 do
            local region = select(i, Button:GetRegions())
            if region and region.Hide then
                region:Hide()
            end
        end
        Base.SetBackdrop(Button, Color.button)
        Base.SetHighlight(Button)
    end

    function Skin.BaseBasicFrameTemplate(Frame)
        if not Frame then return end
        if Frame.TopLeftCorner then Frame.TopLeftCorner:Hide() end
        if Frame.TopRightCorner then Frame.TopRightCorner:Hide() end
        if Frame.TopBorder then Frame.TopBorder:SetTexture("") end

        local titleText = Frame.TitleText
        if titleText then
            titleText:ClearAllPoints()
            titleText:SetPoint("TOPLEFT")
            titleText:SetPoint("BOTTOMRIGHT", Frame, "TOPRIGHT", 0, -20)
        end

        if Frame.BotLeftCorner then Frame.BotLeftCorner:Hide() end
        if Frame.BotRightCorner then Frame.BotRightCorner:Hide() end
        if Frame.BottomBorder then Frame.BottomBorder:Hide() end
        if Frame.LeftBorder then Frame.LeftBorder:Hide() end
        if Frame.RightBorder then Frame.RightBorder:Hide() end
        Skin.FrameTypeFrame(Frame)

        if Frame.CloseButton then
            Skin.UIPanelCloseButton(Frame.CloseButton)
            local bg = Frame:GetBackdropTexture("bg")
            if bg then
                Frame.CloseButton:SetPoint("TOPRIGHT", bg, 5.6, 5)
            end
        end
    end

    function Skin.BasicFrameTemplate(Frame)
        if not Frame then return end
        Skin.BaseBasicFrameTemplate(Frame)

        if Frame.Bg then Frame.Bg:Hide() end
        if Frame.TitleBg then Frame.TitleBg:Hide() end
        if Frame.TopTileStreaks then Frame.TopTileStreaks:SetTexture("") end
    end

    function Skin.InsetFrameTemplate2(Frame)
        if not Frame then return end
        if Frame.TopLeftCorner then Frame.TopLeftCorner:Hide() end
        if Frame.TopRightCorner then Frame.TopRightCorner:Hide() end
        if Frame.BotLeftCorner then Frame.BotLeftCorner:Hide() end
        if Frame.BotRightCorner then Frame.BotRightCorner:Hide() end
        if Frame.TopBorder then Frame.TopBorder:Hide() end
        if Frame.BottomBorder then Frame.BottomBorder:Hide() end
        if Frame.LeftBorder then Frame.LeftBorder:Hide() end
        if Frame.RightBorder then Frame.RightBorder:Hide() end
    end

    function Skin.InsetFrameTemplate3(Frame)
        if not Frame then return end
        if Frame.BorderTopRight then Frame.BorderTopRight:Hide() end
        if Frame.BorderBottomRight then Frame.BorderBottomRight:Hide() end
        if Frame.BorderRightMiddle then Frame.BorderRightMiddle:Hide() end
        if Frame.BorderTopLeft then Frame.BorderTopLeft:Hide() end
        if Frame.BorderBottomLeft then Frame.BorderBottomLeft:Hide() end
        if Frame.BorderLeftMiddle then Frame.BorderLeftMiddle:Hide() end
        if Frame.BorderTopMiddle then Frame.BorderTopMiddle:Hide() end
        if Frame.BorderBottomMiddle then Frame.BorderBottomMiddle:Hide() end
        if Frame.Bg then Frame.Bg:Hide() end
    end

    function Skin.TranslucentFrameTemplate(Frame)
        if not Frame then return end
        if Frame.Bg then Frame.Bg:Hide() end

        if Frame.TopLeftCorner then Frame.TopLeftCorner:Hide() end
        if Frame.TopRightCorner then Frame.TopRightCorner:Hide() end
        if Frame.BottomLeftCorner then Frame.BottomLeftCorner:Hide() end
        if Frame.BottomRightCorner then Frame.BottomRightCorner:Hide() end

        if Frame.TopBorder then Frame.TopBorder:Hide() end
        if Frame.BottomBorder then Frame.BottomBorder:Hide() end
        if Frame.LeftBorder then Frame.LeftBorder:Hide() end
        if Frame.RightBorder then Frame.RightBorder:Hide() end
        Skin.FrameTypeFrame(Frame)
        Frame:SetBackdropOption("offsets", {
            left = 7,
            right = 7,
            top = 7,
            bottom = 7,
        })
    end

    function Skin.ThinGoldEdgeTemplate(Frame)
        if not Frame then return end
        local name = Util.GetName(Frame)
        if name then
            local left = _G[name.."Left"]
            if left then left:Hide() end
            local right = _G[name.."Right"]
            if right then right:Hide() end
            local middle = _G[name.."Middle"]
            if middle then middle:Hide() end
        end

        Base.SetBackdrop(Frame, Color.frame)
        Frame:SetBackdropBorderColor(Color.yellow)
    end

    function Skin.HorizontalBarTemplate(Frame)
        if not Frame then return end
        Frame:SetHeight(1)
        local name = Frame:GetName()
        if name then
            local bg = _G[name.."Bg"]
            if bg then
                bg:SetColorTexture(Color.white.r, Color.white.g, Color.white.b, Color.frame.a)
            end

            local topLeftCorner = _G[name.."TopLeftCorner"]
            if topLeftCorner then topLeftCorner:Hide() end
            local topRightCorner = _G[name.."TopRightCorner"]
            if topRightCorner then topRightCorner:Hide() end
            local botLeftCorner = _G[name.."BotLeftCorner"]
            if botLeftCorner then botLeftCorner:Hide() end
            local botRightCorner = _G[name.."BotRightCorner"]
            if botRightCorner then botRightCorner:Hide() end
            local topBorder = _G[name.."TopBorder"]
            if topBorder then topBorder:Hide() end
            local bottomBorder = _G[name.."BottomBorder"]
            if bottomBorder then bottomBorder:Hide() end
        end
    end

    function Skin.UIExpandingButtonTemplate(Button)
        if not Button then return end
        Skin.UIPanelSquareButton(Button)
    end
end

function private.FrameXML.UIPanelTemplates()
    if _G.SquareButton_SetIcon then
        _G.hooksecurefunc("SquareButton_SetIcon", Hook.SquareButton_SetIcon)
    end

    local HelpPlateTooltip = _G.HelpPlateTooltip
    if HelpPlateTooltip then
        Skin.GlowBoxTemplate(HelpPlateTooltip)
        for direction, dirUpper in next, {Down = "Up", Up = "Down", Left = "Right", Right = "Left"} do
            local arrow = HelpPlateTooltip["Arrow"..dirUpper]
            if arrow then
                Base.SetTexture(arrow, "arrow"..direction)
                arrow:SetVertexColor(1, 1, 0) -- static: not a theme color
            end
            local glow = HelpPlateTooltip["ArrowGlow"..dirUpper]
            if glow then
                glow:SetAlpha(0)
            end
        end
    end
end
