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
        local left = tab.Left or tab.leftTexture or _G[tab:GetName().."Left"]
        left:SetWidth(10)
        _G.PanelTemplates_TabResize(tab, padding, absoluteSize, minWidth, maxWidth, absoluteTextSize)
        resizing = false
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

    function Skin.NineSlicePanelTemplate(Frame)
        Frame._auroraNineSlice = true
        Hook.NineSliceUtil.ApplyLayout(Frame)
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
        if Frame.TitleContainer then
            Frame.TitleContainer:SetHeight(private.FRAME_TITLE_HEIGHT)
        end

        local titleText = Frame.TitleText
        titleText:ClearAllPoints()
        titleText:SetPoint("TOPLEFT", bg)
        titleText:SetPoint("BOTTOMRIGHT", bg, "TOPRIGHT", 0, -private.FRAME_TITLE_HEIGHT)

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
