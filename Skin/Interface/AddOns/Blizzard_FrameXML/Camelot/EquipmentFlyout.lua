local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color = Aurora.Color

-- Camelot replaces EquipmentFlyout wholesale. The XML is frame-for-frame the
-- same as retail's, but the Lua is not: the popout button's two-state
-- EquipmentFlyoutPopoutButton_SetReversed(self, isReversed) is gone, replaced
-- by a four-direction EquipmentFlyoutPopoutButton_RefreshVisualState(self) that
-- picks an atlas set per direction and rotates the textures.
--
-- Everything else here matches Blizzard_FrameXML\Mainline\EquipmentFlyout.lua;
-- the two are kept as separate copies rather than a shared body because only
-- one of them is ever in a manifest and the file is well under the size where
-- Skin\shared\ earns its indirection.

-- Blizzard's POP_OUT_DIRECTION_* constants and its direction resolver are both
-- file-locals, so the read is reproduced here. The constant values are plain
-- strings, so the mapping stays correct as long as those strings do.
local ARROW_FOR_DIRECTION = {
    LEFT = "arrowLeft",
    RIGHT = "arrowRight",
    UP = "arrowUp",
    DOWN = "arrowDown",
}

local function GetFlyoutDirection(self)
    local parent = self:GetParent()
    local direction = (parent and parent.flyoutDirection) or self.flyoutDirection
    if direction then
        return direction
    end
    if parent and parent.verticalFlyout then
        return "UP"
    end
    return "RIGHT"
end

local function ApplyArrow(Button)
    local tex = Button:GetNormalTexture()
    if not tex then return end

    Base.SetTexture(tex, ARROW_FOR_DIRECTION[GetFlyoutDirection(Button)] or "arrowRight")
    tex:SetVertexColor(Color.highlight:GetRGB())
    -- RefreshVisualState rotates the atlas to face the flyout direction. Aurora's
    -- arrows are already drawn per direction, so the rotation has to be undone or
    -- they point the wrong way.
    if tex.SetRotation then
        tex:SetRotation(0)
    end

    Button._auroraArrow = tex
    Button:ClearHighlightTexture()
end

do --[[ FrameXML\EquipmentFlyout.lua ]]
    function Hook.EquipmentFlyout_CreateButton()
        Skin.EquipmentFlyoutButtonTemplate(_G.EquipmentFlyoutFrame.buttons[#_G.EquipmentFlyoutFrame.buttons])
    end
    function Hook.EquipmentFlyoutPopoutButton_RefreshVisualState(self)
        -- Re-applied on every call: Blizzard re-sets the normal atlas here.
        ApplyArrow(self)
    end
end

do --[[ FrameXML\EquipmentFlyout.xml ]]
    function Skin.EquipmentFlyoutButtonTemplate(ItemButton)
        Skin.FrameTypeItemButton(ItemButton)
    end
    function Skin.EquipmentFlyoutPopoutButtonTemplate(Button)
        ApplyArrow(Button)
    end
end

function private.FrameXML.EquipmentFlyout()
    _G.hooksecurefunc("EquipmentFlyout_CreateButton", Hook.EquipmentFlyout_CreateButton)
    _G.hooksecurefunc("EquipmentFlyoutPopoutButton_RefreshVisualState", Hook.EquipmentFlyoutPopoutButton_RefreshVisualState)

    _G.EquipmentFlyoutFrameHighlight:SetTexCoord(0.125, 0.65625, 0.125, 0.65625)
    _G.EquipmentFlyoutFrameHighlight:ClearAllPoints()
    _G.EquipmentFlyoutFrameHighlight:SetPoint("TOPLEFT", 3, -3)
    _G.EquipmentFlyoutFrameHighlight:SetPoint("BOTTOMRIGHT", -3, 3)

    local buttonFrame = _G.EquipmentFlyoutFrame.buttonFrame
    buttonFrame.bg1:SetAlpha(0)
    buttonFrame:DisableDrawLayer("ARTWORK")

    local bd = _G.CreateFrame("Frame", nil, buttonFrame)
    bd:SetPoint("TOPLEFT")
    bd:SetPoint("BOTTOMRIGHT", 3, -1)
    bd:SetFrameLevel(buttonFrame:GetFrameLevel())
    Skin.FrameTypeFrame(bd)

    local NavigationFrame = _G.EquipmentFlyoutFrame.NavigationFrame
    Skin.FrameTypeFrame(NavigationFrame)
    NavigationFrame:SetPoint("TOPLEFT", bd, "BOTTOMLEFT", 0, 1)
    NavigationFrame:SetPoint("TOPRIGHT", bd, "BOTTOMRIGHT", 0, 1)
    NavigationFrame.BottomBackground:Hide()
    Skin.NavButtonPrevious(NavigationFrame.PrevButton)
    Skin.NavButtonNext(NavigationFrame.NextButton)
end
