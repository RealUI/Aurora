local _, private = ...

--[[ Lua Globals ]]
-- luacheck: globals next assert type pcall tinsert math error select wipe

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Color = Aurora.Color

Aurora.classIcons = {}
if not private.isRetail then
     -- adjusted for borderless icons
    Aurora.classIcons.WARRIOR     = {0.01953125, 0.234375, 0.01953125, 0.234375}
    Aurora.classIcons.MAGE        = {0.26953125, 0.48046875, 0.01953125, 0.234375}
    Aurora.classIcons.ROGUE       = {0.515625, 0.7265625, 0.01953125, 0.234375}
    Aurora.classIcons.DRUID       = {0.76171875, 0.97265625, 0.01953125, 0.234375}
    Aurora.classIcons.HUNTER      = {0.01953125, 0.234375, 0.26953125, 0.484375}
    Aurora.classIcons.SHAMAN      = {0.26953125, 0.48046875, 0.26953125, 0.484375}
    Aurora.classIcons.PRIEST      = {0.515625, 0.7265625, 0.26953125, 0.484375}
    Aurora.classIcons.WARLOCK     = {0.76171875, 0.97265625, 0.26953125, 0.484375}
    Aurora.classIcons.PALADIN     = {0.01953125, 0.234375, 0.51953125, 0.734375}
    Aurora.classIcons.DEATHKNIGHT = {0.26953125, 0.48046875, 0.51953125, 0.734375}
    Aurora.classIcons.MONK        = {0.515625, 0.7265625, 0.51953125, 0.734375}
    Aurora.classIcons.DEMONHUNTER = {0.76171875, 0.97265625, 0.51953125, 0.734375}
    Aurora.classIcons.EVOKER      = {0.01953125, 0.234375, 0.734375, 0.94921875}
end

--[[ Base:header
These are most basic skinning functions and are the foundation of every skin in Aurora.
--]]

--[[ Base.AddSkin(_addonName, func_)
Allows an external addon to add a skinning function for the specified
AddOn. `func` will run when the `ADDON_LOADED` event is triggered for
addonName.

**Args:**
* `addonName` - the name of the AddOn to be skinned _(string)_
* `func`      - used to skin the AddOn _(function)_
--]]
function Base.AddSkin(addonName, func)
    assert(not private.AddOns[addonName], addonName .. " already has a registered skin." )
    private.AddOns[addonName] = func
    _G.print("Aurora: Registered skin for", addonName)

    if _G.C_AddOns.IsAddOnLoaded(addonName) then
        func()
    end
end


--[[ Base.GetAddonSkins()
Returns a list of all non-Blizzard AddOn skins.

**Returns:**
* `skinList` - an indexed list of addon names _(table)_
--]]
function Base.GetAddonSkins()
    local skinList = {}
    for name in next, private.AddOns do
        if not name:find("Blizzard") then
            tinsert(skinList, name)
        end
    end
    return skinList
end


