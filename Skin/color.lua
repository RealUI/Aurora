local _, private = ...

--[[ Lua Globals ]]
-- luacheck: globals type assert next pcall tonumber

--[[ Core ]]
local Aurora = private.Aurora
local Color = Aurora.Color

local colorSelect = _G.CreateFrame("ColorSelect")
local Clamp = _G.Clamp

--[=[ ColorMixin:header
This is an extension of Blizzard's own [ColorMixin]. Created using
[Color.Create].

[ColorMixin]: https://github.com/Gethe/wow-ui-source/blob/live/SharedXML/Util.lua#L683
[Color.Create]: https://github.com/Haleth/Aurora/wiki/Color#colorcreater-g-b-a
--]=]
local colorMeta = _G.CreateFromMixins(_G.ColorMixin)

--[[ ColorMixin:SetRGBA(_r, g, b, a_)
This extends the original method by adding two additional properties,
`self.colorStr` and `self.isAchromatic`.

* `colorStr` - the hex representation of the color _(string)_
* `isAchromatic` - weather or not the color is gray-scale _(boolean)_
--]]
function colorMeta:SetRGBA(r, g, b, a)
    self.r = r
    self.g = g
    self.b = b
    self.a = a
    self.colorStr = self:GenerateHexColor()

    self.isAchromatic = (r == g) and (g == b)
end

function colorMeta:GenerateHexColor()
    local r, g, b, a = self:GetRGBAAsBytes()
    return ("%.2x%.2x%.2x%.2x"):format(a, r, g, b)
end

--[[ ColorMixin:IsEqualTo(_otherColor_ or _r, g, b, a_)
This extends the original method by adding support for non-object colors.
--]]
function colorMeta:IsEqualTo(r, g, b, a)
    if type(r) == "table" then
        return self.r == r.r
            and self.g == r.g
            and self.b == r.b
            and self.a == r.a
    else
        return self.r == r
            and self.g == g
            and self.b == b
            and self.a == a
    end
end

--[[ ColorMixin:Hue(_delta_)
See [Color.Hue]
--]]
function colorMeta:Hue(delta)
    return Color.Hue(self, delta)
end
--[[ ColorMixin:Saturation(_delta_)
See [Color.Saturation]
--]]
function colorMeta:Saturation(delta)
    return Color.Saturation(self, delta)
end
--[[ ColorMixin:Lightness(_delta_)
See [Color.Lightness]
--]]
function colorMeta:Lightness(delta)
    return Color.Lightness(self, delta)
end


--[=[ Color:header
A rainbow of predefined colors as well as a few color modification
functions. These all use a custom [[ColorMixin]] when manipulating
colors. Contains predefined colors as well as a few methods to create
or modify colors.

Aurora also provides an implementation of [[CUSTOM_CLASS_COLORS]].
--]=]

local function ExtractColorValueFromHex(str, index)
	return tonumber(str:sub(index, index + 1), 16) / 255;
end

--[[ Color.Create(_r, g, b[, a]_)
Create a new color object with the given color values. If an alpha value is not
provided, it defaults to `1` or `FF`.

**Args:**
* `r` - red value between 0 and 1 _(number)_
* `g` - green value between 0 and 1 _(number)_
* `b` - blue value between 0 and 1 _(number)_
* `a` - _optional_ alpha value between 0 and 1 _(number)_

OR

* `hexColor` - hexadecimal digets in the format RRGGBB or AARRGGBB _(string)_

**Returns:**
* `color` - a new color object _(ColorMixin)_
--]]
-- Use __index metatable instead of CreateFromMixins to avoid copying all
-- methods into every Color object. This eliminates ~816 table copies per
-- combat session (measured via StutterDiag) and significantly reduces GC
-- pressure at high addon memory usage.
local colorMetaIndex = { __index = colorMeta }
function Color.Create(r, g, b, a)
    local color = _G.setmetatable({}, colorMetaIndex)

    if type(r) == "string" then
        local hexColor = r
        if #hexColor == 8 then
            a, r, g, b = ExtractColorValueFromHex(hexColor, 1), ExtractColorValueFromHex(hexColor, 3), ExtractColorValueFromHex(hexColor, 5), ExtractColorValueFromHex(hexColor, 7)
        elseif #hexColor == 6 then
            r, g, b = ExtractColorValueFromHex(hexColor, 1), ExtractColorValueFromHex(hexColor, 3), ExtractColorValueFromHex(hexColor, 5)
        else
            private.debug("Color.Create input must be hexadecimal digits in format RRGGBB or AARRGGBB.");
        end
    end

    color:OnLoad(r, g, b, a or 1)
    return color
