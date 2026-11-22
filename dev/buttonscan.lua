local addonName, private = ...

--[[ buttonscan.lua - aurora-taint-pass (B261), phase 1 (tasks 1.1, 1.4, 1.5).

     Usage: <cmd>                 summary: counts, keys in three groups, PASS/FAIL
            <cmd> full            one line per addon-owned field
            <cmd> protected       buttons with addon-owned keys that are protected
                                  or sit under a protected ancestor (UIParent
                                  itself is not counted)
            <cmd> <FrameName>     summary for that frame and its descendants only
            <cmd> spike           spike S1 (task 1.6), one step per call: arm the
                                  control, install the clean hook, report
            <cmd> spikehover      the same on the scroll bar under the mouse
            <cmd> spikecall       S1's positive control, run last: makes Blizzard's
                                  update call addon code after the hooked call
            <cmd> spikedirty      S1's field-read check (optional, not in the verdict)

     <cmd> is "/realdev buttonscan" under RealUI_Dev (retail, Forever) and
     "/aurora buttonscan" under standalone Aurora (every flavour). Until task 1.3
     lands, /aurora passes no argument: only the plain command and the two
     aliases registered at the bottom of this file work there (the spike words
     are /realdev only until then).

     Walks every Button-type frame (CheckButton and ItemButton included) and
     reports every string key that issecurevariable attributes to an addon,
     plus the keys of plain tables hanging off the button (two levels, only
     into tables Blizzard put there), on Blizzard's buttons only.

     Who made a button (see Owner below): its GetSourceLocation(), the file
     and line that created it. A Blizzard file made it and no ancestor was
     made by an addon: Blizzard's, scanned. An addon file made it: addon-owned,
     counted only. A Blizzard file made it but an ancestor was made by an
     addon (a template child or pooled element inside an addon's frame):
     counted on its own, with examples. Where the location is missing or
     unreadable, the old test decides: Blizzard's with at least one secure key
     or a secure global name, else "addon-owned or unknown".

     The scan is strictly read only: every probe is pcall'd, forbidden frames
     are skipped, and nothing is written to any frame. The only frame it
     creates is its own LibTextDump output window, when that library is
     installed. The spike words are the exception, and only when asked for:
     they create one small frame with one texture of their own and hook
     SetEnabled on one Blizzard scroll bar stepper until /reload; the two
     steps after that each taint that one scroll bar on purpose (see "Spike
     S1" below).

     Loaded twice over: by Aurora.toc (do-not-package block) and by
     RealUI_Dev.toc. Each load gets its own private table, so this file never
     assumes Aurora's (see dev/test.lua). ]]

local commands = private.commands
-- private.commands is created in gui.lua (Aurora) or RealUI_Dev.lua; without
-- it there is nothing to register into.
if not commands then return end

local underAurora = private.Aurora ~= nil
local COMMAND = underAurora and "/aurora buttonscan" or "/realdev buttonscan"
local USAGE = ("Usage: %s [full | protected | spike | <FrameName>]"):format(COMMAND)

local MAX_TABLE_DEPTH = 2    -- plain tables on a button: button.key.key
local MAX_FRAME_DEPTH = 40   -- <FrameName> walk: descendants below the root
local CHAT_LIMIT = 200       -- chat fallback (no LibTextDump): lines printed at most
local PROTECTED_KEYS = 4     -- protected list: key names shown per button
local INSIDE_EXAMPLES = 5    -- Blizzard-made buttons inside addon frames: paths shown

--[[ Aurora's keys, from design.md "Planted-field inventory". Under RealUI the
     client names RealUI_Skins as owner of these and of RealUI's own keys alike,
     so the groups are told apart by name. Category = the phase that removes it:
       skin      button skin state (Requirement 1.1 and task 2.6): Layer 1
       hook      instance hooks (expected to read secure): Layer 2
       backdrop  backdrop methods, backdropInfo, nine-slice pieces: Layer 2
       leftover  named leftovers and hook-once flags: phase 5
       deferred  icon borders, tab sizing, palette bookkeeping, and any other
                 _aurora* key: not in this pass ]]
local AURORA_KEYS = {}
local function AddKeys(category, keys)
    for _, key in ipairs(keys) do
        AURORA_KEYS[key] = category
    end
end
AddKeys("skin", {
    "SetButtonColor", "GetButtonColor", "_enabledColor", "_disabledColor", "_isMinimal",
    "_auroraTextures", "_returnColor", "_onEnter", "_onLeave", "_isHighlighted",
    "_isHighlightLocked", "isEnabled", "isDisabled",
    "_plus", "_minus", "settingHighlight", "_auroraThumb", "__SetStatusBarTexture",
})
AddKeys("hook", { "Enable", "Disable", "SetEnabled", "LockHighlight", "UnlockHighlight" })
AddKeys("backdrop", {
    -- Blizzard's BackdropTemplateMixin (15), copied onto the button by Base.CreateBackdrop
    "OnBackdropLoaded", "OnBackdropSizeChanged", "GetEdgeSize", "SetupTextureCoordinates",
    "SetupPieceVisuals", "SetBorderBlendMode", "HasBackdropInfo", "ClearBackdrop", "ApplyBackdrop",
    "SetBackdrop", "GetBackdrop", "GetBackdropColor", "SetBackdropColor", "GetBackdropBorderColor",
    "SetBackdropBorderColor",
    -- Aurora's own (7)
    "SetBackdropGradient", "SetBackdropLayer", "GetBackdropLayer", "GetBackdropTexture",
    "SetBackdropOption", "GetBackdropOption", "SetBackdropOptions",
    "_backdropInfo", "backdropInfo",
    -- nine-slice pieces (Blizzard_SharedXML/NineSlice.lua)
    "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner",
    "TopEdge", "BottomEdge", "LeftEdge", "RightEdge", "Center",
})
AddKeys("leftover", {
    "_auroraIconBG", "_auroraHeaderHooked",
    "_skinnedIcons", "_skinnedAffixes", "_auroraResetPortrait", "_auroraGameMenuHooked",
    "__auroraStyled", "_auroraAlphaHooked", "_auroraTextColorHooked", "_auroraHeaderSkinned",
    "_auroraOrderTabSkinned", "_auroraResizeRetried", "_auroraNumSkinned", "_auroraIconCropHooked",
    "_auroraRowsHooked", "_auroraEmptySlotHooked", "_auroraItemSlotsHooked", "_auroraHideLocked",
    "_auroraSkinnedQuestMapTab",
})
AddKeys("deferred", {
    "_auroraIconBorder", "_auroraBackground", "_auroraNameBG", "_auroraBG", "_auroraLvlBG",
    "_auroraPortraitBG", "_auroraBorder", "_questTexture",
    "_auroraTabResize", "_auroraWidth", "_auroraSideWidth", "_auroraTabHeight", "_auroraTabWidth",
    "_auroraPaletteBorderDefault", "_auroraBorderHooked", "_auroraPaletteOptOut",
    -- one-off texture handles design.md does not name; found by the first retail run
    "_auroraIconOverlay", "_auroraArrow", "_auroraHighlight", "_auroraCheckBox", "_auroraIcon",
})
local CATEGORY_ORDER = { "skin", "hook", "backdrop", "leftover", "deferred" }

-- RealUI's plants on Blizzard buttons: _stripes (RealUI_Skins.lua), and the
-- character slot regions (RealUI_Skins/FrameXML/PaperDollFrame.lua).
local REALUI_KEYS = {
    _stripes = true,
    ilvl = true, upgrades = true, dura = true, enchant = true, gems = true,
}

local GROUPS = {
    { id = "aurora", title = "Aurora's keys" },
    { id = "realui", title = "Known RealUI keys" },
    { id = "other", title = "Other addon-owned keys" },
}

local function Classify(key)
    local category = AURORA_KEYS[key]
    if category then return "aurora", category end
    if key:find("^_+aurora") then return "aurora", "deferred" end
    if REALUI_KEYS[key] then return "realui" end
    return "other"
end

--[[ Probes. Some secure-environment frames cannot be indexed at all from
     insecure code (LibStrataFix lesson), so each one is pcall'd. ]]
local function IsAccessible(frame)
    -- Boolean tests stay inside the pcall too: a secret result throws there
    -- and reads as "no".
    local ok, accessible = pcall(function() return not frame:IsForbidden() end)
    return ok and accessible
end

local function IsFrame(value)
    if type(value) ~= "table" then return false end
    local ok, isFrame = pcall(function() return type(value.GetObjectType) == "function" end)
    return ok and isFrame
end

local function IsButton(frame)
    local ok, isButton = pcall(function() return frame:IsObjectType("Button") and true or false end)
    return ok and isButton
end

-- A frame's debug name can be a secret string (seen on Forever for aura
-- buttons): it may not be compared, concatenated or sorted. Everything that
-- touches the raw name stays inside the pcall, and only a plain string leaves it.
local function Path(frame)
    local ok, name = pcall(function()
        local raw
        if frame.GetDebugName then raw = frame:GetDebugName() else raw = frame:GetName() end
        if type(raw) ~= "string" then return nil end
        local canaccessvalue = _G.canaccessvalue
        if canaccessvalue and not canaccessvalue(raw) then return "<secret name>" end
        if raw == "" then return nil end
        return raw
    end)
    if ok and name then return name end
    return "<anonymous button>"
end

--[[ Who made a frame. Region:GetSourceLocation() is documented on all five
     source trees (SimpleScriptRegionAPIDocumentation.lua; non-nilable string;
     a secret return under the ObjectDebug aspect on retail and Forever). The
     format is not in Blizzard's Lua; /fstack's SOURCE line shows it as the
     creating file and line, "Interface/AddOns/Blizzard_BuffFrame/BuffFrame.lua:176"
     or "Interface/AddOns/oUF/elements/auras.lua:376". Read by the folder after
     "AddOns/", either slash, any case. Returns "blizzard", "addon", or nil (no
     API, secret, or a location that names no AddOns folder and no Interface/
     path, such as a "[string ...]" chunk): nil leaves it to the fallback. ]]
local function SourceOf(frame)
    local ok, verdict = pcall(function()
        if not frame.GetSourceLocation then return nil end
        local location = frame:GetSourceLocation()
        local canaccessvalue = _G.canaccessvalue
        if canaccessvalue and not canaccessvalue(location) then return nil end
        if type(location) ~= "string" then return nil end
        local folder = location:match("[Aa][Dd][Dd][Oo][Nn][Ss][/\\]([^/\\:]+)")
        if folder then
            return folder:find("^[Bb]lizzard_") and "blizzard" or "addon"
        end
        -- Blizzard code outside AddOns (Interface/FrameXML, Interface/SharedXML)
        if location:find("[Ii][Nn][Tt][Ee][Rr][Ff][Aa][Cc][Ee][/\\]") then return "blizzard" end
        return nil
    end)
    if ok then return verdict end
end

local function Source(run, frame)
    local cached = run.sources[frame]
    if cached == nil then
        cached = SourceOf(frame) or false
        run.sources[frame] = cached
    end
    return cached or nil
end

local function ParentOf(frame)
    local ok, parent = pcall(function() return frame:GetParent() end)
    if ok then return parent end
end

-- "blizzard", "addon", "inside" (Blizzard-made under an addon-made ancestor),
-- or nil when the button's own location cannot be read (fallback decides).
local function Owner(run, button)
    local source = Source(run, button)
    if source ~= "blizzard" then return source end
    local parent, depth = ParentOf(button), 0
    while parent and depth <= MAX_FRAME_DEPTH do
        if Source(run, parent) == "addon" then return "inside" end
        parent, depth = ParentOf(parent), depth + 1
    end
    return "blizzard"
end

local function HasColorPlant(button)
    local ok, has = pcall(function() return rawget(button, "GetButtonColor") ~= nil end)
    return ok and has
end

local function HasSecureGlobalName(frame)
    local ok, secure = pcall(function()
        local name = frame:GetName()
        return type(name) == "string" and rawget(_G, name) == frame and (_G.issecurevariable(name))
    end)
    return ok and secure
end

-- Returns the button itself or its first ancestor that IsProtected() says is
-- protected, and whether that one is protected explicitly. UIParent is passed
-- over: it reads as explicitly protected on Forever, Mists, TBC and Vanilla
-- (checkpoint 0, 2026-11-22), so counting it lists every button under it.
local function ProtectedBy(frame)
    local current, depth = frame, 0
    while current and depth <= MAX_FRAME_DEPTH do
        local ok, isProtected, explicit = false, false, false
        if current ~= _G.UIParent then
            ok, isProtected, explicit = pcall(function()
                local protected, isExplicit = current:IsProtected()
                return protected and true or false, isExplicit and true or false
            end)
        end
        if ok and isProtected then return current, explicit end
        local okParent, parent = pcall(function() return current:GetParent() end)
        if not okParent then return nil end
        current, depth = parent, depth + 1
    end
end

--[[ The scan ]]
local function NewRun(root)
    return {
        root = root,            -- nil: every frame (EnumerateFrames)
        frames = 0,             -- frames visited
        buttons = 0,            -- Button-type frames among them
        -- owner test results: by source location, and by the fallback
        source = { blizzard = 0, addon = 0, inside = 0 },
        fallback = { blizzard = 0, unknown = 0 },
        blizzard = 0,           -- Blizzard's buttons, scanned (both tests)
        skinned = { blizzard = 0, inside = 0, addon = 0 },  -- GetButtonColor plant
        inside = {},            -- Blizzard-made inside addon frames: { button, path, skinned }
        addonSkinned = {},      -- addon-owned or unknown buttons with the plant
        forbidden = 0,          -- frames skipped as forbidden
        probeErrors = 0,        -- tables whose iteration threw
        fields = {},            -- { path, key, owner, group, category }
        flagged = {},           -- Blizzard buttons with addon-owned keys
        tables = {},            -- plain tables already descended into
        sources = {},           -- frame -> "blizzard" / "addon" / false
    }
end

-- Keys of a plain table Blizzard put on the button: addon-owned ones are
-- findings; deeper secure tables are followed up to MAX_TABLE_DEPTH.
local function ScanTable(run, findings, tbl, label, depth)
    local ok = pcall(function()
        for key, value in next, tbl do
            if type(key) == "string" then
                local isSecure, owner = _G.issecurevariable(tbl, key)
                if not isSecure then
                    findings[#findings + 1] = { path = label, key = key, owner = owner or "?" }
                elseif depth < MAX_TABLE_DEPTH and type(value) == "table" and not run.tables[value]
                    and not IsFrame(value) then
                    run.tables[value] = true
                    ScanTable(run, findings, value, label .. "." .. key, depth + 1)
                end
            end
        end
    end)
    if not ok then run.probeErrors = run.probeErrors + 1 end
end

local function CountAddonOwned(run, button)
    if HasColorPlant(button) then
        run.skinned.addon = run.skinned.addon + 1
        run.addonSkinned[#run.addonSkinned + 1] = button
    end
end

local function ScanButton(run, button)
    run.buttons = run.buttons + 1

    local madeBy = Owner(run, button)
    if madeBy == "addon" then
        run.source.addon = run.source.addon + 1
        CountAddonOwned(run, button)
        return
    elseif madeBy == "inside" then
        run.source.inside = run.source.inside + 1
        local skinned = HasColorPlant(button)
        if skinned then run.skinned.inside = run.skinned.inside + 1 end
        run.inside[#run.inside + 1] = { button = button, path = Path(button), skinned = skinned }
        return
    end

    -- Top level first, so Blizzard-ness is known before anything is descended into.
    local top, hasSecureKey = {}, false
    local ok = pcall(function()
        for key, value in next, button do
            if type(key) == "string" then
                local isSecure, owner = _G.issecurevariable(button, key)
                if isSecure then hasSecureKey = true end
                top[#top + 1] = { key = key, value = value, secure = isSecure, owner = owner }
            end
        end
    end)
    if not ok then run.probeErrors = run.probeErrors + 1 end

    if madeBy == "blizzard" then
        run.source.blizzard = run.source.blizzard + 1
    elseif hasSecureKey or HasSecureGlobalName(button) then
        -- Fallback: over-counts where it decides (the engine's own keys and a
        -- named frame's global read secure whoever made the frame).
        run.fallback.blizzard = run.fallback.blizzard + 1
    else
        run.fallback.unknown = run.fallback.unknown + 1
        CountAddonOwned(run, button)
        return
    end
    run.blizzard = run.blizzard + 1

    local path = Path(button)
    local findings = {}
    for _, entry in ipairs(top) do
        if not entry.secure then
            findings[#findings + 1] = { path = path, key = entry.key, owner = entry.owner or "?" }
        elseif type(entry.value) == "table" and not run.tables[entry.value] and not IsFrame(entry.value) then
            -- An addon-owned table (backdropInfo, _returnColor) is one finding; its
            -- contents are addon-written by definition and would only inflate the count.
            run.tables[entry.value] = true
            ScanTable(run, findings, entry.value, path .. "." .. entry.key, 1)
        end
    end
    if #findings == 0 then return end

    local keys = {}
    if HasColorPlant(button) then run.skinned.blizzard = run.skinned.blizzard + 1 end
    for _, field in ipairs(findings) do
        field.group, field.category = Classify(field.key)
        keys[field.key] = true
        run.fields[#run.fields + 1] = field
    end
    run.flagged[#run.flagged + 1] = { button = button, path = path, keys = keys, count = #findings }
end

local function Visit(run, frame)
    run.frames = run.frames + 1
    if not IsAccessible(frame) then
        run.forbidden = run.forbidden + 1
        return false
    end
    if IsButton(frame) then ScanButton(run, frame) end
    return true
end

local function ScanAll(run)
    local enumerate = _G.EnumerateFrames
    local ok, frame = pcall(enumerate)
    while ok and frame do
        Visit(run, frame)
        ok, frame = pcall(enumerate, frame)
    end
    if not ok then run.probeErrors = run.probeErrors + 1 end
    return run
end

local function WalkRoot(run, frame, depth, seen)
    if seen[frame] then return end
    seen[frame] = true
    if not Visit(run, frame) or depth >= MAX_FRAME_DEPTH then return end
    local ok, children = pcall(function() return { frame:GetChildren() } end)
    if not ok then return end
    for _, child in ipairs(children) do
        if IsFrame(child) then WalkRoot(run, child, depth + 1, seen) end
    end
end

local function ScanRoot(run, root)
    WalkRoot(run, root, 0, {})
    return run
end

-- At baseline a skinned button is one carrying the GetButtonColor plant.
-- After task 2.1 this asks the dev iterator Skin/skin.lua exposes on
-- _G.Aurora.Skin instead (never through the private table).
local function IsSkinned(entry)
    return entry.keys.GetButtonColor == true
end

--[[ Output. One LibTextDump window per load, cleared on each run, when the
     library is installed (RealUI ships it; standalone Aurora lists it as an
     optional dependency). Chat otherwise, capped at CHAT_LIMIT lines. Lines
     carry no colour codes so they paste clean. ]]
local dump
local function Show(lines)
    local LibStub = _G.LibStub
    local LTD = LibStub and LibStub("LibTextDump-1.0", true)
    if LTD then
        local ok = pcall(function()
            if not dump then dump = LTD:New(addonName .. " buttonscan", 900, 560) end
            dump:Clear()
            for _, line in ipairs(lines) do
                -- InsertLine, not AddLine: AddLine redraws the open window per line.
                dump:InsertLine(dump:Lines() + 1, line ~= "" and line or " ")
            end
            dump:Display()
        end)
        if ok then
            _G.print(("buttonscan: %d lines in the text window (Ctrl+A, Ctrl+C to copy)."):format(#lines))
            return
        end
    end
    for i = 1, math.min(#lines, CHAT_LIMIT) do
        _G.print(lines[i])
    end
    if #lines > CHAT_LIMIT then
        _G.print(("buttonscan: %d more lines cut. Install LibTextDump-1.0 for the full output."):format(#lines - CHAT_LIMIT))
    end
end

local function Header(lines, run, mode)
    local version, build, _, interface = _G.GetBuildInfo()
    lines[#lines + 1] = ("Aurora buttonscan %s | %s | client %s.%s (%s), project %s | loaded by %s | root: %s"):format(
        mode, _G.date("%Y-%m-%d %H:%M"), tostring(version), tostring(build), tostring(interface),
        tostring(_G.WOW_PROJECT_ID), addonName, run.root or "all frames")
    local source, fallback = run.source, run.fallback
    lines[#lines + 1] = ("Buttons: %d found in %d frames; %d Blizzard's scanned; %d of them with addon-owned keys; %d addon-owned or unknown (count only); %d Blizzard-made inside addon frames (count only); %d forbidden frames skipped"):format(
        run.buttons, run.frames, run.blizzard, #run.flagged, source.addon + fallback.unknown, source.inside,
        run.forbidden)
    lines[#lines + 1] = ("Owner test: source location %d (Blizzard's %d, addon-owned %d, inside addon frames %d); fallback, secure key or global name %d (Blizzard's %d, addon-owned or unknown %d)"):format(
        source.blizzard + source.addon + source.inside, source.blizzard, source.addon, source.inside,
        fallback.blizzard + fallback.unknown, fallback.blizzard, fallback.unknown)
    lines[#lines + 1] = ("Skinned (GetButtonColor key): Blizzard's %d, inside addon frames %d, addon-owned %d"):format(
        run.skinned.blizzard, run.skinned.inside, run.skinned.addon)
    if #run.inside > 0 then
        -- Skinned first: those are the ones that would matter if a Blizzard
        -- button was reparented into an addon frame and lands here by mistake.
        table.sort(run.inside, function(a, b)
            if a.skinned ~= b.skinned then return a.skinned end
            return a.path < b.path
        end)
        for i = 1, math.min(#run.inside, INSIDE_EXAMPLES) do
            local entry = run.inside[i]
            lines[#lines + 1] = ("  inside addon frame, e.g. %s%s"):format(entry.path, entry.skinned and " [skinned]" or "")
        end
    end
    if run.probeErrors > 0 then
        lines[#lines + 1] = ("Probe errors (tables that could not be iterated): %d"):format(run.probeErrors)
    end
end

local function Verdict(lines, run)
    if #run.fields == 0 then
        lines[#lines + 1] = "PASS: no addon-owned field on any Blizzard button in scope."
    else
        lines[#lines + 1] = ("FAIL: %d addon-owned fields on %d Blizzard buttons (PASS means 0; buttons made by addons or inside addon frames are not counted)."):format(
            #run.fields, #run.flagged)
    end
end

local function OwnerList(owners)
    local list = {}
    for owner in next, owners do list[#list + 1] = owner end
    table.sort(list)
    return table.concat(list, "/")
end

local function Summary(run)
    local lines = {}
    Header(lines, run, "summary")

    -- group -> key -> { count, owners, example, category }
    local byGroup = {}
    for _, group in ipairs(GROUPS) do
        byGroup[group.id] = { total = 0, keys = {}, order = {}, categories = {} }
    end
    for _, field in ipairs(run.fields) do
        local group = byGroup[field.group]
        group.total = group.total + 1
        local entry = group.keys[field.key]
        if not entry then
            entry = { key = field.key, count = 0, owners = {}, example = field.path, category = field.category }
            group.keys[field.key] = entry
            group.order[#group.order + 1] = entry
        end
        entry.count = entry.count + 1
        entry.owners[field.owner] = true
        if field.category then
            group.categories[field.category] = (group.categories[field.category] or 0) + 1
        end
    end

    for _, info in ipairs(GROUPS) do
        local group = byGroup[info.id]
        local line = ("%s: %d fields, %d keys"):format(info.title, group.total, #group.order)
        if info.id == "aurora" then
            local parts = {}
            for _, category in ipairs(CATEGORY_ORDER) do
                parts[#parts + 1] = ("%s %d"):format(category, group.categories[category] or 0)
            end
            line = line .. " (" .. table.concat(parts, ", ") .. ")"
        end
        lines[#lines + 1] = line
        table.sort(group.order, function(a, b)
            if a.count == b.count then return a.key < b.key end
            return a.count > b.count
        end)
        for _, entry in ipairs(group.order) do
            lines[#lines + 1] = ("  %s x%d%s <- %s; e.g. %s"):format(entry.key, entry.count,
                entry.category and (" [" .. entry.category .. "]") or "", OwnerList(entry.owners), entry.example)
        end
    end

    Verdict(lines, run)
    Show(lines)
end

local function Full(run)
    local lines = {}
    Header(lines, run, "full")
    table.sort(run.fields, function(a, b)
        if a.path == b.path then return a.key < b.key end
        return a.path < b.path
    end)
    for _, field in ipairs(run.fields) do
        lines[#lines + 1] = ("%s.%s <- %s [%s%s]"):format(field.path, field.key, field.owner, field.group,
            field.category and (":" .. field.category) or "")
    end
    -- Not fields, and not in the verdict: every Blizzard-made button inside an
    -- addon frame, so a misplaced Blizzard button can be spotted.
    for _, entry in ipairs(run.inside) do
        lines[#lines + 1] = ("inside addon frame: %s%s"):format(entry.path, entry.skinned and " [skinned]" or "")
    end
    Verdict(lines, run)
    Show(lines)
end

-- Task 1.5: buttons with addon-owned keys under IsProtected(), skinned first.
local function Protected(run)
    local lines = {}
    Header(lines, run, "protected")

    local skinned, other, clear = {}, {}, 0
    for _, entry in ipairs(run.flagged) do
        local by, explicit = ProtectedBy(entry.button)
        if by then
            local keys = {}
            for key in next, entry.keys do keys[#keys + 1] = key end
            table.sort(keys)
            local shown = {}
            for i = 1, math.min(#keys, PROTECTED_KEYS) do shown[i] = keys[i] end
            local where = by == entry.button and "self" or ("ancestor " .. Path(by))
            local line = ("  %s | protected: %s%s | %d keys: %s%s"):format(entry.path, where,
                explicit and " (explicit)" or "", #keys, table.concat(shown, ", "),
                #keys > PROTECTED_KEYS and ", ..." or "")
            local list = IsSkinned(entry) and skinned or other
            list[#list + 1] = line
        else
            clear = clear + 1
        end
    end
    table.sort(skinned)
    table.sort(other)

    local okRoot, rootProtected, rootExplicit = pcall(function()
        local protected, isExplicit = _G.UIParent:IsProtected()
        return protected and true or false, isExplicit and true or false
    end)
    lines[#lines + 1] = ("UIParent is not counted as a protected ancestor (IsProtected on it: %s%s)"):format(
        okRoot and tostring(rootProtected) or "unreadable", okRoot and rootExplicit and ", explicit" or "")
    lines[#lines + 1] = ("Skinned buttons (GetButtonColor key), protected or under a protected ancestor: %d"):format(#skinned)
    for _, line in ipairs(skinned) do lines[#lines + 1] = line end
    lines[#lines + 1] = ("Other buttons with addon-owned keys, protected or under a protected ancestor: %d"):format(#other)
    for _, line in ipairs(other) do lines[#lines + 1] = line end
    lines[#lines + 1] = ("Not protected, no protected ancestor below UIParent: %d buttons with addon-owned keys (not listed)"):format(clear)

    -- Not Blizzard's: counts only (skinned ones under protection).
    local insideSkinned, insideProtected, insideExamples = 0, 0, {}
    for _, entry in ipairs(run.inside) do
        if entry.skinned then
            insideSkinned = insideSkinned + 1
            if ProtectedBy(entry.button) then
                insideProtected = insideProtected + 1
                if #insideExamples < INSIDE_EXAMPLES then insideExamples[#insideExamples + 1] = entry.path end
            end
        end
    end
    lines[#lines + 1] = ("Blizzard-made inside addon frames, not listed: %d skinned, %d of them protected or under a protected ancestor"):format(
        insideSkinned, insideProtected)
    for _, path in ipairs(insideExamples) do
        lines[#lines + 1] = ("  e.g. %s"):format(path)
    end
    local addonProtected = 0
    for _, button in ipairs(run.addonSkinned) do
        if ProtectedBy(button) then addonProtected = addonProtected + 1 end
    end
    lines[#lines + 1] = ("Addon-owned or unknown, not listed: %d skinned, %d of them protected or under a protected ancestor"):format(
        #run.addonSkinned, addonProtected)
    Show(lines)
end

--[[ Spike S1 (task 1.6; design.md "Spike"): does a post-hook whose body only
     reads a weak table and recolours a texture Aurora owns leave the Blizzard
     update that called it secure?

     The update is a scroll bar thumb drag, by default on the Options panel's
     settings list (SettingsPanel.Container.SettingsList.ScrollBar, see
     SPIKE_TARGETS). While the thumb is held, the bar's OnUpdate
     (ScrollBar.lua:416-426) runs this once per frame as one execution, with
     no addon code on the way in:

       CallInternalScope                    ScrollBar.lua:301-305
         self.internalScope = true          :302
         SetScrollPercentage                :155, then SetScrollPercentageInternal :173
           self.scrollPercentage = ...      ScrollController.lua:177, called at :174
           Update                           :176, body at :219
             Back:SetEnabled(...)           :238   the hooked call
             Forward:SetEnabled(...)        :239
             self:GetScrollPercentage()     :241   reads scrollPercentage back
           TriggerEvent(OnScroll)           :178   the scroll box follows inside
                                                   securecallfunction (CallbackRegistry.lua:201, :210)
         self.internalScope = false         :304   the witness

     The first witness is bar.internalScope: Blizzard writes it after both
     SetEnabled calls returned, in the same Lua call chain, every held frame,
     so issecurevariable on it says whether the execution was still secure
     after the hook. Two more witnesses are written inside the callbacks when
     the list moved: box.updateLock (the constant false at the end of the
     scroll box's Update, ScrollBox.lua:799) and bar.visibleExtentPercentage
     (ScrollBar.lua:134 from ScrollUtil.lua:58). Their values owe nothing to
     the fields the dirty steps write, so only a tainted execution can turn
     them. The scroll percentages are support: bar.scrollPercentage is written
     before the calls and again after them when the list moved (the scroll box
     answers through ScrollUtil.lua:57), box.scrollPercentage after them
     (ScrollUtil.lua:76, ScrollBox.lua:315); their values change, which shows
     the update ran and counts the list's movements.

     Nothing here calls the update: the owner drags, a sampler on this file's
     own frame reads. A frame counts while bar.requireInternalScope (:397,
     cleared at :298) and thumb.down (ButtonStateBehavior.lua:61, :78) are both
     true, minus the first frame of each press, because every such frame had a
     CallInternalScope execution before it (scroll bars do not interpolate:
     ScrollBar.xml:7, ScrollUtil.lua:113-118).

     Phases, each needing SPIKE_MIN_FRAMES:
       control  no spike hook. Says whether this update is secure today, with
                whatever Aurora and RealUI already put on the bar (nothing on
                the Options panel; hooks and plants on a skinned bar). A
                control that reads insecure ends the run before anything is
                hooked: on a skinned bar it cannot say whether the cause is
                today's hook body or post-hooks as such, so move to a bar
                Aurora does not skin.
       clean    hooksecurefunc(Back, "SetEnabled", CleanHook), the only change
                to a Blizzard object in the measured part, and it stays until
                /reload.
       called   "spikecall", run last: the positive control. The bar's
                GetThumbAnchor becomes an addon function, which Update calls
                at :248, after the hooked call and in the same function. A
                Blizzard execution that runs addon code is tainted from there
                on (doctrine rule 8), which is the state a post-hook would
                leave if hooksecurefunc did not put the taint back. The
                verdict rests on the witnesses this step turns insecure: only
                those are shown to see taint that starts where the hook sits.
       dirty    "spikedirty", optional, not in the verdict: a second hook on
                the same key writes bar.scrollPercentage back to itself, which
                Update reads back at :241 and :178 through a getter.

     First run, 2026-11-22, retail 12.1.5.70961: control and clean secure in
     every frame. The dirty step, then the only sensitivity check, left
     bar.internalScope secure in all 912 frames although the field it wrote
     was read back before that write; only box.scrollPercentage turned, and
     that value is the tainted one handed on as data. So a tainted field read
     through a getter did not show as a tainted execution at :304, the check
     proved nothing about the witness, and the call step replaced it.

     Both extra steps leave that scroll bar tainted until /reload. ]]
local SPIKE_MIN_FRAMES = 30   -- thumb-held frames a phase needs before it counts
local SPIKE_KEYS_SHOWN = 6    -- addon-owned key names shown per table
local SPIKE_MIN_MOVES = 10    -- list movements a phase needs before its callback-side witnesses count

local SPIKE_FIELDS = {
    -- [1] is the first witness and gates the control; [3] counts list movements.
    -- SpikeResult reads both by index. A witness is a field Blizzard writes
    -- after the hooked call with a value that owes nothing to what the dirty
    -- steps write, so only a tainted execution can make it read insecure.
    { on = "bar", key = "internalScope", name = "bar.internalScope", label = "bar.internalScope [witness]", witness = true,
        note = "written after both SetEnabled calls returned, same call chain, every held frame (ScrollBar.lua:304)" },
    { on = "bar", key = "scrollPercentage", name = "bar.scrollPercentage", label = "bar.scrollPercentage",
        note = "written before the calls (ScrollController.lua:177 from ScrollBar.lua:174) and again after them when the list moved; the dirty hook writes it" },
    { on = "box", key = "scrollPercentage", name = "box.scrollPercentage", label = "box.scrollPercentage",
        note = "the scroll box's copy, written after the calls inside the bar's OnScroll callback when the list moved (ScrollUtil.lua:76); its value is math.saturate of what the bar read back, so the dirty hook's write reaches it as data" },
    { on = "box", key = "updateLock", name = "box.updateLock", label = "box.updateLock [witness]", witness = true, moves = true,
        note = "the constant false, written at the end of the scroll box's Update inside that callback when the list moved (ScrollBox.lua:799 through :147)" },
    { on = "bar", key = "visibleExtentPercentage", name = "bar.visibleExtentPercentage", label = "bar.visibleExtentPercentage [witness]", witness = true, moves = true,
        note = "written when the scroll box answers back, when the list moved (ScrollBar.lua:134 from ScrollUtil.lua:58); computed from frame extents" },
}
-- Default targets, first one on screen wins. Both are MinimalScrollBars.
local SPIKE_TARGETS = {
    -- Options panel, right-hand list (Blizzard_SettingsList.xml:53). Neither
    -- Aurora nor RealUI skins the Options panel, so the spike's hook is the
    -- only addon code on its steppers: the one place a failing result is clear.
    { "SettingsPanel", "Container", "SettingsList", "ScrollBar" },
    -- AddOn list (AddonList.xml:222), skinned by Skin.MinimalScrollBar: here
    -- the control also says what today's hook body does to the update.
    { "AddonList", "ScrollBar" },
}
-- Phase titles; the report lists phases in the order they were run (spike.order).
local SPIKE_PHASES = {
    control = "control, no spike hook",
    clean = "clean hook",
    called = "clean hook + Blizzard calls the spike's function",
    dirty = "clean hook + dirty hook",
}

local spikeStore = setmetatable({}, { __mode = "k" })   -- [Button] = record; the plan's buttonState
local spike = {}                                        -- the run: target, phase, stats

--[[ The body under test: the plan's Repaint (design.md "The state record")
     without its dedupe return, so every call does all of it. Reads the weak
     table, reads IsEnabled(), stops on a secret, writes Aurora's own record,
     recolours Aurora's own texture. Nothing is written on the button and the
     argument Blizzard passed is never looked at. ]]
local function CleanHook(Button)
    local state = spikeStore[Button]
    if not state then return end
    local enabled = Button:IsEnabled()
    if _G.issecretvalue and _G.issecretvalue(enabled) then return end
    state.runs = state.runs + 1
    state.paintedEnabled = enabled
    if enabled then
        state.texture:SetVertexColor(1, 1, 1)
    else
        state.texture:SetVertexColor(0.5, 0.5, 0.5)
    end
end

-- Never part of the plan. One Blizzard field written back to itself from
-- addon code: same value, addon-owned from then on.
local function DirtyHook(Button)
    local state = spikeStore[Button]
    if not state then return end
    state.dirtyRuns = state.dirtyRuns + 1
    state.bar.scrollPercentage = state.bar.scrollPercentage
end

--[[ Never part of the plan either: the positive control. Takes the place of
     ScrollBarMixin:GetThumbAnchor (ScrollBar.lua:89-91) on the one scroll bar
     and returns what it returned. Update calls it at :248 and nowhere else
     does, ten lines after the hooked call in the same function, so from there
     on Blizzard's execution has run addon code: the state a post-hook would
     leave behind if hooksecurefunc did not put the taint back. ]]
local function CalledByBlizzard(bar)
    local record = spike.record
    if record then record.callRuns = record.callRuns + 1 end
    return bar.thumbAnchor
end

-- present (nil: the probe threw), secure, owner, value as text
local function ReadField(tbl, key)
    local ok, present, secure, owner, text = pcall(function()
        local value = rawget(tbl, key)
        if value == nil then return false end
        local isSecure, who = _G.issecurevariable(tbl, key)
        local shown = type(value) == "number" and ("%.4f"):format(value) or tostring(value)
        return true, isSecure and true or false, who, shown
    end)
    if not ok then return nil end
    return present, secure, owner, text
end

local function FieldState(tbl, key)
    local present, secure, owner, text = ReadField(tbl, key)
    if present == nil then return "unreadable" end
    if not present then return "not set" end
    if secure then return text .. ", secure" end
    return ("%s, INSECURE <- %s"):format(text, tostring(owner or "?"))
end

-- For a method key, where the value itself says nothing.
local function KeyState(tbl, key)
    local present, secure, owner = ReadField(tbl, key)
    if present == nil then return "unreadable" end
    if not present then return "inherited, no key on the instance" end
    if secure then return "key on the instance, secure" end
    return ("key on the instance, INSECURE <- %s"):format(tostring(owner or "?"))
end

local function AddonKeys(tbl)
    local keys, owners = {}, {}
    local ok = pcall(function()
        for key in next, tbl do
            if type(key) == "string" then
                local isSecure, owner = _G.issecurevariable(tbl, key)
                if not isSecure then
                    keys[#keys + 1] = key
                    owners[owner or "?"] = true
                end
            end
        end
    end)
    if not ok then return "unreadable" end
    if #keys == 0 then return "none" end
    table.sort(keys)
    local shown = {}
    for i = 1, math.min(#keys, SPIKE_KEYS_SHOWN) do shown[i] = keys[i] end
    return ("%d <- %s (%s%s)"):format(#keys, OwnerList(owners), table.concat(shown, ", "),
        #keys > SPIKE_KEYS_SHOWN and ", ..." or "")
end

-- A ScrollBarMixin scroll bar with the parts the spike reads.
local function IsScrollBar(frame)
    if not (IsFrame(frame) and IsAccessible(frame)) then return false end
    local ok, result = pcall(function()
        return type(frame.CallInternalScope) == "function" and IsButton(frame.Back)
            and type(frame.Back.SetEnabled) == "function" and IsFrame(frame.Track) and IsFrame(frame.Track.Thumb)
    end)
    return ok and result
end

local function HoveredScrollBar()
    local ok, bar = pcall(function()
        local foci = _G.GetMouseFoci and _G.GetMouseFoci()
        if type(foci) ~= "table" then return nil end
        for _, region in ipairs(foci) do
            local frame, depth = region, 0
            while frame and depth <= MAX_FRAME_DEPTH do
                if IsScrollBar(frame) then return frame end
                frame, depth = ParentOf(frame), depth + 1
            end
        end
    end)
    if ok then return bar end
end

local function IsVisible(frame)
    local ok, visible = pcall(function() return frame:IsVisible() and true or false end)
    return ok and visible
end

-- The first default target that is on screen.
local function DefaultScrollBar()
    for _, keys in ipairs(SPIKE_TARGETS) do
        local ok, bar = pcall(function()
            local frame = _G[keys[1]]
            for i = 2, #keys do
                if not frame then return nil end
                frame = frame[keys[i]]
            end
            return frame
        end)
        if ok and IsScrollBar(bar) and IsVisible(bar) then return bar end
    end
end

local function NewPhase()
    local phase = { frames = 0, hookFrames = 0, fields = {} }
    for index in ipairs(SPIKE_FIELDS) do
        phase.fields[index] = { secure = 0, insecure = 0, unset = 0, changes = 0, owners = {} }
    end
    return phase
end

local function Snapshot()
    local states = {}
    for index, field in ipairs(SPIKE_FIELDS) do
        local tbl = spike[field.on]
        states[index] = tbl and FieldState(tbl, field.key) or "no such frame"
    end
    return states
end

-- Runs from the swatch's OnUpdate, an execution of its own. Reads only.
local function Sample()
    local phase = spike.stats and spike.stats[spike.phase]
    if not phase then return end
    local held = rawget(spike.bar, "requireInternalScope") == true and rawget(spike.thumb, "down") == true
    if not held then
        spike.wasHeld = false
        return
    end
    local runs = spike.record.runs
    if not spike.wasHeld then
        -- First frame of a press: the bar's own OnUpdate may not have run yet.
        spike.wasHeld, spike.lastRuns = true, runs
        return
    end
    phase.frames = phase.frames + 1
    if runs ~= spike.lastRuns then
        phase.hookFrames = phase.hookFrames + 1
        spike.lastRuns = runs
    end
    for index, field in ipairs(SPIKE_FIELDS) do
        local tbl = spike[field.on]
        if tbl then
            local tally = phase.fields[index]
            local present, secure, owner, text = ReadField(tbl, field.key)
            if not present then
                tally.unset = tally.unset + 1
            else
                if secure then
                    tally.secure = tally.secure + 1
                else
                    tally.insecure = tally.insecure + 1
                    tally.owners[tostring(owner or "?")] = true
                end
                if tally.last ~= nil and tally.last ~= text then tally.changes = tally.changes + 1 end
                tally.last = text
            end
        end
    end
end

-- The spike's own frame and texture: a 12 px square at the top of the screen,
-- white while the stepper is enabled, grey while it is disabled.
local function Swatch()
    if spike.swatch then return true end
    return pcall(function()
        local frame = _G.CreateFrame("Frame")
        frame:SetSize(12, 12)
        frame:SetPoint("TOP", _G.UIParent, "TOP", 0, -4)
        frame:SetFrameStrata("TOOLTIP")
        local texture = frame:CreateTexture(nil, "ARTWORK")
        texture:SetAllPoints(frame)
        texture:SetColorTexture(1, 1, 1, 1)
        frame:SetScript("OnUpdate", function()
            if not pcall(Sample) then spike.sampleErrors = (spike.sampleErrors or 0) + 1 end
        end)
        spike.swatch, spike.texture = frame, texture
    end)
end

-- Pick the target and start the control phase. Changes nothing on any Blizzard object.
local function Arm(bar, chosenBy)
    if not Swatch() then
        _G.print("buttonscan spike: could not create its own frame; nothing done.")
        return false
    end
    local back, thumb = bar.Back, bar.Track.Thumb
    local box = rawget(bar, "registeredScrollBox")   -- ScrollUtil.lua:110
    if not (IsFrame(box) and IsAccessible(box)) then box = nil end

    spike.bar, spike.back, spike.thumb, spike.box = bar, back, thumb, box
    spike.path, spike.backPath = Path(bar), Path(back)
    spike.record = { texture = spike.texture, bar = bar, runs = 0, dirtyRuns = 0, callRuns = 0 }
    spikeStore[back] = spike.record
    spike.stats = { control = NewPhase() }
    spike.order = { "control" }
    spike.phase, spike.wasHeld, spike.lastRuns = "control", false, 0
    spike.start = Snapshot()
    spike.about = {
        ("Target: %s (chosen by %s; made by %s); button to hook: %s; scroll box: %s"):format(spike.path, chosenBy,
            SourceOf(bar) or "unknown", spike.backPath, box and Path(box) or "none registered"),
        ("Before the spike, on %s: Aurora's button skin (GetButtonColor key) %s; addon-owned keys %s; SetEnabled %s"):format(
            spike.backPath, HasColorPlant(back) and "yes" or "no", AddonKeys(back), KeyState(back, "SetEnabled")),
        ("Before the spike, addon-owned keys on the scroll bar: %s; on its thumb: %s"):format(AddonKeys(bar), AddonKeys(thumb)),
    }
    return true
end

-- Close the running phase and open the next one.
local function BeginPhase(id, about)
    spike.stats[spike.phase].ended = Snapshot()
    spike.stats[id] = NewPhase()
    spike.stats[id].prev = spike.phase
    spike.order[#spike.order + 1] = id
    spike.phase, spike.wasHeld = id, false
    spike.about[#spike.about + 1] = about
end

-- The one write to a Blizzard object (twice with the dirty hook, same key).
local function InstallHook(id, body, name)
    local back = spike.back
    if not pcall(_G.hooksecurefunc, back, "SetEnabled", body) then
        _G.print(("buttonscan spike: hooksecurefunc on %s failed; nothing changed."):format(spike.backPath))
        return false
    end
    BeginPhase(id, ("Hooked: hooksecurefunc(%s, \"SetEnabled\", %s). SetEnabled now: %s. It stays until /reload."):format(
        spike.backPath, name, KeyState(back, "SetEnabled")))
    return true
end

-- The positive control's write: one method of the scroll bar becomes addon code.
local function InstallCall()
    local bar = spike.bar
    local ok = pcall(function()
        if type(bar.GetThumbAnchor) ~= "function" then error("no GetThumbAnchor") end
        bar.GetThumbAnchor = CalledByBlizzard
    end)
    if not ok then
        _G.print(("buttonscan spike: %s has no GetThumbAnchor to replace; nothing changed."):format(spike.path))
        return false
    end
    BeginPhase("called", ("Replaced: %s.GetThumbAnchor is now the spike's own function; Update calls it at ScrollBar.lua:248, after the hooked call. GetThumbAnchor now: %s. It stays until /reload."):format(
        spike.path, KeyState(bar, "GetThumbAnchor")))
    return true
end

local function Owners(tally)
    if tally.insecure == 0 then return "" end
    return " <- " .. OwnerList(tally.owners)
end

local function FieldNames(indexes)
    if #indexes == 0 then return "none" end
    local names = {}
    for i, index in ipairs(indexes) do names[i] = SPIKE_FIELDS[index].name end
    return table.concat(names, ", ")
end

-- The fields a phase turned insecure that the phase before it had left
-- secure, and those it left secure too. Witnesses only, unless every sampled
-- field is asked for.
local function Turned(phase, everyField)
    local turned, kept = {}, {}
    local before = spike.stats[phase.prev]
    for index, field in ipairs(SPIKE_FIELDS) do
        if spike[field.on] and (everyField or field.witness) and before.fields[index].insecure == 0 then
            local list = phase.fields[index].insecure >= SPIKE_MIN_FRAMES and turned or kept
            list[#list + 1] = index
        end
    end
    return turned, kept
end

-- The clean phase on its own, judged on bar.internalScope. Returns "secure",
-- "failed", or nil while it has too few frames, and the other witnesses that
-- read insecure with the clean hook but not in the control.
local function CleanResult(lines)
    local control, clean = spike.stats.control, spike.stats.clean
    local witness = clean.fields[1]
    local others = {}
    for index, field in ipairs(SPIKE_FIELDS) do
        if index > 1 and field.witness and spike[field.on]
            and clean.fields[index].insecure > 0 and control.fields[index].insecure == 0 then
            others[#others + 1] = index
        end
    end

    local verdict
    if clean.frames < SPIKE_MIN_FRAMES or clean.hookFrames < SPIKE_MIN_FRAMES
        or witness.secure + witness.insecure < SPIKE_MIN_FRAMES then
        lines[#lines + 1] = ("RESULT: none yet, nothing measured (INCONCLUSIVE if this is the last window). With the hook: thumb held %d frames, hook ran in %d of them, witness written in %d (each needs %d)."):format(
            clean.frames, clean.hookFrames, witness.secure + witness.insecure, SPIKE_MIN_FRAMES)
    elseif witness.insecure > 0 then
        verdict = "failed"
        lines[#lines + 1] = ("RESULT: DID NOT STAY SECURE. With the clean hook on %s, bar.internalScope read insecure%s in %d of %d thumb-held frames; the control read secure. STOP: owner first, this reopens AT-D1 and AT-D6 (tasks.md, \"Pulling a tier B row forward\", point 2)."):format(
            spike.backPath, Owners(witness), witness.insecure, clean.frames)
    else
        verdict = "secure"
        lines[#lines + 1] = ("RESULT: STAYED SECURE. With the clean hook on %s, bar.internalScope was written secure in all %d thumb-held frames (the hook ran in %d of them). AT-D2 stands, subject to the sensitivity check."):format(
            spike.backPath, clean.frames, clean.hookFrames)
    end
    if #others > 0 then
        lines[#lines + 1] = ("NOTE: with the clean hook these also read insecure, and did not in the control: %s. They are written inside the scroll box's callback, where taint can start on its own; bar.internalScope cannot be reached from there."):format(
            FieldNames(others))
    end
    return verdict, others
end

--[[ Witnesses shown to turn insecure when taint starts inside Update after
     the hooked call: those the call step turned, and bar.internalScope if the
     dirty step turned it (a field read in Update then reached the write at
     ScrollBar.lua:304). Returns them, the witnesses the call step left secure,
     whether anything was measured, and whether the dirty step supplied one. ]]
local function Proven()
    local stats = spike.stats
    local called, dirty = stats.called, stats.dirty
    local turned, kept, measured, byDirty = {}, {}, false, false
    if called and called.frames >= SPIKE_MIN_FRAMES then
        turned, kept = Turned(called)
        measured = true
    end
    if dirty and dirty.frames >= SPIKE_MIN_FRAMES and dirty.fields[1].insecure >= SPIKE_MIN_FRAMES
        and stats[dirty.prev].fields[1].insecure == 0 then
        table.insert(turned, 1, 1)
        measured, byDirty = true, true
    end
    return turned, kept, measured, byDirty
end

-- The sensitivity line and the verdict that rests on the proven witnesses.
local function VerdictLines(lines, verdict, others, turned, kept, byDirty)
    local clean, called = spike.stats.clean, spike.stats.called
    if #turned == 0 then
        lines[#lines + 1] = ("SENSITIVITY: FAILED. Update called the spike's own function %d times (ScrollBar.lua:248) and no witness turned insecure in %d thumb-held frames (still secure: %s). Taint that starts inside Update after the hooked call does not show in any field sampled here."):format(
            spike.record.callRuns, called.frames, FieldNames(kept))
        lines[#lines + 1] = "VERDICT: INCONCLUSIVE. The clean phase proves nothing until some witness can be turned."
        return
    end
    local how = called and ("Update called the spike's own function at ScrollBar.lua:248, %d calls"):format(spike.record.callRuns)
        or "no call step run"
    if byDirty then
        how = how .. "; bar.internalScope turned in the dirty step, from the field Update read back at :241"
    end
    lines[#lines + 1] = ("SENSITIVITY: OK. Witnesses that turned insecure once taint started inside Update after the hooked call: %s (%s). Still secure: %s. This is what a clean hook that left the execution tainted would look like."):format(
        FieldNames(turned), how, FieldNames(kept))
    if verdict == nil then
        lines[#lines + 1] = "VERDICT: INCONCLUSIVE. The clean phase was not measured."
        return
    end

    -- Witnesses that turned and that the clean phase wrote often enough.
    local rests, onFirst = {}, false
    local moves = spike.box and clean.fields[3].changes or 0
    for _, index in ipairs(turned) do
        local enough = clean.fields[index].secure >= SPIKE_MIN_FRAMES
        if SPIKE_FIELDS[index].moves then enough = enough and moves >= SPIKE_MIN_MOVES end
        if enough then
            rests[#rests + 1] = index
            if index == 1 then onFirst = true end
        end
    end
    if #rests == 0 then
        lines[#lines + 1] = ("VERDICT: INCONCLUSIVE. The witnesses that turned (%s) were not written often enough in the clean phase: the list moved %d times there (needs %d). Run it again and drag the thumb all the way up and down."):format(
            FieldNames(turned), moves, SPIKE_MIN_MOVES)
    elseif #others > 0 and not onFirst then
        lines[#lines + 1] = ("VERDICT: INCONCLUSIVE, mixed. bar.internalScope was not turned, and %s read insecure with the clean hook (see NOTE). A reader has to weigh the field lines."):format(
            FieldNames(others))
    else
        lines[#lines + 1] = ("VERDICT: STAYED SECURE, resting on %s: secure in every clean-phase frame that wrote it, insecure once Blizzard's Update had run tainted after the same hooked call. AT-D2 stands."):format(
            FieldNames(rests))
    end
end

-- Appends the verdict lines; returns what to do next.
local function SpikeResult(lines)
    local command = COMMAND
    local stats = spike.stats
    local control, clean, called, dirty = stats.control, stats.clean, stats.called, stats.dirty
    local controlWitness = control.fields[1]
    local drag = ("close this window, hold the left button on the THUMB of %s and drag it all the way up and down for about three seconds (not the wheel, not the arrows), release"):format(spike.path)

    if controlWitness.insecure > 0 then
        lines[#lines + 1] = ("RESULT: INCONCLUSIVE, already tainted. Without any spike hook this update wrote bar.internalScope insecure%s in %d of %d thumb-held frames, so nothing here can be laid at the clean hook."):format(
            Owners(controlWitness), controlWitness.insecure, control.frames)
        if clean then
            return "paste this whole window, then /reload. A new run needs another scroll bar."
        end
        return ("nothing is hooked. Paste this whole window. To try another scroll bar: hover it and run '%s spikehover' (one Aurora does not skin, such as the Options panel's, is the only kind that can separate today's hooks from the clean one)."):format(command)
    end
    if not clean then
        lines[#lines + 1] = ("CONTROL: not measured yet. Thumb held %d frames, witness written secure in %d (needs %d)."):format(
            control.frames, controlWitness.secure, SPIKE_MIN_FRAMES)
        return ("%s, then run '%s spike' again. If the list does not scroll, hover a scroll bar that does and run '%s spikehover'."):format(
            drag, command, command)
    end
    lines[#lines + 1] = ("CONTROL: without the spike's hook bar.internalScope was written secure in all %d thumb-held frames that wrote it."):format(
        controlWitness.secure)

    local verdict, others = CleanResult(lines)
    if verdict == nil and not (called or dirty) then
        return ("%s, then run '%s spike' again."):format(drag, command)
    elseif verdict == "failed" then
        lines[#lines + 1] = "VERDICT: DID NOT STAY SECURE. The witness read insecure with the clean hook and secure without it; no further step is needed."
        return "paste this whole window, then /reload."
    end

    if dirty then
        if dirty.frames < SPIKE_MIN_FRAMES then
            lines[#lines + 1] = ("FIELD-READ CHECK: not measured yet. Thumb held %d frames with the dirty hook (needs %d)."):format(
                dirty.frames, SPIKE_MIN_FRAMES)
        else
            local turned, kept = Turned(dirty, true)
            lines[#lines + 1] = ("FIELD-READ CHECK: with bar.scrollPercentage addon-owned (the dirty hook ran %d times) and read back by Update (ScrollBar.lua:241, :178), turned insecure: %s. Still secure: %s."):format(
                spike.record.dirtyRuns, FieldNames(turned), FieldNames(kept))
        end
    end
    local turned, kept, measured, byDirty = Proven()
    if measured then
        VerdictLines(lines, verdict, others, turned, kept, byDirty)
    elseif called then
        lines[#lines + 1] = ("SENSITIVITY: not measured yet. Thumb held %d frames since Update started calling the spike's function (needs %d)."):format(
            called.frames, SPIKE_MIN_FRAMES)
    elseif verdict == "secure" then
        lines[#lines + 1] = "SENSITIVITY: not checked yet. Until the call step turns a witness insecure, STAYED SECURE is provisional."
    end

    if stats[spike.phase].frames < SPIKE_MIN_FRAMES then
        return ("%s, then run '%s spike', paste the window, then /reload at once: this scroll bar's updates are tainted until then."):format(
            drag, command)
    elseif not called and #turned == 0 then
        return ("paste this whole window. Then, last: run '%s spikecall', drag the thumb again for three seconds, run '%s spike', paste that window too, then /reload."):format(
            command, command)
    end
    return "paste this whole window, then /reload."
end

local function SpikeReport()
    local lines = {}
    local version, build, _, interface = _G.GetBuildInfo()
    lines[#lines + 1] = ("Aurora buttonscan spike | %s | client %s.%s (%s), project %s | loaded by %s | target: %s"):format(
        _G.date("%Y-%m-%d %H:%M"), tostring(version), tostring(build), tostring(interface),
        tostring(_G.WOW_PROJECT_ID), addonName, spike.path)
    for _, line in ipairs(spike.about) do lines[#lines + 1] = line end

    lines[#lines + 1] = ("Phases (frames with the thumb held, first frame of each press left out; a phase needs %d):"):format(SPIKE_MIN_FRAMES)
    for _, id in ipairs(spike.order) do
        local phase = spike.stats[id]
        local line = ("  %s: %d frames"):format(SPIKE_PHASES[id], phase.frames)
        if id ~= "control" then
            line = line .. ("; the clean hook ran in %d of them"):format(phase.hookFrames)
        end
        lines[#lines + 1] = line
    end
    lines[#lines + 1] = ("Hook runs since install: clean %d, dirty %d. Calls of the spike's function by Update: %d. Sampler errors: %d."):format(
        spike.record.runs, spike.record.dirtyRuns, spike.record.callRuns, spike.sampleErrors or 0)

    lines[#lines + 1] = "Fields (who last wrote them; secure = Blizzard):"
    for index, field in ipairs(SPIKE_FIELDS) do
        local tbl = spike[field.on]
        if tbl then
            lines[#lines + 1] = ("  %s: %s"):format(field.label, field.note)
            lines[#lines + 1] = ("    before the spike: %s"):format(spike.start[index])
            for _, id in ipairs(spike.order) do
                local phase = spike.stats[id]
                local tally = phase.fields[index]
                lines[#lines + 1] = ("    %s: secure %d, insecure %d%s, not set %d; value changed %d times; %s"):format(
                    SPIKE_PHASES[id], tally.secure, tally.insecure, Owners(tally), tally.unset, tally.changes,
                    phase.ended and ("at its end: " .. phase.ended[index]) or ("now: " .. FieldState(tbl, field.key)))
            end
        end
    end

    local nextStep = SpikeResult(lines)
    lines[#lines + 1] = "NEXT: " .. nextStep
    if spike.phase ~= "control" then
        lines[#lines + 1] = ("Until /reload: the spike's hook on %s.SetEnabled%s. The small square at the top of the screen is the spike's own texture."):format(
            spike.backPath, spike.stats.called and (", and its function in place of %s.GetThumbAnchor"):format(spike.path) or "")
    end
    Show(lines)
end

local function SpikeReady()
    if _G.hooksecurefunc and _G.CreateFrame and _G.UIParent then return true end
    _G.print("buttonscan spike: this client lacks hooksecurefunc, CreateFrame or UIParent.")
    return false
end

-- Arms a target unless one is hooked already. Returns true when armed.
local function SpikeTarget(bar, chosenBy, missing)
    if not bar then
        _G.print(missing)
        return false
    end
    if SourceOf(bar) == "addon" then
        _G.print(("buttonscan spike: %s was made by an addon; the spike needs a Blizzard scroll bar."):format(Path(bar)))
        return false
    end
    if not IsVisible(bar) then
        _G.print(("buttonscan spike: %s is not shown. Open its window first."):format(Path(bar)))
        return false
    end
    return Arm(bar, chosenBy)
end

-- "spike": arm the default target, then the control, then the clean hook, then the report.
local function Spike()
    if not SpikeReady() then return end
    if not spike.phase then
        if not SpikeTarget(DefaultScrollBar(), "default",
            ("buttonscan spike: open Options (Esc > Options) on a category whose list scrolls, then run this again. Or hover any Blizzard scroll bar and run '%s spikehover'."):format(COMMAND)) then
            return
        end
    elseif spike.phase == "control" then
        local control = spike.stats.control
        local witness = control.fields[1]
        if control.frames >= SPIKE_MIN_FRAMES and witness.secure >= SPIKE_MIN_FRAMES and witness.insecure == 0 then
            if not InstallHook("clean", CleanHook, "clean body") then return end
        end
    end
    return SpikeReport()
end

-- "spikehover": the scroll bar under the mouse instead of the default.
local function SpikeHover()
    if not SpikeReady() then return end
    if spike.phase and spike.phase ~= "control" then
        _G.print(("buttonscan spike: %s is hooked already; /reload before choosing another scroll bar."):format(spike.backPath))
        return
    end
    if SpikeTarget(HoveredScrollBar(), "mouse-over",
        "buttonscan spike: no Blizzard scroll bar under the mouse. Keep the pointer on the bar while the command runs.") then
        return SpikeReport()
    end
end

-- "spikecall" and "spikedirty": one more phase on top of the clean hook, after
-- the running phase has its frames. Each can be started once.
local function SpikeStimulus(id, install)
    if not SpikeReady() then return end
    local phase = spike.phase
    if phase == id then return SpikeReport() end
    if phase == nil or phase == "control" then
        _G.print(("buttonscan spike: run '%s spike' through the clean step first."):format(COMMAND))
        return
    end
    if spike.stats[id] then
        _G.print("buttonscan spike: that step has run already; /reload for a new run.")
        return
    end
    if spike.stats[phase].frames < SPIKE_MIN_FRAMES then
        _G.print(("buttonscan spike: finish the current step first (drag the thumb, then '%s spike')."):format(COMMAND))
        return
    end
    if install() then return SpikeReport() end
end

-- The positive control the verdict rests on: Blizzard's Update calls addon code after the hooked call.
local function SpikeCall()
    return SpikeStimulus("called", InstallCall)
end

-- The field-read check: the dirty hook leaves bar.scrollPercentage addon-owned for Update to read back.
local function SpikeDirty()
    return SpikeStimulus("dirty", function()
        return InstallHook("dirty", DirtyHook, "dirty body, writes bar.scrollPercentage")
    end)
end

--[[ Arguments. Each mode takes a finished run of all frames; the spike words
     take none and are looked up first, so no scan runs for them. ]]
local MODES = {
    full = Full,
    protected = Protected,
}
local SPIKE_MODES = {
    spike = Spike,
    spikehover = SpikeHover,
    spikecall = SpikeCall,
    spikedirty = SpikeDirty,
}

local function Run(arg)
    if not (_G.EnumerateFrames and _G.issecurevariable) then
        _G.print("buttonscan: this client lacks EnumerateFrames or issecurevariable.")
        return
    end
    if _G.InCombatLockdown and _G.InCombatLockdown() then
        _G.print("buttonscan: not in combat. Run it again after combat.")
        return
    end

    if arg == nil then
        return Summary(ScanAll(NewRun()))
    end
    local spikeMode = SPIKE_MODES[arg]
    if spikeMode then
        return spikeMode()
    end
    local mode = MODES[arg]
    if mode then
        return mode(ScanAll(NewRun()))
    end
    local root = _G[arg]
    if IsFrame(root) then
        if not IsAccessible(root) then
            _G.print(("buttonscan: %s is forbidden; nothing to scan."):format(arg))
            return
        end
        return Summary(ScanRoot(NewRun(arg), root))
    end
    _G.print(USAGE)
end

-- /realdev calls fn(commands, arg); /aurora calls fn(arg) once task 1.3 lands
-- and fn() before it. Take the first string argument from either position.
local function Argument(first, second)
    local arg = first
    if type(arg) ~= "string" then arg = second end
    if type(arg) ~= "string" then return nil end
    arg = arg:match("^%s*(.-)%s*$")
    return arg ~= "" and arg or nil
end

commands.buttonscan = function(first, second)
    return Run(Argument(first, second))
end

if underAurora then
    -- Interim, standalone Aurora only: /aurora looks the whole trimmed message up
    -- as one key (gui.lua, private.commands[msg]) and passes no argument, so these
    -- keys make "/aurora buttonscan full" and "/aurora buttonscan protected" work
    -- now (lower case, one space). Remove them when task 1.3 lands.
    commands["buttonscan full"] = function() return Run("full") end
    commands["buttonscan protected"] = function() return Run("protected") end
end
