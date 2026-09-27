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

    -- No ShouldShowMawBuffs wrapper. Aurora used to own that global (12.1.0.8)
    -- to short-circuit Blizzard's unguarded GetAuraDataByIndex("player", 1,
    -- "MAW") when auras are secret. Owning it tainted the scenario tracker's
    -- UNIT_AURA path (a quarter of a 4.0.1 taint log). Removed 2026-09-27 after
    -- a delve and two LFR wings ran clean without it (RealUI triage B137).
    -- If the tracker throws "Auras cannot be accessed when secret" again, fix
    -- the taint that reaches the tracker; do not re-wrap the global.
end