end

--[[ Color.Hue(_color, delta_)
Create a new color where its hue is offset by a percentage from the hue
of the given color. `color` can be a ColorMixin or a table with `r`,
`g`, and `b` keys.

**Args:**
* `color` - the color to be modified _(ColorMixin)_
* `delta` - a decimal from -1 to 1 where 0 confers no change _(number)_

**Returns:**
* `color` - a new color object _(ColorMixin)_
--]]
function Color.Hue(color, delta)
    -- /dump Aurora.Color.green:Hue(-2/3)
    colorSelect:SetColorRGB(color.r, color.g, color.b)
    local h, s, v = colorSelect:GetColorHSV()

    delta = 360 * delta -- convert decimal to degrees
    local hue = h + delta
    if hue < 0 then
        colorSelect:SetColorHSV((360 + hue) % 360, s, v)
    else
        colorSelect:SetColorHSV(hue % 360, s, v)
    end

    return Color.Create(colorSelect:GetColorRGB())
end

--[[ Color.Saturation(_color, delta_)
Create a new color where its saturation is offset by a percentage from
the saturation of the given color. `color` can be a ColorMixin or a
table with `r`, `g`, and `b` keys.

**Args:**
* `color` - the color to be modified _(ColorMixin)_
* `delta` - a decimal from -1 to 1 where 0 confers no change _(number)_

**Returns:**
* `color` - a new color object _(ColorMixin)_
--]]
function Color.Saturation(color, delta)
    -- /dump Aurora.Color.red:Saturation(1)
    colorSelect:SetColorRGB(color.r, color.g, color.b)
    local h, s, v = colorSelect:GetColorHSV()
    colorSelect:SetColorHSV(h, Clamp(s + s * delta, 0, 1), v)

    return Color.Create(colorSelect:GetColorRGB())
end

--[[ Color.Lightness(_color, delta_)
Create a new color where its lightness is offset by a percentage from
the lightness of the given color. `color` can be a ColorMixin or a
table with `r`, `g`, and `b` keys.

**Args:**
* `color` - the color to be modified _(ColorMixin)_
* `delta` - a decimal from -1 to 1 where 0 confers no change _(number)_

**Returns:**
* `color` - a new color object _(ColorMixin)_
--]]
function Color.Lightness(color, delta)
    -- /dump Aurora.Color.red:Lightness(1)
    colorSelect:SetColorRGB(color.r, color.g, color.b)
    local h, s, v = colorSelect:GetColorHSV()
    colorSelect:SetColorHSV(h, s, Clamp(v + v * delta, 0, 1))

    return Color.Create(colorSelect:GetColorRGB())
end


