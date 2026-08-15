Aurora
======

Aurora is a Blizzard UI skinning addon focused on a clean, consistent visual style across default interface panels and frames.

It is maintained for current Retail WoW and can run standalone or embedded (for example inside RealUI_Skins).

Information
-----------

  * Current development target is WoW 12.1.x.
  * Aurora includes a live Color Mode system with Normal, HDR, and accessibility presets.
  * Skinning updates prioritize taint-safe hooks and compatibility with Blizzard UI changes.


Quick Start
-----------

  * Type `/aurora` to open options.
  * Use Appearance settings to switch Color Mode presets.
  * Type `/aurora status` to print runtime status details.


Slash Commands
--------------

Aurora provides one base slash command with subcommands:

  * `/aurora` - open configuration panel.
  * `/aurora help` - show available commands.
  * `/aurora status` - show configuration/compatibility/integration status.
  * `/aurora debug` - show debug output (requires LibTextDump).
  * `/aurora reset` - reset Aurora configuration to defaults.
  * `/aurora insertframe` - diagnostic; see Developer Notes below.

Slash commands live in `gui.lua`, which is only loaded when Aurora runs
standalone. Hosts that embed Aurora typically include just the skin XML, so
`/aurora` is unavailable there and the host supplies its own options UI.


Developer Notes
---------------

**`GameTooltip_InsertFrame`** — Aurora replaces this global. The replacement differs
from Blizzard's original in two ways: it routes the two `Round()` inputs
through a `SafeNumber()` guard, and it nil-guards `GetLeftLine(2)`, which
Blizzard indexes unconditionally and which errors on tooltips with fewer than
two lines.

Owning a global has a cost: it is tainted for every secure reader. Blizzard's
`Blizzard_ItemUpgradeUI` reads this global inside `PlayUpgradedCelebration()`,
one line before `C_ItemUpgrade.UpgradeItem()`, so the upgrade is blocked
whenever an item's effect text is long enough to reach the truncation branch.

`/aurora insertframe` toggles `AuroraConfig.devRestoreInsertFrame` to run
Blizzard's original instead, so the affected surfaces can be exercised to
determine whether the replacement is still required:

  * LootHistory "all passed" tooltip (most likely to need the nil-guard)
  * Professions reagent and reward tooltips
  * Delve widget-set tooltips
  * Garrison mission threat tooltips
  * Quest-offer map pin tooltips
  * Trinket upgrades in the item upgrade window

Requires `/reload` to apply. When the replacement is disabled, Aurora prints a
notice at load so test runs are not misattributed.

Under RealUI, `RealUI_Skins` embeds Aurora and mirrors this toggle as
`/auroraInsertFrame`, writing to the same `AuroraConfig` key via its own
profile store.


Bug Reports
-----------

Please report issues on [GitHub](https://github.com/Gethe/Aurora).
For support, discussion, and quick troubleshooting help, join the [RealUI Discord](https://discord.gg/sasExJYxgf).
