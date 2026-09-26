# Copilot instructions for Aurora

## Architecture (how Aurora loads)
- Entry point is Aurora.toc, one TOC for every client; it loads libs, Skin/skin.xml, the flavor's manifest (picked per line with [AllowLoadGameType] directives), then aurora.lua and gui.lua. Saved variables live in AuroraConfig.
- The core boot flow is in aurora.lua: it builds the Aurora API tables, registers ADDON_LOADED, then runs functions in private.fileOrder (set in Skin/init.lua) before skinning already-loaded addons.
- Skin module order is defined by Skin/skin.xml (init, color, util, api, backdrop, texture, skin, deprecated). Add new core skin helpers in Skin/ and add to that file.
- Addon-specific skins live under Skin/Interface/AddOns/ and are wired via XML include lists (e.g., Skin/Interface/AddOns/AddOns_Mainline.xml).

## Skin registration patterns
- Use Base.AddSkin(addonName, func) from Skin/api.lua to register skins for non-Blizzard addons; they execute on ADDON_LOADED and also immediately if the addon is already loaded.
- Use the shared helpers in Aurora.Base/Aurora.Skin/Aurora.Util; common texture cleanup uses Base.StripBlizzardTextures and Base.StripAllTextures.
- Respect feature toggles stored in AuroraConfig (bags, chat, loot, tooltips, fonts, mainmenubar); see aurora.lua for how disabled features short-circuit hooks.

## Config/UI conventions
- Options UI is built in gui.lua and registered via Settings.RegisterCanvasLayoutCategory; changes should go through AuroraConfig and update helpers like private.updateHighlightColor.
- Color/alpha updates call Util.SetFrameAlpha and update C.frames to keep frame alpha consistent across skins.

## Build and packaging
- Packaging uses .pkgmeta (manual changelog in CHANGELOG.md). Dev helpers in dev/ are excluded from packages.
- The toc uses do-not-package tags around dev/test.lua; keep debug-only code inside those tags.
- Lua linting uses .luacheckrc (Lua 5.1, libs excluded).

## Integration points
- Optional dependencies are declared in Aurora.toc (Ace3, LibTextDump-1.0, BugSack, WagoAnalytics). Guard usage when those libraries are absent.
- WagoAnalytics is wired in aurora.lua; keep telemetry changes behind the existing config flags.
