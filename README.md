Aurora
======

Aurora is a Blizzard UI skinning addon. It gives the default interface panels and frames one clean, consistent look.

It runs on its own, or embedded inside another addon. RealUI embeds it through `RealUI_Skins`.


Supported Clients
-----------------

One package and one TOC, `Aurora.toc`, cover five clients. Each client loads only its own skin manifest, chosen line by line with a load directive:

| Client | Interface | Load directive | Skin manifest |
| ------ | --------- | -------------- | ------------- |
| Retail (Midnight 12.1.x) | `120100` | `[AllowLoadGameType standard]` | `AddOns_Mainline.xml` |
| WoW Forever (1.60.x beta) | `16001` | `[AllowLoadGameType camelot]` | `AddOns_Forever.xml` |
| Mists of Pandaria Classic | `50504` | `[AllowLoadGameType mists]` | `AddOns_Mists.xml` |
| Burning Crusade Classic | `20506` | `[AllowLoadGameType tbc]` | `AddOns_TBC.xml` |
| Classic Era (1.15.x) | `11509` | `[AllowLoadGameType vanilla]` | `AddOns_Vanilla.xml` |

Retail is the main development target.

WoW Forever is built on the Mainline UI with a `Camelot` game overlay, so Aurora treats it as a Mainline-family flavor, not as a classic port. The other clients don't know the `camelot` token, and a client treats an unknown token as a match. The Forever line therefore also carries `[ExcludeLoadGameType standard, classic]`. Skins that only Camelot needs live in `Blizzard_X\Camelot\`, beside `Mainline\`.

Don't add a suffixed TOC (`Aurora_Mainline.toc` and so on) back. On its own client, a suffixed TOC takes priority over `Aurora.toc`. The same applies when upgrading from 12.1.0.10 or older: delete the Aurora folder first rather than unzipping over it, or the old `Aurora_*.toc` files stay behind and keep loading.


Quick Start
-----------

  * Type `/aurora` to open the options panel.
  * Type `/aurora help` to list every command.
  * Type `/aurora status` to check configuration, compatibility and integration health.


Options
-------

The options panel is under Settings → AddOns → Aurora. It has four sections:

  * **Features**: turn skinning on or off for bags, banks, chat, loot, tooltips, the character sheet, the objective tracker, the main menu bar and fonts. Turn a component off if another addon handles it. Aurora warns about known clashes, for example with Bagnon, AdiBags, ArkInventory, TipTac and Prat. These changes need `/reload`.
  * **Appearance**:
    * button gradients
    * backdrop opacity
    * a custom highlight color
    * the talent art background and the hero talent anchor presets
    * the **Color Mode** preset, one of **Normal**, **HDR**, **Deuteranopia**, **Protanopia** or **Tritanopia**

    Color Mode changes apply live.
  * **Privacy & Analytics**: turn WagoAnalytics reporting on or off. Aurora sends analytics only while this is on.
  * **Performance**: choose the Lua garbage collection mode:
    * **Smooth** (the default) runs frequent small collection passes.
    * **Default** uses standard Lua behaviour.
    * **Combat Pause** stops collection during combat.

    The change applies at once. A host addon can call `Aurora.ApplyGCMode` / `Aurora.GetGCMode` to change the mode itself.

Settings are saved in `AuroraConfig`. Values are validated on load, and old keys are migrated to their current names.


Slash Commands
--------------

  * `/aurora` - open the options panel.
  * `/aurora help` - list the commands.
  * `/aurora status` - show configuration, compatibility, analytics and integration status.
  * `/aurora debug` - show the debug log (needs LibTextDump).
  * `/aurora skinaudit` - list the skins that failed to apply this session, with the client build and interface version.
  * `/aurora reset` - reset the configuration to defaults (then `/reload`).
  * `/aurora insertframe` - dev A/B toggle; see Developer Notes.
  * `/aurora mawbuffs` - dev A/B toggle; see Developer Notes.

The options panel and slash commands live in `gui.lua`. An embedding host usually includes only `Skin\skin.xml` and a flavor manifest, so `/aurora` does not exist there and the host supplies its own options UI. Under RealUI, `RealUI_Skins` stores `AuroraConfig` per profile and mirrors the dev toggles as `/auroraInsertFrame` and `/auroraMawBuffs`.


