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