--[[ Color.color
A range of predetermined colors are also available. The values listed
are in red, green, blue order.

* `Color.red` - 0.8, 0.2, 0.2
* `Color.orange` - 0.8, 0.5, 0.2
* `Color.yellow` - 0.8, 0.8, 0.2
* `Color.lime` - 0.5, 0.8, 0.2
* `Color.green` - 0.2, 0.8, 0.2
* `Color.jade` - 0.2, 0.8, 0.5
* `Color.cyan` - 0.2, 0.8, 0.8
* `Color.marine` - 0.2, 0.5, 0.8
* `Color.blue` - 0.2, 0.2, 0.8
* `Color.violet` - 0.5, 0.2, 0.8
* `Color.magenta` - 0.8, 0.2, 0.8
* `Color.ruby` - 0.8, 0.2, 0.5

* `Color.black` - 0, 0, 0
* `Color.grayDark` - 0.25, 0.25, 0.25
* `Color.gray` - 0.5, 0.5, 0.5
* `Color.grayLight` - 0.75, 0.75, 0.75
* `Color.white` - 1, 1, 1


These colors are used extensively in the UI skins.

* `Color.highlight` - defaults to the player's class color
* `Color.button` - defaults to `Color.grayDark`
* `Color.frame` - defaults to `Color.black`
* `Color.border` - defaults to 0.15, 0.15, 0.15 — UI element borders
--]]
Color.red     = Color.Create("FFCC3333") -- CC3333
Color.orange  = Color.Create(0.8, 0.5, 0.2) -- CC8033
Color.yellow  = Color.Create(0.8, 0.8, 0.2) -- CCCC33
Color.lime    = Color.Create(0.5, 0.8, 0.2) -- 80CC33
Color.green   = Color.Create(0.2, 0.8, 0.2) -- 33CC33
Color.jade    = Color.Create(0.2, 0.8, 0.5) -- 33CC80
Color.cyan    = Color.Create(0.2, 0.8, 0.8) -- 33CCCC
Color.marine  = Color.Create(0.2, 0.5, 0.8) -- 3380CC
Color.blue    = Color.Create(0.2, 0.2, 0.8) -- 3333CC
Color.violet  = Color.Create(0.5, 0.2, 0.8) -- 8033CC
Color.magenta = Color.Create(0.8, 0.2, 0.8) -- CC33CC
Color.ruby    = Color.Create(0.8, 0.2, 0.5) -- CC3380

Color.black     = Color.Create(0, 0, 0) -- 000000
Color.grayDark  = Color.Create(0.25, 0.25, 0.25) -- 404040
Color.gray      = Color.Create(0.5, 0.5, 0.5) -- 808080
Color.grayLight = Color.Create(0.75, 0.75, 0.75) -- BFBFBF
Color.white     = Color.Create(1, 1, 1) -- FFFFFF

Color.panelBg   = Color.Create(0.08, 0.08, 0.08, 1) -- 141414, panel/page backgrounds

Color.highlight = Color.Create(0.243, 0.570, 1) -- HIGHLIGHT_LIGHT_BLUE
Color.button    = Color.Create(Color.grayDark.r, Color.grayDark.g, Color.grayDark.b)
Color.frame     = Color.Create(Color.black.r, Color.black.g, Color.black.b, 0.2)
Color.border    = Color.Create(0.15, 0.15, 0.15, 1.0) -- 262626, UI element borders

