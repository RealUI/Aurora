local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

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
    function Skin.SharedTooltipTemplate(GameTooltip)
        if GameTooltip.debug then
            GameTooltip.NineSlice.debug = GameTooltip.debug
        end
        Skin.NineSlicePanelTemplate(GameTooltip.NineSlice)
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

    local setTooltipMoneyPatched = false
    local setTooltipMoneyPatchFrame

    -- Shared helper: coerce secret/tainted numbers to safe fallbacks so
    -- arithmetic in Blizzard code doesn't error on addon-tainted values.
    local function SafeNumber(value, fallback)
        if type(value) ~= "number" then return fallback end
        if _G.issecretvalue and _G.issecretvalue(value) then return fallback end
        return value
    end

    -- NOTE: Do NOT replace _G.GetUnscaledFrameRect here.
    -- Overwriting that global with an addon-owned function taints it,
    -- which propagates through layout paths into the GameMenu secure
    -- execution and causes ADDON_ACTION_FORBIDDEN on Logout/Quit.

    -- Replace GameTooltip_InsertFrame to avoid taint: Aurora's font
    -- modifications cause GetLineHeight() and GetHeight() to return secret
    -- numbers, breaking Round() arithmetic at SharedTooltipTemplates.lua:202.
    -- securecallfunction does NOT help — secret values error on ANY
    -- arithmetic regardless of context.  Use SafeNumber for all tooltips.
    --
    -- COST OF OWNING THIS GLOBAL: an addon-written global is tainted for every
    -- secure reader.  Blizzard_ItemUpgradeUI.lua:867 reads it inside
    -- PlayUpgradedCelebration(), one line before C_ItemUpgrade.UpgradeItem(),
    -- so the upgrade is blocked whenever an item's effect text is tall enough
    -- to hit the truncation branch.
    --
    -- The replacement differs from Blizzard's original in TWO ways:
    --   1. SafeNumber() around the two Round() inputs (the documented reason)
    --   2. a nil-guard on GetLeftLine(2) — Blizzard indexes it unconditionally
    --      and errors on any tooltip with fewer than two lines (undocumented,
    --      and the likelier reason this was ever needed; cf. LootHistory)
    --
    -- /aurora insertframe flips devRestoreInsertFrame to run Blizzard's
    -- original, so the surfaces at risk (LootHistory "all passed", Professions
    -- reagent/reward, delve widget sets, Garrison mission threats, quest-offer
    -- map pins, trinket item upgrades) can be exercised to find out which of
    -- those two differences is actually load-bearing.
    local restoreOriginal = _G.AuroraConfig and _G.AuroraConfig.devRestoreInsertFrame
    if restoreOriginal then
        _G.print("|cffffcc00Aurora:|r GameTooltip_InsertFrame replacement DISABLED (/aurora insertframe).")
    end

    if _G.GameTooltip_InsertFrame and not restoreOriginal then
        _G.GameTooltip_InsertFrame = function(tooltipFrame, frame, verticalPadding)
            verticalPadding = verticalPadding or 0

            local textSpacing = tooltipFrame:GetCustomLineSpacing() or 2
            local leftLine2 = tooltipFrame:GetLeftLine(2)
            local rawLineHeight = leftLine2 and leftLine2:GetLineHeight() or 12
            local textHeight = _G.Round(SafeNumber(rawLineHeight, 12))
            local rawFrameHeight = frame:GetHeight()
            local neededHeight = _G.Round(SafeNumber(rawFrameHeight, 0) + verticalPadding)
            local numLinesNeeded = _G.math.ceil(neededHeight / (textHeight + textSpacing))
            local currentLine = tooltipFrame:NumLines()
            _G.GameTooltip_AddBlankLinesToTooltip(tooltipFrame, numLinesNeeded)
            frame:SetParent(tooltipFrame)
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT", tooltipFrame:GetLeftLine(currentLine + 1), "TOPLEFT", 0, -verticalPadding)
            if not tooltipFrame.insertedFrames then
                tooltipFrame.insertedFrames = {}
            end
            local frameWidth = SafeNumber(frame:GetWidth(), 0)
            if tooltipFrame:GetMinimumWidth() < frameWidth then
                tooltipFrame:SetMinimumWidth(frameWidth)
            end
            frame:Show()
            _G.tinsert(tooltipFrame.insertedFrames, frame)
            return (numLinesNeeded * textHeight) + (numLinesNeeded - 1) * textSpacing
        end
    end

    -- NOTE: Do NOT wrap GameTooltip_AddWidgetSet here.
    -- Replacing the global with an addon-owned function taints the execution
    -- before RegisterForWidgetSet is called, causing GetUnscaledFrameRect to
    -- receive secret values from frame:GetScaledRect() and error on arithmetic.
    -- The GameTooltip_InsertFrame replacement above is picked up via global
    -- lookup by Blizzard's original GameTooltip_AddWidgetSet regardless of
    -- execution context — securecallfunction shares the same _G as all code.

    -- Replace SetTooltipMoney to avoid taint: Aurora's GameTooltip
    -- skinning marks the tooltip hierarchy as addon-modified, causing
    -- GetTextWidth() on MoneyFrame buttons to return secret numbers.
    -- MoneyFrame_Update then does arithmetic on these secret values and
    -- errors with "attempt to perform arithmetic on a secret number
    -- value (tainted by 'RealUI_Skins')".
    -- WoWUIBugs #801 — acknowledged by Blizzard, tracked internally.
    -- Workaround: render tooltip money as an inline coin-textured string
    -- via GetCoinTextureString, bypassing MoneyFrame_Update entirely.
    local function InstallSetTooltipMoneyWorkaround()
        if setTooltipMoneyPatched then
            return true
        end
        if not _G.SetTooltipMoney then
            return false
        end

        local origClearMoney = _G.GameTooltip_ClearMoney

        _G.SetTooltipMoney = function(frame, money, type, prefixText, suffixText)
            -- Hide any previously shown money frames (from before this
            -- replacement took effect or from a prior tooltip cycle).
            if origClearMoney and frame.shownMoneyFrames then
                origClearMoney(frame)
            end

            local coinText = _G.C_CurrencyInfo.GetCoinTextureString(money)
            if coinText then
                local line = ""
                if prefixText and prefixText ~= "" then
                    line = prefixText .. " "
                end
                line = line .. coinText
                if suffixText and suffixText ~= "" then
                    line = line .. " " .. suffixText
                end
                _G.GameTooltip_AddBlankLinesToTooltip(frame, 1)
                frame:AddLine(line, 1, 1, 1)
            end
            frame.hasMoney = 1
        end

        setTooltipMoneyPatched = true
        return true
    end

    if not InstallSetTooltipMoneyWorkaround() then
        setTooltipMoneyPatchFrame = _G.CreateFrame("Frame")
        setTooltipMoneyPatchFrame:RegisterEvent("ADDON_LOADED")
        setTooltipMoneyPatchFrame:SetScript("OnEvent", function(self, _, addonName)
            if addonName ~= "Blizzard_MoneyFrame" then
                return
            end

            if InstallSetTooltipMoneyWorkaround() then
                self:UnregisterAllEvents()
                self:SetScript("OnEvent", nil)
            end
        end)
    end
end
