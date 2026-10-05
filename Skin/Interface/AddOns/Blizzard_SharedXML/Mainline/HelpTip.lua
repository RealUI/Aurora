local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Util = Aurora.Util

do --[[ FrameXML\HelpTip.lua ]]
    local directions = {
        "Down",
        "Left",
        "Up",
        "Right"
    }

    Hook.HelpTipTemplateMixin = {}
    function Hook.HelpTipTemplateMixin:RotateArrow(rotation)
        local Arrow = self.Arrow
        local direction = directions[rotation]
        if direction == "Left" or direction == "Right" then
            Arrow:SetSize(17, 41)
        else
            Arrow:SetSize(41, 17)
        end

        --Base.SetTexture(Arrow.Arrow, "arrow"..direction)
        _G.C_Timer.NewTicker(0, function(...)
            Base.SetTexture(Arrow.Arrow, "arrow"..direction)
        end, 1)
    end
end

do --[[ FrameXML\HelpTip.xml ]]
    function Skin.HelpTipTemplate(Frame)
        Skin.GlowBoxTemplate(Frame)
        Skin.UIPanelCloseButton(Frame.CloseButton)
        Skin.UIPanelButtonTemplate(Frame.OkayButton)
        Skin.GlowBoxArrowTemplate(Frame.Arrow)
    end
end

function private.FrameXML.HelpTip()
    Util.Mixin(_G.HelpTipTemplateMixin, Hook.HelpTipTemplateMixin)

    -- Skin each help tip frame once, when the pool first hands it out. This
    -- used to replace HelpTip.framePool.Acquire with an Aurora closure, so
    -- every help tip Blizzard showed (quest, map, tracker and tutorial code)
    -- ran Aurora code inside that execution (B167 class, found 2026-10-06 by
    -- tracker-widget-taint-rewrite). Util.WrapPoolAcquire post-hooks Acquire
    -- and skins each frame once, including the frames already active.
    Util.WrapPoolAcquire(_G.HelpTip.framePool, function(frame)
        Skin.HelpTipTemplate(frame)
        Util.Mixin(frame, Hook.HelpTipTemplateMixin)
    end)
	for frame in _G.HelpTip.framePool:EnumerateActive() do
        Hook.HelpTipTemplateMixin.RotateArrow(frame, frame.Arrow.rotation)
	end
end