--[[ Color.Modes
Named palette presets for the color mode system. Each entry defines:
  - tokens: replacement values for the neutral Color.* palette tokens
  - highlightBoost: optional descriptor applied transiently in Color.GetHighlightColor()

Adding a new mode requires only a new table entry — no code changes elsewhere.
--]]
Color.Modes = {
    Normal = {
        tokens = {
            panelBg = Color.Create(0.08, 0.08, 0.08, 1),
            button  = Color.Create(0.25, 0.25, 0.25, 1),
            frame   = Color.Create(0, 0, 0, 0.2),
            border  = Color.Create(0.15, 0.15, 0.15, 1.0),
        },
        highlightBoost = nil, -- no boost; class color returned as-is
    },

    HDR = {
        tokens = {
            panelBg = Color.Create(0.00, 0.00, 0.00, 0.95), -- true black
            button  = Color.Create(0.30, 0.30, 0.34, 1.0),  -- brighter borders to stay visible against darker panels
            frame   = Color.Create(0, 0, 0, 0.7),            -- pure black, higher opacity for more solid panels
            border  = Color.Create(0.40, 0.40, 0.45, 1.0),  -- brighter edge
        },
        highlightBoost = { saturationDelta = 0.15, lightnessDelta = 0.05 },
    },

    Deuteranopia = {
        tokens = {
            panelBg = Color.Create(0.08, 0.08, 0.08, 1),
            button  = Color.Create(0.25, 0.25, 0.25, 1),
            frame   = Color.Create(0, 0, 0, 0.2),
            border  = Color.Create(0.15, 0.15, 0.17, 1.0),  -- slight blue tint aids red/green CVD
        },
        -- Shifts accent away from red/green confusion zone toward blue/yellow axis
        highlightBoost = { hueDelta = 180, saturationDelta = 0.10, lightnessDelta = 0.10 },
    },

    Protanopia = {
        tokens = {
            panelBg = Color.Create(0.08, 0.08, 0.08, 1),
            button  = Color.Create(0.26, 0.26, 0.26, 1),    -- slightly brighter for red-weak vision
            frame   = Color.Create(0, 0, 0, 0.2),
            border  = Color.Create(0.16, 0.16, 0.16, 1.0),  -- brighter border compensates for reduced red
        },
        -- Compensates for red-channel insensitivity; maximises blue/yellow luminance
        highlightBoost = { hueDelta = 200, saturationDelta = 0.10, lightnessDelta = 0.15 },
    },

    Tritanopia = {
        tokens = {
            panelBg = Color.Create(0.08, 0.08, 0.08, 1),
            button  = Color.Create(0.25, 0.25, 0.25, 1),
            frame   = Color.Create(0, 0, 0, 0.2),
            border  = Color.Create(0.16, 0.15, 0.14, 1.0),  -- warmer border aids blue/yellow CVD
        },
        -- Compensates for blue/yellow insensitivity; maximises red/green luminance
        highlightBoost = { hueDelta = 90, saturationDelta = 0.05, lightnessDelta = 0.10 },
    },
}


--[[ Color Mode Switching
Active mode tracking and live palette switching API.
--]]
local activeMode = "Normal"

--[[ Color.GetActiveMode()
Returns the name of the currently active color mode.

**Returns:**
* `name` - the active mode name _(string)_
--]]
function Color.GetActiveMode()
    return activeMode
end

--[[ Color.SetMode(_name_)
Switch the active color mode. Applies the named mode's palette tokens
to the live `Color.*` objects, updates `activeMode` and
`AuroraConfig.colorMode`, broadcasts to all registered elements, and
dispatches a CONFIG_CHANGED event.

No-op if `name` is already the active mode or is not a valid mode name.

**Args:**
* `name` - a key in `Color.Modes` _(string)_
--]]
function Color.SetMode(name)
    if name == activeMode then return end       -- no-op guard (Req 3.4)
    local mode = Color.Modes[name]
    if not mode then return end

    -- Apply neutral palette tokens
    for token, value in _G.pairs(mode.tokens) do
        Color[token]:SetRGBA(value:GetRGBA())
    end

    activeMode = name
    _G.AuroraConfig.colorMode = name

    Color.ApplyPaletteToAll()                   -- re-apply neutral tokens to all tracked frames
    Color.RefreshHighlightColor()               -- recalculate boost + broadcast
    if private.Integration then
        private.Integration.DispatchEvent("CONFIG_CHANGED", "colorMode", name)
    end
end

