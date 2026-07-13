local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals next select

--[[ Core ]]
local Aurora = private.Aurora
local Color, Util = Aurora.Color, Aurora.Util

--[[ Vanilla (era) world map.
    Evidence: wow-ui-source-era/Interface/AddOns/Blizzard_WorldMap/
    Blizzard_WorldMap.xml + Vanilla/Blizzard_WorldMap.lua — fullscreen
    parchment border (12 unnamed BorderFrame tiles over a fullscreen
    BlackoutFrame), a windowed mini mode (MiniBorderFrame), three
    WowStyle1 dropdowns, ZoomOut/Close/MaximizeMinimize buttons.

    TAINT-SAFE rules apply exactly as in the Mainline skin: WorldMapFrame's
    OnShow runs in a secure context from the TOGGLEWORLDMAP keybinding, and
    addon-created children (CreateTexture/CreateLine/CreateFrame), direct
    Lua table writes, or HookScript calls on frames in this hierarchy mark
    the tree addon-modified and can poison the secure pin path. Only widget
    API calls (Hide, SetAlpha, SetTexture, SetPoint, SetSize, SetText, ...)
    and hooksecurefunc are used here — no Base.SetBackdrop, no Skin.FrameType*.

    The MagnifyingGlass button is left stock.
]]

-- Flat dark button via state textures only (no CreateTexture, no table writes)
local function StyleFlatButton(btn)
    btn:SetNormalTexture([[Interface\Buttons\White8x8]])
    btn:GetNormalTexture():SetVertexColor(Color.button:GetRGB())
    btn:SetPushedTexture([[Interface\Buttons\White8x8]])
    btn:GetPushedTexture():SetVertexColor(Color.border:GetRGB())
    btn:SetDisabledTexture([[Interface\Buttons\White8x8]])
    btn:GetDisabledTexture():SetVertexColor(Color.border.r, Color.border.g, Color.border.b, 0.5)
    btn:SetHighlightTexture([[Interface\Buttons\White8x8]], "ADD")
    btn:GetHighlightTexture():SetVertexColor(1, 1, 1) -- static: not a theme color
    btn:GetHighlightTexture():SetAlpha(0.25)
    btn:SetPushedTextOffset(1, -1)
end

-- Small square title-bar button with a text glyph
local function StyleIconButton(btn, text)
    btn:SetSize(22, 22)
    StyleFlatButton(btn)
    btn:SetNormalFontObject("GameFontHighlightLarge")
    btn:SetHighlightFontObject("GameFontHighlightLarge")
    btn:SetDisabledFontObject("GameFontDisableLarge")
    btn:SetText(text)
    if btn.Border then btn.Border:SetAlpha(0) end
end

function private.AddOns.Blizzard_WorldMap()
    local WorldMapFrame = _G.WorldMapFrame

    -- Maximized parchment border: 12 unnamed tiles; the fullscreen
    -- BlackoutFrame already provides the dark surround. The WORLD_MAP title
    -- FontString is kept.
    local BorderFrame = WorldMapFrame.BorderFrame
    for i = 1, select("#", BorderFrame:GetRegions()) do
        local region = select(i, BorderFrame:GetRegions())
        if region:IsObjectType("Texture") then
            region:SetAlpha(0)
        end
    end

    -- Mini (windowed) mode: repurpose the left stone sheet as a flat title
    -- bar (recoloring/re-anchoring an EXISTING texture is taint-safe; the
    -- drag button and MiniWorldMapTitle already anchor to it, and the
    -- MiniBorderFrame parent auto-hides it when maximized).
    if _G.MiniBorderLeft then
        local bar = _G.MiniBorderLeft
        bar:SetColorTexture(0, 0, 0, 0.8)
        bar:ClearAllPoints()
        bar:SetPoint("TOPLEFT", WorldMapFrame)
        bar:SetPoint("TOPRIGHT", WorldMapFrame)
        bar:SetHeight(24)
        _G.MiniBorderRight:SetAlpha(0)
    end
    -- Blizzard re-anchors the canvas and title-bar buttons on every
    -- mini/max sync against the (now restyled) border art — re-tuck them.
    _G.hooksecurefunc(WorldMapFrame, "SynchronizeDisplayState", function(self)
        local closeButton = _G.WorldMapFrameCloseButton
        if self:IsMaximized() then
            closeButton:SetPoint("TOPRIGHT", self.BorderFrame, "TOPRIGHT", -4, -3)
        else
            -- zone maps are exactly 3:2 (1002x668); the container must match
            -- or the canvas letterboxes — 606x404 inside the 610x438 frame
            self.ScrollContainer:SetPoint("TOPLEFT", self, "TOPLEFT", 2, -24)
            self.ScrollContainer:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -2, 10)
            closeButton:SetPoint("TOPRIGHT", self, "TOPRIGHT", -2, -1)
        end
        self.MaximizeMinimizeFrame:SetPoint("RIGHT", closeButton, "LEFT", -2, 0)
    end)

    -- Close: dark square with an X glyph
    if _G.WorldMapFrameCloseButton then
        StyleIconButton(_G.WorldMapFrameCloseButton, "\195\151") -- × (U+00D7)
    end

    -- Maximize/minimize: dark squares with +/– glyphs (Friz Quadrata has
    -- no diagonal-arrow glyphs — U+2197/2199 render as tofu boxes here)
    local maxMin = WorldMapFrame.MaximizeMinimizeFrame
    if maxMin then
        -- the buttons are setAllPoints on the 32x32 holder — size the holder,
        -- not the buttons, to match the 22x22 close button
        maxMin:SetSize(22, 22)
        if maxMin.MaximizeButton then
            StyleIconButton(maxMin.MaximizeButton, "+")
        end
        if maxMin.MinimizeButton then
            StyleIconButton(maxMin.MinimizeButton, "\226\128\147") -- – (U+2013)
        end
    end

    -- Zoom Out: strip the goldbutton pieces, flat-color the states
    local zoomOut = _G.WorldMapZoomOutButton
    if zoomOut then
        if zoomOut.Left then zoomOut.Left:SetAlpha(0) end
        if zoomOut.Middle then zoomOut.Middle:SetAlpha(0) end
        if zoomOut.Right then zoomOut.Right:SetAlpha(0) end
        StyleFlatButton(zoomOut)
    end

    -- Dropdowns: recolor the classic textholder into a flat dark box
    -- hugging the button (keeps the arrow affordance)
    local r, g, b = Color.frame:GetRGB()
    for _, name in next, {"WorldMapContinentDropdown", "WorldMapZoneDropdown", "WorldMapZoneMinimapDropdown"} do
        local dropdown = _G[name]
        if dropdown and dropdown.Background then
            local bg = dropdown.Background
            bg:SetColorTexture(r, g, b, Util.GetFrameAlpha())
            bg:ClearAllPoints()
            bg:SetPoint("TOPLEFT", 0, 0)
            bg:SetPoint("BOTTOMRIGHT", 0, 0)
        end
    end
end
