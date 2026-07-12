local ADDON_NAME, private = ...

-- luacheck: globals select tostring tonumber math floor
-- luacheck: globals setmetatable rawset debugprofilestop type tinsert

private.API_MAJOR, private.API_MINOR = 12, 0

private.isRetail = _G.WOW_PROJECT_ID == _G.WOW_PROJECT_MAINLINE
private.isVanilla = _G.WOW_PROJECT_ID == _G.WOW_PROJECT_CLASSIC
private.isBCC = _G.WOW_PROJECT_ID == _G.WOW_PROJECT_BURNING_CRUSADE_CLASSIC
private.isWrath = _G.WOW_PROJECT_ID == (_G.WOW_PROJECT_WRATH_CLASSIC or 11)
private.isCata = _G.WOW_PROJECT_ID == (_G.WOW_PROJECT_CATACLYSM_CLASSIC or 14)
private.isMists = _G.WOW_PROJECT_ID == (_G.WOW_PROJECT_MISTS_CLASSIC or 19)

private.isClassic = not private.isRetail
private.isMidnight = private.isRetail and select(4, _G.GetBuildInfo()) >= 120000
private.isBetaBuild = private.isRetail and select(4, _G.GetBuildInfo()) >= 130000


local debugProjectID = {
    [0] = private.isRetail,
    [10] = private.isVanilla,
    [20] = private.isBCC,
    [30] = private.isWrath,
    [40] = private.isCata,
    [50] = private.isMists,
}
function private.shouldSkip()
    return not debugProjectID[_G.AURORA_DEBUG_PROJECT]
end

private.uiScale = 1
private.disabled = {
    bags = false,
    banks = false,
    chat = false,
    fonts = false,
    tooltips = false,
    mainmenubar = false,
    pixelScale = true
}
private.textures = {
    plain = [[Interface\Buttons\WHITE8x8]],
}

local pixelScale, uiScaleChanging = false, false
function private.UpdateUIScale()
    -- When a host addon (e.g. RealUI_Skins) replaces this function,
    -- this original version should never run. Guard just in case.
    if private.scaleReported then return end
    if uiScaleChanging then return end
    local _, pysHeight = _G.GetPhysicalScreenSize()

    if not private.disabled.pixelScale then
        -- Standalone Aurora: apply pixel-perfect scale once at login
        pixelScale = 768 / pysHeight
        local parentScale = floor(_G.UIParent:GetScale() * 100 + 0.5) / 100
        private.debug("scale", pixelScale, parentScale)
        uiScaleChanging = true
        if parentScale ~= pixelScale then
            private.debug("Setting UIParent:SetScale to", pixelScale)
            _G.UIParent:SetScale(pixelScale)
        end
        uiScaleChanging = false
    end
end


local classLocale, classToken, classID = _G.UnitClass("player")
private.charClass = {
    locale = classLocale,
    token = classToken,
    id = classID,
}

do -- private.font
    local fontPath = [[Interface\AddOns\Aurora\media\font.ttf]]
    if _G.LOCALE_koKR then
        fontPath = [[Fonts/2002.ttf]]
    elseif _G.LOCALE_zhCN then
        fontPath = [[Fonts/ARKai_T.ttf]]
    elseif _G.LOCALE_zhTW then
        fontPath = [[Fonts/blei00d.ttf]]
    end

    private.font = {
        normal = fontPath,
        chat = fontPath,
        crit = fontPath,
        header = fontPath,
    }
end

function private.nop() end
local debug do
    if not private.debug then
        local LTD = _G.LibStub("LibTextDump-1.0", true)
        if LTD then
            local debugger
            function debug(...)
                if not debugger then
                    if LTD then
                        debugger = LTD:New(ADDON_NAME .." Debug Output", 640, 480)
                        private.debugger = debugger
                    else
                        return
                    end
                end
                local time = _G.date("%H:%M:%S")
                local text = ("[%s]"):format(time)
                for i = 1, select("#", ...) do
                    local arg = select(i, ...)
                    text = text .. "     " .. tostring(arg)
                end
                -- Use pcall to safely handle tainted/secret strings
                local success, err = pcall(debugger.AddLine, debugger, text)
                if not success and not err:match("secret string") then
                    -- Only report non-taint related errors
                    _G.print("Aurora debug error:", err)
                end
            end
        else
            debug = private.nop
        end
        private.debug = debug
    end
