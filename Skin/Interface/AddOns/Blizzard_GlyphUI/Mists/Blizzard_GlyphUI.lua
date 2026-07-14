local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs select hooksecurefunc

--[[ Core ]]
local Aurora = private.Aurora
local Base, Skin = Aurora.Base, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

--[[ Mists (5.5.4) glyph pane — lives inside PlayerTalentFrame as tab 3.
    The central glyph-socket art (glyph-bg circle, socket rings, level
    overlays) is layout-bearing and kept (book-page rule); the right-hand
    glyph list gets the full treatment. Evidence: wow-ui-source-classic/
    Interface/AddOns/Blizzard_GlyphUI/Mists/Blizzard_GlyphUI.xml, plus the
    ORIGINAL MoP-era Aurora skin (repo history, AddOns/Blizzard_GlyphUI.lua)
    which killed the row plaque as a plain region — so the plaque's exact
    slot (NormalTexture vs numbered region) is treated as unknown and the
    rows are swept layout-agnostically.
    NOTE: HybridScrollFrame calls scrollFrame.update — a REFERENCE captured
    at OnLoad — so hooking the global updater by name never fires; hook the
    scrollFrame FIELD instead.
]]

local function SkinGlyphListButton(button)
    if button.icon then
        Base.CropIcon(button.icon)
    end

    -- sweep every texture region except the icon and the functional
    -- gray-out overlay — catches the maroon plaque wherever this client
    -- build parks it (it also bleeds through the header rows, which
    -- Blizzard positions ON TOP of ordinary list rows)
    local highlight = button:GetHighlightTexture()
    for i = 1, _G.select("#", button:GetRegions()) do
        local region = _G.select(i, button:GetRegions())
        if region:GetObjectType() == "Texture"
            and region ~= button.icon
            and region ~= button.disabledBG
            and region ~= button.selectedTex
            and region ~= highlight then
            region:SetAlpha(0)
        end
    end

    -- rebuild state feedback as flat tints (Blizzard drives show/hide)
    local r, g, b = Color.highlight:GetRGB()
    if button.selectedTex then
        button.selectedTex:SetBlendMode("BLEND")
        button.selectedTex:SetColorTexture(r, g, b, 0.2)
    end
    if highlight then
        highlight:SetBlendMode("BLEND")
        highlight:SetColorTexture(r, g, b, 0.2)
    end
end

local function SkinGlyphHeader(header)
    -- strip the header bar art but keep the +/- state icons; guard both
    -- the parentKey layout and the old named-global layout
    local name = header:GetName()
    local keep = {
        header.expandedIcon, header.collapsedIcon,
        _G[name.."ExpandedIcon"], _G[name.."CollapsedIcon"],
    }
    for i = 1, _G.select("#", header:GetRegions()) do
        local region = _G.select(i, header:GetRegions())
        if region:GetObjectType() == "Texture" then
            local isIcon = false
            for _, icon in ipairs(keep) do
                if region == icon then
                    isIcon = true
                    break
                end
            end
            if not isIcon then
                region:SetAlpha(0)
            end
        end
    end
end

function private.AddOns.Blizzard_GlyphUI()
    local GlyphFrame = _G.GlyphFrame
    if not GlyphFrame then return end

    -- central socket-board art: the parchment circle CAN go (the original
    -- MoP-era Aurora hid it) — the gold socket rings stay as functional
    -- slot markers, so hide only the board, its spec cover ring and the
    -- pulsing glow copy
    local background = GlyphFrame.background or _G.GlyphFrameBackground
    if background then
        background:SetAlpha(0)
    end
    if GlyphFrame.specRing then
        GlyphFrame.specRing:SetAlpha(0)
    end
    if GlyphFrame.glow then
        GlyphFrame.glow:SetAlpha(0)
    end
    -- "Unlocked at Level X" renders in a BLACK huge font over dark now —
    -- hide the plates, lighten the text
    for i = 1, 2 do
        local overlay = GlyphFrame["levelOverlay"..i]
        if overlay then
            overlay:SetAlpha(0)
        end
        local overlayText = GlyphFrame["levelOverlayText"..i]
        if overlayText then
            overlayText:SetTextColor(Color.grayLight:GetRGB())
        end
    end

    local sideInset = GlyphFrame.sideInset or _G.GlyphFrameSideInset
    if sideInset then
        Skin.InsetFrameTemplate(sideInset)
    end

    -- hand-rolled search box (Common-Input-Border three-slice)
    local searchBox = _G.GlyphFrameSearchBox
    if searchBox then
        Util.HideFrameTextures(searchBox)
        Skin.FrameTypeEditBox(searchBox)
    end

    if GlyphFrame.FilterDropdown then
        Skin.DropdownButton(GlyphFrame.FilterDropdown)
    end

    local scrollBar = _G.GlyphFrameScrollFrameScrollBar
    if scrollBar then
        Skin.HybridScrollBarTemplate(scrollBar)
    end

    -- the parentKey may not exist on the live build — the named global
    -- provably does (the scrollbar global resolved from it)
    local scrollFrame = GlyphFrame.scrollFrame or _G.GlyphFrameScrollFrame

    local function SkinList()
        if scrollFrame and scrollFrame.buttons then
            for _, button in ipairs(scrollFrame.buttons) do
                SkinGlyphListButton(button)
            end
        end
        local i = 1
        local header = _G["GlyphFrameHeader"..i]
        while header do
            SkinGlyphHeader(header)
            i = i + 1
            header = _G["GlyphFrameHeader"..i]
        end
    end

    SkinList()
    -- re-apply on every list refresh: hook the scrollFrame FIELD that
    -- HybridScrollFrame actually calls, plus OnShow as a backstop
    if scrollFrame and scrollFrame.update then
        _G.hooksecurefunc(scrollFrame, "update", SkinList)
    end
    GlyphFrame:HookScript("OnShow", SkinList)

    local clearIcon = (GlyphFrame.clearInfo and GlyphFrame.clearInfo.icon)
        or _G.GlyphFrameClearInfoFrameIcon
    if clearIcon then
        Base.CropIcon(clearIcon)
    end
end
