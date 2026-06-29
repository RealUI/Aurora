local _, private = ...

--[[ Lua Globals ]]
-- luacheck: globals type next error
local MergeTable = _G.MergeTable -- From TableUtil.lua

-- [[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Color, Util = Aurora.Color, Aurora.Util

local backdrop = {
    -- Blizzard options
    bgFile = private.textures.plain,
    tile = false,
    tileEdge = false,
    insets = {
        left = 0,
        right = 0,
        top = 0,
        bottom = 0,
    },
    edgeFile = private.textures.plain,
    edgeSize = 1,

    -- Custom options
    offsets = {
        left = 0,
        right = 0,
        top = 0,
        bottom = 0,
    },
    backdropLayer = "BACKGROUND",
    backdropSubLevel = -8,
    backdropBorderLayer = "BACKGROUND",
    backdropBorderSubLevel = -7,
}
private.backdrop = backdrop

-- Reusable Color cache for SetBackdropColor / SetBackdropBorderColor.
-- These two functions are called frequently (every color change on every
-- skinned frame) and previously created a brand-new Color object each time
-- via Color.Create(). Since the Color is immediately stored on backdropInfo
-- and the old one becomes garbage, we can reuse a small pool of Color
-- objects and just update their RGBA values in-place.
local colorPool = {}
local colorPoolSize = 0
local COLOR_POOL_MAX = 8 -- more than enough; only 2 are typically in-flight

local function GetColor(red, green, blue, alpha)
    local a
    if type(red) == "table" then
        a = green
        red, green, blue, alpha = red:GetRGBA()
    end
    alpha = a or alpha

    -- Try to reuse a pooled Color object instead of allocating a new one
    if colorPoolSize > 0 then
        local color = colorPool[colorPoolSize]
        colorPool[colorPoolSize] = nil
        colorPoolSize = colorPoolSize - 1
        color:SetRGBA(red, green, blue, alpha or 1)
        return color
    end

    return Color.Create(red, green, blue, alpha)
end

-- Return a Color object to the pool for reuse. Called when a frame's
-- backdropColor/backdropBorderColor is about to be replaced.
local function RecycleColor(color)
    if color and colorPoolSize < COLOR_POOL_MAX then
        colorPoolSize = colorPoolSize + 1
        colorPool[colorPoolSize] = color
    end
end

-- WoW 12.0 changed Texture:SetVertexColor to prefer a color object.
-- Aurora's custom Color objects are not always accepted by the C API,
-- so convert to Blizzard's CreateColor() object when available.
local vertexColorCompat = _G.CreateColor and _G.CreateColor(1, 1, 1, 1)
local function SetRegionVertexColor(region, color)
    if not region or not color then
        return
    end

    local r, g, b, a = color:GetRGBA()

    if vertexColorCompat then
        vertexColorCompat:SetRGBA(r, g, b, a)
        local ok = _G.pcall(region.SetVertexColor, region, vertexColorCompat)
        if ok then
            return
        end
    end

    _G.pcall(region.SetVertexColor, region, r, g, b, a)
end
-- Table pool for CopyBackdrop — avoids creating 3 tables (copy + insets + offsets)
-- per Base.CreateBackdrop call. Frames that get re-skinned return their old
-- backdropInfo to the pool via Base.CreateBackdrop.
local bdPool = {}
local bdPoolSize = 0
local BD_POOL_MAX = 16

local function AcquireBackdropTable()
    if bdPoolSize > 0 then
        local t = bdPool[bdPoolSize]
        bdPool[bdPoolSize] = nil
        bdPoolSize = bdPoolSize - 1
        return t
    end
    return { insets = {}, offsets = {} }
end

local function ReleaseBackdropTable(t)
    if t and bdPoolSize < BD_POOL_MAX then
        bdPoolSize = bdPoolSize + 1
        bdPool[bdPoolSize] = t
    end
end

local function CopyBackdrop(bdOptions)
    local copy = AcquireBackdropTable()

    copy.bgFile = bdOptions.bgFile
    copy.tile = bdOptions.tile
    copy.tileEdge = bdOptions.tileEdge
    copy.edgeFile = bdOptions.edgeFile
    copy.edgeSize = bdOptions.edgeSize
    copy.backdropLayer = bdOptions.backdropLayer
    copy.backdropSubLevel = bdOptions.backdropSubLevel
    copy.backdropBorderLayer = bdOptions.backdropBorderLayer
    copy.backdropBorderSubLevel = bdOptions.backdropBorderSubLevel

    local si = bdOptions.insets
    local di = copy.insets
    di.left, di.right, di.top, di.bottom = si.left, si.right, si.top, si.bottom

    local so = bdOptions.offsets
    local do_ = copy.offsets
    do_.left, do_.right, do_.top, do_.bottom = so.left, so.right, so.top, so.bottom

    return copy
end
local function SanitizeTable(optionDB, parentDB)
    for option, value in next, parentDB do
        if type(value) == "table" then
            optionDB[option] = SanitizeTable(optionDB[option] or {}, value)
        else
            if optionDB[option] == nil then
                optionDB[option] = parentDB[option]
            end
        end
    end

    return optionDB
end

local bgTextures = {}
for new, old in next, Util.NineSliceTextures do
    bgTextures[old] = new
end

local function IsForbiddenFrame(frame)
    if not frame or not frame.IsForbidden then
        return false
    end

    local ok, isForbidden = _G.pcall(function()
        return frame:IsForbidden()
    end)
    return ok and isForbidden
end

local function SafeFrameName(frame)
    if not frame then
        return "<nil>"
    end

    local ok, debugName = _G.pcall(function()
        return frame.GetDebugName and frame:GetDebugName()
    end)
    if ok and type(debugName) == "string" and debugName ~= "" then
        return debugName
    end

    local okName, name = _G.pcall(function()
        return frame.GetName and frame:GetName()
    end)
    if okName and type(name) == "string" and name ~= "" then
        return name
    end

    return "<frame>"
end


-- Blizzard methods
local BackdropMixin do
    BackdropMixin = _G.Mixin({}, _G.BackdropTemplateMixin)

    -- Pre-allocate a single reusable layout table for GetNineSliceLayout.
    -- Previously, every ApplyBackdrop() call created ~10 sub-tables that
    -- became garbage immediately after use. This eliminates that churn.
    local reuseLayout = {
        TopLeftCorner     = { layer = "", subLevel = 0, x = 0, y = 0 },
        TopRightCorner    = { layer = "", subLevel = 0, x = 0, y = 0 },
        BottomLeftCorner  = { layer = "", subLevel = 0, x = 0, y = 0 },
        BottomRightCorner = { layer = "", subLevel = 0, x = 0, y = 0 },
        TopEdge           = { layer = "", subLevel = 0 },
        BottomEdge        = { layer = "", subLevel = 0 },
        LeftEdge          = { layer = "", subLevel = 0 },
        RightEdge         = { layer = "", subLevel = 0 },
        Center            = { layer = "", subLevel = 0, x = 0, y = 0, x1 = 0, y1 = 0 },
        disableSharpening = true,
        setupPieceVisualsFunction = nil, -- set after BackdropMixin is defined
    }

    local function GetNineSliceLayout(frame)
        local backdropInfo = frame.backdropInfo

        local x, y, x1, y1 = 0, 0, 0, 0
        if backdropInfo.bgFile then
            local edgeSize = frame:GetEdgeSize()
            x = -edgeSize
            y = edgeSize
            x1 = edgeSize
            y1 = -edgeSize
            local insets = backdropInfo.insets
            if insets then
                x = x + (insets.left or 0)
                y = y - (insets.top or 0)
                x1 = x1 - (insets.right or 0)
                y1 = y1 + (insets.bottom or 0)
            end
        end

        local left, right, top, bottom = 0, 0, 0, 0
        local offsets = backdropInfo.offsets
        if offsets then
            left, right, top, bottom = (offsets.left or left), (offsets.right or right), (offsets.top or top), (offsets.bottom or bottom)
        end
        if frame.debug then
            private.debug("GetNineSliceLayout", frame:GetDebugName(), frame.debug)
            private.debug("  offsets:", left, right, top, bottom)
            if Aurora.debug then
                _G.error("Found usage")
            end
        end

        -- Update the reusable layout in-place instead of allocating new tables
        local borderLayer = backdropInfo.backdropBorderLayer
        local borderSub = backdropInfo.backdropBorderSubLevel

        local tl = reuseLayout.TopLeftCorner
        tl.layer, tl.subLevel, tl.x, tl.y = borderLayer, borderSub, left, -top

        local tr = reuseLayout.TopRightCorner
        tr.layer, tr.subLevel, tr.x, tr.y = borderLayer, borderSub, -right, -top

        local bl = reuseLayout.BottomLeftCorner
        bl.layer, bl.subLevel, bl.x, bl.y = borderLayer, borderSub, left, bottom

        local br = reuseLayout.BottomRightCorner
        br.layer, br.subLevel, br.x, br.y = borderLayer, borderSub, -right, bottom

        local te = reuseLayout.TopEdge
        te.layer, te.subLevel = borderLayer, borderSub

        local be = reuseLayout.BottomEdge
        be.layer, be.subLevel = borderLayer, borderSub

        local le = reuseLayout.LeftEdge
        le.layer, le.subLevel = borderLayer, borderSub

        local re = reuseLayout.RightEdge
        re.layer, re.subLevel = borderLayer, borderSub

        local center = reuseLayout.Center
        center.layer = backdropInfo.backdropLayer
        center.subLevel = backdropInfo.backdropSubLevel
        center.x, center.y = x, y
        center.x1, center.y1 = x1, y1

        return reuseLayout
    end

    function BackdropMixin:OnBackdropLoaded()
        return _G.BackdropTemplateMixin.OnBackdropLoaded(self)
    end
    function BackdropMixin:SetupPieceVisuals(piece, setupInfo, pieceLayout, textureKit, userLayout)
        if self.debug then
            private.debug("SetupPieceVisuals", piece:GetDebugName(),self.debug)
            private.debug("  ", setupInfo.pieceName, ":")
            private.debug("      size:", piece:GetSize())
            if pieceLayout.x then
                private.debug("      x, y:", pieceLayout.x, pieceLayout.y)
            end
            if pieceLayout.x1 then
                private.debug("      x1, y1:", pieceLayout.x1, pieceLayout.y1)
            end
            --_G.error("Found usage")
        end
        _G.BackdropTemplateMixin.SetupPieceVisuals(self, piece, setupInfo, pieceLayout, textureKit, userLayout)
    end

    -- Now that SetupPieceVisuals is defined, wire it into the reusable layout
    reuseLayout.setupPieceVisualsFunction = BackdropMixin.SetupPieceVisuals
    function BackdropMixin:ApplyBackdrop()
        local userLayout = GetNineSliceLayout(self)
        _G.NineSliceUtil.ApplyLayout(self, userLayout, "AuroraSkin")
        if self.debug then
            _G.print("ApplyBackdrop", self:GetDebugName(), self.debug)
        end
        for old, pieceName in next, bgTextures do
            local pieceLayout = userLayout[pieceName]
            local piece = Util.GetNineSlicePiece(self, pieceName)
            if piece then
                if self.debug then
                    private.debug("  ", pieceName, ":")
                    private.debug("      size:", piece:GetSize())
                    if pieceLayout.x then
                        private.debug("      x, y:", pieceLayout.x, pieceLayout.y)
                    end
                    if pieceLayout.x1 then
                        private.debug("      x1, y1:", pieceLayout.x1, pieceLayout.y1)
                    end
                    --_G.error("Found usage")
                end

                if pieceLayout.layer then
                    piece:SetDrawLayer(pieceLayout.layer, pieceLayout.subLevel)
                end

                -- Blizzard's NineSlice SetupEdge hardcodes tileHorizontal/tileVertical=true
                -- on edge pieces; disable it to prevent seam lines at non-integer UI scales.
                piece:SetHorizTile(false)
                piece:SetVertTile(false)
                piece:Show()
            end
        end

        local backdropInfo = self.backdropInfo
        if Base.IsTextureRegistered(backdropInfo.bgFile) then
            Base.SetTexture(Util.GetNineSlicePiece(self, "Center"), backdropInfo.bgFile)
        end

        local r, g, b, a = 1, 1, 1, 1
        if backdropInfo.backdropColor then
            r, g, b, a = backdropInfo.backdropColor:GetRGBA()
        end
        self:SetBackdropColor(r, g, b, a)


        r, g, b, a = 1, 1, 1, 1
        if backdropInfo.backdropBorderColor then
            r, g, b, a = backdropInfo.backdropBorderColor:GetRGBA()
        end
        self:SetBackdropBorderColor(r, g, b, a)
        if not _G.canaccesssecrets or _G.canaccesssecrets(self) then
            self:SetupTextureCoordinates()
        end
    end


    function BackdropMixin:SetBackdrop(backdropInfo, textures)
        if self.debug then
            _G.print("BackdropMixin:SetBackdrop", self.debug, backdropInfo, self.backdropInfo, self._backdropInfo)
        end

        if IsForbiddenFrame(self) then
            return
        end

        if backdropInfo == true then
            backdropInfo = self._backdropInfo
        end

        if self.backdropInfo then
            if backdropInfo then
                backdropInfo = self.backdropInfo
            end
        end

        if textures and backdropInfo then
            for textureName, texture in next, textures do
                if bgTextures[textureName] then
                    textureName = bgTextures[textureName]
                end

                if not self[textureName] then
                    self[textureName] = texture
                end
            end
        end

        local ok, result = _G.pcall(_G.BackdropTemplateMixin.SetBackdrop, self, backdropInfo)
        if not ok then
            private.debug("BackdropMixin:SetBackdrop failed", SafeFrameName(self), result)
            return
        end
        return result
    end
    function BackdropMixin:SetBackdropColor(red, green, blue, alpha)
        if not self.backdropInfo then return end
        RecycleColor(self.backdropInfo.backdropColor)
        self.backdropInfo.backdropColor = GetColor(red, green, blue, alpha)

        local center = Util.GetNineSlicePiece(self, "Center")
        if center then
            SetRegionVertexColor(center, self.backdropInfo.backdropColor)
        end
        --return _G.BackdropTemplateMixin.SetBackdropColor(self, self.backdropInfo.backdropColor:GetRGBA())
    end
    function BackdropMixin:GetBackdropColor()
        if not self.backdropInfo then return end
        return self.backdropInfo.backdropColor:GetRGBA()
    end
    function BackdropMixin:SetBackdropBorderColor(red, green, blue, alpha)
        if not self.backdropInfo then return end

        RecycleColor(self.backdropInfo.backdropBorderColor)
        local backdropBorderColor = GetColor(red, green, blue, alpha)
        for _, pieceName in next, bgTextures do
            if pieceName ~= "Center" then
                local region = Util.GetNineSlicePiece(self, pieceName)
                if region then
                    SetRegionVertexColor(region, backdropBorderColor)
                end
            end
        end

        self.backdropInfo.backdropBorderColor = backdropBorderColor
        --return _G.BackdropTemplateMixin.SetBackdropBorderColor(self, self.backdropInfo.backdropBorderColor:GetRGBA())
    end
    function BackdropMixin:GetBackdropBorderColor()
        if not self.backdropInfo then return end
        return self.backdropInfo.backdropBorderColor:GetRGBA()
    end

    -- Custom Methods
    function BackdropMixin:SetBackdropGradient(red, green, blue, alpha)
        if not self.backdropInfo then return end

        if red then
            RecycleColor(self.backdropInfo.backdropColor)
            self.backdropInfo.backdropColor = GetColor(red, green, blue, alpha)
        end
        self:SetBackdropOption("bgFile", "gradientUp")
    end
    function BackdropMixin:SetBackdropLayer(layer, sublevel)
        if not self.backdropInfo then return end

        self.backdropInfo.backdropLayer = layer
        self.backdropInfo.backdropSubLevel = sublevel
        self.backdropInfo.backdropBorderLayer = layer
        self.backdropInfo.backdropBorderSubLevel = sublevel + 1
        self:ApplyBackdrop()
    end
    function BackdropMixin:GetBackdropLayer()
        if self.backdropInfo then
            return self.backdropInfo.backdropLayer, self.backdropInfo.backdropSubLevel
        end
    end
    function BackdropMixin:GetBackdropTexture(texture)
        if not self.backdropInfo then return end

        if bgTextures[texture] then
            texture = bgTextures[texture]
        end

        return (Util.GetNineSlicePiece(self, texture))
    end
    function BackdropMixin:SetBackdropOption(optionKey, optionValue, skipApply)
        if self.backdropInfo then
            local options = self.backdropInfo
            if type(options[optionKey]) == "table" then
                MergeTable(options[optionKey], optionValue)
            else
                if options[optionKey] ~= optionValue then
                    options[optionKey] = optionValue
                end
            end

            if not skipApply then
                self:ApplyBackdrop()
            end
        end
    end
    function BackdropMixin:GetBackdropOption(optionKey)
        if self.backdropInfo then
            local options = self.backdropInfo
            return options[optionKey]
        end
    end
    function BackdropMixin:SetBackdropOptions(options)
        if self.backdropInfo then
            for optionKey, optionValue in next, options do
                self:SetBackdropOption(optionKey, optionValue, true)
            end
            self:ApplyBackdrop()
        end
    end
end

function Base.CreateBackdrop(frame, options, textures)
    if not frame or IsForbiddenFrame(frame) then
        return
    end

    for name, func in next, BackdropMixin do
        frame[name] = func
    end

    -- Recycle the old backdrop table and its Color objects before replacing
    local oldInfo = frame._backdropInfo
    if oldInfo then
        RecycleColor(oldInfo.backdropColor)
        RecycleColor(oldInfo.backdropBorderColor)
        oldInfo.backdropColor = nil
        oldInfo.backdropBorderColor = nil
        ReleaseBackdropTable(oldInfo)
    end

    local backdropInfo
    if options == backdrop then
        backdropInfo = CopyBackdrop(options)
    else
        backdropInfo = SanitizeTable(options, backdrop)
    end

    frame._backdropInfo = backdropInfo
    if frame.backdropInfo then
        frame.backdropInfo = nil
    end
    frame:SetBackdrop(backdropInfo, textures)
end

function Base.SetBackdrop(frame, color, alpha)
    if frame.debug then
        _G.print("Base.SetBackdrop", frame.debug)
    end
    Base.CreateBackdrop(frame, frame._backdropInfo or backdrop)
    Base.SetBackdropColor(frame, color, alpha)

    -- Register for palette refresh: only pure frame backgrounds, not buttons/interactive elements.
    if not frame._auroraPaletteOptOut and color == Color.frame then
        Color.RegisterPaletteElement(frame, "frame", alpha)
        frame._auroraPaletteBorderDefault = true

        -- Track if border is later customized by external code
        if not frame._auroraBorderHooked and frame.SetBackdropBorderColor then
            _G.hooksecurefunc(frame, "SetBackdropBorderColor", function()
                if not Color._applyingPalette then
                    frame._auroraPaletteBorderDefault = false
                end
            end)
            frame._auroraBorderHooked = true
        end
    end
end
function Base.SetBackdropColor(frame, color, alpha)
    if not color then color = Color.frame end
    if type(color) ~= "table" or color.r == nil then error("`color` must be a Color object. See Color.Create") end
    if frame.debug then
        private.debug("Base.SetBackdropColor", frame.debug)
    end

    local a = alpha or color.a
    local backdropColor = Color.Lightness(color, -0.3)
    frame:SetBackdropColor(backdropColor.r, backdropColor.g, backdropColor.b, a)
    frame:SetBackdropBorderColor(color.r, color.g, color.b, 1)
end
