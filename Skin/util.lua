local _, private = ...

--[[ Lua Globals ]]
-- luacheck: globals wipe select next type floor tinsert xpcall

local setmetatable = setmetatable

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

--[[ Util:header
Helpful functions for layout, widget info, and debugging.
--]]


--[[ Layout ]]--

local anchors = {}
local tickPool = _G.CreateUnsecuredObjectPool(function(pool)
    local tick = _G.UIParent:CreateTexture(nil, "ARTWORK", nil, 5)
    tick:SetSize(1, 1)
    return tick
end, function(pool, tick)
    tick:ClearAllPoints()
    tick:Hide()
end)
function Util.PositionBarTicks(anchor, numSegments, color)
    color = color or Color.button
    if not anchors[anchor] then
        anchors[anchor] = {}
    end

    if numSegments ~= #anchors[anchor] then
        Util.ReleaseBarTicks(anchor)

        local divWidth = anchor:GetWidth() / numSegments
        local xpos = divWidth
        for i = 1, numSegments - 1 do
            local tick = tickPool:Acquire()
            tick:SetParent(anchor)
            tick:SetColorTexture(color:GetRGB())
            tick:SetPoint("TOPLEFT", anchor, floor(xpos), 0)
            tick:SetPoint("BOTTOMLEFT", anchor, floor(xpos), 0)
            tick:Show()
            xpos = xpos + divWidth

            tinsert(anchors[anchor], tick)
        end
    end
end

function Util.ReleaseBarTicks(anchor)
    if not anchors[anchor] then return end

    for i = 1, #anchors[anchor] do
        tickPool:Release(anchors[anchor][i])
    end

    wipe(anchors[anchor])
end

function Util.PositionRelative(point, anchor, relPoint, x, y, gap, direction, widgets)
    widgets[1]:ClearAllPoints()
    widgets[1]:SetPoint(point, anchor, relPoint, x, y)

    if direction == "Left" then
        point = "TOPRIGHT"
        relPoint = "TOPLEFT"
        x, y = -gap, 0
    elseif direction == "Right" then
        point = "TOPLEFT"
        relPoint = "TOPRIGHT"
        x, y = gap, 0
    elseif direction == "Up" then
        point = "BOTTOMLEFT"
        relPoint = "TOPLEFT"
        x, y = 0, gap
    elseif direction == "Down" then
        point = "TOPLEFT"
        relPoint = "BOTTOMLEFT"
        x, y = 0, -gap
    end

    for i = 2, #widgets do
        widgets[i]:ClearAllPoints()
        widgets[i]:SetPoint(point, widgets[i - 1], relPoint, x, y)
    end
end


--[[ Skinning Helpers ]]--

--[[ Util.SkinOnce(_frame, skinFunc_)
Guards a skinning function to run at most once per frame. If `frame`
is nil or already skinned (`frame._auroraSkinned` is truthy), the call
is a no-op.

**Args:**
* `frame`    - the widget to skin _(Frame|nil)_
* `skinFunc` - the function to apply _(function)_
--]]
function Util.SkinOnce(frame, skinFunc)
    if not frame or frame._auroraSkinned then return end
    skinFunc(frame)
    frame._auroraSkinned = true
end

function Util.SetHighlightColor(texture, alpha)
    texture:SetColorTexture(Color.highlight.r, Color.highlight.g, Color.highlight.b, alpha or 1)
end

--[[ Util.HideFrameTextures(_frame_)
Hides every Texture region directly attached to the frame; FontStrings are
left alone. Useful for classic frames whose sheet art is layered as unnamed
quadrant textures (character sheet, quest panels, etc.).
--]]
function Util.HideFrameTextures(Frame)
    for i = 1, _G.select("#", Frame:GetRegions()) do
        local region = _G.select(i, Frame:GetRegions())
        if region:IsObjectType("Texture") then
            region:SetTexture("")
        end
    end
end


--[[ Widget Data ]]--

--[[ Util.GetName(_widget_)
Iterates through the widget hierarchy, starting with the given widget,
until a viable global name is found. This is primarily useful when the
template for a widget that assumes it has a global name, when it
actually doesn't due to modern naming practices.

**Args:**
* `widget` - the widget to fine a name for _(Widget)_

**Returns:**
* `widgetName` - the name of the given widget _(string)_
--]]
function Util.GetName(widget)
    local name = widget:GetName()

    while not name do
        widget = widget:GetParent()
        name = widget:GetName()
    end

    return name
end