--[[ Color.PreviewMode(_name_)
Temporarily apply the named mode's palette tokens and highlight boost
to all registered UI elements via `Color.PreviewHighlightColor`. Does
**not** persist the change to `activeMode` or `AuroraConfig.colorMode`.

Used by the RealUI display wizard preview frame to show how a mode
looks before it is confirmed.

**Args:**
* `name` - a key in `Color.Modes` _(string)_
--]]
function Color.PreviewMode(name)
    local mode = Color.Modes[name]
    if not mode then return end

    -- Temporarily apply palette tokens (does not update activeMode)
    for token, value in _G.pairs(mode.tokens) do
        Color[token]:SetRGBA(value:GetRGBA())
    end

    Color.ApplyPaletteToAll()                   -- refresh all tracked frames with new tokens

    -- Resolve highlight boost into (r, g, b)
    local r, g, b = Color.GetClassColor()
    local boost = mode.highlightBoost
    if boost then
        colorSelect:SetColorRGB(r, g, b)
        local h, s, v = colorSelect:GetColorHSV()
        if boost.hueDelta then
            h = (h + boost.hueDelta) % 360
        end
        s = Clamp(s + (boost.saturationDelta or 0), 0, 1)
        v = Clamp(v + (boost.lightnessDelta or 0), 0, 1)
        colorSelect:SetColorHSV(h, s, v)
        r, g, b = colorSelect:GetColorRGB()
    end

    Color.PreviewHighlightColor(r, g, b)
end


private.FACTION_COLORS = {
    Alliance = Color.Create(0.0, 0.2, 0.6),
    Horde = Color.Create(0.5, 0.0, 0.0),
}
private.AZERITE_COLORS = {
    Color.Create(0.3765, 0.8157, 0.9098),
    Color.Create(0.7098, 0.5019, 0.1725),
}
private.COVENANT_COLORS = {
    Kyrian = Color.Create(0.5, 0.45, 0.45),
    Venthyr = Color.Create(0.4, 0.0, 0.0),
    NightFae = Color.Create(0.2, 0.3, 0.4),
    Necrolord = Color.Create(0.1, 0.4, 0.15),
    Maw = Color.Create(0.302, 0.525, 0.553),
}

--[[ Color Management System
Core color management functionality for Aurora theme system.
Provides RGB handling, class color integration, and custom color overrides.
--]]

-- Color validation and sanitization
function Color.ValidateRGB(r, g, b)
    if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then
        return false, "RGB values must be numbers"
    end
    if r < 0 or r > 1 or g < 0 or g > 1 or b < 0 or b > 1 then
        return false, "RGB values must be between 0 and 1"
    end
    return true
end

function Color.SanitizeRGB(r, g, b)
    r = type(r) == "number" and Clamp(r, 0, 1) or 0
    g = type(g) == "number" and Clamp(g, 0, 1) or 0
    b = type(b) == "number" and Clamp(b, 0, 1) or 0
    return r, g, b
end

-- Get class color from CUSTOM_CLASS_COLORS
function Color.GetClassColor(classToken)
    if not classToken then
        classToken = private.charClass.token
    end

    if _G.CUSTOM_CLASS_COLORS and _G.CUSTOM_CLASS_COLORS[classToken] then
        return _G.CUSTOM_CLASS_COLORS[classToken]:GetRGB()
    end

    -- Fallback to default class color
    return 0.5, 0.5, 0.5
end

-- Apply custom color override or use class color with optional mode boost
function Color.GetHighlightColor(config)
    config = config or _G.AuroraConfig

    if not config then
        return Color.GetClassColor()
    end

    if config.customHighlight and config.customHighlight.enabled then
        -- User override: return as-is, no boost (Req 4.3)
        local r, g, b = config.customHighlight.r, config.customHighlight.g, config.customHighlight.b
        return Color.SanitizeRGB(r, g, b)
    end

    local r, g, b = Color.GetClassColor()
    local boost = Color.Modes[activeMode] and Color.Modes[activeMode].highlightBoost
    if boost then
        -- Apply boost transiently; do not mutate stored class color (Req 4.4)
        colorSelect:SetColorRGB(r, g, b)
        local h, s, v = colorSelect:GetColorHSV()
        if boost.hueDelta then
            h = (h + boost.hueDelta) % 360
        end
        s = Clamp(s + (boost.saturationDelta or 0), 0, 1)
        v = Clamp(v + (boost.lightnessDelta or 0), 0, 1)
        colorSelect:SetColorHSV(h, s, v)
        r, g, b = colorSelect:GetColorRGB()
    end
    return r, g, b
