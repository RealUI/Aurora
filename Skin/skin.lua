local _, private = ...

--[[ Lua Globals ]]
-- luacheck: globals next

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

do -- Frame
    function Skin.FrameTypeFrame(Frame)
        Base.SetBackdrop(Frame, Color.frame, Util.GetFrameAlpha())
    end
end

--[[ Button state store (B261, Layer 1)

Everything the button skin and `Base.SetHighlight` know about a frame lives
here, never on the frame: a key written onto a Blizzard frame is addon-owned,
and Blizzard code that reads it runs tainted from then on
(objective-tracker-taint.md, rules 1 and 9).

One record per frame, created on first use:

    buttonState[frame] = {
        -- Skin.FrameTypeButton / Skin.SetButtonColor
        minimal        = boolean|nil,   -- glyph-only button: no backdrop colour, the textures carry the state
        enabledColor   = Color,         -- set means "skinned by Skin.FrameTypeButton"
        disabledColor  = Color,
        colorToken     = "button"|"frame"|nil, -- the live token the enabled colour came from (B164, later)
        paintedEnabled = boolean|nil,   -- the state Repaint last painted; dedupe only
        hooked         = true|nil,      -- Enable/Disable/SetEnabled are hooked
        -- Skin.SetButtonTextures
        textures       = {Texture, ...}, -- glyphs that follow the button's colour
        -- Base.SetHighlight (api.lua)
        onEnter, onLeave = function,
        returnColor    = Color,
        highlighted, highlightLocked = boolean|nil,
        highlightHooked = true|nil,     -- OnEnter/OnLeave and the lock hooks are installed
        -- Skin.TaintSafeFrameTypeButton (Layer 2)
        layer2         = "panel"|"flat"|nil, -- the shape; set means "drawn by the engine, no hooks"
        panel          = Frame|nil,     -- the Aurora-owned frame with the border and fill (shape "panel")
    }

A record with no `enabledColor` belongs to a frame that only had
`Base.SetHighlight` or `Skin.SetButtonTextures` called on it, or to a Layer 2
button (`layer2` set), which has no colours in the store at all.

In Layer 1 the frame that carries the backdrop is not stored: it is the button
itself, and a value that references its own key keeps a weak-keyed entry alive
for good (Lua 5.1 has no ephemerons). In Layer 2 it is `panel`, a frame of
Aurora's own that holds no reference back to the button.
--]]
local buttonState = _G.setmetatable({}, {__mode = "k"})
local issecretvalue = _G.issecretvalue -- 12.x only; nil on the classic clients

local function GetButtonState(frame)
    local state = buttonState[frame]
    if not state then
        state = {}
        buttonState[frame] = state
    end
    return state
end

-- Internal: api.lua loads before this file and reaches the store through this
-- at call time. Not part of Aurora's API.
function private.GetButtonState(frame, create)
    if create then
        return GetButtonState(frame)
    end
    return buttonState[frame]
end