--[[ Base.CropIcon(_texture[, parent]_)
Sets texture coordinates to just inside a square icon's built-in border.
If the optional second argument is provided, an other texture will be
created at a black background for the icon.

**Args:**
* `texture` - the texture to be cropped _(Texture)_
* `parent`  - _optional_ a frame that can create a texture _(Frame)_

**Returns:**
* `iconBorder` - _optional_ a black texture behind the icon to act as a border _(Texture)_
--]]
function Base.CropIcon(texture, parent)
    if not texture then return end

    -- Blizzard masks a lot of icons into rounded shapes (ItemButton's IconMask,
    -- the action bar's IconFrame mask). The client refuses SetTexCoord on a
    -- masked texture ("Cannot set tex coords when texture has mask"), so the
    -- pcall below swallowed the refusal and the icon silently stayed rounded —
    -- which is what item buttons in bags and at vendors were showing.
    -- This function's contract is a SQUARE cropped icon, so drop the masks
    -- first. Iterate downwards: removing a mask reindexes the rest.
    if texture.GetNumMaskTextures and texture.RemoveMaskTexture then
        for i = texture:GetNumMaskTextures(), 1, -1 do
            local mask = texture:GetMaskTexture(i)
            if mask then
                texture:RemoveMaskTexture(mask)
            end
        end
    end

    -- Kept as belt-and-braces: a texture can still refuse the call for other
    -- reasons (forbidden/secure-environment textures).
    pcall(texture.SetTexCoord, texture, .08, .92, .08, .92)
    if parent then
        -- 12.1: textures on AuraContainer secure-environment frames return
        -- SECRET layer/subLevel values to insecure code — arithmetic on them
        -- errors. When unknown, the border must go BELOW everything
        -- (BACKGROUND): oUF aura icons draw at BORDER, and a higher-layer
        -- fallback would paint the black border over the icon.
        local layer, subLevel = texture:GetDrawLayer()
        if _G.issecretvalue(layer) or not layer then
            layer = "BACKGROUND"
        end
        if _G.issecretvalue(subLevel) or type(subLevel) ~= "number" then
            subLevel = 1
        end
        local iconBorder = parent:CreateTexture(nil, layer, nil, subLevel - 1)
        iconBorder:SetPoint("TOPLEFT", texture, -1, 1)
        iconBorder:SetPoint("BOTTOMRIGHT", texture, 1, -1)
        iconBorder:SetColorTexture(0, 0, 0)
        return iconBorder
    end
end

--[[ Base.KeepIconCrop(_texture_)
Keeps an item button's icon cropped after Blizzard resets its texture
coordinates. Since Forever 70755 and retail 12.1.7, `SetItemButtonTexture`
calls `icon:SetTexCoord(0, 1, 0, 1)` straight after `SetTexture`, which undoes a
`Base.CropIcon` made at skin time on every texture change. Call this once
alongside that crop on any icon `GetItemButtonIconTexture` can return.

The hook acts only on the full reset, so the crop it applies cannot re-enter it.
It passes no parent to `Base.CropIcon`: this runs on every texture change, and a
parent would create a border texture each time.

**Args:**
* `texture` - the icon to keep cropped _(Texture)_
--]]
local keptCrops = _G.setmetatable({}, {__mode = "k"})
local function ReapplyCrop(texture, left, right, top, bottom)
    if left == 0 and right == 1 and top == 0 and bottom == 1 then
        Base.CropIcon(texture)
    end
end
function Base.KeepIconCrop(texture)
    if not texture or not private.isRetail or keptCrops[texture] then return end

    keptCrops[texture] = true
    _G.hooksecurefunc(texture, "SetTexCoord", ReapplyCrop)
end
function Base.CropCircularIcon(icon, parent)
    icon:SetMask("")
    local frame = parent or icon:GetParent()
    if frame.CircleMask then
        frame.CircleMask:Hide()
    end
    return Base.CropIcon(icon, parent)
end

local blizzTextures = {
    "Inset",
    "inset",
    "InsetFrame",
    "LeftInset",
    "RightInset",
    "NineSlice",
    "BG",
    "Bg",
    "border",
    "Border",
    "Background",
    "BorderFrame",
    "bottomInset",
    "BottomInset",
    "bgLeft",
    "bgRight",
    "FilligreeOverlay",
    "PortraitOverlay",
    "ArtOverlayFrame",
    "Portrait",
    "portrait",
    "ScrollFrameBorder",
    "ScrollUpBorder",
    "ScrollDownBorder"
}

function Base.StripBlizzardTextures(frame)
    if not frame or not frame.GetNumRegions then return end
    local frameName = frame.GetName and frame:GetName()
    -- check for blizzTextures
    for _, texture in pairs(blizzTextures) do
        local blizzFrame = frame[texture] or (frameName and _G[frameName..texture])
        if blizzFrame then
            Base.StripBlizzardTextures(blizzFrame)
        end
    end
    for i = 1, frame:GetNumRegions() do
        local region = select(i, frame:GetRegions())
        if region and region.GetObjectType and region:GetObjectType() == "Texture" then
            region:SetTexture("")
            region:SetAtlas("")
        end
    end
end


function Base.StripAllTextures(frame, kill)
    if not frame or not frame.GetNumRegions then return end

    for i = 1, frame:GetNumRegions() do
        local region = select(i, frame:GetRegions())
        if region and region.GetObjectType and region:GetObjectType() == "Texture" then
            if kill then
                region:Kill()
            else
                region:SetTexture(nil)
            end
        end
    end
end

function Base.SetFont(fontObj, fontPath, fontSize, fontStyle, fontColor, shadowColor, shadowX, shadowY)
    if _G.type(fontObj) == "string" then fontObj = _G[fontObj] end
    if not fontObj then return end

    if fontPath and not private.disabled.fonts then
        fontObj:SetFont(fontPath, fontSize, fontStyle or "")
    end

    if fontColor then
        fontObj:SetTextColor(fontColor.r, fontColor.g, fontColor.b)
    end

    if shadowColor then
        fontObj:SetShadowColor(shadowColor.r, shadowColor.g, shadowColor.b, 0.5)
    end

    if shadowX and shadowY then
        fontObj:SetShadowOffset(shadowX, shadowY)
    end
end

do -- Base.SetHighlight
    --[[
    local tempColor = {}
    local function GetColorTexture(string)
        _G.wipe(tempColor)
        string = string:gsub("Color%-", "")

        local prevChar, val
        string:gsub("(%x)", function(char)
            if prevChar then
                val = _G.tonumber(prevChar..char, 16) / 255 -- convert hex to perc decimal
                _G.tinsert(tempColor, val - (val % 0.01)) -- round val to two decimal places
                prevChar = nil
            elseif char == "0" then
                _G.tinsert(tempColor, 0)
            else
                prevChar = char
            end
        end)

        return tempColor[1], tempColor[2], tempColor[3], tempColor[4]
    end
    ]]

    -- B261: the highlight keeps nothing on the frame. Its state is in the
    -- button state store of Skin/skin.lua (`returnColor`, `onEnter`,
    -- `onLeave`, `highlighted`, `highlightLocked`, `highlightHooked`), reached
    -- through private.GetButtonState at call time because skin.lua loads after
    -- this file. The functions below run from script hooks and from post-hooks
    -- on LockHighlight/UnlockHighlight, so inside Blizzard's own calls: they
    -- write the record and recolour through the handlers, and no key on the
    -- frame.
    local issecretvalue = _G.issecretvalue -- 12.x only; nil on the classic clients

    -- Button:IsEnabled() returns a secret once Blizzard has called SetEnabled
    -- with one, and testing a secret is an error. nil here means the client
    -- will not say; every caller treats that as not enabled.
    local function IsEnabled(button)
        local enabled = button:IsEnabled()
        if issecretvalue and issecretvalue(enabled) then
            return nil
        end
        return enabled
    end

    local function GetReturnColor(button, state)
        local enabledColor = state.enabledColor
        if enabledColor then
            -- skinned with Skin.FrameTypeButton
            if IsEnabled(button) then
                return enabledColor
            else
                return state.disabledColor
            end
        else
            local _, _, _, a = button:GetBackdropColor()
            local r, g, b = button:GetBackdropBorderColor()
            return Color.Create(r, g, b, a)
        end
    end
    local function ShowHighlight(button, state)
        if IsEnabled(button) then
            if not state.highlightLocked then
                return not state.highlighted
            end
        end

        return state.highlightLocked
    end
    local function Highlight(button, state)
        if ShowHighlight(button, state) and not state.highlighted then
            local returnColor = GetReturnColor(button, state)
            state.returnColor = returnColor

            local highlight = Color.highlight
            if button.IsEnabled and not IsEnabled(button) then
                highlight = highlight:Lightness(-0.3)
            end
            local alpha = returnColor.a or highlight.a

            state.onEnter(button, highlight, alpha)
            state.highlighted = true
        end
    end
    local function Unhighlight(button, state)
        if not ShowHighlight(button, state) and state.highlighted then
            state.onLeave(button, state.returnColor)
            state.highlighted = false
        end
    end

    -- Script hooks. A frame with no record is one another frame's handler was
    -- called for by hand; leave it alone.
    local function OnEnter(button)
        local state = private.GetButtonState(button)
        if state then
            Highlight(button, state)
        end
    end
    local function OnLeave(button)
        local state = private.GetButtonState(button)
        if state then
            Unhighlight(button, state)
        end
    end

    -- Post-hooks, shared by every button.
    local function Hook_LockHighlight(button)
        local state = private.GetButtonState(button)
        if state then
            state.highlightLocked = true
            Highlight(button, state)
        end
    end
    local function Hook_UnlockHighlight(button)
        local state = private.GetButtonState(button)
        if state then
            state.highlightLocked = nil
            Unhighlight(button, state)
        end
    end

    local function BaseOnEnter(self, highlight, alpha)
        Base.SetBackdropColor(self, highlight, alpha)
    end
    local function BaseOnLeave(self, returnColor)
        Base.SetBackdropColor(self, returnColor)
    end


    --[[ Base.SetHighlight(_button[, onEnter, onLeave]_)
    Highlights a frame while the mouse is over it or its highlight is locked.
    By default the frame's backdrop takes the highlight colour and returns to
    its own colour afterwards; the frame needs a backdrop for that
    (`Base.SetBackdrop`).

    Calling it again on the same frame replaces the handlers and adds no
    second set of hooks.

    **Args:**
    * `button`  - the frame to highlight _(Frame)_
    * `onEnter` - _optional_ called as `onEnter(button, highlightColor, alpha)` in place of the default _(function)_
    * `onLeave` - _optional_ called as `onLeave(button, returnColor)` in place of the default _(function)_
    --]]
    function Base.SetHighlight(button, onEnter, onLeave)
        local state = private.GetButtonState(button, true)
        state.returnColor = GetReturnColor(button, state)
        state.onEnter = onEnter or BaseOnEnter
        state.onLeave = onLeave or BaseOnLeave

        if not state.highlightHooked then
            button:HookScript("OnEnter", OnEnter)
            button:HookScript("OnLeave", OnLeave)

            if button.LockHighlight then
                _G.hooksecurefunc(button, "LockHighlight", Hook_LockHighlight)
                _G.hooksecurefunc(button, "UnlockHighlight", Hook_UnlockHighlight)
            end
            state.highlightHooked = true
        end
    end
end

do -- Base.SetTexture
    local snapshots = {}

    function Base.IsTextureRegistered(textureName)
        return not not snapshots[textureName]
    end

    function Base.SetTexture(texture, textureName)
        if not texture then
            _G.print("texture is nil")
            return
        end
        _G.assert(type(texture) == "table" and texture.GetObjectType, "texture widget expected, got "..type(texture))
        _G.assert(texture:GetObjectType() == "Texture", "texture widget expected, got "..texture:GetObjectType())

        local snapshot = snapshots[textureName]
        _G.assert(snapshot, (textureName or "nil") .. " is not a registered texture.")

        snapshot(texture:GetParent(), texture)
    end

    function Base.RegisterTexture(textureName, createFunc)
        _G.assert(not snapshots[textureName], textureName .. " is already registered.")
        private.debug("RegisterTexture", textureName)
        snapshots[textureName] = createFunc
    end
end
