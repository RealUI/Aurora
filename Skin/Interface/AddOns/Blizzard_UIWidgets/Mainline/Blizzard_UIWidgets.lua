local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals _G next type

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Util = Aurora.Util

local FORCE_WIDGET_CHAT_DEBUG = false

-- Track skinned widget frames without writing to the frame's Lua table.
-- Direct table writes (frame._auroraSkinned = true) persist when WoW's global
-- widget pool recycles frames from non-nameplate containers into nameplate
-- containers.  The tainted field then causes GetScaledRect() to fail with
-- "Can't measure restricted regions" inside the secure OnNamePlateAdded path.
-- Weak keys let the GC collect released frames normally.
local skinnedWidgetFrames = _G.setmetatable({}, {__mode = "k"})

local function IsSecret(value)
    if _G.issecretvalue and _G.issecretvalue(value) then
        return true
    end
    if _G.issecrettable and _G.issecrettable(value) then
        return true
    end
    return false
end

local function SafeSetAlpha(obj, alpha)
    if obj then
        _G.pcall(obj.SetAlpha, obj, alpha)
    end
end

local function SafeNumber(value, fallback)
    if type(value) ~= "number" or IsSecret(value) then
        return fallback
    end
    return value
end

local function SafeDebugName(frame)
    if not frame then
        return "<nil>"
    end

    local ok, debugName = _G.pcall(function()
        return frame:GetDebugName()
    end)
    if ok and type(debugName) == "string" and not IsSecret(debugName) and debugName ~= "" then
        return debugName
    end

    local okName, name = _G.pcall(function()
        return frame.GetName and frame:GetName()
    end)
    if okName and type(name) == "string" and not IsSecret(name) and name ~= "" then
        return name
    end

    return "<frame>"
end

-- NOTE: Do NOT replace _G.GetUnscaledFrameRect here. Overwriting a global
-- function from addon code taints the global itself, which propagates taint
-- through every LayoutFrame:GetExtents() → Layout() call chain. This caused
-- massive CooldownViewer combat taint (all viewer frames, UIParentBottomManagedFrameContainer,
-- UIParentRightManagedFrameContainer blocked in combat). The original Blizzard
-- function in FrameUtil.lua is secure and should remain untouched.

local function IsBelowMinimapContainer(container)
    return container == _G.UIWidgetBelowMinimapContainerFrame
end

-- Widget containers parented to a GameTooltip must NOT be skinned.
-- Skinning writes to frame tables and creates textures, tainting the widget
-- frames' geometry.  The tainted GetHeight() return values propagate back
-- through GameTooltip_AddWidgetSet → AreaPoiUtil.TryShowTooltip, poisoning
-- the execution context so that subsequent SetPoint calls (inside
-- AddSuppressedPinsToTooltip) produce secret anchor values.  When
-- ResizeLayoutMixin:Layout() later compares GetNumPoints(), the comparison
-- fails with "attempt to compare a secret number value".
local function IsTooltipWidgetContainer(container)
    local ok, parent = _G.pcall(container.GetParent, container)
    if ok and parent then
        local okType, isTooltip = _G.pcall(parent.IsObjectType, parent, "GameTooltip")
        if okType and isTooltip then
            return true
        end
    end
    return false
end

local function IsRestrictedWidgetContainer(container)
    if not container then
        return false
    end

    local okForbidden, isForbidden = _G.pcall(function()
        return container.IsForbidden and container:IsForbidden()
    end)
    if okForbidden and isForbidden then
        return true
    end

    local okProtected, isProtected = _G.pcall(function()
        return container.IsProtected and container:IsProtected()
    end)
    if okProtected and isProtected then
        return true
    end

    return false
end

-- Blizzard_NamePlates.xml:241 declares the nameplate WidgetContainer as a plain
-- <Frame> with no protected="true", so IsRestrictedWidgetContainer misses it.
-- However the nameplate layout runs from [C] OnNamePlateAdded in a secure C
-- context; writing _auroraSkinned to widget frames inside this container taints
-- them, causing GetScaledRect to fail with "Can't measure restricted regions"
-- when the secure path tries to measure those frames.
-- Detect nameplate containers by their parent structure: the WidgetContainer's
-- parent is always the NamePlateUnitFrameMixin button which has HealthBarsContainer.healthBar.
local function IsNamePlateWidgetContainer(container)
    local ok, parent = _G.pcall(container.GetParent, container)
    if not ok or not parent then return false end
    local ok2, result = _G.pcall(function()
        return parent.HealthBarsContainer and parent.HealthBarsContainer.healthBar
    end)
    return ok2 and result and true or false
end

local function DebugBelowMinimap(...)
    if not private.isDev and not FORCE_WIDGET_CHAT_DEBUG then
        return
    end

    if private.debug then
        private.debug("UIWidgetBelowMinimap", ...)
    end
    if FORCE_WIDGET_CHAT_DEBUG then
        _G.pcall(_G.print, "|cff33ff99Aurora UIWidgetBelowMinimap|r", ...) -- static: not a theme color
    end
end

local function DebugUIWidgets(...)
    if not private.isDev and not FORCE_WIDGET_CHAT_DEBUG then
        return
    end

    if private.debug then
        private.debug(...)
    end
    if FORCE_WIDGET_CHAT_DEBUG then
        _G.pcall(_G.print, "|cff33ff99Aurora UIWidgets|r", ...) -- static: not a theme color
    end
end