do -- Button
    local function SetTexturesToColor(textures, color)
        if textures then
            for _, texture in next, textures do
                texture:SetVertexColor(color:GetRGB())
            end
        end
    end
    local function MinimalOnEnter(self, highlight, alpha)
        SetTexturesToColor(buttonState[self].textures, highlight)
    end
    local function MinimalOnLeave(self, returnColor)
        SetTexturesToColor(buttonState[self].textures, returnColor)
    end

    -- Post-hook body for Enable, Disable and SetEnabled, so it runs inside
    -- whichever Blizzard update changed the button. It takes no argument from
    -- the hooked call: SetEnabled can be handed a secret boolean, and testing
    -- that is an error in Blizzard's execution. It writes the record and
    -- recolours what Aurora put on the button, nothing else, and no key on
    -- the button itself.
    --
    -- Layer 1 limit: Base.SetBackdropColor replaces `backdropColor` and
    -- `backdropBorderColor` inside the button's `backdropInfo` table. That
    -- table is Aurora's (made at skin time) and no Blizzard code reads those
    -- two keys; it leaves the button with the backdrop, in Layer 2.
    local function Repaint(Button)
        local state = buttonState[Button]
        if not state or not state.enabledColor then
            return
        end

        local enabled = Button:IsEnabled()
        if issecretvalue and issecretvalue(enabled) then
            return
        end
        enabled = not not enabled
        if state.paintedEnabled == enabled then
            return
        end
        state.paintedEnabled = enabled

        if state.minimal then
            SetTexturesToColor(state.textures, enabled and state.enabledColor or state.disabledColor)
        elseif enabled then
            Base.SetBackdropColor(Button, state.enabledColor)
            SetTexturesToColor(state.textures, Color.white)
        else
            Base.SetBackdropColor(Button, state.disabledColor)
            SetTexturesToColor(state.textures, Color.gray)
        end
    end

    --[[ Skin.SetButtonColor(_Button, color[, alpha, disabledColor]_)
    Sets the colours a button skinned with `Skin.FrameTypeButton` shows when it
    is enabled and when it is disabled, and paints the enabled colour straight
    away. A button that is disabled at that moment takes its disabled colour
    the next time Blizzard enables or disables it.

    For a minimal button (scroll bar steppers) no backdrop is touched: the
    colours are what its glyph textures take.

    Called on a frame that was never skinned, it gives the frame a backdrop and
    a record, but nothing repaints it when it is enabled or disabled.

    **Args:**
    * `Button`        - the button to colour _(Button)_
    * `color`         - the enabled colour; the backdrop is drawn 30% darker, the border in this colour _(Color)_
    * `alpha`         - _optional_ the backdrop alpha, defaults to the colour's own _(number)_
    * `disabledColor` - _optional_ the disabled colour; `false` uses the enabled
                        colour for both states, nil a 30% darker one _(Color|false)_
    --]]
    function Skin.SetButtonColor(Button, color, alpha, disabledColor)
        local state = GetButtonState(Button)

        local r, g, b, a, _
        if state.minimal then
            r, g, b = color:GetRGB()
        else
            Base.SetBackdrop(Button, color, alpha)
            _, _, _, a = Button:GetBackdropColor()
            r, g, b = Button:GetBackdropBorderColor()
        end

        local enabledColor = Color.Create(r, g, b, alpha or a)
        state.enabledColor = enabledColor

        if disabledColor == false then
            state.disabledColor = enabledColor
        elseif disabledColor then
            state.disabledColor = disabledColor
        else
            state.disabledColor = Color.Lightness(enabledColor, -0.3)
        end

        -- Nothing reads this yet. A live palette (B164) can repaint from it.
        if color == Color.button then
            state.colorToken = "button"
        elseif color == Color.frame then
            state.colorToken = "frame"
        else
            state.colorToken = nil
        end
    end

    --[[ Skin.GetButtonColor(_Button_)
    Returns the colours set by `Skin.SetButtonColor`. Both are nil for a frame
    that was never skinned with `Skin.FrameTypeButton`, which makes this the
    test for "is this a skinned button".

    **Args:**
    * `Button` - the button to read _(Button)_

    **Returns:**
    * `enabledColor`  - the colour shown when enabled _(Color|nil)_
    * `disabledColor` - the colour shown when disabled _(Color|nil)_
    --]]
    function Skin.GetButtonColor(Button)
        local state = buttonState[Button]
        if state then
            return state.enabledColor, state.disabledColor
        end
    end

    --[[ Skin.SetButtonTextures(_Button, textures_)
    Registers the glyphs of a button (arrows, a cross, a minimise bar) so they
    follow its state: white when enabled and grey when disabled, or the
    button's own colours and the highlight colour on a minimal button. The list
    replaces any earlier one and is kept as given, not copied.

    Works on any frame, skinned or not; on a frame that is not skinned with
    `Skin.FrameTypeButton` nothing recolours them.

    **Args:**
    * `Button`   - the button the glyphs belong to _(Button)_
    * `textures` - a list of textures or lines, or nil to clear it _(table|nil)_
    --]]
    function Skin.SetButtonTextures(Button, textures)
        GetButtonState(Button).textures = textures
    end

    --[[ Skin.GetButtonTextures(_Button_)
    Returns the list given to `Skin.SetButtonTextures`.

    **Args:**
    * `Button` - the button to read _(Button)_

    **Returns:**
    * `textures` - the list itself, or nil when none was set _(table|nil)_
    --]]
    function Skin.GetButtonTextures(Button)
        local state = buttonState[Button]
        return state and state.textures
    end

    --[[ Skin.IterateButtonState()
    Development only. Iterates the button state store for the scan in
    `Aurora/dev/buttonscan.lua`: every frame with a record, and the record.
    Yields nothing unless `private.isDev` is set; the flag is read here and not
    when this file loads, because the dev files that set it load later.

    A record with `enabledColor` set is a button skinned with
    `Skin.FrameTypeButton`. The records are the live ones: read them, never
    write them.

    **Returns:**
    * an iterator for a generic `for`, yielding `frame, state` _(function)_
    --]]
    function Skin.IterateButtonState()
        if not private.isDev then
            return private.nop
        end
        return next, buttonState
    end

    --[[ Skin.FrameTypeButton(_Button[, OnEnter, OnLeave, minimal]_)
    The base button skin: clears Blizzard's state textures, gives the button a
    backdrop in the button colour, a highlight on hover and a repaint when
    Blizzard enables or disables it. Nothing is written onto the button except
    the backdrop (which goes in Layer 2); the state is in the store above.

    **Args:**
    * `Button`  - the button to skin _(Button)_
    * `OnEnter` - _optional_ replaces the default highlight, see `Base.SetHighlight` _(function)_
    * `OnLeave` - _optional_ replaces the default highlight removal _(function)_
    * `minimal` - _optional_ true for a glyph-only button with no backdrop
                  colour (scroll bar steppers); nil keeps what an earlier call
                  set _(boolean)_

    **Returns:**
    * `skinned` - true; false when the button is already a Layer 2 button
                  (`Skin.TaintSafeFrameTypeButton`) and was left alone. A
                  caller that goes on to touch the button checks it _(boolean)_
    --]]
    function Skin.FrameTypeButton(Button, OnEnter, OnLeave, minimal)
        local state = GetButtonState(Button)
        if state.layer2 then
            -- Already a Layer 2 button (Skin.TaintSafeFrameTypeButton). The
            -- Layer 1 skin would put its backdrop, methods and state hooks
            -- over the engine-drawn states: a second skin call on the same
            -- button somewhere else. Callers that go on to touch the button
            -- test the false; one that does not errors on its next backdrop
            -- call (the button has no backdrop methods), which names the file.
            private.debug("FrameTypeButton: already a Layer 2 button", Button:GetDebugName())
            return false
        end
        if minimal ~= nil then
            state.minimal = not not minimal
        end

        if not state.hooked then
            _G.hooksecurefunc(Button, "Disable", Repaint)
            _G.hooksecurefunc(Button, "Enable", Repaint)
            _G.hooksecurefunc(Button, "SetEnabled", Repaint)
            state.hooked = true
        end

        if Button.ClearNormalTexture then
            Button:ClearNormalTexture()
            Button:ClearPushedTexture()
            Button:ClearDisabledTexture()

            local highlight = Button:GetHighlightTexture()
            if highlight then
                highlight:Hide()
            end
        elseif Button.SetNormalTexture then
            Button:SetNormalTexture("")
            Button:SetPushedTexture("")
            Button:SetHighlightTexture("")
            Button:SetDisabledTexture("")
        end

        if state.minimal then
            Skin.SetButtonColor(Button, Color.grayLight, 1, Color.gray)
            Base.SetHighlight(Button, MinimalOnEnter, MinimalOnLeave)
        else
            -- B164: the live token, not a copy taken at file load (which
            -- predated the saved colour mode and so was always Normal's).
            Skin.SetButtonColor(Button, Color.button, nil, Color.buttonDisabled)
            Base.SetHighlight(Button, OnEnter, OnLeave)
        end
        return true
    end
end

--[[ Layer 2 state greys (B261, AT-D3)

A Layer 2 button shows hover, pressed and disabled through the engine's own
state textures, so these three numbers are the whole look of those states.
Plain greys: there is no highlight-colour variant and no option for one.

    hover     white added over the fill, at this alpha
    pressed   this much lighter than the fill at rest (0 to 1, added to each
              of red, green and blue)
    disabled  black over the fill, at this alpha

LAYER2_PRESSED_STEP is the value the owner picks in game (CHECKPOINT V of the
aurora-taint-pass spec): change this one number and reload. It has to stay
clearly visible, which means at least three times LAYER2_HOVER_ALPHA.
--]]
local LAYER2_HOVER_ALPHA = 0.08
local LAYER2_PRESSED_STEP = 0.25
local LAYER2_DISABLED_ALPHA = 0.45

do -- Button, Layer 2
    local plain = private.textures.plain

    local function ClearStateTextures(Button)
        if Button.ClearNormalTexture then
            Button:ClearNormalTexture()
            Button:ClearPushedTexture()
            Button:ClearDisabledTexture()
            if Button.ClearHighlightTexture then
                Button:ClearHighlightTexture()
            end
        elseif Button.SetNormalTexture then
            Button:SetNormalTexture("")
            Button:SetPushedTexture("")
            Button:SetDisabledTexture("")
            Button:SetHighlightTexture("")
        end
    end

    -- Tints one of the engine's state textures. The alpha and the blend mode
    -- are set outright, because a caller may have swept the button's regions
    -- to alpha 0 first (the Mists panel button). Never Show or Hide here:
    -- the engine shows and hides the normal, pushed and disabled textures
    -- itself, and a Show would leave the pushed one on screen until the next
    -- state change.
    local function Paint(texture, blendMode, r, g, b, alpha)
        if texture then
            texture:SetBlendMode(blendMode)
            texture:SetVertexColor(r, g, b)
            texture:SetAlpha(alpha)
        end
    end

    -- Puts a state texture inside the panel's border, so pressed, disabled
    -- and hover cover the fill and leave the border as it is. Anchored to
    -- the border's corner pieces, so it follows the panel when a caller
    -- moves it or gives its backdrop offsets.
    local function FitInsideBorder(texture, panel)
        if not texture then
            return
        end

        local topLeft = Util.GetNineSlicePiece(panel, "TopLeftCorner")
        local bottomRight = Util.GetNineSlicePiece(panel, "BottomRightCorner")
        texture:ClearAllPoints()
        if topLeft and bottomRight then
            texture:SetPoint("TOPLEFT", topLeft, "BOTTOMRIGHT")
            texture:SetPoint("BOTTOMRIGHT", bottomRight, "TOPLEFT")
        else
            texture:SetPoint("TOPLEFT", panel, 1, -1)
            texture:SetPoint("BOTTOMRIGHT", panel, -1, 1)
        end
    end

    --[[ Skin.TaintSafeFrameTypeButton(_Button, shape_)
    The Layer 2 button skin (B261), for a button whose state Blizzard changes
    inside a protected or secret-value update. Use it instead of
    `Skin.FrameTypeButton`, never after it.

    Nothing of Aurora's ends up on the button: no field, no method, no
    backdrop, no hook on `Enable`, `Disable` or `SetEnabled`, no script. The
    engine draws every state from the button's own state textures, so a
    button Blizzard disables with no script firing still looks disabled, and
    no Aurora code runs when its state changes. The label keeps Blizzard's
    font objects and so greys by itself.

    Two shapes. A third, leaving the button Blizzard's, is the absence of a
    call (and a line under "Deliberately unskinned" in `docs/KnownIssues.md`).

    * `"panel"` - a frame of Aurora's own, a child of the button one frame
      level below it, carries the 1px border and the fill, exactly as a
      `Skin.FrameTypeButton` button looks at rest. Pressed, disabled and
      hover are the button's state textures, fitted inside the border. For a
      button that may have a child frame: not a `ResizeLayoutFrame` or other
      frame that measures its children, not pooled, not a frame a secure
      system lays out.
    * `"flat"` - the button's four state textures and nothing else: a flat
      fill in the button colour, no border, no frame created.

    This clears the button's state textures and nothing more. Art a template
    keeps in other regions (the `Left`/`Middle`/`Right` plates of a panel
    button, a close button's `Border`) is the caller's to hide:
    `Skin.TaintSafeUIPanelButtonTemplate` does it for panel buttons.

    It reads `Color.button` when it runs, like `Skin.FrameTypeButton`. A
    second call repaints the same button and makes no second panel.

    **Args:**
    * `Button` - the button to skin _(Button)_
    * `shape`  - `"panel"` or `"flat"` _(string)_

    **Returns:**
    * `panel` - the frame carrying the border and fill, for glyphs and for
                backdrop options; nil for `"flat"` _(Frame|nil)_
    --]]
    function Skin.TaintSafeFrameTypeButton(Button, shape)
        if shape ~= "panel" and shape ~= "flat" then
            _G.error('`shape` must be "panel" or "flat"')
        end

        local state = GetButtonState(Button)
        if state.enabledColor then
            -- Already through Skin.FrameTypeButton. Its backdrop, methods and
            -- hooks cannot be taken off the button again, so painting state
            -- textures over them would only hide the mistake.
            private.debug("TaintSafeFrameTypeButton: already skinned with FrameTypeButton", Button:GetDebugName())
            return
        end
        state.layer2 = shape

        ClearStateTextures(Button)

        local panel = state.panel
        local r, g, b
        if shape == "panel" then
            if not panel then
                -- A plain frame takes no mouse input, so clicks reach the button.
                panel = _G.CreateFrame("Frame", nil, Button)
                panel:SetAllPoints(Button)
                state.panel = panel
            end
            -- Below the button, so its label and state textures draw on top.
            panel:SetFrameLevel(_G.math.max(Button:GetFrameLevel() - 1, 0))
            panel:Show()

            Base.SetBackdrop(panel, Color.button)
            -- One sublevel pair above a frame backdrop's (BACKGROUND -8 and
            -- -7, backdrop.lua:33-36). A button that is a direct child of a
            -- skinned frame puts its panel at that frame's own level, where
            -- two regions on one layer and sublevel have no defined order,
            -- and the frame's fill could be drawn over the panel's.
            panel:SetBackdropLayer("BACKGROUND", -6)
            r, g, b = panel:GetBackdropColor()
        else
            if panel then
                panel:Hide()
            end

            r, g, b = Color.button:GetRGB()
            Button:SetNormalTexture(plain)
            Paint(Button:GetNormalTexture(), "BLEND", r, g, b, 1)
        end

        Button:SetPushedTexture(plain)
        local pushed = Button:GetPushedTexture()
        Button:SetDisabledTexture(plain)
        local disabled = Button:GetDisabledTexture()
        if shape == "panel" then
            -- Both lie over the panel, so the fill (a gradient, under
            -- standalone Aurora) and any glyph on the panel show through:
            -- pressed adds white, disabled lays black over them.
            Paint(pushed, "ADD", 1, 1, 1, LAYER2_PRESSED_STEP)
            Paint(disabled, "BLEND", 0, 0, 0, LAYER2_DISABLED_ALPHA)
        else
            -- Each is drawn in place of the normal texture, so each has to
            -- be the finished colour.
            Paint(pushed, "BLEND", _G.math.min(r + LAYER2_PRESSED_STEP, 1), _G.math.min(g + LAYER2_PRESSED_STEP, 1),
                _G.math.min(b + LAYER2_PRESSED_STEP, 1), 1)
            local keep = 1 - LAYER2_DISABLED_ALPHA
            Paint(disabled, "BLEND", r * keep, g * keep, b * keep, 1)
        end

        Button:SetHighlightTexture(plain, "ADD")
        local highlight = Button:GetHighlightTexture()
        Paint(highlight, "ADD", 1, 1, 1, LAYER2_HOVER_ALPHA)

        if shape == "panel" then
            FitInsideBorder(pushed, panel)
            FitInsideBorder(disabled, panel)
            FitInsideBorder(highlight, panel)
            return panel
        end
    end

    --[[ Skin.GetButtonPanel(_Button_)
    Returns the frame that carries the border and fill of a button skinned
    with `Skin.TaintSafeFrameTypeButton(Button, "panel")`. It is Aurora's
    frame: glyphs, backdrop options and anchors on it are fine, and nothing
    on it is read by Blizzard.

    **Args:**
    * `Button` - the button to read _(Button)_

    **Returns:**
    * `panel` - the frame, or nil for a flat button, a Layer 1 button or a
                frame that was never skinned _(Frame|nil)_
    --]]
    function Skin.GetButtonPanel(Button)
        local state = buttonState[Button]
        if state and state.layer2 == "panel" then
            return state.panel
        end
    end

    --[[ Skin.TaintSafeUIPanelScrollBar(_ScrollBar_)
    The Layer 2 form of the classic `UIPanelScrollBarTemplate` slider (the bar
    of `UIPanelScrollFrameTemplate` and `FauxScrollFrameTemplate`), for a bar
    Blizzard updates inside a protected or gated execution. Use it instead of
    `Skin.UIPanelScrollFrameTemplate` or `Skin.FauxScrollFrameTemplate` for
    that frame, never after them.

    Both steppers get the panel shape with an arrow drawn on the panel, and
    no `direction` key. The thumb is a texture of the slider, restyled in
    place (rule 3): a plain fill in the button colour at the 16x24 the Layer 1
    skin gives it. Nothing is written on the slider or the scroll frame.

    For `UIPanelScrollUpButtonTemplate` and `UIPanelScrollDownButtonTemplate`
    (`Blizzard_SharedXML/SecureUIPanelTemplates.xml`, the classic trees):
    18x16, state textures set in XML only. Not for `MinimalScrollBar` or the
    trim bars, whose steppers redraw their own atlas on every state change.

    **Args:**
    * `ScrollBar` - the slider, `ScrollFrame.ScrollBar` _(Slider)_
    --]]
    function Skin.TaintSafeUIPanelScrollBar(ScrollBar)
        local steppers = {
            {ScrollBar.ScrollUpButton, "arrowUp"},
            {ScrollBar.ScrollDownButton, "arrowDown"},
        }
        for _, stepper in next, steppers do
            local panel = Skin.TaintSafeFrameTypeButton(stepper[1], "panel")
            local arrow = panel:CreateTexture(nil, "ARTWORK")
            arrow:SetSize(14, 6)
            arrow:SetPoint("CENTER")
            Base.SetTexture(arrow, stepper[2])
        end

        local thumb = ScrollBar.ThumbTexture
        thumb:SetTexture(plain)
        thumb:SetVertexColor(Color.button:GetRGB())
        thumb:SetSize(16, 24)
    end

    --[[ Skin.TaintSafeNavButton(_Button, arrowTexture_)
    The Layer 2 form of a page button (`Skin.NavButtonPrevious` and
    `Skin.NavButtonNext` in Layer 1): the panel shape, its box 5 inside the
    button, with the arrow drawn on the panel. For a 32x32 button whose state
    textures are set in XML only (the classic spell book's page buttons).

    **Args:**
    * `Button`       - the button _(Button)_
    * `arrowTexture` - `"arrowLeft"` or `"arrowRight"`, a texture registered
                       with `Base.RegisterTexture` _(string)_
    --]]
    function Skin.TaintSafeNavButton(Button, arrowTexture)
        local panel = Skin.TaintSafeFrameTypeButton(Button, "panel")
        panel:ClearAllPoints()
        panel:SetPoint("TOPLEFT", Button, 5, -5)
        panel:SetPoint("BOTTOMRIGHT", Button, -5, 5)

        local bg = panel:GetBackdropTexture("bg")
        local arrow = panel:CreateTexture(nil, "ARTWORK")
        arrow:SetPoint("TOPLEFT", bg, 8, -5)
        arrow:SetPoint("BOTTOMRIGHT", bg, -8, 5)
        Base.SetTexture(arrow, arrowTexture)
    end

    --[[ Skin.TaintSafePanelCloseButton(_Button_)
    The Layer 2 form of `Skin.UIPanelCloseButton`: the panel shape with the
    cross drawn on the panel, the box where the Layer 1 skin draws it. The
    panel is moved, never the button, so the button keeps Blizzard's size,
    anchor and hit rect.

    * Classic flavours: `UIPanelCloseButton` is 32x32 and the box sits 4, 11,
      10 and 5 inside it (left, right, top, bottom).
    * Retail and Forever: a 17x17 box at the button's top right. On Forever,
      `UIPanelCloseButtonDefaultAnchors` makes the button 28x28 at
      `TOPRIGHT 0, 3` (`Blizzard_SharedXML/Camelot/SharedUIPanelTemplates.lua:1-5`),
      so the box goes 3 lower to land where the Layer 1 skin put it.

    Not `Skin.TaintSafeUIPanelCloseButton`, the flat 22x22 "x" of the
    TaintSafe portrait frames, which resizes the button.

    **Args:**
    * `Button` - the close button _(Button)_
    --]]
    function Skin.TaintSafePanelCloseButton(Button)
        local panel = Skin.TaintSafeFrameTypeButton(Button, "panel")
        panel:ClearAllPoints()
        if not private.isRetail then
            panel:SetPoint("TOPLEFT", Button, 4, -10)
            panel:SetPoint("BOTTOMRIGHT", Button, -11, 5)
        else
            local mixin = _G.UIPanelCloseButtonDefaultAnchorsMixin
            if private.isForever and mixin and Button.OnLoad and Button.OnLoad == mixin.OnLoad then
                panel:SetPoint("TOPRIGHT", Button, -2.8, -6)
            else
                panel:SetPoint("TOPRIGHT", Button, -3.8, -3)
            end
            panel:SetSize(17, 17)
        end

        local bg = panel:GetBackdropTexture("bg")
        for i = 1, 2 do
            local line = panel:CreateLine(nil, "ARTWORK")
            line:SetColorTexture(1, 1, 1) -- static: not a theme color
            line:SetThickness(1.2)
            if i == 1 then
                line:SetStartPoint("TOPLEFT", bg, 3.6, -3)
                line:SetEndPoint("BOTTOMRIGHT", bg, -3, 3)
            else
                line:SetStartPoint("TOPRIGHT", bg, -3, -3)
                line:SetEndPoint("BOTTOMLEFT", bg, 3.6, 3)
            end
        end
    end
end

do -- CheckButton
    function Skin.FrameTypeCheckButton(CheckButton)
        if CheckButton.ClearNormalTexture then
            CheckButton:ClearNormalTexture()
            CheckButton:ClearPushedTexture()
            CheckButton:ClearHighlightTexture()
        else
            CheckButton:SetNormalTexture("")
            CheckButton:SetPushedTexture("")
            CheckButton:SetHighlightTexture("")
        end

        Base.SetBackdrop(CheckButton, Color.button, 0.3)
        Base.SetHighlight(CheckButton)
    end
end

do -- EditBox
    function Skin.FrameTypeEditBox(EditBox)
        Base.SetBackdrop(EditBox, Color.frame)
        EditBox:SetBackdropBorderColor(Color.button)
    end
end

do -- StatusBar
    -- Bars whose SetStatusBarTexture hook is running, so the texture it sets
    -- does not re-enter it. Kept here, not on the bar (B261, AT-D9).
    local settingTexture = _G.setmetatable({}, {__mode = "k"})

    local function Hook_SetStatusBarTexture(self, asset)
        if type(self) ~= "table" or type(self.GetObjectType) ~= "function" or not self:IsObjectType("StatusBar") then
            return
        end
        if settingTexture[self] then
            return
        end
        settingTexture[self] = true
        if type(asset) ~= "string" then
            settingTexture[self] = nil
            return
        end
        local ok, color = _G.pcall(function()
            return private.assetColors[asset]
        end)
        if not ok then
            color = nil
        end
        local ok2, color2 = _G.pcall(function()
            return private.assetColors[asset .. "_2"]
        end)
        if not ok2 then
            color2 = nil
        end

        if color then
            local ok3, texture = _G.pcall(self.GetStatusBarTexture, self)
            if not ok3 or not texture then
                settingTexture[self] = nil
                return
            end
            texture:SetTexture(private.textures.plain)
            if color2 then
                if texture.SetGradientAlpha then
                    local r, g, b = color:GetRGB()
                    local r2, g2, b2 = color2:GetRGB()
                    texture:SetGradient("VERTICAL", r, g, b, r2, g2, b2)
                else
                    texture:SetGradient("VERTICAL", color, color2)
                end
            else
                texture:SetVertexColor(color:GetRGB())
            end
        else
            local ok4, name = _G.pcall(self.GetDebugName, self)
            private.debug("Missing color for status bar asset:", asset, ok4 and name or "unknown")
        end

        settingTexture[self] = nil
    end
    local function Hook_SetStatusBarColor(self, r, g, b)
        if type(self) ~= "table" or type(self.GetObjectType) ~= "function" or not self:IsObjectType("StatusBar") then
            return
        end
        local ok, texture = _G.pcall(self.GetStatusBarTexture, self)
        if not ok or not texture then
            return
        end
        texture:SetVertexColor(r, g, b)
    end
    function Skin.FrameTypeStatusBar(StatusBar)
        if StatusBar.IsForbidden and StatusBar:IsForbidden() then
            return
        end

        -- WoW Forever introduces bars that are Frames, not StatusBars:
        -- ColoredProgressBarTemplate drives a masked Fill texture through its
        -- mixin and has none of the SetStatusBar* API this function uses.
        -- Every caller here assumed a real StatusBar, so one such frame threw
        -- "SetStatusBarTexture is not a function" and took the caller's whole
        -- skin function with it. Route them instead of throwing; on retail
        -- every caller passes a genuine StatusBar, so nothing changes there.
        if not StatusBar.SetStatusBarColor then
            if Skin.ColoredProgressBarTemplate then
                Skin.ColoredProgressBarTemplate(StatusBar)
            end
            return
        end

        if StatusBar.SetStatusBarAtlas then
            _G.hooksecurefunc(StatusBar, "SetStatusBarAtlas", Hook_SetStatusBarTexture)
        else
            _G.hooksecurefunc(StatusBar, "SetStatusBarTexture", Hook_SetStatusBarTexture)
        end
        _G.hooksecurefunc(StatusBar, "SetStatusBarColor", Hook_SetStatusBarColor)

        Base.SetBackdrop(StatusBar, Color.button, Color.frame.a)
        StatusBar:SetBackdropOption(
            "offsets",
            {
                left = -1,
                right = -2,
                top = -1,
                bottom = -1
            }
        )

        local red, green, blue = StatusBar:GetStatusBarColor()
        local tex = StatusBar:GetStatusBarTexture()

        local asset
        if tex then
            asset = tex:GetAtlas()
            if not asset then
                asset = tex:GetTexture()
            end
        else
            StatusBar:SetStatusBarTexture(private.textures.plain)
            tex = StatusBar:GetStatusBarTexture()
        end

        Base.SetTexture(tex, "gradientUp")

        local assetColor
        if type(asset) == "string" then
            local ok, value = _G.pcall(function()
                return private.assetColors[asset]
            end)
            if ok then
                assetColor = value
            end
        end

        if assetColor then
            Hook_SetStatusBarTexture(StatusBar, asset)
        else
            Hook_SetStatusBarColor(StatusBar, red, green, blue)
        end
    end
end

do -- ScrollBar
    -- B261: the frame carrying the thumb's backdrop, keyed by the Blizzard
    -- thumb. Was `_auroraThumb` on the thumb.
    local thumbs = _G.setmetatable({}, {__mode = "k"})

    local function Hook_Hide(self)
        thumbs[self]:Hide()
    end
    local function Hook_Show(self)
        thumbs[self]:Show()
    end
    local function ScrollBarThumb(ScrollThumb)
        local thumb
        if ScrollThumb.Middle then
            ScrollThumb.Middle:SetAlpha(0)
            ScrollThumb.Begin:SetAlpha(0)
            ScrollThumb.End:SetAlpha(0)

            thumb = ScrollThumb
        else
            ScrollThumb:SetAlpha(0)
            ScrollThumb:SetSize(16, 24)

            thumb = _G.CreateFrame("Frame", nil, ScrollThumb:GetParent())
            thumb:SetPoint("TOPLEFT", ScrollThumb)
            thumb:SetPoint("BOTTOMRIGHT", ScrollThumb)
        end

        Base.SetBackdrop(thumb, Color.button)
        thumb:SetShown(ScrollThumb:IsShown())
        thumb:SetBackdropOption(
            "offsets",
            {
                left = 0,
                right = 0,
                top = 2,
                bottom = 2
            }
        )
        -- Only a separate frame has to follow the thumb's Show and Hide. Where
        -- the thumb carries the backdrop itself (it has Middle) there is nothing
        -- to mirror: an entry would be a value that is its own key, which a
        -- weak-keyed table never lets go, and the Hide hook would call Hide on
        -- the thumb it hooks (ScrollBarMixin:DisableControls hides the thumb).
        if thumb ~= ScrollThumb then
            thumbs[ScrollThumb] = thumb

            _G.hooksecurefunc(ScrollThumb, "Hide", Hook_Hide)
            _G.hooksecurefunc(ScrollThumb, "Show", Hook_Show)
        end
    end

    local function UpdateTexture(self)
        local state = buttonState[self]
        local tex = state.textures[1]
        local texAnchor = self
        local length, width = 14, 6
        local xOffset, yOffset = 2, 4
        if not state.minimal then
            texAnchor = self:GetBackdropTexture("bg")
        end

        local isDecrement = self.direction == _G.ScrollControllerMixin.Directions.Decrease
        self:SetSize(18, 16)
        tex:ClearAllPoints()
        if self.isHorizontal then
            tex:SetSize(width, length)
            if isDecrement then
                tex:SetPoint("BOTTOMRIGHT", texAnchor, -yOffset, xOffset)
                Base.SetTexture(tex, "arrowLeft")
            else
                tex:SetPoint("BOTTOMLEFT", texAnchor, yOffset, xOffset)
                Base.SetTexture(tex, "arrowRight")
            end
        else
            tex:SetSize(length, width)
            if isDecrement then
                tex:SetPoint("BOTTOMLEFT", texAnchor, xOffset, yOffset)
                Base.SetTexture(tex, "arrowUp")
            else
                tex:SetPoint("TOPLEFT", texAnchor, xOffset, -yOffset)
                Base.SetTexture(tex, "arrowDown")
            end
        end
    end
    local function ScrollBarButton(Button, notMinimal)
        -- A Layer 2 stepper (Skin.TaintSafeUIPanelScrollBar) is left as it is: no
        -- texture, no hook, no arrow on the Blizzard button.
        if not Skin.FrameTypeButton(Button, nil, nil, not notMinimal) then
            return false
        end

        local tex = Button.Texture or Button:CreateTexture()
        if Button.direction then
            Skin.SetButtonTextures(Button, {tex})
            if Button.UpdateAtlas then
                -- No client in wow-ui-source* has UpdateAtlas on a scroll
                -- stepper any more (2026-11-23); kept for one that does. The
                -- OnDisable script hook that went with it is gone (B261): it
                -- added a handler Blizzard's button did not have, and such a
                -- button refuses SetEnabled with a secret argument.
                _G.hooksecurefunc(Button, "UpdateAtlas", UpdateTexture)
            elseif Button.OnButtonStateChanged then
                -- B35: 12.x moved the atlas application from UpdateAtlas into
                -- ButtonStateBehavior's OnButtonStateChanged, which re-stamps
                -- Texture:SetAtlas() on every enable/disable/enter/leave/
                -- mouse-down — including scrollbar init at login, after the
                -- skin ran. The OnShow fallback below misses all of that: the
                -- arrow stayed Blizzard's until the first scroll toggled a
                -- Hide→Show. Re-assert after every stamp instead.
                _G.hooksecurefunc(Button, "OnButtonStateChanged", UpdateTexture)
            else
                Button:HookScript("OnShow", UpdateTexture)
            end

            UpdateTexture(Button)
        else
            tex:Hide()
        end
        return true
    end

    function Skin.FrameTypeScrollBar(ScrollBar, notMinimal)
        local back = ScrollBar.Back or ScrollBar.ScrollUpButton or _G[ScrollBar:GetName() .. "ScrollUpButton"]
        local forward = ScrollBar.Forward or ScrollBar.ScrollDownButton or _G[ScrollBar:GetName() .. "ScrollDownButton"]
        -- A bar already drawn by Skin.TaintSafeUIPanelScrollBar is left whole: its
        -- steppers are refused by Skin.FrameTypeButton, and its thumb keeps
        -- the in-place restyle instead of getting a backdrop frame and hooks.
        if not ScrollBarButton(back, notMinimal) then
            return
        end
        ScrollBarButton(forward, notMinimal)

        local thumb =
            (ScrollBar.Track and ScrollBar.Track.Thumb) or ScrollBar.ThumbTexture or
            _G[ScrollBar:GetName() .. "ThumbTexture"]
        ScrollBarThumb(thumb)
    end
end
