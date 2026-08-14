local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Hook = Aurora.Hook

do --[[ FrameXML\CompactUnitFrame.lua ]]
    function Hook.CompactUnitFrame_UpdateHealthColor(frame)
        if frame:IsForbidden() then return end
        -- Nameplate bars live in the restricted nameplate system; calling
        -- SetStatusBarColor here taints the execution context and causes
        -- GetMinMaxValues() in UpdateHealPrediction to return "secret number value".
        local unit = frame.unit
        if not unit or _G.issecretvalue(unit) then return end
        if unit:find("^nameplate") then return end

        -- WoW 12 combat: unit info APIs return secret values to tainted hooks
        -- (string ops, truth tests, and table indexing all throw). When any
        -- input is secret, bail — the bar keeps Blizzard's own secure class
        -- color; only the custom palette tint is skipped for that update.
        local connected = _G.UnitIsConnected(unit)
        if _G.issecretvalue(connected) or not connected then return end

        local opts = frame.optionTable
        if not opts.healthBarColorOverride then
            local _, classToken = _G.UnitClass(unit)
            if not classToken or _G.issecretvalue(classToken) then return end
            local classColor = _G.CUSTOM_CLASS_COLORS[classToken]

            local isPlayer = _G.UnitIsPlayer(unit)
            if _G.issecretvalue(isPlayer) then isPlayer = false end
            local treatAsPlayer = _G.UnitTreatAsPlayerForDisplay(unit)
            if _G.issecretvalue(treatAsPlayer) then treatAsPlayer = false end

            if (opts.allowClassColorsForNPCs or isPlayer or treatAsPlayer) and classColor and opts.useClassColors then
                frame.healthBar:SetStatusBarColor(classColor.r, classColor.g, classColor.b)
                if opts.colorHealthWithExtendedColors then
                    frame.selectionHighlight:SetVertexColor(classColor.r, classColor.g, classColor.b)
                end
            end
        end
    end
end

--do --[[ FrameXML\CompactUnitFrame.xml ]]
--end

function private.FrameXML.CompactUnitFrame()
    _G.hooksecurefunc("CompactUnitFrame_UpdateHealthColor", Hook.CompactUnitFrame_UpdateHealthColor)
end
