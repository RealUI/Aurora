local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals next

--[[ Core ]]
local Aurora = private.Aurora
local Base, Hook, Skin = Aurora.Base, Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

do --[[ FrameXML\GameTooltip.lua ]]
    function Hook.GameTooltip_ShowStatusBar(self)
        Util.WrapPoolAcquire(self.statusBarPool, Skin.TooltipStatusBarTemplate)
    end
    function Hook.GameTooltip_ShowProgressBar(self)
        Util.WrapPoolAcquire(self.progressBarPool, Skin.TooltipProgressBarTemplate)
    end

    function Hook.EmbeddedItemTooltip_Clear(self)
        -- Don't lazily skin frames here; doing so during the tooltip display
        -- flow taints the layout and causes "secret number" errors in
        -- EmbeddedItemTooltip_UpdateSize. Only act on frames that were
        -- explicitly skinned at init time.
        if not self._auroraIconBorder then return end
        self._auroraIconBorder:SetBackdropBorderColor(0, 0, 0)
        self._auroraIconBorder:Hide()
    end
    function Hook.EmbeddedItemTooltip_PrepareForItem(self)
        if not self._auroraIconBorder then return end
        self._auroraIconBorder:Show()
    end
    function Hook.EmbeddedItemTooltip_PrepareForSpell(self)
        if not self._auroraIconBorder then return end
        self._auroraIconBorder:Show()
    end
end

do --[[ FrameXML\GameTooltip.xml ]]
    -- The taint-safe tooltip skin (Skin.SharedTooltipTemplate). The
    -- <name>StatusBar is left as Blizzard art, as on GameTooltip itself:
    -- Skin.FrameTypeStatusBar and Base.SetBackdrop write methods onto it and
    -- SetPoint gives it an addon anchor (2026-10-06 taint audit).
    function Skin.GameTooltipTemplate(GameTooltip)
        Skin.SharedTooltipTemplate(GameTooltip)
    end
    function Skin.InternalEmbeddedItemTooltipTemplate(Frame)
        Base.CropIcon(Frame.Icon)
        local bg = _G.CreateFrame("Frame", nil, Frame)
        bg:SetPoint("TOPLEFT", Frame.Icon, -1, 1)
        bg:SetPoint("BOTTOMRIGHT", Frame.Icon, 1, -1)
        Base.SetBackdrop(bg, Color.black, 0)
        -- Do NOT store as _auroraIconBorder: the SetItemButtonQuality,
        -- EmbeddedItemTooltip_Clear, and EmbeddedItemTooltip_Prepare*
        -- hooks would then modify this frame during the secure tooltip
        -- display flow, tainting layout values that
        -- EmbeddedItemTooltip_UpdateSize reads immediately afterward.
        bg:Show()

        if private.isRetail then
            Skin.GarrisonFollowerTooltipContentsTemplate(Frame.FollowerTooltip)
            Util.Mixin(_G.GarrisonFollowerPortraitMixin, Hook.GarrisonFollowerPortraitMixin)
        end
    end
    function Skin.ShoppingTooltipTemplate(GameTooltip)
        Skin.SharedTooltipTemplate(GameTooltip)
    end
    --[[ Tooltip status and progress bars come from GameTooltip's pools,
        acquired inside the tooltip display (GameTooltip_ShowStatusBar /
        ShowProgressBar, e.g. world-quest pins, then GameTooltip_AddWidgetSet
        in the same execution). So: in place only (taint audit 2026-10-06,
        B170 follow-up). Existing regions are recoloured or cleared; no size,
        anchor or draw-layer change. ]]
    function Skin.TooltipStatusBarTemplate(StatusBar)
        -- The unnamed UI-StatusBar-Border texture.
        local _, border = StatusBar:GetRegions()
        if border and border.SetTexture then
            border:SetTexture("")
        end

        local texture = StatusBar:GetStatusBarTexture()
        if texture then
            texture:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
        end

        local r, g, b = Color.highlight:GetRGB()
        StatusBar:SetStatusBarColor(r, g, b)
    end

    -- A 7x14 divider drawn as a 1px line: vertex offsets narrow the quad
    -- without resizing the region (1 upper-left, 2 lower-left, 3 upper-right,
    -- 4 lower-right).
    local function StyleDivider(divider)
        if not divider then return end
        divider:SetColorTexture(Color.button:GetRGB())
        divider:SetVertexOffset(1, 3, 0)
        divider:SetVertexOffset(2, 3, 0)
        divider:SetVertexOffset(3, -3, 0)
        divider:SetVertexOffset(4, -3, 0)
    end
    function Skin.TooltipProgressBarTemplate(Frame)
        local bar = Frame.Bar
        if not bar then
            return
        end

        local texture = bar:GetStatusBarTexture()
        if texture then
            texture:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
        end

        local r, g, b = Color.highlight:GetRGB()
        bar:SetStatusBarColor(r, g, b)

        if bar.BorderLeft then bar.BorderLeft:SetTexture("") end
        if bar.BorderRight then bar.BorderRight:SetTexture("") end
        if bar.BorderMid then bar.BorderMid:SetTexture("") end

        StyleDivider(bar.LeftDivider)
        StyleDivider(bar.RightDivider)

        -- The unnamed dark-blue BACKGROUND colour texture.
        for i = 1, _G.select("#", bar:GetRegions()) do
            local region = _G.select(i, bar:GetRegions())
            if region ~= texture and region:IsObjectType("Texture")
            and region:GetDrawLayer() == "BACKGROUND" then
                region:SetColorTexture(Color.frame.r, Color.frame.g, Color.frame.b, Color.frame.a)
            end
        end
    end
