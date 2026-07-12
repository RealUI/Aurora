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

    -- Hook.ObjectPoolMixin removed in 11.0.0 (private API).
    -- Wrap the pool's Acquire method to skin and mixin frames when first created.
    do
        local poolAcquire = _G.HelpTip.framePool.Acquire
        _G.HelpTip.framePool.Acquire = function(pool, ...)
            local frame, isNew = poolAcquire(pool, ...)
            if isNew then
                Skin.HelpTipTemplate(frame)
                Util.Mixin(frame, Hook.HelpTipTemplateMixin)
            end
            return frame, isNew
        end
    end
	for frame in _G.HelpTip.framePool:EnumerateActive() do
        Skin.HelpTipTemplate(frame)
        Util.Mixin(frame, Hook.HelpTipTemplateMixin)
        Hook.HelpTipTemplateMixin.RotateArrow(frame, frame.Arrow.rotation)
	end
end
