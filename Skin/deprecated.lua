local ADDON_NAME, private = ...

--[[ Lua Globals ]]
-- luacheck: globals type

--[[ Core ]]
local Aurora = private.Aurora
local Base, Skin = Aurora.Base, Aurora.Skin
local Color = Aurora.Color

--[[ ALPHA 0.7 ]]--
local origBase_SetHighlight = Base.SetHighlight
function Base.SetHighlight(button, option, onEnter, onLeave)
    if type(option) == "string" then
        origBase_SetHighlight(button, onEnter, onLeave)
    else
        origBase_SetHighlight(button, option, onEnter)
    end
end

--[[ Legacy API ]]--
local F, C = {}, {}
Aurora[1] = F
Aurora[2] = C

C.classcolours = _G.CUSTOM_CLASS_COLORS
C.backdrop = private.backdrop
C.media = {
    ["arrowUp"] = [[Interface\AddOns\Aurora\media\arrow-up-active]],
    ["arrowDown"] = [[Interface\AddOns\Aurora\media\arrow-down-active]],
    ["arrowLeft"] = [[Interface\AddOns\Aurora\media\arrow-left-active]],
    ["arrowRight"] = [[Interface\AddOns\Aurora\media\arrow-right-active]],
    ["backdrop"] = [[Interface\ChatFrame\ChatFrameBackground]],
    ["checked"] = [[Interface\AddOns\Aurora\media\CheckButtonHilight]],
    ["font"] = private.font.normal,
    ["gradient"] = [[Interface\AddOns\Aurora\media\gradient]],
    ["roleIcons"] = [[Interface\AddOns\Aurora\media\UI-LFG-ICON-ROLES]],
}


C.themes = {}
C.themes[ADDON_NAME] = {}

F.dummy = function() end

F.CreateBD = function(frame, alpha)
    local color, a
    if alpha then
        color = Color.frame
        a = alpha
    end

    Base.SetBackdrop(frame, color, a)
end


-- B261: Skin.FrameTypeButton no longer puts SetButtonColor/GetButtonColor on
-- the buttons it skins; the API is Skin.SetButtonColor(Button, ...) and
-- Skin.GetButtonColor(Button). Skins written against this legacy table still
-- call the methods, so Reskin, and nothing else, gives the frame it skins two
-- that forward. They are shared functions, not a closure per frame.
local function Reskin_SetButtonColor(self, color, alpha, disabledColor)
    Skin.SetButtonColor(self, color, alpha, disabledColor)
end
local function Reskin_GetButtonColor(self)
    return Skin.GetButtonColor(self)
end

F.Reskin = function(f, noHighlight)
    Skin.FrameTypeButton(f)
    f.SetButtonColor = Reskin_SetButtonColor
    f.GetButtonColor = Reskin_GetButtonColor

    if f.Left then f.Left:SetAlpha(0) end
    if f.Middle then f.Middle:SetAlpha(0) end
    if f.Right then f.Right:SetAlpha(0) end
    if f.LeftSeparator then f.LeftSeparator:Hide() end
    if f.RightSeparator then f.RightSeparator:Hide() end
end

F.ReskinInput = function(f, height, width)
    local frame = f:GetName()

    local left = f.Left or _G[frame.."Left"]
    local middle = f.Middle or _G[frame.."Middle"] or _G[frame.."Mid"]
    local right = f.Right or _G[frame.."Right"]

    left:Hide()
    middle:Hide()
    right:Hide()

    Skin.FrameTypeEditBox(f)

    if height then f:SetHeight(height) end
    if width then f:SetWidth(width) end
end

F.SetBD = function(f, x, y, x2, y2)
    local bg = _G.CreateFrame("Frame", nil, f)
    if not x then
        bg:SetPoint("TOPLEFT")
        bg:SetPoint("BOTTOMRIGHT")
    else
        bg:SetPoint("TOPLEFT", x, y)
        bg:SetPoint("BOTTOMRIGHT", x2, y2)
    end
    bg:SetFrameLevel(f:GetFrameLevel()-1)
    Skin.FrameTypeFrame(bg)
end

F.CreateBDFrame = function(f, a, left, right, top, bottom)
    local frame
    if f:GetObjectType() == "Texture" then
        frame = f:GetParent()
    else
        frame = f
    end

    local lvl = frame:GetFrameLevel()

    local bg = _G.CreateFrame("Frame", nil, frame)
    bg:SetPoint("TOPLEFT", f, left or -1, top or 1)
    bg:SetPoint("BOTTOMRIGHT", f, right or 1, bottom or -1)
    bg:SetFrameLevel(lvl == 0 and 1 or lvl - 1)

    F.CreateBD(bg, a or .5)

    return bg
end


F.ReskinIcon = function(icon)
    icon:SetTexCoord(.08, .92, .08, .92)
    return F.CreateBDFrame(icon)
end