local function BootstrapWidgetContainer(container)
    if not container then
        return
    end

    local activeSetID = container.widgetSetID
    local belowMinimapSetID = _G.C_UIWidgetManager and _G.C_UIWidgetManager.GetBelowMinimapWidgetSetID and _G.C_UIWidgetManager.GetBelowMinimapWidgetSetID()
    DebugBelowMinimap("Bootstrap", SafeDebugName(container), "activeSetID", activeSetID, "belowMinimapSetID", belowMinimapSetID)

    if not activeSetID then
        return
    end

    local setWidgets = _G.C_UIWidgetManager.GetAllWidgetsBySetID(activeSetID)
    DebugBelowMinimap("Bootstrap widgets", #setWidgets)
    for _, widgetInfo in next, setWidgets do
        local widgetTypeInfo = _G.UIWidgetManager:GetWidgetTypeInfo(widgetInfo.widgetType)
        local template = widgetTypeInfo and widgetTypeInfo.templateInfo and widgetTypeInfo.templateInfo.frameTemplate or "<missing>"
        DebugBelowMinimap("Bootstrap widget", "widgetID", widgetInfo.widgetID, "widgetType", widgetInfo.widgetType, "template", template)
    end

    Hook.UIWidgetManagerMixin.OnWidgetContainerRegistered(_G.UIWidgetManager, container)
end

do --[[ AddOns\Blizzard_UIWidgets.lua ]]
    do --[[ Blizzard_UIWidgetManager ]]
        Hook.UIWidgetContainerMixin = {}
        function Hook.UIWidgetContainerMixin:CreateWidget(widgetID, widgetType, widgetTypeInfo)
            if IsTooltipWidgetContainer(self) then return end
            if IsRestrictedWidgetContainer(self) then return end
            if IsNamePlateWidgetContainer(self) then return end
            local widgetFrame = self.widgetFrames[widgetID]
            if not widgetFrame then
                -- if private.isDev then
                --     _G.print("UIWidgetContainerMixin:CreateWidget no widgetFrame", self:GetDebugName(), widgetID, widgetType)
                -- end
                return
            end

            local template = widgetTypeInfo.templateInfo.frameTemplate
            if IsBelowMinimapContainer(self) then
                DebugBelowMinimap("CreateWidget", "container", SafeDebugName(self), "widgetID", widgetID, "widgetType", widgetType, "template", template)
            end

            if Skin[template] then
                DebugUIWidgets("Skinning template for UIWidgetContainerMixin", SafeDebugName(widgetFrame), template)
                if not skinnedWidgetFrames[widgetFrame] then
                    local ok, err = _G.pcall(Skin[template], widgetFrame)
                    if not ok then
                        DebugUIWidgets("Error skinning template", template, SafeDebugName(widgetFrame), err)
                    end
                    skinnedWidgetFrames[widgetFrame] = true
                    if IsBelowMinimapContainer(self) then
                        DebugBelowMinimap("Skinned template", template, SafeDebugName(widgetFrame))
                    end
                end
            else
                DebugUIWidgets("Missing template for UIWidgetContainerMixin", SafeDebugName(widgetFrame), template)
                if IsBelowMinimapContainer(self) then
                    DebugBelowMinimap("Missing template", template, SafeDebugName(widgetFrame))
                end
            end
        end

        Hook.UIWidgetManagerMixin = {}
        function Hook.UIWidgetManagerMixin:OnWidgetContainerRegistered(widgetContainer)
            if IsTooltipWidgetContainer(widgetContainer) then return end
            if IsRestrictedWidgetContainer(widgetContainer) then return end
            if IsNamePlateWidgetContainer(widgetContainer) then return end
            local setWidgets = _G.C_UIWidgetManager.GetAllWidgetsBySetID(widgetContainer.widgetSetID)
            if IsBelowMinimapContainer(widgetContainer) then
                DebugBelowMinimap("OnWidgetContainerRegistered", SafeDebugName(widgetContainer), "widgetSetID", widgetContainer.widgetSetID, "count", #setWidgets)
            end

            local widgetID, widgetType, widgetTypeInfo, widgetVisInfo
            for _, widgetInfo in next, setWidgets do
                widgetID, widgetType = widgetInfo.widgetID, widgetInfo.widgetType
                widgetTypeInfo = _G.UIWidgetManager:GetWidgetTypeInfo(widgetType)
                widgetVisInfo = widgetTypeInfo.visInfoDataFunction(widgetID)

                Hook.UIWidgetContainerMixin.CreateWidget(widgetContainer, widgetID, widgetType, widgetTypeInfo, widgetVisInfo)
            end
        end
    end

    do --[[ Blizzard_UIWidgetBelowMinimapFrame ]]
        function Skin.UIWidgetBelowMinimapContainerFrame(Frame)
            DebugBelowMinimap("Skin container frame", SafeDebugName(Frame))

            SafeSetAlpha(Frame and Frame.LeftLine, 0)
            SafeSetAlpha(Frame and Frame.RightLine, 0)
            SafeSetAlpha(Frame and Frame.BarBackground, 0)
            SafeSetAlpha(Frame and Frame.Glow1, 0)
            SafeSetAlpha(Frame and Frame.Glow2, 0)
            SafeSetAlpha(Frame and Frame.Glow3, 0)
        end

        Hook.UIWidgetBelowMinimapContainerMixin = {}
        function Hook.UIWidgetBelowMinimapContainerMixin:RegisterForWidgetSet(widgetSetID)
                if IsBelowMinimapContainer(self) then
                    DebugBelowMinimap("RegisterForWidgetSet", SafeDebugName(self), widgetSetID)
                Skin.UIWidgetBelowMinimapContainerFrame(self)
            end
        end

        function Hook.UIWidgetBelowMinimapContainerMixin:ProcessAllWidgets()
                if IsBelowMinimapContainer(self) then
                    DebugBelowMinimap("ProcessAllWidgets", SafeDebugName(self), self.widgetSetID)
                Skin.UIWidgetBelowMinimapContainerFrame(self)
            end
        end
    end
end

do --[[ AddOns\Blizzard_UIWidgets.xml ]]
    do --[[ Blizzard_UIWidgetTemplateBase ]]
        function Skin.UIWidgetBaseStatusBarTemplate(StatusBar)
            -- TAINT-SAFE: Skin.FrameTypeStatusBar installs runtime hooks on
            -- SetStatusBarColor/SetStatusBarTexture that write frame._aurora*
            -- Lua table fields; Base.SetBackdrop also writes _auroraSkinned etc.
            -- UIWidget status bar frames are pooled globally and can be recycled
            -- from non-tooltip containers (BelowMinimap, TopCenter) into tooltip
            -- widget containers.  Lua table writes and hook-triggered writes
            -- persist after pool release, causing GetWidth() to return secret
            -- numbers when the recycled frame is later laid out in a tainted
            -- context.  Widget API calls only — no table writes, no runtime hooks.
            StatusBar:SetStatusBarTexture(private.textures.plain)
            local tex = StatusBar:GetStatusBarTexture()
            if tex then tex:SetDrawLayer("BORDER") end
        end
        function Skin.UIWidgetBaseSpellTemplate(Frame)
            Base.CropIcon(Frame.Icon, Frame)

            SafeSetAlpha(Frame.Border, 0)
            SafeSetAlpha(Frame.DebuffBorder, 0)
        end
        function Skin.UIWidgetBaseScenarioHeaderTemplate(Frame)
            SafeSetAlpha(Frame.Frame, 0)
        end
    end
    do --[[ Blizzard_UIWidgetTemplateIconAndText ]]
        Skin.UIWidgetTemplateIconAndText = private.nop
    end
    do --[[ Blizzard_UIWidgetTemplateStatusBar ]]
        function Skin.UIWidgetTemplateStatusBar(Frame)
            local StatusBar = Frame.Bar
            Skin.UIWidgetBaseStatusBarTemplate(StatusBar)
            SafeSetAlpha(StatusBar.BGLeft, 0)
            SafeSetAlpha(StatusBar.BGRight, 0)
            SafeSetAlpha(StatusBar.BGCenter, 0)
            SafeSetAlpha(StatusBar.BorderLeft, 0)
            SafeSetAlpha(StatusBar.BorderRight, 0)
            SafeSetAlpha(StatusBar.BorderCenter, 0)
            SafeSetAlpha(StatusBar.Spark, 0)
        end
    end
    do --[[ Blizzard_UIWidgetTemplateDoubleStatusBar ]]
        function Skin.UIWidgetTemplateDoubleStatusBar_StatusBarTemplate(StatusBar)
            Skin.UIWidgetBaseStatusBarTemplate(StatusBar)

            SafeSetAlpha(StatusBar.BG, 0)
            SafeSetAlpha(StatusBar.BorderLeft, 0)
            SafeSetAlpha(StatusBar.BorderRight, 0)
            SafeSetAlpha(StatusBar.BorderCenter, 0)
            SafeSetAlpha(StatusBar.Spark, 0)
            SafeSetAlpha(StatusBar.SparkGlow, 0)
            if StatusBar.BorderGlow then
                StatusBar.BorderGlow:SetAllPoints(StatusBar)
                StatusBar.BorderGlow:SetTexCoord(0.025, 0.975, 0.19354838709677, 0.80645161290323)
            end
        end
        function Skin.UIWidgetTemplateDoubleStatusBar(Frame)
            Skin.UIWidgetTemplateDoubleStatusBar_StatusBarTemplate(Frame.LeftBar)
            Skin.UIWidgetTemplateDoubleStatusBar_StatusBarTemplate(Frame.RightBar)
        end
    end
    do --[[ Blizzard_UIWidgetTemplateTextWithState ]]
        Skin.UIWidgetTemplateTextWithState = private.nop
    end
    do --[[ Blizzard_UIWidgetTemplateButtonHeader ]]
        function Skin.ButtonHeaderButton(Button)
            if Button._auroraSkinned then
                return
            end
            -- _isMinimal prevents Skin.FrameTypeButton from adding its own backdrop,
            -- so the button sits seamlessly inside our unified _auroraBackdrop
            Button._isMinimal = true
            Skin.FrameTypeButton(Button)
            -- Explicitly hide the atlas texture sub-objects (parentKey refs in UIWidgetBaseButtonTemplate)
            SafeSetAlpha(Button.NormalTexture, 0)
            SafeSetAlpha(Button.HighlightTexture, 0)
            SafeSetAlpha(Button.PushedTexture, 0)
            Base.CropIcon(Button.Icon, Button)
            Button._auroraSkinned = true
        end

        local function ApplyButtonHeaderBackdrop(Frame)
            if not Frame._auroraBackdrop then
                local backdrop = _G.CreateFrame("Frame", nil, Frame)
                backdrop:SetFrameLevel(Frame:GetFrameLevel())
                Skin.FrameTypeFrame(backdrop)
                Frame._auroraBackdrop = backdrop
            end
            Frame._auroraBackdrop:ClearAllPoints()
            Frame._auroraBackdrop:SetPoint("LEFT",   Frame.HeaderText,      "LEFT",  -16, 0)
            Frame._auroraBackdrop:SetPoint("TOP",    Frame.ButtonContainer, "TOP")
            Frame._auroraBackdrop:SetPoint("RIGHT",  Frame.ButtonContainer, "RIGHT")
            Frame._auroraBackdrop:SetPoint("BOTTOM", Frame.ButtonContainer, "BOTTOM")
        end

        function Skin.UIWidgetTemplateButtonHeader(Frame)
            SafeSetAlpha(Frame.Frame, 0)

            if Frame.buttonPool then
                for Button in Frame.buttonPool:EnumerateActive() do
                    Skin.ButtonHeaderButton(Button)
                end
            end

            -- Apply immediately if already laid out (bootstrap: Setup already ran before skin)
            if Frame.ButtonContainer and Frame.ButtonContainer:GetWidth() > 0 then
                ApplyButtonHeaderBackdrop(Frame)
            end

            if not Frame._auroraButtonHeaderSetupHook then
                _G.hooksecurefunc(Frame, "Setup", function(self)
                    if self.buttonPool then
                        for Button in self.buttonPool:EnumerateActive() do
                            Skin.ButtonHeaderButton(Button)
                        end
                    end
                    -- Runs after ButtonContainer:Layout(), so size is correct
                    ApplyButtonHeaderBackdrop(self)
                end)
                Frame._auroraButtonHeaderSetupHook = true
            end
        end
    end
    do --[[ Blizzard_UIWidgetTemplateScenarioHeaderCurrenciesAndBackground ]]
        function Skin.UIWidgetTemplateScenarioHeaderCurrenciesAndBackground(Frame)
            Skin.UIWidgetBaseScenarioHeaderTemplate(Frame)
        end
    end
    do --[[ Blizzard_UIWidgetTemplateSpellDisplay ]]
        function Skin.UIWidgetTemplateSpellDisplay(Frame)
            Skin.UIWidgetBaseSpellTemplate(Frame.Spell)
        end
    end
end

function private.AddOns.Blizzard_UIWidgets()
    ----====####################====----
    --    Blizzard_UIWidgetManager    --
    ----====####################====----
    _G.hooksecurefunc(_G.UIWidgetManager, "OnWidgetContainerRegistered", function(_, widgetContainer)
        Hook.UIWidgetManagerMixin.OnWidgetContainerRegistered(_G.UIWidgetManager, widgetContainer)
    end)

    -- NOTE: Do NOT hook UIWidgetContainerMixin.CreateWidget globally via
    -- hooksecurefunc.  RegisterForWidgetSet calls ProcessAllWidgets (line 275)
    -- which calls CreateWidget for each widget and then IMMEDIATELY calls
    -- UpdateWidgetLayout (line 569) — all within the same synchronous call chain.
    -- Any hooksecurefunc callback that fires inside CreateWidget taints the
    -- execution context, and that taint persists into UpdateWidgetLayout →
    -- DefaultWidgetLayout → GetUnscaledFrameRect → frame:GetScaledRect(), which
    -- then returns secret number values for widget frames managed by the C layout
    -- system (including tooltip widget containers).
    -- UIWidgetManager:OnWidgetContainerRegistered fires at line 284, AFTER
    -- ProcessAllWidgets returns, so the hook there is safe and handles initial
    -- widget skinning for non-tooltip containers.
    -- UIWidgetBelowMinimapContainerFrame and UIWidgetTopCenterContainerFrame use
    -- Util.Mixin to install CreateWidget directly on the frame instance, bypassing
    -- the mixin's hooksecurefunc entirely.

    ----====#####################====----
    --  Blizzard_UIWidgetTemplateBase  --
    ----====#####################====----
    -- NOTE: Do NOT replace UIWidgetBaseStatusBarTemplateMixin.InitPartitions here.
    -- Replacing the global mixin writes an addon-owned slot. When a nameplate
    -- StatusBar widget calls InitPartitions from the secure [C] OnNamePlateAdded
    -- → ProcessAllWidgets chain, hitting the addon-owned slot taints the execution
    -- context and the subsequent UpdateWidgetLayout → GetScaledRect() fails with
    -- "Can't measure restricted regions".
    --
    -- The replacement was originally added to guard against GetWidth() returning a
    -- secret number when Aurora wrapped GameTooltip_AddWidgetSet. That wrapper was
    -- removed (see SharedTooltipTemplates.lua: "Do NOT wrap GameTooltip_AddWidgetSet").
    -- StatusBar frames in tooltip widget containers are not restricted, so GetWidth()
    -- returns a normal number and the original Blizzard InitPartitions works correctly.

    ----====################%%########====----
    -- Blizzard_UIWidgetTemplateIconAndText --
    ----====################%%########====----


    ----====####################################====----
    -- Blizzard_UIWidgetTemplateIconTextAndBackground --
    ----====####################################====----


    ----====#########################====----
    -- Blizzard_UIWidgetTemplateCaptureBar --
    ----====#########################====----


    ----====########################====----
    -- Blizzard_UIWidgetTemplateStatusBar --
    ----====########################====----


    ----====####################%%########====----
    -- Blizzard_UIWidgetTemplateDoubleStatusBar --
    ----====####################%%########====----


    ----====################################====----
    -- Blizzard_UIWidgetTemplateDoubleIconAndText --
    ----====################################====----


    ----====#####################################====----
    -- Blizzard_UIWidgetTemplateStackedResourceTracker --
    ----====#####################################====----


    ----====####################################====----
    -- Blizzard_UIWidgetTemplateIconTextAndCurrencies --
    ----====####################################====----


    ----====############################====----
    -- Blizzard_UIWidgetTemplateTextWithState --
    ----====############################====----
    if _G.UIWidgetTemplateTextWithStateMixin and _G.UIWidgetTemplateTextWithStateMixin.Setup then
        -- Replacing the mixin Setup taints the table slot, so even
        -- securecallfunction cannot restore a fully secure context.
        -- Re-implement the geometry with SafeNumber to avoid secret
        -- number arithmetic in every call path.
        _G.UIWidgetTemplateTextWithStateMixin.Setup = function(self, widgetInfo, widgetContainer)
            if _G.UIWidgetBaseTemplateMixin and _G.UIWidgetBaseTemplateMixin.Setup then
                _G.pcall(_G.UIWidgetBaseTemplateMixin.Setup, self, widgetInfo, widgetContainer)
            end
            self.orderIndex = SafeNumber(self.orderIndex, 0)

            local tooltip = widgetInfo and widgetInfo.tooltip
            if IsSecret(tooltip) then
                tooltip = ""
            end
            _G.pcall(self.SetTooltip, self, tooltip)

            local widgetSizeSetting = widgetInfo and widgetInfo.widgetSizeSetting
            widgetSizeSetting = SafeNumber(widgetSizeSetting, 0)

            if widgetSizeSetting > 0 then
                self.Text:SetWidth(widgetSizeSetting)
            else
                self.Text:SetWidth(0)
            end

            local text = widgetInfo and widgetInfo.text
            if IsSecret(text) or type(text) ~= "string" then
                text = ""
            end
            local fontType = SafeNumber(widgetInfo and widgetInfo.fontType, 0)
            local textSizeType = SafeNumber(widgetInfo and widgetInfo.textSizeType, 0)
            local enabledState = SafeNumber(widgetInfo and widgetInfo.enabledState, 0)
            local hAlign = SafeNumber(widgetInfo and widgetInfo.hAlign, 0)

            self.Text:Setup(text, fontType, textSizeType, enabledState, hAlign)

            if self.fontColor then
                self.Text:SetTextColor(self.fontColor:GetRGB())
            end

            if widgetSizeSetting > 0 then
                self:SetWidth(widgetSizeSetting)
            else
                self:SetWidth(SafeNumber(self.Text:GetStringWidth(), 1))
            end

            local textHeight = SafeNumber(self.Text:GetStringHeight(), 0)
            local bottomPadding = SafeNumber(widgetInfo and widgetInfo.bottomPadding, 0)
            bottomPadding = _G.Clamp(bottomPadding, 0, _G.math.max(textHeight - 1, 0))
            self:SetHeight(textHeight + bottomPadding)
        end
    end


    ----====############################====----
    -- Blizzard_UIWidgetTemplateItemDisplay --
    ----====############################====----
    -- Mirrors Blizzard's local iconSizes / GetWidgetIconSize
    local widgetIconSizeLookup = {
        [_G.Enum.WidgetIconSizeType.Small]    = 24,
        [_G.Enum.WidgetIconSizeType.Medium]   = 30,
        [_G.Enum.WidgetIconSizeType.Large]    = 36,
        [_G.Enum.WidgetIconSizeType.Standard] = 28,
    }
    local function SafeGetWidgetIconSize(iconSizeType)
        return widgetIconSizeLookup[iconSizeType] or widgetIconSizeLookup[_G.Enum.WidgetIconSizeType.Small]
    end

    -- Mirrors Blizzard's local stackCountTextFontSizes / GetItemCountTextSizeFont
    local stackCountTextFontSizes = {
        [_G.Enum.WidgetIconSizeType.Small]    = "NumberFontNormalSmall",
        [_G.Enum.WidgetIconSizeType.Medium]   = "NumberFontNormal",
        [_G.Enum.WidgetIconSizeType.Large]    = "NumberFontNormal",
        [_G.Enum.WidgetIconSizeType.Standard] = "NumberFontNormalSmall",
    }
    local function SafeGetItemCountTextSizeFont(iconSizeType)
        return stackCountTextFontSizes[iconSizeType] or stackCountTextFontSizes[_G.Enum.WidgetIconSizeType.Small]
    end

    -- Mirrors Blizzard's local earnedCheckSizes / GetEarnedCheckSize
    local earnedCheckSizeLookup = {
        [_G.Enum.WidgetIconSizeType.Small]    = 12,
        [_G.Enum.WidgetIconSizeType.Medium]   = 15,
        [_G.Enum.WidgetIconSizeType.Large]    = 18,
        [_G.Enum.WidgetIconSizeType.Standard] = 14,
    }
    local function SafeGetEarnedCheckSize(iconSizeType)
        return earnedCheckSizeLookup[iconSizeType] or earnedCheckSizeLookup[_G.Enum.WidgetIconSizeType.Small]
    end

    -- Mirrors Blizzard's local helpers
    local function SafeIsOverrideStateActive(overrideState)
        return overrideState == _G.Enum.UIWidgetOverrideState.Active
    end
    local function SafeGetOverrideValueIfActive(overrideState, overrideValue)
        if SafeIsOverrideStateActive(overrideState) then
            return overrideValue
        end
        return nil
    end

    -- Replace UIWidgetBaseItemTemplateMixin.Setup to avoid taint: Aurora's font
    -- modifications cause GetWidth()/GetHeight() on ItemName/InfoText to return
    -- secret numbers, breaking arithmetic at Blizzard_UIWidgetTemplateBase.lua:1694.
    if _G.UIWidgetBaseItemTemplateMixin and _G.UIWidgetBaseItemTemplateMixin.Setup then
        _G.UIWidgetBaseItemTemplateMixin.Setup = function(self, widgetContainer, itemInfo, widgetSizeSetting, tooltipLoc)
            if _G.UIWidgetTemplateTooltipFrameMixin and _G.UIWidgetTemplateTooltipFrameMixin.Setup then
                _G.UIWidgetTemplateTooltipFrameMixin.Setup(self, widgetContainer, tooltipLoc)
            end

            self.itemID = itemInfo.itemID
            self.tooltipEnabled = itemInfo.tooltipEnabled
            local itemName, _, quality, _, _, _, _, _, _, itemTexture = _G.C_Item.GetItemInfo(self.itemID)
            self.quality = quality
            local iconSize = SafeGetWidgetIconSize(itemInfo.iconSizeType)

            self.Icon:SetSize(iconSize, iconSize)
            self.IconBorder:SetSize(iconSize, iconSize)
            self.IconOverlay:SetSize(iconSize, iconSize)
            self.IconOverlay2:SetSize(iconSize, iconSize)

            local earnedCheckSize = SafeGetEarnedCheckSize(itemInfo.iconSizeType)
            self.EarnedCheck:SetSize(earnedCheckSize, earnedCheckSize)
            self.EarnedCheck:SetShown(itemInfo.showAsEarned)

            self.Count:SetFontObject(SafeGetItemCountTextSizeFont(itemInfo.iconSizeType))

            self.Icon:SetTexture(itemTexture)
            _G.SetItemButtonCount(self, itemInfo.stackCount or 1)
            self:SetDisplayColor()

            local itemNameEnabledState = SafeGetOverrideValueIfActive(itemInfo.itemNameCustomColorOverrideState, itemInfo.itemNameCustomColor)
            local LEFT_ALIGN = _G.Enum.WidgetTextHorizontalAlignmentType.Left
            local widgetWidth, widgetHeight

            if itemInfo.textDisplayStyle == _G.Enum.ItemDisplayTextDisplayStyle.WorldQuestReward then
                self.ItemName:Hide()
                self.InfoText:Hide()
                self.NameFrame:Hide()

                self:ShowEmbeddedTooltip(self.itemID)

                widgetWidth = iconSize + SafeNumber(self.Tooltip:GetWidth(), 0) + 10
                widgetHeight = _G.math.max(iconSize, SafeNumber(self.Tooltip:GetHeight(), 0))

            elseif itemInfo.textDisplayStyle == _G.Enum.ItemDisplayTextDisplayStyle.PlayerChoiceReward then
                self:HideEmbeddedTooltip()
                self.InfoText:Hide()

                local minNameFrameWidth = 100
                local maxNameFrameWidth = 209

                widgetSizeSetting = SafeNumber(widgetSizeSetting, 0)
                local desiredNameFrameWidth = (widgetSizeSetting > 0) and (widgetSizeSetting - (iconSize + 2)) or maxNameFrameWidth
                local nameFrameWidth = _G.Clamp(desiredNameFrameWidth, minNameFrameWidth, maxNameFrameWidth)
                self.NameFrame:SetSize(nameFrameWidth, iconSize)
                self.NameFrame:Show()

                self.ItemName:ClearAllPoints()
                self.ItemName:SetPoint("TOPLEFT", self.NameFrame, "TOPLEFT", 4, -2)
                self.ItemName:SetPoint("BOTTOMRIGHT", self.NameFrame, "BOTTOMRIGHT", -4, 2)
                self.ItemName:Setup(itemInfo.overrideItemName or itemName, itemInfo.itemNameTextFontType, itemInfo.itemNameTextSizeType, itemNameEnabledState, LEFT_ALIGN)
                self.ItemName:Show()

                widgetWidth = iconSize + nameFrameWidth + 2
                widgetHeight = iconSize

            elseif itemInfo.textDisplayStyle == _G.Enum.ItemDisplayTextDisplayStyle.ItemNameOnlyCentered then
                self:HideEmbeddedTooltip()
                self.NameFrame:Hide()
                self.InfoText:Hide()

                widgetSizeSetting = SafeNumber(widgetSizeSetting, 0)
                local desiredItemNameWidth = (widgetSizeSetting > 0) and (widgetSizeSetting - (iconSize + 10)) or 0
                local itemNameWidth = _G.math.max(desiredItemNameWidth, 0)

                self.ItemName:ClearAllPoints()
                self.ItemName:SetPoint("TOPLEFT", self.Icon, "TOPRIGHT", 10, 0)
                self.ItemName:SetSize(itemNameWidth, iconSize)
                self.ItemName:Setup(itemInfo.overrideItemName or itemName, itemInfo.itemNameTextFontType, itemInfo.itemNameTextSizeType, itemNameEnabledState, LEFT_ALIGN)
                self.ItemName:Show()

                widgetWidth = iconSize + SafeNumber(self.ItemName:GetWidth(), 0) + 10
                widgetHeight = iconSize

            else
                self:HideEmbeddedTooltip()
                self.NameFrame:Hide()

                widgetSizeSetting = SafeNumber(widgetSizeSetting, 0)
                local desiredTextWidth = (widgetSizeSetting > 0) and (widgetSizeSetting - (iconSize + 10)) or 0
                local textWidth = _G.math.max(desiredTextWidth, 0)

                self.ItemName:ClearAllPoints()
                self.ItemName:SetPoint("TOPLEFT", self.Icon, "TOPRIGHT", 10, 0)
                self.ItemName:SetSize(textWidth, 0)
                self.ItemName:Setup(itemInfo.overrideItemName or itemName, itemInfo.itemNameTextFontType, itemInfo.itemNameTextSizeType, itemNameEnabledState, LEFT_ALIGN)
                self.ItemName:Show()

                if itemInfo.infoText then
                    self.InfoText:SetSize(textWidth, 0)
                    self.InfoText:Setup(itemInfo.infoText, itemInfo.infoTextFontType, itemInfo.infoTextSizeType, itemInfo.infoTextEnabledState, LEFT_ALIGN)
                    self.InfoText:Show()

                    widgetWidth = iconSize + SafeNumber(self.InfoText:GetWidth(), 0) + 10
                    widgetHeight = _G.math.max(iconSize, SafeNumber(self.ItemName:GetHeight(), 0) + SafeNumber(self.InfoText:GetHeight(), 0) + 2)
                else
                    self.InfoText:Hide()
                    widgetWidth = iconSize + SafeNumber(self.ItemName:GetWidth(), 0) + 10
                    widgetHeight = _G.math.max(iconSize, SafeNumber(self.ItemName:GetHeight(), 0))
                end
            end

            self:SetTooltip(itemInfo.overrideTooltip)
            self:SetWidth(widgetWidth)
            self:SetHeight(widgetHeight)

            _G.EventRegistry:RegisterCallback("ColorManager.OnColorDataUpdated", self.SetDisplayColor, self)
        end
    end


    -- Replace UIWidgetTemplateItemDisplayMixin.Setup to avoid taint: the
    -- ContinueOnLoad callback calls self.Item:GetWidth()/GetHeight() which
    -- return secret numbers because the item sub-frame inherits tainted font
    -- geometry.  Also wraps UIWidgetBaseTemplateMixin.Setup in pcall and
    -- MarkDirtyLayout in pcall to prevent propagation.
    if _G.UIWidgetTemplateItemDisplayMixin and _G.UIWidgetTemplateItemDisplayMixin.Setup then
        _G.UIWidgetTemplateItemDisplayMixin.Setup = function(self, widgetInfo, widgetContainer)
            if self.continuableContainer then
                self.continuableContainer:Cancel()
            end

            self.continuableContainer = _G.ContinuableContainer:Create()

            self:SetSize(1, 1)

            local item = _G.Item:CreateFromItemID(widgetInfo.itemInfo.itemID)
            self.continuableContainer:AddContinuable(item)

            self.continuableContainer:ContinueOnLoad(function()
                if _G.UIWidgetBaseTemplateMixin and _G.UIWidgetBaseTemplateMixin.Setup then
                    _G.pcall(_G.UIWidgetBaseTemplateMixin.Setup, self, widgetInfo, widgetContainer)
                end
                self.orderIndex = SafeNumber(self.orderIndex, 0)

                self.Item:Setup(widgetContainer, widgetInfo.itemInfo, widgetInfo.widgetSizeSetting, widgetInfo.tooltipLoc)

                local itemWidth = SafeNumber(self.Item:GetWidth(), 1)
                local itemHeight = SafeNumber(self.Item:GetHeight(), 1)
                self:SetWidth(itemWidth)
                self:SetHeight(itemHeight)

                _G.pcall(widgetContainer.MarkDirtyLayout, widgetContainer)
            end)
        end
    end

    ----====########################%%%########====----
    -- Blizzard_UIWidgetTemplateHorizontalCurrencies --
    ----====########################%%%########====----
    -- Mirrors Blizzard's local GetTextColorForEnabledState
    local function SafeGetTextColorForEnabledState(enabledState, overrideNormalFontColor)
        if enabledState == _G.Enum.WidgetEnabledState.Disabled then
            return _G.DISABLED_FONT_COLOR
        elseif enabledState == _G.Enum.WidgetEnabledState.Red then
            return _G.RED_FONT_COLOR
        elseif enabledState == _G.Enum.WidgetEnabledState.White then
            return _G.HIGHLIGHT_FONT_COLOR
        elseif enabledState == _G.Enum.WidgetEnabledState.Green then
            return _G.GREEN_FONT_COLOR
        elseif enabledState == _G.Enum.WidgetEnabledState.Artifact then
            return _G.ARTIFACT_GOLD_COLOR
        elseif enabledState == _G.Enum.WidgetEnabledState.Black then
            return _G.BLACK_FONT_COLOR
        elseif enabledState == _G.Enum.WidgetEnabledState.BrightBlue then
            return _G.BRIGHTBLUE_FONT_COLOR
        else
            return overrideNormalFontColor or _G.NORMAL_FONT_COLOR
        end
    end

    -- Mirrors Blizzard's local currencyIconSizes / GetCurrencyIconSize
    local currencyIconSizeLookup = {
        [_G.Enum.WidgetIconSizeType.Small]    = 16,
        [_G.Enum.WidgetIconSizeType.Medium]   = 20,
        [_G.Enum.WidgetIconSizeType.Large]    = 22,
        [_G.Enum.WidgetIconSizeType.Standard] = 18,
    }
    local function SafeGetCurrencyIconSize(iconSizeType)
        return currencyIconSizeLookup[iconSizeType] or currencyIconSizeLookup[_G.Enum.WidgetIconSizeType.Small]
    end

    -- Replace UIWidgetBaseCurrencyTemplateMixin.Setup to avoid taint: font objects
    -- modified by Aurora cause GetWidth()/GetHeight() to return secret numbers,
    -- breaking arithmetic in the original Blizzard code.
    if _G.UIWidgetBaseCurrencyTemplateMixin and _G.UIWidgetBaseCurrencyTemplateMixin.Setup then
        _G.UIWidgetBaseCurrencyTemplateMixin.Setup = function(self, widgetContainer, currencyInfo, enabledState, tooltipEnabledState, hideIcon, customFont, overrideFontColor, tooltipLoc)
            if _G.UIWidgetTemplateTooltipFrameMixin and _G.UIWidgetTemplateTooltipFrameMixin.Setup then
                _G.UIWidgetTemplateTooltipFrameMixin.Setup(self, widgetContainer, tooltipLoc)
            end
            self:SetOverrideNormalFontColor(overrideFontColor)

            local function SetUpFontString(fontstring, text)
                if customFont then
                    fontstring:SetText(text)
                    fontstring:SetFontObject(customFont)
                else
                    local hAlignType = _G.Enum.WidgetTextHorizontalAlignmentType.Left
                    fontstring:Setup(text, currencyInfo.textFontType, currencyInfo.textSizeType, enabledState, hAlignType)
                end
            end

            _G.WidgetUtil.UpdateTextWithAnimation(self, _G.GenerateClosure(SetUpFontString, self.Text), currencyInfo.updateAnimType, currencyInfo.text)

            local tooltip = currencyInfo.tooltip
            if IsSecret(tooltip) then tooltip = "" end
            self:SetTooltip(tooltip, SafeGetTextColorForEnabledState(tooltipEnabledState or enabledState))

            self.Icon:SetTexture(currencyInfo.iconFileID)
            self.Icon:SetDesaturated(enabledState == _G.Enum.WidgetEnabledState.Disabled)

            local iconSize = SafeGetCurrencyIconSize(currencyInfo.iconSizeType)
            self.Icon:SetSize(iconSize, iconSize)

            self:SetEnabledState(enabledState)

            local totalWidth = SafeNumber(self.Text:GetWidth(), 0)
            local widgetHeight = SafeNumber(self.Text:GetHeight(), 0)

            if currencyInfo.leadingText ~= "" then
                SetUpFontString(self.LeadingText, currencyInfo.leadingText)

                self.LeadingText:Show()
                self.Icon:SetPoint("LEFT", self.LeadingText, "RIGHT", 5, 0)
                totalWidth = totalWidth + SafeNumber(self.LeadingText:GetWidth(), 0) + 5
                widgetHeight = _G.math.max(widgetHeight, SafeNumber(self.LeadingText:GetHeight(), 0))
            else
                self.LeadingText:Hide()
                self.Icon:SetPoint("LEFT", self, "LEFT", 0, 0)
            end

            if hideIcon then
                self.Icon:Hide()
                self.Text:SetPoint("LEFT", self.Icon, "LEFT", 0, 0)
            else
                self.Icon:Show()
                self.Text:SetPoint("LEFT", self.Icon, "RIGHT", 5, 0)
                totalWidth = totalWidth + SafeNumber(self.Icon:GetWidth(), 0) + 5
            end

            self:SetWidth(totalWidth)
            self:SetHeight(widgetHeight)
        end
    end

    -- Replace UIWidgetTemplateHorizontalCurrenciesMixin.Setup to avoid taint:
    -- currency frame dimensions (set by the replaced Setup above) return secret
    -- numbers, breaking comparisons and arithmetic in the original Blizzard code.
    if _G.UIWidgetTemplateHorizontalCurrenciesMixin and _G.UIWidgetTemplateHorizontalCurrenciesMixin.Setup then
        _G.UIWidgetTemplateHorizontalCurrenciesMixin.Setup = function(self, widgetInfo, widgetContainer)
            if _G.UIWidgetBaseTemplateMixin and _G.UIWidgetBaseTemplateMixin.Setup then
                _G.UIWidgetBaseTemplateMixin.Setup(self, widgetInfo, widgetContainer)
            end
            self.orderIndex = SafeNumber(self.orderIndex, 0)
            self.currencyPool:ReleaseAll()

            local previousCurrencyFrame
            local biggestHeight = 0
            local totalWidth = 0

            for _, currencyInfo in _G.ipairs(widgetInfo.currencies) do
                local currencyFrame = self.currencyPool:Acquire()
                currencyFrame:Show()

                local tooltipEnabledState = currencyInfo.isCurrencyMaxed and _G.Enum.WidgetEnabledState.Red or _G.Enum.WidgetEnabledState.White

                currencyFrame:Setup(widgetContainer, currencyInfo, _G.Enum.WidgetEnabledState.Yellow, tooltipEnabledState, nil, nil, nil, widgetInfo.tooltipLoc)

                if previousCurrencyFrame then
                    currencyFrame:SetPoint("TOPLEFT", previousCurrencyFrame, "TOPRIGHT", 10, 0)
                    totalWidth = totalWidth + SafeNumber(currencyFrame:GetWidth(), 0) + 10
                else
                    currencyFrame:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
                    totalWidth = SafeNumber(currencyFrame:GetWidth(), 0)
                end

                currencyFrame:SetOverrideNormalFontColor(self.fontColor)

                previousCurrencyFrame = currencyFrame

                local currencyHeight = SafeNumber(currencyFrame:GetHeight(), 0)
                if currencyHeight > biggestHeight then
                    biggestHeight = currencyHeight
                end
            end

            local widgetSizeSetting = SafeNumber(widgetInfo.widgetSizeSetting, 0)
            local useSizeSetting = widgetSizeSetting > totalWidth

            local width = useSizeSetting and (totalWidth + ((widgetSizeSetting - totalWidth) / 2)) or totalWidth
            self:SetWidth(width)
            self:SetHeight(biggestHeight)
        end
    end

    ----====#############################====----
    -- Blizzard_UIWidgetTemplateBulletTextList --
    ----====#############################====----


    ----====####################################################====----
    -- Blizzard_UIWidgetTemplateScenarioHeaderCurrenciesAndBackground --
    ----====####################################################====----


    ----====#############################====----
    -- Blizzard_UIWidgetTemplateTextureAndText --
    ----====#############################====----


    ----====################%%%########====----
    -- Blizzard_UIWidgetTemplateSpellDisplay --
    ----====################%%%########====----


    ----====#################################====----
    -- Blizzard_UIWidgetTemplateDoubleStateIconRow --
    ----====#################################====----


    ----====################################====----
    -- Blizzard_UIWidgetTemplateTextureAndTextRow --
    ----====################################====----


    ----====################%%########====----
    -- Blizzard_UIWidgetTemplateZoneControl --
    ----====################%%########====----


    ----====################%%########====----
    -- Blizzard_UIWidgetTemplateCaptureZone --
    ----====################%%########====----


    --====#####################====----
    -- Blizzard_UIWidgetTopCenterFrame --
    ----====#####################====----
    Util.Mixin(_G.UIWidgetTopCenterContainerFrame, Hook.UIWidgetContainerMixin)

    ----====########################====----
    -- Blizzard_UIWidgetBelowMinimapFrame --
    ----====########################====----
    local BelowMinimapFrame = _G.UIWidgetBelowMinimapContainerFrame
    DebugBelowMinimap("Setup hooks", SafeDebugName(BelowMinimapFrame))
    Skin.UIWidgetBelowMinimapContainerFrame(BelowMinimapFrame)
    Util.Mixin(BelowMinimapFrame, Hook.UIWidgetContainerMixin, Hook.UIWidgetBelowMinimapContainerMixin)
    BootstrapWidgetContainer(BelowMinimapFrame)
    ----====####################====----
    -- Blizzard_UIWidgetPowerBarFrame --
    ----====####################====----

end
