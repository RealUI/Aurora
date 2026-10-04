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

The options panel and slash commands live in `gui.lua`. An embedding host usually includes only `Skin\skin.xml` and a flavor manifest, so `/aurora` does not exist there and the host supplies its own options UI. Under RealUI, `RealUI_Skins` stores `AuroraConfig` per profile.


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

**`GameTooltip_InsertFrame`**: Aurora does not replace this global, and should not. Releases up to 12.1.0.12 replaced it to guard secret `Round()` inputs on the loot history roll tooltips. The cost was trinket upgrades: the replacement wrote `insertedFrames` on the item upgrade preview tooltip, and on confirm Blizzard read that tainted field one call before `C_ItemUpgrade.UpgradeItem()`, which was then refused for any item whose effect text reached the truncation branch. The secret values only appeared because the loot history already ran tainted, from Aurora's own overrides there, which are gone. An A/B with Blizzard's original confirmed both sides: trinket upgrades go through and the LFR loot history is clean.

**`ShouldShowMawBuffs`**: Aurora wraps this global so that it returns `false` while `C_Secrets.ShouldAurasBeSecret()` is true. Blizzard's version calls `C_UnitAuras.GetAuraDataByIndex("player", 1, "MAW")` without a guard, and that call throws when auras are secret and the execution is tainted. Its callers are inside the objective tracker's update and layout code, so the throw breaks the delve and LFR stage blocks partway through layout. Owning the global has a taint cost on the scenario tracker's `UNIT_AURA` path. The wrapper was removed once after several clean runs, and the error returned in the next delve, so clean runs do not show it is unneeded. It can go once the objective tracker skin stops tainting that layout code.


Bug Reports
-----------

Please report issues on [GitHub](https://github.com/RealUI/Aurora).
For support, discussion and quick troubleshooting help, join the [RealUI Discord](https://discord.gg/sasExJYxgf).
