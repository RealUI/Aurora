local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals _G next

--[[ Core ]]
local Aurora = private.Aurora
local Color = Aurora.Color

--[[ UI widget skin, taint-safe rewrite (tracker-widget-taint-rewrite task 2,
     2026-10-05; .kiro/steering/objective-tracker-taint.md R1-R7).

     The previous skin was gated on 2026-08-21: it hooked widget containers
     (OnWidgetContainerRegistered, Util.Mixin on container instances), resized
     and re-anchored pooled widget frames inside Blizzard's widget layout, and
     wrote _aurora* fields onto them. All of that is gone. What remains:

     - Post-hooks on three global widget template mixins (Setup), installed
       when this module runs, before the widgets are created; the hooks reach
       every widget frame created afterwards. hooksecurefunc keeps the hooked
       key secure (verified in game 2026-10-05, `/realdev trackerscan`).
     - Only widgets in an allow-listed container are touched (design.md D4).
       The container is the argument Blizzard passes to Setup, so tooltip,
       nameplate, restricted and objective-tracker containers are excluded
       without ever being queried.
     - Every change is in place: SetTexture("") to clear art, SetColorTexture
       on an existing background, SetTexCoord on an icon. No geometry, no new
       regions, no fields written onto any Blizzard frame. Blizzard's bar fill
       (texture kit art tinted by SetStatusBarColor) is kept: it carries the
       bar's meaning.
     - Restyle runs after every Setup, because Setup re-applies the texture
       kit art each time. It is idempotent.

     Widget types not listed here stay Blizzard's (icons and text only, or no
     reported case yet). ]]

-- Containers whose widgets are styled. Resolved at call time: the delve
-- picker's container belongs to a load-on-demand addon.
local function IsAllowedContainer(container)
    if not container then return false end
    if container == _G.UIWidgetTopCenterContainerFrame
        or container == _G.UIWidgetBelowMinimapContainerFrame
        or container == _G.UIWidgetPowerBarContainerFrame then
        return true
    end
    -- B48: the delve entry screen's modifier list (spell display widgets).
    local picker = _G.DelvesDifficultyPickerFrame
    return picker ~= nil and container == picker.DelveModifiersWidgetContainer
end

local function Clear(texture)
    if texture then
        texture:SetTexture("")
    end
end

local function SetBackground(texture)
    if texture then
        local r, g, b = Color.panelBg:GetRGB()
        texture:SetColorTexture(r, g, b, 0.75)
    end
end

-- UIWidgetTemplateStatusBar: Bar is a UIWidgetBaseStatusBarTemplate with
-- texture-kit caps, borders, background and spark.
local function RestyleStatusBar(frame)
    local bar = frame.Bar
    if not bar then return end
    Clear(bar.BGLeft)
    Clear(bar.BGRight)
    SetBackground(bar.BGCenter)
    Clear(bar.BorderLeft)
    Clear(bar.BorderRight)
    Clear(bar.BorderCenter)
    Clear(bar.Spark)
    Clear(bar.BackgroundGlow)
    Clear(bar.GlowLeft)
    Clear(bar.GlowRight)
    Clear(bar.GlowCenter)
end

-- UIWidgetTemplateDoubleStatusBar: two UIWidgetTemplateDoubleStatusBar_StatusBarTemplate bars.
local function RestyleDoubleBar(bar)
    if not bar then return end
    SetBackground(bar.BG)
    Clear(bar.BorderLeft)
    Clear(bar.BorderRight)
    Clear(bar.BorderCenter)
    Clear(bar.Spark)
    Clear(bar.SparkGlow)
    Clear(bar.BorderGlow)
end
local function RestyleDoubleStatusBar(frame)
    RestyleDoubleBar(frame.LeftBar)
    RestyleDoubleBar(frame.RightBar)
end

-- UIWidgetTemplateSpellDisplay (B48, delve modifiers): square icon, no round
-- border. The debuff border stays: its colour is the debuff type.
local function RestyleSpellDisplay(frame)
    local spell = frame.Spell
    if not spell or not spell.Icon then return end
    -- UIWidgetBaseSpellTemplate masks the icon twice (IconMask, and CircleMask
    -- for the round style); both round it.
    if spell.IconMask then
        spell.Icon:RemoveMaskTexture(spell.IconMask)
    end
    if spell.CircleMask then
        spell.Icon:RemoveMaskTexture(spell.CircleMask)
    end
    spell.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    Clear(spell.Border)
end

local RESTYLE_BY_MIXIN = {
    UIWidgetTemplateStatusBarMixin = RestyleStatusBar,
    UIWidgetTemplateDoubleStatusBarMixin = RestyleDoubleStatusBar,
    UIWidgetTemplateSpellDisplayMixin = RestyleSpellDisplay,
}

-- For frames that already existed: pick the restyle by the regions the
-- template has.
local function RestyleFor(frame)
    if frame.Bar and frame.Bar.BGCenter then
        return RestyleStatusBar
    elseif frame.LeftBar and frame.RightBar then
        return RestyleDoubleStatusBar
    elseif frame.Spell then
        return RestyleSpellDisplay
    end
end

-- Widget frames that already have an instance hook. Weak keys: nothing is
-- written onto the frames.
local instanceHooked = _G.setmetatable({}, {__mode = "k"})

-- Widgets created before this module ran carry Setup copies without the
-- mixin hook: restyle them now and hook their own Setup (the in-game spike
-- showed an instance hooksecurefunc keeps the key secure).
local function RestyleExisting(container)
    local frames = container and container.widgetFrames
    if not frames then return end
    for _, frame in next, frames do
        local restyle = RestyleFor(frame)
        if restyle then
            restyle(frame)
            if frame.Setup and not instanceHooked[frame] then
                instanceHooked[frame] = true
                _G.hooksecurefunc(frame, "Setup", function(self, _, widgetContainer)
                    if IsAllowedContainer(widgetContainer) then
                        restyle(self)
                    end
                end)
            end
        end
    end
end

function private.AddOns.Blizzard_UIWidgets()
    -- Every hooked Setup is Setup(widgetInfo, widgetContainer).
    for mixinName, restyle in next, RESTYLE_BY_MIXIN do
        local mixin = _G[mixinName]
        if mixin and mixin.Setup then
            _G.hooksecurefunc(mixin, "Setup", function(self, _, widgetContainer)
                if IsAllowedContainer(widgetContainer) then
                    restyle(self)
                end
            end)
        end
    end

    -- Widgets created before this module ran never got the hooked Setup.
    RestyleExisting(_G.UIWidgetTopCenterContainerFrame)
    RestyleExisting(_G.UIWidgetBelowMinimapContainerFrame)
    RestyleExisting(_G.UIWidgetPowerBarContainerFrame)
end