end

local Aurora = {
    Base = {},
    Scale = {},
    Hook = {},
    Skin = {},
    Color = {},
    Util = {},
}
private.Aurora = Aurora
_G.Aurora = Aurora

do -- set up file order
    private.fileOrder = {}
    local mt = {
        __newindex = function(t, k, v)
            tinsert(private.fileOrder, {list = t, name = k})
            rawset(t, k, v)
        end
    }

    private.AddOns = {} --  setmetatable({}, mt) --
    private.FrameXML = setmetatable({}, mt)
    private.SharedXML = setmetatable({}, mt)
end


-- GC Tuning System
-- Provides three modes for Lua's garbage collector:
--   "smooth"  — aggressive incremental: smaller, more frequent GC passes (setpause 110)
--   "default" — Lua defaults: let the engine handle it (setpause 200, setstepmul 200)
--   "combat"  — pause GC during combat, restart after (zero in-combat GC stutter)
--
-- Applied early with "smooth" as default; re-applied from AuroraConfig in ADDON_LOADED.
local GC_MODES = {
    smooth  = function()
        _G.collectgarbage("restart")
        _G.collectgarbage("setpause", 110)
        _G.collectgarbage("setstepmul", 200)
    end,
    default = function()
        _G.collectgarbage("restart")
        _G.collectgarbage("setpause", 200)
        _G.collectgarbage("setstepmul", 200)
    end,
    combat  = function()
        -- Start with smooth tuning; combat events toggle stop/restart
        _G.collectgarbage("restart")
        _G.collectgarbage("setpause", 110)
        _G.collectgarbage("setstepmul", 200)
    end,
}

local activeGCMode = "smooth"
local combatFrame -- created lazily for "combat" mode

local function ApplyGCMode(mode)
    if not GC_MODES[mode] then mode = "smooth" end

    -- Tear down combat frame if switching away from combat mode
    if activeGCMode == "combat" and combatFrame then
        combatFrame:UnregisterAllEvents()
    end

    activeGCMode = mode
    GC_MODES[mode]()

    -- Set up combat frame if entering combat mode
    if mode == "combat" then
        if not combatFrame then
            combatFrame = _G.CreateFrame("Frame")
            combatFrame:SetScript("OnEvent", function(_, event)
                if event == "PLAYER_REGEN_DISABLED" then
                    _G.collectgarbage("stop")
                else
                    _G.collectgarbage("restart")
                    _G.collectgarbage("setpause", 110)
                    _G.collectgarbage("setstepmul", 200)
                end
            end)
        end
        combatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
        combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    end
end

-- Expose so RealUI_Config can change the mode live via _G.Aurora
function private.ApplyGCMode(mode)
    ApplyGCMode(mode)
end
function private.GetGCMode()
    return activeGCMode
end
-- Also expose on the global Aurora table for cross-addon access
Aurora.ApplyGCMode = function(mode)
    ApplyGCMode(mode)
end
Aurora.GetGCMode = function()
    return activeGCMode
end

-- Apply default mode immediately at file load (before SavedVariables are available)
ApplyGCMode("smooth")

local eventFrame = _G.CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("UI_SCALE_CHANGED")

local appliedAddOnSkins = {}

local function IsAddOnFullyLoaded(addOnName)
    local loadedOrLoading, loaded = _G.C_AddOns.IsAddOnLoaded(addOnName)
    if loaded ~= nil then
        return loaded
    end
    return loadedOrLoading
end

local function SafeApplyAddOnSkin(addOnName, addOnModule)
    if appliedAddOnSkins[addOnName] then
        return
    end
    if _G.type(addOnModule) ~= "function" then
        return
    end

    local ok, err = _G.pcall(addOnModule)
    if ok then
        appliedAddOnSkins[addOnName] = true
    else
        private.debug("skin", "addOn module failed", addOnName, err)
    end