Layout
------

  * `Skin/`: the engine and its public API (`Aurora.Base`, `Aurora.Skin`, `Aurora.Hook`, `Aurora.Color`, `Aurora.Theme`, `Aurora.Util`). `Skin/init.lua` sets the flavor flags (`private.isRetail`, `isForever`, `isMists`, `isBCC`, `isVanilla`, …).
  * `Skin/Interface/AddOns/`: one folder per Blizzard addon, holding the per-flavor skins (`Mainline\`, `Camelot\`, `Classic\`, `TBC\`, `Mists\`, `Vanilla\`), and the generated `AddOns_<Flavor>.xml` manifests.
  * `Skin/shared/`: skin bodies shared across flavors. Each flavor calls them through a thin wrapper.
  * `config.lua`, `compatibility.lua`, `analytics.lua`, `integration.lua`, `aurora.lua`, `gui.lua`: configuration, conflict detection, analytics consent, error handling, startup, and the options UI.
  * `dev/`: tooling for developers. The packager leaves this folder out.

**Never edit the manifests by hand.** Regenerate them with `dev/updatexmls.py`. The script resolves each client's TOCs against the `wow-ui-source*` checkouts next to the repo, and it also reports:

  * skin templates a flavor calls but never registers
  * positional `select(n, ...)` child picks that break when a client adds a child

`dev/forever_report.py` rebuilds the gap analysis between Camelot and Mainline.

Every skin runs inside `pcall`. A skin written for frames that a client lacks therefore fails without an error message. After logging in on a new or updated client, run `/aurora skinaudit` to get the list of skins to fix.


Developer Notes
---------------

**`GameTooltip_InsertFrame`**: Aurora replaces this global. Its version differs from Blizzard's original in two ways:

  * It passes the two `Round()` inputs through a `SafeNumber()` guard.
  * It nil-guards `GetLeftLine(2)`. Blizzard's original indexes that line without a check, and it errors on tooltips that have fewer than two lines.

Replacing a global has a cost: the global is then tainted for every secure caller. Blizzard's `Blizzard_ItemUpgradeUI` reads this global inside `PlayUpgradedCelebration()`, one line before `C_ItemUpgrade.UpgradeItem()`. The upgrade is therefore blocked whenever an item's effect text is long enough to reach the truncation branch.

`/aurora insertframe` toggles `AuroraConfig.devRestoreInsertFrame`. With it on, Aurora runs Blizzard's original, so you can test the affected surfaces and find out whether the replacement is still needed:

  * LootHistory "all passed" tooltip (most likely to need the nil-guard)
  * Professions reagent and reward tooltips
  * Delve widget-set tooltips
  * Garrison mission threat tooltips
  * Quest-offer map pin tooltips
  * Trinket upgrades in the item upgrade window

The toggle takes effect after `/reload`. While the replacement is off, Aurora prints a notice at load, so test runs are not misread.

**`ShouldShowMawBuffs`**: Aurora wraps this global so that it returns `false` while `C_Secrets.ShouldAurasBeSecret()` is true. Blizzard's version calls `C_UnitAuras.GetAuraDataByIndex("player", 1, "MAW")` without a guard. Under WoW 12's secret-aura rules, that call throws once addon code is running in the same execution. All three callers are inside the objective tracker's update and layout code, so the throw broke the delve and LFR stage blocks partway through layout.

This wrapper has the same taint cost, on a more frequently called path. The scenario tracker's `UNIT_AURA` handler reads the global, so every aura update carries Aurora's taint. In one 4.0.1 field log, this taint made up a quarter of all taint-log lines.

`/aurora mawbuffs` toggles `AuroraConfig.devRestoreMawBuffs`. With it on, Aurora leaves Blizzard's original in place, so you can measure whether the wrapper is still needed. To test:

  1. Run an LFR wing and a delve with the objective tracker visible, once with the wrapper off and once with it on.
  2. Compare the error counts and taint logs from the two runs.

The toggle takes effect after `/reload`. While the wrapper is off, Aurora prints a notice at load.


Bug Reports
-----------

Please report issues on [GitHub](https://github.com/RealUI/Aurora).
For support, discussion and quick troubleshooting help, join the [RealUI Discord](https://discord.gg/sasExJYxgf).