end

-- Set highlight color from configuration
function Color.UpdateHighlightColor(config)
    local r, g, b = Color.GetHighlightColor(config)
    Color.highlight:SetRGB(r, g, b)
    return r, g, b
end

--[[ Palette Element Tracking
Frames that use neutral palette tokens (panelBg, button, frame, border) register
here so Color.SetMode can re-apply their colors when the mode changes.
--]]
local paletteElements = {}
local paletteTextures = {}

function Color.RegisterPaletteElement(frame, colorToken, alpha)
    if not frame then return end
    if frame._auroraPaletteOptOut then return end
    local key = frame
    if type(frame) == "table" and frame.GetName then
        -- Some widget types expose a GetName reference that isn't a valid
        -- method for that object (fails as "bad self"); fall back to using
        -- the frame itself as the table key in that case.
        local ok, name = pcall(frame.GetName, frame)
        if ok and name then
            key = name
        end
    end
    paletteElements[key] = {
        frame = frame,
        colorToken = colorToken,
        alpha = alpha,
    }
end

function Color.RegisterPaletteTexture(texture, colorToken, alpha)
    if not texture then return end
    paletteTextures[texture] = {
        texture = texture,
        colorToken = colorToken,
        alpha = alpha,
    }
end

function Color.ApplyPaletteToAll()
    Color._applyingPalette = true
    local count = 0
    for key, data in _G.next, paletteElements do
        local frame = data.frame
        local color = Color[data.colorToken]
        if frame and color then
            count = count + 1
            -- Use the higher of stored alpha and token alpha.
            -- This lets HDR mode increase opacity beyond the user's slider setting.
            local a = _G.math.max(data.alpha or 0, color.a or 0)
            local backdropColor = Color.Lightness(color, -0.3)
            local ok, err = _G.pcall(function()
                frame:SetBackdropColor(backdropColor.r, backdropColor.g, backdropColor.b, a)
                if frame._auroraPaletteBorderDefault then
                    frame:SetBackdropBorderColor(color.r, color.g, color.b, 1)
                end
            end)
            if not ok then
                private.debug("Color", "Failed to update palette element", key, ":", err)
            end
        end
    end
    Color._applyingPalette = false
    local texCount = 0
    for tex, data in _G.next, paletteTextures do
        local color = Color[data.colorToken]
        if tex and color then
            texCount = texCount + 1
            local ok, err = _G.pcall(function()
                tex:SetVertexColor(color.r, color.g, color.b)
                if data.alpha then
                    tex:SetAlpha(data.alpha)
                end
            end)
            if not ok then
                private.debug("Color", "Failed to update palette texture", tostring(tex), ":", err)
            end
        end
    end
end

-- Highlight Color Application System
-- Tracks all themed elements that use highlight colors for dynamic updates

local highlightedElements = {}

-- Register an element that uses highlight color
function Color.RegisterHighlightElement(element, updateFunc)
    if not element then return end

    local key = element
    if type(element) == "table" and element.GetName then
        key = element:GetName() or element
    end

    highlightedElements[key] = {
        element = element,
        updateFunc = updateFunc
    }
end

-- Unregister an element from highlight tracking
function Color.UnregisterHighlightElement(element)
    if not element then return end

    local key = element
    if type(element) == "table" and element.GetName then
        key = element:GetName() or element
    end

    highlightedElements[key] = nil
end

-- Apply highlight color to all registered elements
function Color.ApplyHighlightToAll()
    local r, g, b = Color.highlight:GetRGB()

    for key, data in next, highlightedElements do
        if data.element and data.updateFunc then
            local success, err = pcall(data.updateFunc, data.element, r, g, b)
            if not success then
                private.debug("Color", "Failed to update element", key, ":", err)
            end
        end
    end
end

