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
    -- C_UnitAuras.GetAuraDataByIndex("player", 1, "MAW") unguarded, and under
    -- the Midnight rules that API THROWS instead of returning nil when auras
    -- are secret and the execution is tainted:
    --
    --   GetAuraDataByIndex(): Auras cannot be accessed when secret while
    --   tainted by 'RealUI_Skins'
    --
    -- Its only three callers are MawBuffsContainerMixin:Update and the scenario
    -- tracker's OnEvent / LayoutContents, so the throw lands mid-layout and
    -- takes the delve stage block down with it. This is the audible symptom in
    -- B97 and in the 2026-08-21 delve fault behind
    -- .kiro/steering/objective-tracker-taint.md.
    --
    -- Community workaround: ask C_Secrets first and short-circuit before the
    -- aura read. false is the right answer for all three callers - if auras are
    -- secret we cannot know whether there is a Maw buff, and the Maw/Torghast
    -- surface this gates is legacy content.
    --
    -- COST: this OWNS a Blizzard global, which taints it permanently for every
    -- later reader - the same cost documented for GameTooltip_InsertFrame in
    -- SharedXML\Mainline\SharedTooltipTemplates.lua. Accepted here because all
    -- three readers already sit inside the poisoned tracker set, and because
    -- the alternative is an error that aborts LayoutContents. hooksecurefunc is
    -- not an option: the fix has to change the return value.
    --
    -- NOTE: this only silences the throw. It does NOT undo the tracker layout
    -- state poisoning that objective-tracker-taint.md describes; that is still
    -- what the Blizzard_ObjectiveTracker skin gate is waiting on.
    if _G.C_Secrets and _G.C_Secrets.ShouldAurasBeSecret and _G.ShouldShowMawBuffs then
        local origShouldShowMawBuffs = _G.ShouldShowMawBuffs
        _G.ShouldShowMawBuffs = function()
            if _G.C_Secrets.ShouldAurasBeSecret() then return false end
            return origShouldShowMawBuffs()
        end
    end
end