end

function private.FrameXML.GameTooltip()
    if private.disabled.tooltips then return end

    _G.hooksecurefunc("EmbeddedItemTooltip_Clear", Hook.EmbeddedItemTooltip_Clear)
    _G.hooksecurefunc("EmbeddedItemTooltip_PrepareForItem", Hook.EmbeddedItemTooltip_PrepareForItem)
    _G.hooksecurefunc("EmbeddedItemTooltip_PrepareForSpell", Hook.EmbeddedItemTooltip_PrepareForSpell)
    _G.hooksecurefunc("GameTooltip_ShowStatusBar", Hook.GameTooltip_ShowStatusBar)
    _G.hooksecurefunc("GameTooltip_ShowProgressBar", Hook.GameTooltip_ShowProgressBar)

    -- Taint-safe tooltip skin: Skin.SharedTooltipTemplate (SharedTooltipTemplates.lua)
    -- hides the NineSlice border pieces with SetAlpha(0), colours Center once,
    -- writes nothing onto Blizzard's tables and never sets _auroraNineSlice, so
    -- the NineSliceUtil.ApplyLayout hook (Base.SetBackdrop on every backdrop
    -- style change) never runs on a tooltip. The old route marked GameTooltip's
    -- child hierarchy as addon-modified and broke GameTooltip_AddWidgetSet
    -- (AreaPOI tooltips). B94 moved GameTooltip and the shopping tooltips over;
    -- the 2026-10-06 taint audit moved the template itself, so every tooltip
    -- skinned through Skin.GameTooltipTemplate / ShoppingTooltipTemplate /
    -- SharedTooltipTemplate (EmbeddedItemTooltip, ItemRefTooltip, Contribution
    -- and Garrison tooltips, FrameStackTooltip) is on it.
    -- GameTooltipStatusBar is not skinned: Base.SetBackdrop writes methods and
    -- SetPoint gives it an addon anchor.
    private.ApplyTaintSafeTooltipSkin = Skin.SharedTooltipTemplate

    Skin.SharedTooltipTemplate(_G.GameTooltip)
    Skin.SharedTooltipTemplate(_G.ShoppingTooltip1)
    Skin.SharedTooltipTemplate(_G.ShoppingTooltip2)

    Skin.GameTooltipTemplate(_G.EmbeddedItemTooltip)
    Skin.InternalEmbeddedItemTooltipTemplate(_G.EmbeddedItemTooltip.ItemTooltip)
end
