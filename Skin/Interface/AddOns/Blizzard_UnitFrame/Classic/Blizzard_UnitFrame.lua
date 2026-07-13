local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Hook = Aurora.Hook

--[[ Classic-family unit frames (era/TBC/Mists; retail resolves Mainline/).
    Scope matches retail Aurora deliberately: NO reskin of the player/target
    frame art — only the CompactUnitFrame (raid frame) health-bar recolor so
    bars use Aurora's CUSTOM_CLASS_COLORS. Evidence: wow-ui-source-*/
    Interface/AddOns/Blizzard_UnitFrame/Classic/CompactUnitFrame.lua L393
    (no UnitTreatAsPlayerForDisplay on classic).
]]

do --[[ Classic\CompactUnitFrame.lua ]]
    function Hook.CompactUnitFrame_UpdateHealthColor(frame)
        if frame:IsForbidden() then return end
        -- Nameplate bars live in the restricted nameplate system; recoloring
        -- them from here taints the execution context.
        if frame.unit and frame.unit:find("^nameplate") then return end

        if _G.UnitIsConnected(frame.unit) then
            local opts = frame.optionTable
            if opts and not opts.healthBarColorOverride then
                local _, classToken = _G.UnitClass(frame.unit)
                local classColor = classToken and _G.CUSTOM_CLASS_COLORS[classToken]
                if (opts.allowClassColorsForNPCs or _G.UnitIsPlayer(frame.unit)) and classColor and opts.useClassColors then
                    frame.healthBar:SetStatusBarColor(classColor.r, classColor.g, classColor.b)
                    if opts.colorHealthWithExtendedColors and frame.selectionHighlight then
                        frame.selectionHighlight:SetVertexColor(classColor.r, classColor.g, classColor.b)
                    end
                end
            end
        end
    end
end

function private.FrameXML.CompactUnitFrame()
    _G.hooksecurefunc("CompactUnitFrame_UpdateHealthColor", Hook.CompactUnitFrame_UpdateHealthColor)
end