-- Update highlight color and apply to all elements
function Color.RefreshHighlightColor(config)
    Color.UpdateHighlightColor(config)
    Color.ApplyHighlightToAll()
end

-- Color consistency enforcement
-- Ensures all themed elements maintain consistent color application

local colorConsistencyRules = {
    -- Rule: All highlight colors should match the configured highlight
    highlight = function(element)
        if element.SetBackdropBorderColor then
            element:SetBackdropBorderColor(Color.highlight:GetRGB())
        end
    end,

    -- Rule: All frame backgrounds should use frame color
    frame = function(element)
        if element.SetBackdropColor then
            element:SetBackdropColor(Color.frame:GetRGB())
        end
    end,

    -- Rule: All buttons should use button color
    button = function(element)
        if element.SetBackdropColor then
            element:SetBackdropColor(Color.button:GetRGB())
        end
    end,
}

-- Apply color consistency rule to an element
function Color.EnforceConsistency(element, ruleType)
    if not element or not ruleType then return end

    local rule = colorConsistencyRules[ruleType]
    if rule then
        local success, err = pcall(rule, element)
        if not success then
            private.debug("Color", "Failed to enforce consistency for", ruleType, ":", err)
        end
    end
end

-- Preview color change without saving
function Color.PreviewHighlightColor(r, g, b)
    if not Color.ValidateRGB(r, g, b) then
        return false
    end

    Color.highlight:SetRGB(r, g, b)
    Color.ApplyHighlightToAll()
    return true
end

--[[ CUSTOM_CLASS_COLORS:header
This is a community developed standard, and is intended to be a drop-in
replacement for Blizzard's RAID_CLASS_COLORS. It's purpose is to allow
the user to change the in-game class colors without tainting the
default UI. [ClassColors], created by Phanx, was the original
implementation of this idea.

[ClassColors]: https://github.com/phanx-wow/ClassColors
--]]

local meta = {}

--[[ CUSTOM_CLASS_COLORS:RegisterCallback(_handler_ or _method, handler_)
Registers a function to be called when values in `CUSTOM_CLASS_COLORS`
are changed.

**Args:**
* `handler` - the function to be called _(function)_

or

**Args:**
* `method` - the name of a method _(string)_
* `handler` - the method handler _(table or Frame)_
--]]
local callbacks, numCallbacks = {}, 0
function meta:RegisterCallback(method, handler)
    --print("CUSTOM_CLASS_COLORS:RegisterCallback", method, handler)
    assert(type(method) == "string" or type(method) == "function", "Bad argument #1 to :RegisterCallback (string or function expected)")
    if type(method) == "string" then
        assert(type(handler) == "table", "Bad argument #2 to :RegisterCallback (table expected)")
        assert(type(handler[method]) == "function", "Bad argument #1 to :RegisterCallback (method \"" .. method .. "\" not found)")
        method = handler[method]
    end
    -- assert(not callbacks[method] "Callback already registered!")
    callbacks[method] = handler or true
    numCallbacks = numCallbacks + 1
end

--[[ CUSTOM_CLASS_COLORS:UnregisterCallback(_handler_ or _method, handler_)
Removes a function from the callback registry, so it will no longer be
called when class colors are changed.

**Args:**
* `handler` - a function previously registered _(function)_

or

**Args:**
* `method` - the name of a registered method _(string)_
* `handler` - the method handler _(table or Frame)_
--]]
function meta:UnregisterCallback(method, handler)
    --print("CUSTOM_CLASS_COLORS:UnregisterCallback", method, handler)
    assert(type(method) == "string" or type(method) == "function", "Bad argument #1 to :UnregisterCallback (string or function expected)")
    if type(method) == "string" then
        assert(type(handler) == "table", "Bad argument #2 to :UnregisterCallback (table expected)")
        assert(type(handler[method]) == "function", "Bad argument #1 to :UnregisterCallback (method \"" .. method .. "\" not found)")
        method = handler[method]
    end
    -- assert(callbacks[method], "Callback not registered!")
    callbacks[method] = nil
    numCallbacks = numCallbacks - 1