local ignoreTemplate = {
    TAV_AtlasFrameTemplate = true,

    AreaPOIPinTemplate = true,
    ContributionCollectorPinTemplate = true,
    DigSitePinTemplate = true,
    DungeonEntrancePinTemplate = true,
    FlightPointPinTemplate = true,
    FogOfWarPinTemplate = true,
    GroupMembersPinTemplate = true,
    MapExplorationPinTemplate = true,
    MapHighlightPinTemplate = true,
    PetTamerPinTemplate = true,
    QuestBlobPinTemplate = true,
    QuestPinTemplate = true,
    ScenarioBlobPinTemplate = true,
    StorylineQuestPinTemplate = true,
    WorldQuestSpellEffectPinTemplate = true,

    MapCanvasDetailLayerTemplate = true,
    MapCanvasDetailTileTemplate = true,
    WorldMapBountyBoardTabTemplate = true,
    WorldMapBountyBoardObjectiveTemplate = true,

    ModelSceneActorTemplate = true,
}
function Util.CheckTemplate(getNext, mixinName, ...)
    for i = 1, select("#", ...) do
        local template = select(i, ...)
        --print("CheckTemplate", i, template)
        if Skin[template] then
            for obj in getNext() do
                if not obj._auroraSkinned then
                    Skin[template](obj)
                end
                obj._auroraSkinned = true
            end
        elseif private.isDev and not ignoreTemplate[template] then
            private.debug("Missing template for", mixinName, template)
        end
    end
end

Util.NineSliceTextures = {
    Center = "bg",

    LeftEdge = "l",
    RightEdge = "r",
    TopEdge = "t",
    BottomEdge = "b",

    TopLeftCorner = "tl",
    TopRightCorner = "tr",
    BottomLeftCorner = "bl",
    BottomRightCorner = "br",
}
function Util.GetNineSlicePiece(container, pieceName)
    local piece
    if container.GetNineSlicePiece then
        piece = container:GetNineSlicePiece(pieceName)
        if piece then
            return piece, true
        end
    end

    piece = container[pieceName]
    if piece then
        return piece, true
    end
end
function Util.HideNineSlice(frame)
    if frame.NineSlice then
        frame.NineSlice:Hide()
    else
        _G.print("Report: No NineSlice for", frame:GetName())
        frame:SetBackdrop(nil)
    end
end

local uiTextureKits = {
    default = {
        color = Color.frame,
        backdrop = Color.frame,
        title = Color.white,
        text = Color.grayLight,
        emblem = "",
        emblemSmall = "",
    },
    alt = {
        color = Color.button,
        backdrop = Color.button,
        title = Color.white,
        text = Color.grayLight,
        emblem = "",
        emblemSmall = "",
    },

    alliance = {
        color = private.FACTION_COLORS.Alliance,
        backdrop = private.FACTION_COLORS.Alliance:Lightness(-0.8),
        title = Color.white,
        text = Color.grayLight,
        emblem = "pvpqueue-sidebar-honorbar-badge-alliance",
        emblemSmall = "communities-create-button-wow-alliance",
    },
    horde = {
        color = private.FACTION_COLORS.Horde,
        backdrop = private.FACTION_COLORS.Horde:Lightness(-0.6),
        title = Color.white,
        text = Color.grayLight,
        emblem = "pvpqueue-sidebar-honorbar-badge-horde",
        emblemSmall = "communities-create-button-wow-horde",
    },

    legion = {
        color = Color.green:Lightness(-0.3),
        backdrop = Color.green:Lightness(-0.8),
        title = Color.white,
        text = Color.grayLight,
        emblem = "",
    },

    kyrian = {
        color = private.COVENANT_COLORS.Kyrian,
        backdrop = private.COVENANT_COLORS.Kyrian:Lightness(-0.8),
        title = Color.white,
        text = Color.grayLight,
        emblem = "ShadowlandsMissionsLandingPage-Background-Kyrian",
    },
    necrolord = {
        color = private.COVENANT_COLORS.Necrolord,
        backdrop = private.COVENANT_COLORS.Necrolord:Lightness(-0.8),
        title = Color.white,
        text = Color.grayLight,
        emblem = "ShadowlandsMissionsLandingPage-Background-Necrolord",
    },
    nightfae = {
        color = private.COVENANT_COLORS.NightFae,
        backdrop = private.COVENANT_COLORS.NightFae,
        title = Color.white,
        text = Color.grayLight,
        emblem = "ShadowlandsMissionsLandingPage-Background-NightFae",
    },
    venthyr = {
        color = private.COVENANT_COLORS.Venthyr,
        backdrop = private.COVENANT_COLORS.Venthyr:Lightness(-0.8),
        title = Color.white,
        text = Color.grayLight,
        emblem = "ShadowlandsMissionsLandingPage-Background-Venthyr",
    },
    maw = {
        color = private.COVENANT_COLORS.Maw,
        backdrop = private.COVENANT_COLORS.Maw:Lightness(-0.8),
        title = Color.white,
        text = Color.grayLight,
        emblem = "",
    },
}
uiTextureKits.bastion = uiTextureKits.kyrian
uiTextureKits.maldraxxus = uiTextureKits.necrolord
uiTextureKits.ardenweald = uiTextureKits.nightfae
uiTextureKits.fey = uiTextureKits.nightfae
uiTextureKits.fevendreth = uiTextureKits.venthyr
uiTextureKits["jailerstower-scenario"] = uiTextureKits.maw
Util.uiTextureKits = uiTextureKits

