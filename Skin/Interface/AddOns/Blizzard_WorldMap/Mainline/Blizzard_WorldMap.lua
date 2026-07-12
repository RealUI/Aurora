local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals next

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

do --[[ AddOns\Blizzard_WorldMap.lua ]]
    do --[[ Blizzard_WorldMap.lua ]]
        Hook.WorldMapMixin = {}
        function Hook.WorldMapMixin:Minimize()
            self.NavBar:SetPoint("TOPLEFT", self.TitleCanvasSpacerFrame, 5, -30)
        end
        function Hook.WorldMapMixin:Maximize()
            --self.NavBar:SetPoint("TOPLEFT", self.TitleCanvasSpacerFrame, 4, -25)
        end
        function Hook.WorldMapMixin:AddOverlayFrame(templateName, templateType, anchorPoint, relativeTo, relativePoint, offsetX, offsetY)
            if Skin[templateName] then
                Skin[templateName](self.overlayFrames[#self.overlayFrames])
            end
        end
    end
end

do --[[ AddOns\Blizzard_WorldMap.xml ]]
    do --[[ Blizzard_WorldMapTemplates.xml ]]
        -- TAINT-SAFE: Only use widget API calls (Hide, SetAlpha, SetTexture,
        -- SetPoint, etc.) on existing objects.  Avoid FrameTypeButton,
        -- Base.SetBackdrop, CreateTexture, CreateLine, CreateFrame, direct
        -- Lua table writes, and HookScript — all of these mark the
        -- WorldMapFrame child hierarchy as addon-modified at the C level and
        -- propagate taint into the secure pin-creation path
        -- (AcquirePin → CheckMouseButtonPassthrough → SetPassThroughButtons).
        function Skin.WorldMapFloorNavigationFrameTemplate(Button)
            -- DropdownButton uses Base.SetBackdrop (CreateTexture) and direct
            -- table writes (_auroraSkinned, _auroraTextures).  Only hide the
            -- existing decorations instead.
            if Button.Left   then Button.Left:SetAlpha(0)   end
            if Button.Middle then Button.Middle:SetAlpha(0)  end
            if Button.Right  then Button.Right:SetAlpha(0)   end
            if Button.Background    then Button.Background:Hide()       end
            if Button.TopEdge       then Button.TopEdge:Hide()          end
            if Button.TopLeftCorner then Button.TopLeftCorner:Hide()    end
            if Button.TopRightCorner then Button.TopRightCorner:Hide()  end
            if Button.BottomEdge    then Button.BottomEdge:Hide()       end
            if Button.BottomLeftCorner  then Button.BottomLeftCorner:Hide()  end
            if Button.BottomRightCorner then Button.BottomRightCorner:Hide() end
            if Button.LeftEdge  then Button.LeftEdge:Hide()  end
            if Button.RightEdge then Button.RightEdge:Hide() end
            if Button.Arrow then Button.Arrow:SetAlpha(0) end
        end
        function Skin.WorldMapTrackingOptionsButtonTemplate(Button)
            Button:GetRegions():SetPoint("TOPRIGHT")
            Button.Background:Hide()
            Button.Border:Hide()

            local tex = Button:GetHighlightTexture()
            tex:SetTexture([[Interface\Minimap\Tracking\None]], "ADD")
            tex:SetAllPoints(Button.Icon)
        end
        function Skin.WorldMapShowLegendButtonTemplate(Button)
        end
        function Skin.WorldMapNavBarTemplate(Frame)
            -- NavBarTemplate uses FrameTypeButton (direct table writes +
            -- HookScript) on overflow and home buttons.  Only hide existing
            -- decorations and reposition text here.
            Frame:GetRegions():Hide()
            Frame.overlay:Hide()
            Frame.overflow:SetWidth(28)
            local tex = Frame.overflow:GetNormalTexture()
            if tex then
                tex:SetPoint("TOPLEFT", 10, -5)
                tex:SetPoint("BOTTOMRIGHT", -10, 5)
                Base.SetTexture(tex, "arrowLeft")
            end
            Frame.home:GetRegions():Hide()
            Frame.home.text:SetPoint("RIGHT", -10, 0)
            Frame.InsetBorderBottomLeft:Hide()
            Frame.InsetBorderBottomRight:Hide()
            Frame.InsetBorderBottom:Hide()
            Frame.InsetBorderLeft:Hide()
            Frame.InsetBorderRight:Hide()
        end

        function Skin.WorldMapSidePanelToggleTemplate(Frame)
            -- SkinQuestToggle used FrameTypeButton + CreateTexture.  Skip the
            -- full skin to avoid taint; only adjust points.
            Frame.OpenButton:SetAllPoints()
            Frame.CloseButton:SetAllPoints()
        end
        function Skin.WorldMapZoneTimerTemplate(Frame)
        end
    end

    do --[[ Blizzard_WorldMap.xml ]]
        function Skin.WorldMapFrameTemplate(Frame)
            Skin.MapCanvasFrameTemplate(Frame)
            Skin.MapCanvasFrameScrollContainerTemplate(Frame.ScrollContainer)
        end
    end

end

function private.AddOns.Blizzard_WorldMap()
    ----====#####################====----
    --        Blizzard_WorldMap        --
    ----====#####################====----
    -- TAINT-SAFE version: WorldMapFrame's OnShow runs in a secure context
    -- from the TOGGLEWORLDMAP keybinding.  Any addon-created children
    -- (CreateTexture/CreateLine/CreateFrame), direct Lua table writes
    -- (frame.key = value), or HookScript calls on frames in this hierarchy
    -- mark the frame tree as addon-modified at the C level.  When the secure
    -- OnShow then calls PlayerMovementFrameFader.AddDeferredFrame, the taint
    -- propagates into the fadingFrames table and poisons every subsequent
    -- OnUpdate tick, eventually blocking SetPassThroughButtons on map pins.
    --
    -- Only widget API calls (Hide, SetTexture, SetPoint, SetAlpha, SetSize,
    -- SetFrameLevel, SetFrameStrata, ClearAllPoints, ClearNormalTexture, etc.)
    -- and hooksecurefunc are safe here.
    local WorldMapFrame = _G.WorldMapFrame
    Skin.WorldMapFrameTemplate(WorldMapFrame)
    Util.Mixin(WorldMapFrame, Hook.WorldMapMixin)  -- hooksecurefunc, safe

    -- PortraitFrameTemplate: manual taint-safe reimplementation.
    -- Skipped: Skin.NineSlicePanelTemplate (direct writes + SetBackdrop →
    --   CreateTexture), Skin.UIPanelCloseButton (FrameTypeButton →
    --   direct writes + HookScript + CreateLine), Skin.MaximizeMinimize-
    --   ButtonFrameTemplate (FrameTypeButton + CreateLine + CreateTexture).
    local BorderFrame = WorldMapFrame.BorderFrame
    Util.Mixin(BorderFrame, Hook.PortraitFrameMixin)  -- hooksecurefunc, safe

    -- NineSlice: hide all ornate border textures.  This replaces
    -- Skin.NineSlicePanelTemplate which uses direct writes (_auroraNineSlice)
    -- and Base.SetBackdrop (mass table writes + CreateTexture).
    local ns = BorderFrame.NineSlice
    ns:SetFrameLevel(BorderFrame:GetFrameLevel() + 1)
    for _, region in next, {ns:GetRegions()} do
        region:SetAlpha(0)
    end

    -- Darken existing Bg texture to serve as the frame backdrop.
    local frameBg = BorderFrame.Bg
    if frameBg then
        frameBg:ClearAllPoints()
        frameBg:SetAllPoints(BorderFrame)
        local r, g, b = Color.frame:GetRGB()
        frameBg:SetColorTexture(r, g, b, Util.GetFrameAlpha())
    end

    BorderFrame.PortraitContainer:Hide()
    BorderFrame.TitleContainer:SetHeight(private.FRAME_TITLE_HEIGHT)
    BorderFrame.TitleContainer:SetPoint("TOPLEFT", 24, -1)
    local titleText = BorderFrame.TitleContainer.TitleText
    titleText:ClearAllPoints()
    titleText:SetPoint("TOPLEFT", BorderFrame.TitleContainer)
    titleText:SetPoint("BOTTOMRIGHT", BorderFrame.TitleContainer)
    if BorderFrame.TopTileStreaks then
        BorderFrame.TopTileStreaks:SetTexture("")
    end

    BorderFrame:SetFrameStrata(WorldMapFrame:GetFrameStrata())
    BorderFrame.InsetBorderTop:Hide()

    -- Helper: style a title-bar button as a dark square with a text icon.
    -- Uses only widget API (SetNormalTexture, SetText, etc.) — no table
    -- writes, no CreateTexture/CreateLine, no HookScript.
    local function StyleTitleButton(btn, text)
        btn:SetSize(22, 22)
        btn:SetNormalTexture("Interface\\Buttons\\White8x8")
        btn:GetNormalTexture():SetVertexColor(Color.button:GetRGB())
        btn:SetPushedTexture("Interface\\Buttons\\White8x8")
        btn:GetPushedTexture():SetVertexColor(Color.border:GetRGB())
        btn:SetDisabledTexture("Interface\\Buttons\\White8x8")
        btn:GetDisabledTexture():SetVertexColor(Color.border.r, Color.border.g, Color.border.b, 0.5)
        btn:SetHighlightTexture("Interface\\Buttons\\White8x8", "ADD")
        btn:GetHighlightTexture():SetVertexColor(1, 1, 1) -- static: not a theme color
        btn:GetHighlightTexture():SetAlpha(0.25)
        btn:SetNormalFontObject("GameFontHighlightLarge")
        btn:SetHighlightFontObject("GameFontHighlightLarge")
        btn:SetDisabledFontObject("GameFontDisableLarge")
        btn:SetText(text)
        btn:SetPushedTextOffset(1, -1)
        if btn.Border then btn.Border:SetAlpha(0) end
    end

    -- CloseButton: dark square with X icon.
    if BorderFrame.CloseButton then
        StyleTitleButton(BorderFrame.CloseButton, "\195\151")  -- × (U+00D7)
    end

    -- MaximizeMinimize: dark squares with arrow icons matching the old Aurora
    -- style as closely as possible.  Original used CreateLine (unsafe) for
    -- diagonal + corner bars; we approximate with Unicode arrows.
    local maxMin = BorderFrame.MaximizeMinimizeFrame
    if maxMin then
        if maxMin.MaximizeButton then
            StyleTitleButton(maxMin.MaximizeButton, "\226\134\151")  -- ↗ (U+2197)
        end
        if maxMin.MinimizeButton then
            StyleTitleButton(maxMin.MinimizeButton, "\226\134\153")  -- ↙ (U+2199)
        end
    end

    Skin.MainHelpPlateButton(BorderFrame.Tutorial)  -- only Hide + SetPoint, safe
    BorderFrame.Tutorial:SetPoint("TOPLEFT", WorldMapFrame, "TOPLEFT", -15, 15)

    Skin.WorldMapFloorNavigationFrameTemplate(WorldMapFrame.overlayFrames[1])
    Skin.WorldMapTrackingOptionsButtonTemplate(WorldMapFrame.overlayFrames[2])
    WorldMapFrame.overlayFrames[2]:SetPoint("TOPRIGHT", WorldMapFrame:GetCanvasContainer(), "TOPRIGHT", 0, 0)
    Skin.WorldMapShowLegendButtonTemplate(WorldMapFrame.overlayFrames[3])
    Skin.WorldMapBountyBoardTemplate(WorldMapFrame.overlayFrames[4])
    Skin.WorldMapActionButtonTemplate(WorldMapFrame.overlayFrames[5])
    Skin.WorldMapZoneTimerTemplate(WorldMapFrame.overlayFrames[6])

    Skin.WorldMapNavBarTemplate(WorldMapFrame.NavBar)
    WorldMapFrame.NavBar:SetPoint("BOTTOMRIGHT", WorldMapFrame.TitleCanvasSpacerFrame, -5, 5)

    Skin.WorldMapSidePanelToggleTemplate(WorldMapFrame.SidePanelToggle)
end

