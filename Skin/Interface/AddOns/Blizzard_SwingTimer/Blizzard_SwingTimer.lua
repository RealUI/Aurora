local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals next

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin

-- Forever-only addon (## AllowLoadGameType: camelot): the melee/ranged swing
-- timers, one frame per hand plus ranged. Retail has no equivalent.
--
-- SwingTimerFrameTemplate inherits EditModeSwingTimerSystemTemplate, so these
-- are Edit Mode systems and the player can move them; nothing here re-anchors.

do --[[ AddOns\Blizzard_SwingTimer.xml ]]
    function Skin.SwingTimerFrameTemplate(Frame)
        if not Frame or private.IsSkinned(Frame) then return end
        private.SetSkinned(Frame, true)

        -- ui-swingtimerbar-background and -frame are the bar chrome;
        -- Skin.FrameTypeStatusBar gives it Aurora's backdrop instead. They are
        -- hidden, not faded: ApplyRangePresentation sets their alpha (1 in
        -- range) and since 70532 runs on every swing. Blizzard never shows them.
        for _, key in next, {"Background", "Border"} do
            if Frame[key] then
                Frame[key]:Hide()
            end
        end
        -- TypeLabelShadow is the drop shadow behind the "Main Hand" label;
        -- range presentation dims the status bar, not this texture.
        if Frame.TypeLabelShadow then
            Frame.TypeLabelShadow:SetAlpha(0)
        end

        Skin.FrameTypeStatusBar(Frame.StatusBar)

        -- Pip marks the point in the swing and is the reason to look at this
        -- bar at all, so it is kept -- same policy as the PVPRankFrame badges.
    end
end

function private.AddOns.Blizzard_SwingTimer()
    for _, name in next, {
        "SwingTimerMainHandFrame",
        "SwingTimerOffHandFrame",
        "SwingTimerRangedFrame",
    } do
        Skin.SwingTimerFrameTemplate(_G[name])
    end
end