--[[ Util.GetTextureKit(_textureKit_)
Provides the skin colors for a given textureKit.

**Args:**
* `textureKit` - the widget to fine a name for _(string)_

**Returns:**
* `kit` - the name of the given widget _(table)_

    The table `colors` contains the following keys:
    * `color` - the primary kit color _(ColorMixin)_
    * `backdrop` - a backdrop color _(ColorMixin)_
    * `title` - a title text color _(ColorMixin)_
    * `text` - a regular text color _(ColorMixin)_
    * `emblem` - an atlas name _(string)_
--]]
function Util.GetTextureKit(textureKit, useAlt)
    if textureKit then
        textureKit = textureKit:lower()
        if uiTextureKits[textureKit] then
            return uiTextureKits[textureKit]
        else
            private.debug("Missing kit for textureKit", textureKit)
        end
    end
    return useAlt and uiTextureKits.alt or uiTextureKits.default
end


local tempMixin = {}
function Util.Mixin(table, ...)
    wipe(tempMixin)
    for i = 1, select("#", ...) do
        local hook = select(i, ...)
        if hook then
            for name, func in next, hook do
                tempMixin[name] = func
            end
        end
    end
    -- if not table then
    --     return
    -- end
    for name, func in next, tempMixin do
        _G.hooksecurefunc(table, name, func)
    end
end

local wrappedPools = setmetatable({}, {__mode = "k"})
function Util.WrapPoolAcquire(pool, templateOrSkinFunc)
    if not pool or wrappedPools[pool] then
        return
    end

    local skinFunc
    local isTemplate = type(templateOrSkinFunc) == "string"
    if isTemplate then
        skinFunc = Skin[templateOrSkinFunc]
        if not skinFunc then
            return
        end
    elseif type(templateOrSkinFunc) == "function" then
        skinFunc = templateOrSkinFunc
    else
        return
    end

    local function Apply(frame)
        if not frame then
            return
        end

        if isTemplate then
            if frame._auroraSkinned then
                return
            end

            skinFunc(frame)
            frame._auroraSkinned = true
        else
            skinFunc(frame)
        end
    end

    local acquire = pool.Acquire
    pool.Acquire = function(self, ...)
        local frame, isNew = acquire(self, ...)
        Apply(frame)
        return frame, isNew
    end

    wrappedPools[pool] = true

    if pool.EnumerateActive then
        for frame in pool:EnumerateActive() do
            Apply(frame)
        end
    end
end

local frameAlpha = 0.2
function Util.SetFrameAlpha(alpha)
    frameAlpha = alpha
end
function Util.GetFrameAlpha()
    return frameAlpha
end

--[[ Debug and Testing ]]--

function Util.FindUsage(table, func)
    _G.hooksecurefunc(table, func, function()
        _G.error("Found usage")
    end)
end

function Util.TestHook(table, func, name)
    _G.hooksecurefunc(table, func, function(...)
        _G.print("Test", name, ...)
    end)
end

local debugTools
function Util.TableInspect(focusedTable)
    if not debugTools then
        debugTools = _G.UIParentLoadAddOn("Blizzard_DebugTools")
    end
    _G.DisplayTableInspectorWindow(focusedTable)
end

function Util.SafeCall(func, ...)
    return xpcall(func, private.nop, ...)
end

function Util.Dump(value)
    if not debugTools then
        debugTools = _G.UIParentLoadAddOn("Blizzard_DebugTools")
    end

    if type(value) ~= "function" then
        local v = value
        value = function(...)
            return v
        end
    end

    _G.DevTools_Dump({value()}, "value")
end

Util.OpposingSide = {
    LEFT = "RIGHT",
    RIGHT = "LEFT",
    TOP = "BOTTOM",
    BOTTOM = "TOP"
}
