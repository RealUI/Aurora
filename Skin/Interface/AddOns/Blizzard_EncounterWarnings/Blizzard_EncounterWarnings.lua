local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

-- [[ Core ]]
local Aurora = private.Aurora
local Base, Hook = Aurora.Base, Aurora.Hook
local Util = Aurora.Util

-- Shared helper: skin the icon element children (LeftIcon / RightIcon)
local function SkinIconElement(iconFrame)
    if not iconFrame or private.IsSkinned(iconFrame) then return end
    if iconFrame.IsForbidden and iconFrame:IsForbidden() then return end

    -- Crop the ability icon texture
    local icon = iconFrame.Icon
    if icon then
        Base.CropIcon(icon)
    end

    -- Strip decorative overlay textures from the icon frame
    for _, key in _G.ipairs({
        "NormalOverlay",
        "DeadlyOverlay",
        "DeadlyOverlayGlow",
        "IconMask",
    }) do
        local tex = iconFrame[key]
        if tex and tex.SetTexture then
            tex:SetTexture("")
            tex:SetAtlas("")
        end
    end

    private.SetSkinned(iconFrame, true)
end

-- Shared helper: skin a single EncounterWarningsView (the View child of each severity frame)
local function SkinView(view)
    if not view or private.IsSkinned(view) then return end
    if view.IsForbidden and view:IsForbidden() then return end

    -- Strip decorative textures from the view itself
    Base.StripBlizzardTextures(view)

    -- Skin the left and right icon elements (static children)
    SkinIconElement(view.LeftIcon)
    SkinIconElement(view.RightIcon)

    private.SetSkinned(view, true)
end

do --[[ AddOns\Blizzard_EncounterWarnings.lua ]]
    -- Hook the view mixin's ShowWarning to re-skin icon elements after
    -- Init is called (icons may change texture per warning).
    Hook.EncounterWarningsViewMixin = {}
    function Hook.EncounterWarningsViewMixin:ShowWarning()
        -- Post-hook: icons have been Init'd with new textures, re-crop them.
        local leftIcon = self.LeftIcon
        if leftIcon and leftIcon.Icon then
            Base.CropIcon(leftIcon.Icon)
        end

        local rightIcon = self.RightIcon
        if rightIcon and rightIcon.Icon then
            Base.CropIcon(rightIcon.Icon)
        end
    end
end

--[[ AddOns\Blizzard_EncounterWarnings.xml ]]
-- Warning elements are static children defined in XML templates.
-- No Skin template functions needed.

function private.AddOns.Blizzard_EncounterWarnings()
    ------------------------------------------------
    -- Hook mixin prototypes via Util.Mixin
    ------------------------------------------------
    Util.Mixin(_G.EncounterWarningsViewMixin, Hook.EncounterWarningsViewMixin)

    ------------------------------------------------
    -- Skin the three severity warning frames' View children.
    -- The parent frames (CriticalEncounterWarnings, MediumEncounterWarnings,
    -- MinorEncounterWarnings) are EditMode-managed — do NOT touch them.
    -- Only skin child visual elements on the View sub-frames.
    ------------------------------------------------
    local severityFrames = {
        _G.CriticalEncounterWarnings,
        _G.MediumEncounterWarnings,
        _G.MinorEncounterWarnings,
    }

    for _, systemFrame in _G.ipairs(severityFrames) do
        if systemFrame then
            local view = systemFrame.View
            if not view and systemFrame.GetView then
                view = systemFrame:GetView()
            end
            SkinView(view)
        end
    end
end