end

local function ApplyLoadedAddOnSkins()
    for addOnName, addOnModule in _G.next, private.AddOns do
        if IsAddOnFullyLoaded(addOnName) then
            SafeApplyAddOnSkin(addOnName, addOnModule)
        end
    end
end

eventFrame:SetScript("OnEvent", function(dialog, event, addonName)
    if event == "UI_SCALE_CHANGED" then
        -- Defer to a new execution context so that SetCVar("uiScale") taint
        -- does not propagate through Blizzard event handlers, which would cause
        -- ADDON_ACTION_BLOCKED for protected functions like SetPassThroughButtons
        -- when opening the WorldMap.
        _G.C_Timer.After(0, function()
            private.UpdateUIScale()
        end)
    else
        if addonName == ADDON_NAME then
            local phyScreenWidth, phyScreenHeight = _G.GetPhysicalScreenSize()
            _G.print(("%s v%s loaded."):format(ADDON_NAME, private.API_MAJOR + private.API_MINOR / 100))
            _G.print(("Blizzard World of Warcraft - %s (%s)"):format(select(1, _G.GetBuildInfo()),select(2, _G.GetBuildInfo())))
            -- Setup function for the host addon
            private.OnLoad()
            -- Defer scale-related reads and CVar writes to a new execution
            -- context so addon code does not contaminate the ADDON_LOADED
            -- processing chain. Reading UIParent:GetScale() or calling
            -- SetCVar during ADDON_LOADED can propagate taint to
            -- C_ActionBar / UIParentPanelManager, which causes
            -- ADDON_ACTION_BLOCKED errors for protected functions like
            -- MultiBar:ShowBase() and SetPassThroughButtons.
            _G.C_Timer.After(0, function()
                private.UpdateUIScale()
                if not private.scaleReported then
                    -- Standalone Aurora: just report the raw engine scale.
                    -- When a host addon (e.g. RealUI_Skins) is active, it sets
                    -- private.scaleReported = true to suppress this message.
                    -- In dev mode Aurora may load as a separate addon; check the
                    -- global flag set by the host addon's UpdateUIScale.
                    if not _G.AURORA_SCALE_REPORTED then
                        _G.print(("Running on %sx%s - UI Scale: %.2f"):format(phyScreenWidth, phyScreenHeight, _G.UIParent:GetScale()))
                    end
                end
                if (tonumber(_G.GetCVar("questTextContrast")) ~= 4) then
                    _G.SetCVar("questTextContrast", 4)
                end
            end)

            if _G.AuroraConfig then
                Aurora[2].buttonsHaveGradient = _G.AuroraConfig.buttonsHaveGradient
                -- Apply user's chosen GC mode from saved variables
                if _G.AuroraConfig.gcMode then
                    ApplyGCMode(_G.AuroraConfig.gcMode)
                end
            end

            for i = 1, #private.fileOrder do
                local file = private.fileOrder[i]
                local ok, err = _G.pcall(file.list[file.name])
                if not ok then
                    private.debug("skin", "file module failed", file.name, err)
                end
            end

            -- Skin prior loaded AddOns and run short delayed catch-up passes to
            -- recover from missed/reordered load signaling in the client.
            ApplyLoadedAddOnSkins()
            _G.C_Timer.After(0, ApplyLoadedAddOnSkins)
            _G.C_Timer.After(2, ApplyLoadedAddOnSkins)
            _G.C_Timer.After(8, ApplyLoadedAddOnSkins)

            private.isLoaded = true
        else
            local addOnModule = private.AddOns[addonName]
            if addOnModule then
                SafeApplyAddOnSkin(addonName, addOnModule)
            end
        end

        -- Load deprected themes
        local addonModule = Aurora[2].themes[addonName]
        if addonModule then
            if _G.type(addonModule) == "function" then
                addonModule()
            else
                for _, moduleFunc in _G.next, addonModule do
                    moduleFunc()
                end
            end
        end
    end
end)
