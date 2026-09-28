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

    ----------------------------------------
    -- ShouldShowMawBuffs secret-aura guard --
    ----------------------------------------
    -- Blizzard bug (WoW 12.x secret auras). Blizzard_MawBuffs.lua:4 reads
    -- C_UnitAuras.GetAuraDataByIndex("player", 1, "MAW") unguarded, and that
    -- API THROWS when auras are secret and the execution is tainted:
    --
    --   GetAuraDataByIndex(): Auras cannot be accessed when secret while
    --   tainted by 'RealUI_Skins'
    --
    -- Its callers are MawBuffsContainerMixin:Update and the scenario tracker's
    -- OnEvent / LayoutContents, so the throw aborts the delve stage block
    -- mid-layout (B97). The taint comes from the tracker skin's own layout
    -- writes (objective-tracker-taint.md); this guard hides the throw, not that.
    --
    -- COST: owning the global taints it for every later reader, including the
    -- scenario tracker's UNIT_AURA path (a quarter of one 4.0.1 taint log).
    --
    -- History: removed 2026-09-27 after a delve and two LFR wings ran clean
    -- without it; the throw came back in the next delve (2026-09-28, B137).
    -- Clean runs do not prove it unneeded. It can go only once the tracker
    -- skin's rewrite stops tainting LayoutContents, or the skin is gated.
    if _G.C_Secrets and _G.C_Secrets.ShouldAurasBeSecret and _G.ShouldShowMawBuffs then
        local origShouldShowMawBuffs = _G.ShouldShowMawBuffs
        _G.ShouldShowMawBuffs = function()
            if _G.C_Secrets.ShouldAurasBeSecret() then return false end
            return origShouldShowMawBuffs()
        end
    end
end
