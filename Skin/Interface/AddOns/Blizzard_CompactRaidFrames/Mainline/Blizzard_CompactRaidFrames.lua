local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Color = Aurora.Color
local Skin = Aurora.Skin
local Util = Aurora.Util

-- B260 (2026-11-21, retail battleground, taintLog 5): a roster/unit-flags
-- update ran CompactRaidFrameManager_UpdateDisplayCounts → UpdateFilterInfo
-- → UpdateRoleFilterButton, whose button:Disable() was blocked. The log
-- shows two injectors, both from this file:
--
-- * Skin.FrameTypeFrame(CompactRaidFrameManager) put BackdropMixin, the
--   backdrop info and nine textures on the manager itself (rules 1 and 9,
--   the B160 shape).
-- * Skin.FrameTypeButton on the role and group filter buttons and on the
--   toolbar buttons post-hooked Enable/Disable/SetEnabled. Blizzard calls
--   those inside every roster, options and Edit Mode update, so the hook
--   body ran in Blizzard's execution (first logged at login: Edit Mode
--   UpdateSystems → UpdateRoleFilterButton → Disable → skin.lua Hook_Disable
--   reading Aurora colour tables), wrote isEnabled/isDisabled onto the
--   button, and left the rest of that update tainted, writing the manager's
--   own state tainted for every later update to read (self-perpetuating).
--   It also planted SetButtonColor/GetButtonColor and highlight fields, and
--   cleared the normal texture that UpdateRoleFilterButton,
--   UpdateGroupFilterButton and OnButtonStateChanged SetAtlas on every
--   update.
--
-- Now nothing is written onto the manager or any of its buttons:
-- * the panel is a sibling frame (child of the manager, so it follows
--   Blizzard's SetPoint/SetHeight and RealUI's reparent; it carries all the
--   backdrop state). Blizzard's Background and divider pool sit in the
--   manager's ARTWORK layer, hidden by DisableDrawLayer; Blizzard only ever
--   SetAtlas's and acquires them, it reads nothing back.
-- * The filter buttons, toolbar buttons (edit mode, settings, hide groups,
--   everyone-is-assist, difficulty, ready check, role poll, countdown) and
--   raid marker buttons stay Blizzard's. Their state is drawn by atlases
--   Blizzard re-sets on every update (selected/hover/disabled), so in-place
--   recolouring would hide the filter state; the toolbar buttons are also
--   measured by the options FlowContainer and the markers are laid out by a
--   GridLayout (rule 3: no SetSize/SetPoint).
-- * The collapse/expand toggles stay Blizzard's too: their OnEnter/OnLeave
--   SetAtlas the normal texture, which overwrote Aurora's arrow on the first
--   hover anyway, and the old skin re-anchored the buttons.
function private.AddOns.Blizzard_CompactRaidFrames()
    ----====############%%########====----
    -- Blizzard_CompactRaidFrameManager --
    ----====############%%########====----
    local CompactRaidFrameManager = _G.CompactRaidFrameManager
    CompactRaidFrameManager:DisableDrawLayer("ARTWORK")

    local bg = _G.CreateFrame("Frame", nil, CompactRaidFrameManager)
    bg:SetAllPoints()
    bg:SetFrameLevel(CompactRaidFrameManager:GetFrameLevel())
    Base.SetBackdrop(bg, Color.frame, Util.GetFrameAlpha())

    local displayFrame = CompactRaidFrameManager.displayFrame
    -- Unchanged by B260 (no field or geometry write). On 12.x the first
    -- region is the "Raid"/"Party" label FontString, not a background, so
    -- this hides the title; Blizzard only SetText's it.
    displayFrame:GetRegions():Hide()
    -- Texture-only restyle (no fields, no frame geometry); the button is
    -- anchored by XML and not a FlowContainer object.
    Skin.UIPanelInfoButton(_G[displayFrame:GetName().."OptionsButton"])
end
