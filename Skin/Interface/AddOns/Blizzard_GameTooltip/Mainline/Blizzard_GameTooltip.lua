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
    function Skin.GameTooltipTemplate(GameTooltip)
        Skin.SharedTooltipTemplate(GameTooltip)

        local statusBar = _G[GameTooltip:GetName().."StatusBar"]
        Skin.FrameTypeStatusBar(statusBar)
        Base.SetBackdropColor(statusBar, Color.frame)

        statusBar:SetHeight(4)
        statusBar:SetPoint("TOPLEFT", GameTooltip, "BOTTOMLEFT", 1, 0)
        statusBar:SetPoint("TOPRIGHT", GameTooltip, "BOTTOMRIGHT", -1, 0)
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
    function Skin.TooltipStatusBarTemplate(StatusBar)
        local _, border = StatusBar:GetRegions()
        if border then
            border:Hide()
        end

        local texture = StatusBar:GetStatusBarTexture()
        if texture then
            texture:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
        end

        local r, g, b = Color.highlight:GetRGB()
        StatusBar:SetStatusBarColor(r, g, b)
    end
    function Skin.TooltipProgressBarTemplate(Frame)
        local bar = Frame.Bar
        if not bar then
            return
        end

        local texture = bar:GetStatusBarTexture()
        if texture then
            texture:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
            texture:SetDrawLayer("BORDER")
        end

        local r, g, b = Color.highlight:GetRGB()
        bar:SetStatusBarColor(r, g, b)

        if bar.BorderLeft then bar.BorderLeft:Hide() end
        if bar.BorderRight then bar.BorderRight:Hide() end
        if bar.BorderMid then bar.BorderMid:Hide() end

        local LeftDivider = bar.LeftDivider
        if LeftDivider then
            LeftDivider:SetColorTexture(Color.button:GetRGB())
            LeftDivider:SetSize(1, 15)
        end

        local RightDivider = bar.RightDivider
        if RightDivider then
            RightDivider:SetColorTexture(Color.button:GetRGB())
            RightDivider:SetSize(1, 15)
        end

        local background = _G.select(7, bar:GetRegions())
        if background then
            background:Hide()
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

    Skin.ShoppingTooltipTemplate(_G.ShoppingTooltip1)
    Skin.ShoppingTooltipTemplate(_G.ShoppingTooltip2)

    -- Taint-safe GameTooltip skin: the standard Skin.GameTooltipTemplate
    -- calls Skin.NineSlicePanelTemplate (sets _auroraNineSlice, enabling
    -- the NineSliceUtil.ApplyLayout hook that runs Base.SetBackdrop on
    -- EVERY backdrop style change—writing BackdropMixin methods to the
    -- NineSlice table and creating textures), plus Base.SetBackdrop /
    -- SetPoint / SetHeight on the StatusBar.  These operations mark
    -- GameTooltip's child hierarchy as addon-modified, causing
    -- GetWidth/GetScaledRect to return "secret number" values that break
    -- widget set processing in GameTooltip_AddWidgetSet (AreaPOI tooltips).
    do
        local ns = _G.GameTooltip.NineSlice
        -- Hide border pieces; keep Center visible for backdrop color.
        -- SetAlpha does not get reset by NineSliceUtil.ApplyLayout.
        local borderPieces = {
            "TopLeftCorner", "TopRightCorner",
            "BottomLeftCorner", "BottomRightCorner",
            "TopEdge", "BottomEdge", "LeftEdge", "RightEdge",
        }
        for _, name in next, borderPieces do
            local piece = ns[name]
            if piece then
                piece:SetAlpha(0)
            end
        end
        local r, g, b = Color.frame:GetRGB()
        ns:SetCenterColor(r, g, b, Util.GetFrameAlpha())
        -- Do NOT set ns._auroraNineSlice — this would enable the heavy
        -- NineSlice hook (Base.SetBackdrop) on every tooltip display.
        -- Do NOT skin GameTooltipStatusBar — Base.SetBackdrop creates
        -- textures/writes methods, and SetPoint creates a tainted anchor.
        -- Tell the SharedTooltip_SetBackdropStyle hook to skip this tooltip
        -- so it doesn't call NineSlice:SetCenterColor from addon context
        -- during the tooltip display flow.
        Hook.SetTaintSafe(_G.GameTooltip)
    end

    Skin.GameTooltipTemplate(_G.EmbeddedItemTooltip)
    Skin.InternalEmbeddedItemTooltipTemplate(_G.EmbeddedItemTooltip.ItemTooltip)
end
