local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin

do --[[ AddOns\Blizzard_MawBuffs.lua ]]
    Hook.MawBuffsListMixin = {}
    function Hook.MawBuffsListMixin:OnShow()
        self.button:ClearPushedTexture()
        self.button:ClearHighlightTexture()
        self.button:SetWidth(253)
        self.button:SetButtonState("NORMAL");
        self.button:SetPushedTextOffset(1.25, -1)
        self.button:SetButtonState("PUSHED", true);
    end
    function Hook.MawBuffsListMixin:OnHide()
        self.button:ClearPushedTexture()
        self.button:ClearHighlightTexture()
    end
end

do --[[ AddOns\Blizzard_MawBuffs.xml ]]
    local color = private.COVENANT_COLORS.Maw
    function Skin.MawBuffsList(Frame)
        Frame:HookScript("OnShow", Hook.MawBuffsListMixin.OnShow)
        Frame:HookScript("OnHide", Hook.MawBuffsListMixin.OnHide)

        Base.SetBackdrop(Frame, color)
        Frame:SetBackdropOptions({
            bgFile = "gradientUp",
            offsets = {
                left = 5,
                right = 5,
                top = 12,
                bottom = 12,
            }
        })

        Frame.TopBG:SetAlpha(0)
        Frame.BottomBG:SetAlpha(0)
        Frame.MiddleBG:SetAlpha(0)
    end
    function Skin.MawBuffsContainer(Button)
        Skin.FrameTypeButton(Button)
        Button:SetButtonColor(color)
        Button:SetBackdropOptions({
            bgFile = "gradientUp",
            offsets = {
                left = 13,
                right = 3,
                top = 11,
                bottom = 11,
            }
        })

        Skin.MawBuffsList(Button.List)
    end
end

function private.AddOns.Blizzard_MawBuffs()
    ----====####################====----
    --              File              --
    ----====####################====----

    -- The ShouldShowMawBuffs wrapper that lived here (B97, 2026-08-29 to
    -- 2026-10-05) is gone, and must not come back. A login taint.log
    -- (tracker-widget-taint-rewrite task 5.8) showed it was the injector, not
    -- the cure: the scenario tracker's LayoutContents reads the global on every
    -- layout, starting with the tracker's first update at login, and reading
    -- an addon-written global taints the execution. The very next write
    -- (Module.lua:159 `state`) carried that taint into the whole tracker's
    -- layout state for the session. The GetAuraDataByIndex throw it was meant
    -- to hide only happens when the tracker is already tainted; fix the taint,
    -- never the global.
end
