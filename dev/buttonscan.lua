local addonName, private = ...

--[[ buttonscan.lua - aurora-taint-pass (B261), phase 1 (tasks 1.1, 1.4, 1.5).

     Usage: <cmd>                 summary: counts, keys in three groups, PASS/FAIL
            <cmd> full            one line per addon-owned field
            <cmd> protected       buttons with addon-owned keys that are protected
                                  or sit under a protected ancestor
            <cmd> <FrameName>     summary for that frame and its descendants only

     <cmd> is "/realdev buttonscan" under RealUI_Dev (retail, Forever) and
     "/aurora buttonscan" under standalone Aurora (every flavour). Until task 1.3
     lands, /aurora passes no argument: only the plain command and the two
     aliases registered at the bottom of this file work there.

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

     Strictly read only: every probe is pcall'd, forbidden frames are skipped,
     and nothing is written to any frame. The only frame this file creates is
     its own LibTextDump output window, when that library is installed.

     Loaded twice over: by Aurora.toc (do-not-package block) and by
     RealUI_Dev.toc. Each load gets its own private table, so this file never
     assumes Aurora's (see dev/test.lua). ]]

local commands = private.commands
-- private.commands is created in gui.lua (Aurora) or RealUI_Dev.lua; without
-- it there is nothing to register into.
if not commands then return end

local underAurora = private.Aurora ~= nil
local COMMAND = underAurora and "/aurora buttonscan" or "/realdev buttonscan"
local USAGE = ("Usage: %s [full | protected | <FrameName>]"):format(COMMAND)

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
-- protected, and whether that one is protected explicitly.
local function ProtectedBy(frame)
    local current, depth = frame, 0
    while current and depth <= MAX_FRAME_DEPTH do
        local ok, isProtected, explicit = pcall(function()
            local protected, isExplicit = current:IsProtected()
            return protected and true or false, isExplicit and true or false
        end)
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

    lines[#lines + 1] = ("Skinned buttons (GetButtonColor key), protected or under a protected ancestor: %d"):format(#skinned)
    for _, line in ipairs(skinned) do lines[#lines + 1] = line end
    lines[#lines + 1] = ("Other buttons with addon-owned keys, protected or under a protected ancestor: %d"):format(#other)
    for _, line in ipairs(other) do lines[#lines + 1] = line end
    lines[#lines + 1] = ("Not protected, no protected ancestor: %d buttons with addon-owned keys (not listed)"):format(clear)

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

--[[ Arguments. Each mode takes a finished run of all frames. Task 1.6 adds
     MODES.spike here; until then "spike" falls through to the usage line. ]]
local MODES = {
    full = Full,
    protected = Protected,
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
