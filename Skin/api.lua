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
    -- Some textures may have a mask; calling SetTexCoord on a masked
    -- texture errors in the client (see: "Cannot set tex coords when texture has mask").
    -- Use a protected call to avoid throwing an error for those textures.
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

    local function GetReturnColor(button)
        local bdFrame = button._auroraBDFrame or button
        if bdFrame.GetButtonColor then
            local enabled, disabled = bdFrame:GetButtonColor()
            if bdFrame:IsEnabled() then
                return enabled
            else
                return disabled
            end
        else
            local _, _, _, a = bdFrame:GetBackdropColor()
            local r, g, b = bdFrame:GetBackdropBorderColor()
            return Color.Create(r, g, b, a)
        end
    end
    local function ShowHighlight(button)
        if button:IsEnabled() then
            if not button._isHighlightLocked then
                return not button._isHighlighted
            end
        end

        return button._isHighlightLocked
    end
    local function OnEnter(button)
        if ShowHighlight(button) and not button._isHighlighted then
            button._returnColor = GetReturnColor(button)

            local highlight = Color.highlight
            if button.IsEnabled and not button:IsEnabled() then
                highlight = highlight:Lightness(-0.3)
            end
            local alpha = button._returnColor.a or highlight.a

            button:_onEnter(highlight, alpha)
            button._isHighlighted = true
        end
    end
    local function OnLeave(button)
        if not ShowHighlight(button) and button._isHighlighted then
            button:_onLeave(button._returnColor)
            button._isHighlighted = false
        end
    end

    local function BaseOnEnter(self, highlight, alpha)
        Base.SetBackdropColor(self._auroraBDFrame or self, highlight, alpha)
    end
    local function BaseOnLeave(self, returnColor)
        Base.SetBackdropColor(self._auroraBDFrame or self, returnColor)
    end


    function Base.SetHighlight(button, onEnter, onLeave)
        button._returnColor = GetReturnColor(button)
        button._onEnter = onEnter or BaseOnEnter
        button._onLeave = onLeave or BaseOnLeave

        button:HookScript("OnEnter", OnEnter)
        button:HookScript("OnLeave", OnLeave)

        if button.LockHighlight then
            _G.hooksecurefunc(button, "LockHighlight", function(dialog, ...)
                button._isHighlightLocked = true
                OnEnter(button)
            end)
            _G.hooksecurefunc(button, "UnlockHighlight", function(dialog, ...)
                button._isHighlightLocked = nil
                OnLeave(button)
            end)
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