end
local function DispatchCallbacks()
    if numCallbacks < 1 then return end
    --print("CUSTOM_CLASS_COLORS:DispatchCallbacks", numCallbacks)
    for method, handler in next, callbacks do
        local ok, err = pcall(method, handler ~= true and handler or nil)
        if not ok then
            _G.print("ERROR:", err)
        end
    end
end


--[[ CUSTOM_CLASS_COLORS:NotifyChanges()
Notifies other addons that class colors have changed.
--]]
local colorCache
function meta:NotifyChanges()
    --print("CUSTOM_CLASS_COLORS:NotifyChanges", colorCache)
    local hasChanged = false
    if colorCache then
        for i = 1, #_G.CLASS_SORT_ORDER do
            local classToken = _G.CLASS_SORT_ORDER[i]
            local color = self[classToken]
            local cache = colorCache[classToken]
            if not cache then
                colorCache[classToken] = {}
                cache = colorCache[classToken]
            end

            if not color:IsEqualTo(cache) then
                --print("Change found in", classToken)
                cache.r = color.r
                cache.g = color.g
                cache.b = color.b
                cache.colorStr = color.colorStr

                hasChanged = true
            end
        end
    end

    if hasChanged then
        DispatchCallbacks()
    end
end

local classTokens = {}
for classToken, className in next, _G.LOCALIZED_CLASS_NAMES_MALE do
    classTokens[className] = classToken
end
for classToken, className in next, _G.LOCALIZED_CLASS_NAMES_FEMALE do
    classTokens[className] = classToken
end

--[[ CUSTOM_CLASS_COLORS:GetClassToken(_className_)
Returns the locale-independent token (eg. "WARLOCK") for the specified
localized class name (eg. "Warlock" or "Hexenmeister").
--]]
function meta:GetClassToken(className)
    return className and classTokens[className]
end


function private.setColorCache(newCache)
    if colorCache then return end
    --print("setColorCache", newCache)

    colorCache = newCache
    private.classColorsReset(_G.CUSTOM_CLASS_COLORS, newCache)
end
function private.classColorsReset(oldColors, newColors)
    local classToken, oldColor, newColor

    --print("classColorsReset", oldColors, newColors)
    for i = 1, #_G.CLASS_SORT_ORDER do
        classToken = _G.CLASS_SORT_ORDER[i]
        newColor = newColors[classToken]
        oldColor = oldColors[classToken]
        --print("Class", i, classToken, newColor, oldColor)

        if newColor then
            if oldColor then
                oldColor.r = newColor.r
                oldColor.g = newColor.g
                oldColor.b = newColor.b
                oldColor.colorStr = newColor.colorStr
            else
                oldColors[classToken] = {
                    r = newColor.r,
                    g = newColor.g,
                    b = newColor.b,
                    colorStr = newColor.colorStr
                }
            end
        end
    end

    _G.CUSTOM_CLASS_COLORS:NotifyChanges()
end
function private.updateHighlightColor()
    --print("updateHighlightColor")
    Color.highlight:SetRGB(_G.CUSTOM_CLASS_COLORS[private.charClass.token]:GetRGB())
end


-- If another addon (e.g. ClassColors) already defined CUSTOM_CLASS_COLORS,
-- skip creating our own implementation but keep the helper functions above.
if _G.CUSTOM_CLASS_COLORS then return end

_G.CUSTOM_CLASS_COLORS = {}
_G.setmetatable(_G.CUSTOM_CLASS_COLORS, {__index = meta}) do
	for className, classColor in next, _G.RAID_CLASS_COLORS do
		_G.CUSTOM_CLASS_COLORS[className] = Color.Create(classColor.r, classColor.g, classColor.b)
	end
end

_G.CUSTOM_CLASS_COLORS:RegisterCallback(function()
    --print("color CCC:RegisterCallback")
    private.updateHighlightColor()
end)
