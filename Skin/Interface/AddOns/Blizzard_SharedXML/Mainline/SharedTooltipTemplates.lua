local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals next

--[[ Core ]]
local Aurora = private.Aurora
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

do --[[ FrameXML\SharedTooltipTemplates.lua ]]
    -- Tooltips skinned via the taint-safe path (NineSlice border pieces
    -- hidden with SetAlpha(0), no _auroraNineSlice flag) must not have
    -- their NineSlice touched from addon context during display, or the
    -- "secret number" taint propagates to child widgets.
    local taintSafeTooltips = {}
    function Hook.SetTaintSafe(tooltip)
        taintSafeTooltips[tooltip] = true
    end

    function Hook.SharedTooltip_SetBackdropStyle(self, style, embedded)
        if self:IsForbidden() then return end
        if taintSafeTooltips[self] then return end
        if not (embedded or self.IsEmbedded) then
            local r, g, b = Color.frame:GetRGB()
            local a = Util.GetFrameAlpha()

            self.NineSlice:SetCenterColor(r, g, b, a);
        end
    end
end

do --[[ FrameXML\SharedTooltipTemplates.xml ]]
    --[[ Every tooltip goes through the taint-safe path (B94, then the
        2026-10-06 taint audit). It used to call Skin.NineSlicePanelTemplate,
        which sets _auroraNineSlice and so enables the NineSliceUtil.ApplyLayout
        post-hook: Skin.FrameTypeFrame and Base.SetBackdrop (BackdropMixin
        methods, new textures, RealUI's stripes) on the NineSlice on every
        backdrop style change, in the middle of Blizzard's tooltip display.
        SharedTooltip_SetBackdropStyle then calls SetCenterColor on that same
        NineSlice, and widget tooltips (EmbeddedItemTooltip, scenario and
        area-POI widget sets) ran tainted.
        Now: border pieces hidden with SetAlpha(0), which ApplyLayout does not
        reset (SetTexture("") would be undone by its SetAtlas); the Center
        piece coloured once; no field on Blizzard's tables; the backdrop-style
        hook told to leave the tooltip alone. ]]
    local TOOLTIP_BORDER_PIECES = {
        "TopLeftCorner", "TopRightCorner",
        "BottomLeftCorner", "BottomRightCorner",
        "TopEdge", "BottomEdge", "LeftEdge", "RightEdge",
    }
    function Skin.SharedTooltipTemplate(GameTooltip)
        local ns = GameTooltip and GameTooltip.NineSlice
        if not ns then return end

        for _, name in next, TOOLTIP_BORDER_PIECES do
            local piece = ns[name]
            if piece then
                piece:SetAlpha(0)
            end
        end
        local r, g, b = Color.frame:GetRGB()
        ns:SetCenterColor(r, g, b, Util.GetFrameAlpha())
        Hook.SetTaintSafe(GameTooltip)
    end
    function Skin.SharedNoHeaderTooltipTemplate(GameTooltip)
        Skin.SharedTooltipTemplate(GameTooltip)
    end

    function Skin.TooltipBackdropTemplate(Frame)
        if Frame.debug then
            Frame.NineSlice.debug = Frame.debug
        end
        Skin.NineSlicePanelTemplate(Frame.NineSlice)

        local r, g, b = Color.frame:GetRGB()
        Frame:SetBackdropColor(r, g, b, Frame.backdropColorAlpha or 1)
    end

    function Skin.TooltipBorderBackdropTemplate(Frame)
        Skin.TooltipBackdropTemplate(Frame)
    end

    function Skin.TooltipBorderedFrameTemplate(Frame)
        Skin.TooltipBackdropTemplate(Frame)
    end

end

function private.SharedXML.SharedTooltipTemplates()
    if private.disabled.tooltips then return end

    _G.hooksecurefunc("SharedTooltip_SetBackdropStyle", Hook.SharedTooltip_SetBackdropStyle)

    -- NOTE: Do NOT replace _G.GetUnscaledFrameRect here.
    -- Overwriting that global with an addon-owned function taints it,
    -- which propagates through layout paths into the GameMenu secure
    -- execution and causes ADDON_ACTION_FORBIDDEN on Logout/Quit.

    -- NOTE: Do NOT replace GameTooltip_InsertFrame. Aurora owned it from
    -- 094362e4 to guard secret Round() inputs (SafeNumber) for the LootHistory
    -- roll tooltips, and it cost trinket upgrades (B53/B145): the replacement
    -- wrote insertedFrames on the item upgrade preview tooltip, and on confirm
    -- SetOwner -> SharedTooltip_ClearInsertedFrames read that tainted field
    -- one call before C_ItemUpgrade.UpgradeItem(), which was then refused.
    -- The secret values only appeared because LootHistory already ran
    -- tainted, from Aurora's own Init hook and Layout override (both removed).
    -- Removed 2026-10-04 after an A/B with Blizzard's original: long-text
    -- trinket upgrades go through, and an LFR loot history hover is clean.

    -- NOTE: Do NOT wrap GameTooltip_AddWidgetSet here.
    -- Replacing the global with an addon-owned function taints the execution
    -- before RegisterForWidgetSet is called, causing GetUnscaledFrameRect to
    -- receive secret values from frame:GetScaledRect() and error on arithmetic.

    -- NOTE: Do NOT replace SetTooltipMoney. Aurora replaced it with an
    -- inline coin string (WoWUIBugs #801, secret GetTextWidth in
    -- MoneyFrame_Update). Nothing in Blizzard's 12.1 UI calls it any more
    -- (MoneyFrame.lua:609 only defines it), and replacing a Blizzard global
    -- taints whatever calls it. Removed 2026-10-05 (taint audit,
    -- tracker-widget-taint-rewrite).
end
