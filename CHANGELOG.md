## [12.0.7.0] ##
### Added ###

  * add: skin `Blizzard_ExpansionLandingPage`

### Changed ###

  * chg: update progress bar style for dialogs with countdown timers
  * chg: guard `Blizzard_ProfessionsCustomerOrders` tab layout against third-party tab insertions and layout modifications

### Fixed ###

  * fix: hide `TradeRecipientBG` white overlay that made the recipient side of the trade frame appear lighter


## [12.0.5.13] ##
### Fixed ###

  * fix: remove `UIWidgetBaseStatusBarTemplateMixin.InitPartitions` replacement — writing an addon-owned slot on the mixin taints the execution context when nameplate widgets call it from the secure `OnNamePlateAdded` path, causing `GetScaledRect()` to fail


## [12.0.5.12] ##
### Fixed ###

  * fix: track skinned `UIWidget` frames in a separate weak-key table instead of writing `_auroraSkinned` onto the frame to prevent `GetScaledRect()` taint in the secure `OnNamePlateAdded` path
  * fix: remove `SetPoint` and `SetHeight` calls from `QueueStatusEntry` hooks — layout writes on pool entry sub-frames taint frame geometry and crash `QueueStatusEntry_SetMinimalDisplay`


## [12.0.5.11] ##
### Fixed ###

  * fix: remove `MapCanvasScrollControllerMixin` method replacements — direct writes to the mixin table tainted every frame using it, causing `SetPropagateMouseClicks` to fail in the secure pin-acquisition path (`secureexecuterange → AcquirePin → OnAcquired → UpdateMousePropagation`)
  * fix: skip nameplate health/cast bar skinning entirely — `Base.SetBackdrop` writes onto restricted nameplate bar frames, tainting them; that taint propagated into `CompactUnitFrame_UpdateHealPrediction` causing `GetMinMaxValues()` to return "secret number value" errors
  * fix: guard nameplate units in `CompactUnitFrame_UpdateHealthColor` hook — calling `SetStatusBarColor` on nameplate bars tainted the execution context and caused `GetMinMaxValues()` in `UpdateHealPrediction` to return "secret number value" errors
  * fix: remove `GameTooltip_AddWidgetSet` global wrapper — replacing the global with an addon-owned function tainted execution before `RegisterForWidgetSet`, causing `GetUnscaledFrameRect` → `GetScaledRect` to return secret values in widget layout
  * fix: remove `UIWidgetContainerMixin.CreateWidget` global `hooksecurefunc` — callbacks fired inside `CreateWidget` propagated taint into the synchronous `UpdateWidgetLayout → DefaultWidgetLayout → GetScaledRect` call chain for tooltip widget containers


## [12.0.5.10] ##
### Fixed ###
  * fix: skip UIWidget skinning for nameplate `WidgetContainer` to prevent `GetScaledRect` taint in the secure `OnNamePlateAdded` call chain
  * fix: use `Color.button` for inactive `TabSystemButton` tabs so borders remain visible
  * fix: use `Color.button` for inactive Achievement tabs so borders remain visible
  * fix: use `Color.button` for inactive Garrison mission tabs so borders remain visible
  * fix: use `Color.button` for inactive Garrison landing page tabs so borders remain visible


## [12.0.5.9] ##
### Changed ###
  * chg: update TOC for WoW 12.0.7 (120007)

### Fixed ###
  * fix: remove `UpdatePresence` mixin to eliminate `CommunitiesMemberList` taint
  * fix: remove `securecallfunction` wrapper from `GameTooltip_AddWidgetSet` to fix tooltip arithmetic taint ([#178])
  * fix: make `Skin.StatusTrackingBarTemplate` taint-safe ([#178])
  * fix: make `UIWidgetBaseStatusBarTemplate` taint-safe; guard `InitPartitions` bar width with `SafeNumber`
  * fix: use `Color.button` for inactive panel tabs so borders remain visible


## [12.0.5.8] ##
### Fixed ###
  * fix: replace circular CDM cooldown swipe with plain square texture so the overlay covers the full cropped icon area
  * fix: re-apply icon texcoord crop after CDM refreshes the spell texture (`SetTexture` resets coords to 0–1)
  * fix: prevent C stack overflow in SpellBook spec-button border hooks by removing recursive `SetTexture(nil)` calls


## [12.0.5.7] ##
### Changed ###
  * chg: overhaul Blizzard_CooldownViewer skinning in preparation for RealUI_Auras, including robust mixin hooks, viewer child re-skinning on show, icon mask/overlay cleanup, and BuffBar visual restyling
  * chg: use full `Skin.ButtonFrameTemplate` pass for CooldownViewerSettings to align with ButtonFrameTemplate visuals
  * chg: refresh README documentation

### Fixed ###
  * fix: increase HDR mode button brightness to improve visibility against darker panel backgrounds


## [12.0.5.6] ##
### Fixed ###
  * fix: guard `private.Integration` nil check in `Color.SetMode` to prevent errors when called before Integration is initialised


## [12.0.5.5] ##
### Added ###
  * add: **Color Mode system** — switch between named palette presets that control the neutral UI palette (backgrounds, borders) and modulate the class color highlight. All switching is live, no reload required.
  * **Normal** — default Aurora look, unchanged from previous versions
  * **HDR** — deeper blacks, more opaque panels, brighter borders for high-contrast displays
  * **Deuteranopia / Protanopia / Tritanopia** — accessibility modes that shift the class color highlight hue to compensate for color vision deficiencies
  * add: `Color.border` token for UI element borders, used by the mode system
  * add: `Color.SetMode`, `Color.GetActiveMode`, `Color.PreviewMode` API for programmatic mode switching
  * add: color mode radio selector in the Appearance options panel
  * add: HDR info note in options when HDR boost is inactive due to custom highlight override
  * add: palette element tracking system — 500+ frames auto-refresh on mode switch with smart border preservation
  * add: scrollable Appearance options panel to accommodate the new color mode selector


### Changed ###
  * chg: TalkingHeadUI background now uses `Color.panelBg` token instead of lightened `Color.frame` — darker on Normal, true black on HDR ([#177])
  * chg: color consistency audit — replaced hardcoded color values across skin files with `Color.*` tokens; annotated intentionally static colors

### Fixed ###
  * fix(tooltip): make SetTooltipMoney workaround load-order safe ([#176])
  * fix: guard nil dropdown skin calls in FriendsFrame and PlayerSpells


## [12.0.5.4] ##
### Added ###
  * add: skin for Blizzard_FrameXML TalkingHeadUI

### Changed ###
  * chg: update LFGDungeonReadyStatus skinning pass
  * chg: refine icon skinning in MacroUI


### Fixed ###
  * fix: make DelvesCompanionConfigurationFrame skin non-transparent
  * fix: add defensive guard for SendMailFrame.SendMailAttachments ([#174])
  * fix: apply startup UI scale on login
  * fix: make standalone mode reliably skin delayed Blizzard addon loads ([#175])
  * fix: ensure setup popup waits for UI skinning to complete in standalone mode ([#175])


## [12.0.5.3] ##
### Fixed ###
  * fix: prefer base spell texture for PlayerSpells spec icons
  * fix: prevent UIWidget container taint in restricted layout paths
  * fix: wrap GameTooltip_AddWidgetSet in securecallfunction to avoid LayoutFrame secret-number taint
  * fix: prevent PaperDoll stat taint from CharacterFrame skinning
  * fix: use SharedButtonSmallTemplate for dialog buttons (12.0.5)


## [12.0.5.2] ##
### Fixed ###
  * fix: avoid QueueStatusFrame taint by no longer skinning the protected tooltip backdrop directly; queue entries are still skinned via the entry pool
  * fix: protect backdrop vertex coloring on WoW 12.0.5 by converting Aurora Color objects to Blizzard color objects before SetVertexColor


## [12.0.5.1] ##
### Fixed ###
  * fix: handle MovieFrame CloseDialog button nesting change — buttons moved into CloseDialog.Buttons HorizontalLayoutFrame wrapper
  * fix: guard OpenMailFrameIcon removed in 12.0.5 MailFrame update — portrait now managed by ButtonFrameTemplate
  * fix: guard CharacterBag0Slot-CharacterBag3Slot removed from Mainline XML — bags now dynamically created by BagsBarMixin


## [12.0.5.0] ##
### Changed ###
  * chg: bump ## Interface to 120005

### Fixed ###
  * fix: handle MovieFrame CloseDialog button nesting change — buttons moved into CloseDialog.Buttons HorizontalLayoutFrame wrapper
  * fix: guard OpenMailFrameIcon removed in 12.0.5 MailFrame update — portrait now managed by ButtonFrameTemplate
  * fix: guard CharacterBag0Slot-CharacterBag3Slot removed from Mainline XML — bags now dynamically created by BagsBarMixin


## [12.0.1.31] ##
### Changed ###
  * chg: make TextStatusBarText and TextStatusBarTextLarge use outlined fonts

### Fixed ###
  * fix: remove ExternalDefensivesFrame container backdrop to prevent an always-visible empty bar
  * fix: hide LootHistory BackgroundArtFrame textures so item names remain visible


## [12.0.1.30] ##
### Added ###
  * add: skin for Blizzard_HouseEditor — 6-mode editor, deferred mode-frame skinning, hooksecurefunc-only, IsForbidden() guards
  * add: skin for Blizzard_HouseList — house entry list with expand/collapse backdrop hooks
  * add: skin for Blizzard_HousingBulletinBoard — roster list, column headers, invite dialog, pendingInvitesPool wrap
  * add: skin for Blizzard_HousingCharter — charter creation, signaturePool wrap, request signature dialog
  * add: skin for Blizzard_HousingCornerstone — tabbed panel with TabSystem skinning, confirmation dialogs
  * add: skin for Blizzard_HousingCreateNeighborhood — charter and guild neighborhood creation dialogs
  * add: skin for Blizzard_HousingHouseFinder — neighborhood button pools, map canvas border hiding
  * add: skin for Blizzard_HousingHouseSettings — access dropdowns, checkboxes, abandon house dialog
  * add: skin for Blizzard_HousingModelPreview — PortraitFrame with ModelScene left unskinned
  * add: skin for Blizzard_HousingMarketCart — cart items/bundles, CropIcon on icons, FullUpdate re-skin hook
  * add: skin for Blizzard_HousingPhotoSharing — photo preview and browser panels
  * add: skin for Blizzard_GenericShoppingCart — base ShoppingCartVisualsFrameTemplate for all cart consumers
  * add: skin for Blizzard_Subtitles — minimal backdrop with reduced alpha for readability

### Changed ###
  * update: register 13 AddOn skins in AddOns_Mainline.xml — Midnight housing feature complete

### Fixed ###
  * fix: use DefaultPanelTemplate instead of PortraitFrameTemplate for ButtonFrameTemplateNoPortrait frames (HousingCornerstone, HousingPhotoSharing browsers)
  * fix: replace Util.HideNineSlice with direct region hiding for GenericShoppingCart Background NineSlice
  * fix: replace AcquireTab hooksecurefunc with SetTab hook on TabSystemOwner for HouseEditor StoragePanel tabs


## [12.0.1.29] ##
### Added ###
  * add: skin for Blizzard_AlliedRacesUI — race info overlay and abilities
  * add: skin for Blizzard_AutoCompletePopupList — chat autocomplete popup
  * add: skin for Blizzard_ClassTrial — trial dialog and timer, no font mods
  * add: skin for Blizzard_ClickBindingUI — click binding config dialog
  * add: skin for Blizzard_ContentTracking — tracking checkmark guard
  * add: skin for Blizzard_CovenantToasts — covenant choice and renown toasts
  * add: skin for Blizzard_CustomizationUI — character customization frame
  * add: skin for Blizzard_DelvesToast — delves completion toast
  * add: skin for Blizzard_ExpansionTrial — expansion trial checkpoint dialog
  * add: skin for Blizzard_GenericTraitUI — generic trait frame decorations
  * add: skin for Blizzard_GuildRename — guild rename dialog
  * add: skin for Blizzard_ItemBeltFrame — quick-use item belt bar
  * add: skin for Blizzard_MajorFactions — renown and unlock toasts
  * add: skin for Blizzard_NamePlates — health/cast bars, aura icons, hooksecurefunc only
  * add: skin for Blizzard_ObliterumUI — Legion obliterum forge
  * add: skin for Blizzard_PerksProgram — Trading Post product browser
  * add: skin for Blizzard_PlunderstormPrematchUI — Plunderstorm lobby
  * add: skin for Blizzard_ProfessionsCustomerOrders — crafting order panels
  * add: skin for Blizzard_QuestTimer — timed quest countdown frame
  * add: skin for Blizzard_QuickKeybind — keybind dialog, tooltip untouched
  * add: skin for Blizzard_RemixArtifactUI — MoP Remix artifact talent frame
  * add: skin for Blizzard_ReportFrame — player report dialog
  * add: skin for Blizzard_RuneforgeUI — Shadowlands legendary crafting
  * add: skin for Blizzard_SharedTalentUI — talent tree nodes and frame
  * add: skin for Blizzard_StableUI — pet stable management panel

### Changed ###
  * update: register 25 AddOn skins in AddOns_Mainline.xml

### Fixed ###
  * fix: guard NameFrame nil in LargeItemButtonTemplate for PVP loot buttons
  * fix: taint-safe PVP queue/join button skinning to prevent JoinBattlefield ADDON_ACTION_FORBIDDEN


## [12.0.1.28] ##
### Added ###
  * add: skin for Blizzard_DamageMeter — EditMode child-visual-only with ScrollBox entry skinning
  * add: skin for Blizzard_EncounterTimeline — EditMode child-visual-only with EventRegistry callback
  * add: skin for Blizzard_EncounterWarnings — EditMode child-visual-only, no SetAttribute/GetStringWidth
  * add: skin for Blizzard_CooldownViewer — EditMode child-visual-only with external weak table for taint-safe skinned state
  * add: skin for Blizzard_BuffFrame — hooksecurefunc-only approach for taint-sensitive aura update paths
  * add: skin for Blizzard_MatchmakingQueueDisplay — queue type buttons, ready/leave buttons
  * add: skin for Blizzard_EndOfMatchUI — 3 pool wraps with PVPMatch color coordination
  * add: skin for Blizzard_PersonalResourceDisplay — health/power/alternate StatusBars with Util.Mixin re-skin hooks
  * add: skin for Blizzard_SpellDiminishUI — trayItemPool wrap via Util.Mixin
  * add: skin for Blizzard_WorldLootObjectList — ScrollBox acquired frame callback
  * add: skin for Blizzard_CombatLog — quick-filter buttons and filter bar backdrop
  * add: skin for Blizzard_ScriptErrorsFrame — UIPanelDialogTemplate dialog with nav/action buttons
  * add: skin for Blizzard_HelpPlate — hooksecurefunc on HelpPlate.Show for dynamic tiles
  * add: skin for Blizzard_DelvesCompanionConfiguration — config slots, ability list, paging controls

### Fixed ###
  * fix: CooldownViewer taint — use external weak table instead of writing _auroraSkinned on item frames to avoid tainting secure cooldown/aura update paths
  * fix: CooldownViewer EnumeratePools crash — categoryPool is a plain table, not a FramePoolCollection
  * fix: CooldownViewer CharacterSpecificLayoutCheckButton — target inner .Button child instead of wrapper frame for Skin.FrameTypeCheckButton


## [12.0.1.27] ##
### Added ###
  * add: Util.SkinOnce helper and convert 30 guard patterns
  * add: Base.CropCircularIcon to consolidate circular icon cropping
  * add: Util.SetHighlightColor to consolidate highlight color texture calls

### Changed ###
  * ci: trim CHANGELOG.md to current version section for GitHub releases

### Fixed ###
  * fix: replace GetBackdrop call with _auroraSkinned check to prevent nil method error in combat


## [12.0.1.26] ##
### Added ###
  * add: Hero Talents anchor preset dropdown to config with preset-based positioning
  * add: optional HeroTalentsContainer custom re-anchor with default-off per-character behavior

### Changed ###
  * chg: additional tuning for heroTalentsAnchorPreset
  * chg: updated AddOns_Mainline.xml with data from wow-ui-sources
  * chg: ignore Mists TOC types when running on live branch
  * chg: removed deprecated Blizzard_UIMenu code

### Fixed ###
  * fix: restore backdrop alpha transparency in Base.SetBackdropColor (#171)
  * fix: re-parent item Name into bg frame to fix hidden text
  * fix: move MainMenuBarBagButtons skin to standalone Blizzard_MainMenuBarBagButtons addon
  * fix: move TabSystemTemplates.lua to Shared/TabSystem/ to match Blizzard restructure
  * fix: unused file detection in updatexmls.py — scope bug, stale addon, remove XML fallback


## [12.0.1.25] ##
### Changed ###
  * chg: continued work on PVPMatchResults skin

### Fixed ###
  * fix: replace securecallfunction wrapper with SafeNumber reimplementation for GameTooltip_AddWidgetSet to avoid secret-number taint
  * fix: remove securecallfunction branches and sanitize orderIndex after Setup calls
  * fix: wrap QuestMapLogTitleButton_OnEnter in securecallfunction to prevent GetStringWidth secret number taint
  * fix: SafeNumber for all InsertFrame tooltip paths and LootHistory tooltip line layout
  * fix: pass RGBA values to backdrop APIs instead of Aurora Color objects
  * fix: Aurora NineSlice layout resolution for tooltip backdrop hooks


## [12.0.1.24] ##
### Fixed ###
  * fix: update DelvesDifficultyPicker to skin its dropdown with DropdownButton instead of the old WowStyle1DropdownTemplate
  * fix: stop skinning pooled QuestMapFrame title rows to avoid tooltip-owner taint in the quest log


## [12.0.1.23] ##
### Fixed ###
  * fix: call GameTooltip_AddWidgetSet via securecallfunction to prevent secret layoutIndex taint on delve tooltip hide
  * fix: removed taint from titleFramePool
  * fix: AdventureMapFrame nil error by hooking AdventureMapMixin:OnLoad for pool wrap


## [12.0.1.22] ##
### Fixed ###
  * fix: race condition in VisitHouse
  * fix: protect against AuroraConfig being nil on embedded Aurora


## [12.0.1.21] ##
### Added ###
  * add: skins for Blizzard_CovenantCallings, Blizzard_DelvesDifficultyPicker, Blizzard_HousingControls, Blizzard_HousingTemplates, and PVP match results

### Changed ###
  * chg: expand pooled-frame skinning across housing dashboard rewards, weekly rewards extra items, adventure map widgets, quest map frames, queue status entries, chat config tabs, campaign headers, and transmog collection/set buttons
  * chg: consolidate pooled frame acquisition helpers into Util.WrapPoolAcquire and remove the obsolete WardrobeOutfits shim
  * chg: stop touching CommunitiesListEntryTemplate buttons at runtime to keep Communities skinning combat-safe

### Fixed ###
  * fix: taint-safe tooltip status/progress bar skinning and securecallfunction wrapping for DefaultWidgetLayout to avoid UIWidget secret-number layout errors (WoWUIBugs[#811])
  * fix: replace SetTooltipMoney with GetCoinTextureString to avoid MoneyFrame secret-number taint in tooltips (WoWUIBugs[#801])
  * fix: remove taint-unsafe ChannelRoster skinning that could break voice activity notifications
  * fix: make VehicleLeaveButton and TaintSafeUIPanelButtonTemplate skinning safe, and align auxiliary/zone ability cooldown overlays
  * fix: follow wardrobe custom set renames and guard campaign header/map canvas edge cases


## [12.0.1.20] ##
### Added ###
  * add: GUI toggles for character sheet, objective tracker, and talent background skins ([#151], [#158], [#160])
  * add: Color.panelBg constant and unified panel background colors ([#155])
  * add: SetSize clamping hook to crafting order tabs ([#167])
  * add: config and compatibility foundations ([#151], [#158], [#160], [#167])

### Changed ###
  * chg: gate character sheet skin on config toggle ([#151])
  * chg: gate objective tracker skin on config toggle ([#158])
  * chg: gate talent background hiding on config toggle ([#160])
  * chg: clamp PlayerChoice frame to screen bounds ([#164])
  * chg: reduce border width on Achievement and Loot frames ([#157])
  * chg: talentArtBackground defaults to true


## [12.0.1.19] ##
### Changed ###
  * chg: Add taint-safe frame skinning for high-risk protected-function frames (ItemUpgrade, ItemInteraction, Scrapping, AzeriteEssence, AzeriteUI)
  * chg: call Base.CropIcon(texture) without the parent argument to avoid tainting button geometry

### Fixed ###
  * fix: nil texture name crash in ClubFinder role icons and SetTexture assertion
  * fix: move CUSTOM_CLASS_COLORS early-return guard below private definitions so they're always available to host addons
  * fix: duplicate scale message on login in dev mode
  * fix: remove GetUnscaledFrameRect override that tainted GameMenu secure callback path [#166]
  * fix: taint-safe replacement for GameTooltip_AddWidgetSet in SharedTooltipTemplates.lua
  * fix: taint-safe status bar skinning to prevent OverlayPlayerCastingBarFrame taint propagating into action bar secure execution path


## [12.0.1.18] ##
### Changed ###
  * chg: stop aroura from doing any scaling when a host addon is handling scaling..


## [12.0.1.17] ##
### Fixed ###
  * fix: UIWidgetContainerMixin is tainting again
  * fix: replace GameTooltip_InsertFrame to avoid taint
  * fix: replaced $$$$%%%%$$$$$ to just #'s


## [12.0.1.16] ##
### Added ###
  * add: configurable GC tuning modes (smooth / default / combat-pause) to reduce microstutter — selectable in Aurora settings UI
  * add: object pooling for Color objects and backdrop tables, plus a reusable NineSlice layout, to eliminate per-frame table allocations feeding GC pressure
  * add: GC settings UI available in both Aurora standalone config and when used with other addons


## [12.0.1.15] ##
### Fixed ###
  * fix: attempt to fix potentional stutter issues when using large amount of memory.. GC is an issue
  * fix: taint safe skinning of  LFGPVP Join Battle button..
  * fix: taint-safe Blizzard_Communities skin — remove FrameTypeButton/CreateTexture/SetBackdrop from list entries and ScrollBox, guard UpdatePresence with InCombatLockdown()
  * fix: more attempts of fixing taints in tables for widgets


## [12.0.1.14] ##
### Fixed ###
  * fix: attempt to fix [#149]
  * fix: another attempt on uiwidgets fixes


## [12.0.1.13] ##
### Added ###
  * add: skinning of VehicleLeaveButton [#125]

### Fixed ###
  * fix: PlayerChoice frames being too high (Worldsoul Memories) [#156]
  * fix: Tradeskills screen with addon TradeSkillFluxCapacitor buttons out of bonds [#154]
  * fix: skin of custom tabs in QuestMapFrame.... and removed border from Tabs
  * fix: VehicleLeaveButton skinning [#125]


## [12.0.1.12] ##
### Fixed ###
  * fix: Widget containers parented to a GameTooltip must NOT be skinned.
  * chg: somewhat taint safe Blizzard_WorldMap -- until we allow it to be moved...
  * fix: QuestMapFrame Tabs to be skinned and not repositioned..
  * fix: more taint fixes for tooltips
  * fix: trying to make GameTooltip taint safe


## [12.0.1.11] ##
### Fixed ###
  * fix: Revert GetUnscaledFrameRect global replacement — overwriting this global taints every LayoutFrame call, causing massive CooldownViewer combat taint.

## [12.0.1.10] ##
### Fixed ###
  * fix: Protect GetUnscaledFrameRect against secret (tainted) values from GetScaledRect.
  * fix: ADDON_LOADED contaminates the execution context that feeds into the action bar initialization chain.

## [12.0.1.9] ##
### Added ###
  * add: skin for Blizzard_Transmog
  * add: three new reusable Skin.* functions to SharedUIPanelTemplates.lua: Skin.InputBoxNineSliceTemplate, Skin.InputBoxInstructionsNineSliceTemplate and Skin.SearchBoxNineSliceTemplate

### Changed ###
  * chg: cleaned up Blizzard_Communities
  * chg: Replaced deprecated calls with current API in AdventureMap skin.

### Fixed ###
  * fix: another taint in communitiesListScrollBox
  * fix: only hide ScrollBar borders when they exist
  * fix: safeguarding possible taints from in-combat issues
  * fix: replacing more out of date calls
  * fix: deprecated ui calls


## [12.0.1.8] ##
### Fixed ###
  * fix: possible "Texture:SetTextCoord(): Cannot set tex coords when texture has mask" error
  * fix: Aurora.test loot windows and roll behavior
  * fix: additional Aurora Test Loot fixes
  * fix: update "Running on" UI information
  * fix: Blizzard_BlackMarketUI and gfx crash


## [12.0.1.7] ##
### Added ###
  * add: Blizzard_HousingDashboard skin
  * add: skin for EventToastManager

### Fixed ###
  * fix: another tain in UIWidgets
  * fix: hooking of alerts
  * fix: for uiscale
  * fix: random taints
  * fix: uiScale taints
  * fix: error in Blizzard_CompactRaidFrames
  * fix: updates to Blizzard_HousingDashboard


## [12.0.1.6] ##
### Fixed ###
  * fix: skinning of BankFrame
  * fix: skins for PVEFrame tabs
  * fix: Blizzard_AddOnList - skinning AddonList entries
  * fix: skin - replace removed convertToGroup/convertToRaid with new settings button in CompactRaidFrameManager
  * fix: removed dead code from GossipFrame
  * fix: AlertFrameSystem - updated to cover all 31 alert systems (up from 8)
  * fix: safeguard Util.Mixin
  * fix: RecruitAFriendRewardsFrame.rewardPool can no longer use ObjectPoolMixin
  * fix: ZoneAbilityFrameTemplate
  * fix: replacement of dead Hook.ObjectPoolMixin with proper acquires
  * fix: removed deprecated Wardrobe code from Collections
  * fix: ArchaeologyUI fixes
  * fix: skinning of AchievementUI was incomplete
  * fix: cleaned up deprecated code in Blizzard_ArchaeologyUI
  * fix: Blizzard_TimeManager to no longer use deprecated APIs
  * fix: skin StopwatchResetButton/StopwatchPlayPauseButton from Blizzard_TimeManager
  * fix: SpecificScrollBox taint
  * fix: LFD/LFG/LFR fixes for Frames/RaidFinder
  * fix: partly fixed taint bug in the Blizzard_Communities - Guild Finder
  * fix: instanceButton gets garbled by DropIcon
  * fix: updated ObjectiveTracker for WOW11+
  * fix: Blizzard_StaticPopup_Game_GameDialog updated for WOW12
  * fix: Blizzard_ActionBarController updated for wow12
  * fix: updated OrderHallUI for wow12
  * fix: Blizzard_AuctionHouseUI for wow12
  * fix: updated Blizzard_Collections for wow12
  * fix: updated Blizzard_Collections ToggleDynamicFlightFlyoutButton
  * fix: LFGList menus
  * fix: added fixes to FriendsFrame

### Changed ###
  * chg: update for wow12 compatibility
  * chg: cleanup deprecated compatibility API from deprecated.lua
  * chg: cleaned up Blizzard_UIPanels_Game QuestMapFrame

### Removed ###
  * removed: Hook.ObjectPoolMixin removed in 11.0.0 (private API), no replacement
  * removed: Blizzard_SharedXMLBase\Pools.lua - dead code
  * removed: unused and outdated code from Blizzard_Calendar

## [12.0.1.5] ##
### Added ###
  * add: skinning Blizzard_Professions
  * add: skinning of all Blizzard_PlayerSpells panels
  * add: skinning of PlayerChoice

### Fixed ###
  * fix: arrow down on dropdown buttons
  * fix: skinned Blizzard_ProffesionsBook
  * fix: don't skin CommunitiesList ScrollBox to prevent SetAvatarTexture taint
  * fix: backdrops and playchoice fixes
  * fix: skinning of all Blizzard_PlayerSpells panels
  * fix: SpellBookFrame skinned properly
  * fix: skinning of PlayerChoice

### Removed ###
  * removed: Blizzard_PlayerSpellsFrame.lua duplicates Blizzard_PlayerSpells.lua

## [12.0.1.4] ##
### Fixed ###
  * fix: use SetAlpha(0) instead of Hide() on LFG InfoBackground
  * fix: Lua error ui widget [#146]
  * fix: Error on certain mouseovers that impacts mouseover tooltips afterwards [#147]
  * fix: quit catch-up button doesn't show up [#148]
  * fix: fixed error "calling 'SetAlpha' on bad self" when nameplate widget containers are registered with pooled/recycled frames (Blizzard_UIWidgets) [#139]
  * fix: isMidnight starts with 12.0.0

### Changed ###
  * chg: remove isPatch as it is no longer used


## [12.0.1.3] ##

** wrongly tagged **

## [12.0.1.2] ##
### Fixed ###
  * fix: Protect from calling GetStatusBarTexture on invalid objects
  * fix(aurora): guard backdrop setup on forbidden/invalid frames to prevent NineSlice CreateTexture crashes in UIWidgets/nameplates
  * fix: Updated DeathRecap skin for WoW 12 API changes
  * fix: Wrapped debug name handling to safely process tainted/secret strings from WoW API values


### Changed ###
  * chg: Added Blizzard_PlayerSpells skinning and follow-up cleanup
  * chg: Updated Aurora options menu
  * chg: Updated updatexmls.py for WoW 12 XML changes
  * chg: Added configuration management system, color/highlight management, theme/frame processing, and configuration UI
  * chg: Integrated analytics/external systems and finalized integration polish
  * chore: linting updates


## [12.0.1.1] ##
### Fixed ###
  * fix: Added a nil check to the CropIcon function in api.lua. Gethe/Aurora#145
  * chg: prevents Aurora from interfering with Chonky Character Sheet's modifications to the character frame Gethe/Aurora#142
  * fix(aurora): apply proper Aurora styling to game menu buttons Gethe/Aurora#143
  * chg: Cleaned up ChatFrame
  * fix(aurora): sanitize chat sender names to avoid secret-string taint
  * fix(aurora): guard UIWidget debug name calls against tainted frames
  * fix: crash path in the chat bubble skin.
  * fix: prevents secret-value violations in chatbubbles


## [12.0.1.0] ##
### Fixed ###
  * chg: Hook_SetStatusBarTexture now uses pcall when indexing private.assetColors (prevents protected/secret-index error)
  * chg: fix 12.0.1 tables now being secret
  * chg: combat-safeMultiActionBar skinning so the action bar buttons are only skinned out of combat


## [12.0.0.2] ##
### Fixed ###
  * chg: fix hooking of SetPortraitToTexture and BuildIconArray if they exist
  * chg: avoid passing secret widgetSizeSetting into SetWidth.
  * fix: chatframe errors in raid


## [12.0.0.1] ##
### Fixed ###
  * chg: intial EventsFrame list setup (intial idea found from Wetxius/ShestakUI)
  * chg: fixes to GameMenu to not taint shop
  * chg; updates to PVEFrame and Blizzard_PVPUI
  * chg: updated Blizzard_EncounterJournal
  * chg: only skin FrameTypeButton SetNormalTexture when SetNormalTexture exists
  * chg: skin EncounterJournalJourneysTab
  * fix: DressUpFrame fixes for wow12
  * chg: skin TutorialsFrame.Contents.StartButton


## [12.0.0.0] ##
### Fixed ###
  * fix: added back removed Skin.FrameTypeScrollBarButton ...
  * chg: updated AddOns_Mainline.xml file
  * fix: removed some references to F.Reskin* (deprecated code) with newer Skin.. for BlackMarketFrame
  * chg: SetsTransmogFrame, WardrobeFrame and WardrobeTransmogFrame removed - disabled code for now
  * fix: LFGRoleButtonTemplate missing Button - catch error
  * chg: remove old debug messages left in the codebase
  * fix: Aurora AddOn Config window fix and /slashcmd fix
  * chg: ChatEdit_UpdateHeader is now ChatFrameEditBoxMixinUpdateHeader so renaming functions
  * beta: wrappers to make things run in beta
  * chore: toc update for beta


## Detailed Changes ##
[Unreleased]: https://github.com/Gethe/Aurora/compare/12.0.7.0...develop
[12.0.7.0]: https://github.com/Gethe/Aurora/compare/12.0.5.13...12.0.7.0
[12.0.5.13]: https://github.com/Gethe/Aurora/compare/12.0.5.12...12.0.5.13
[12.0.5.12]: https://github.com/Gethe/Aurora/compare/12.0.5.11...12.0.5.12
[12.0.5.11]: https://github.com/Gethe/Aurora/compare/12.0.5.10...12.0.5.11
[12.0.5.10]: https://github.com/Gethe/Aurora/compare/12.0.5.9...12.0.5.10
[12.0.5.9]: https://github.com/Gethe/Aurora/compare/12.0.5.8...12.0.5.9
[12.0.5.8]: https://github.com/Gethe/Aurora/compare/12.0.5.7...12.0.5.8
[12.0.5.7]: https://github.com/Gethe/Aurora/compare/12.0.5.6...12.0.5.7
[12.0.5.6]: https://github.com/Gethe/Aurora/compare/12.0.5.5...12.0.5.6
[12.0.5.5]: https://github.com/Gethe/Aurora/compare/12.0.5.4...12.0.5.5
[12.0.5.4]: https://github.com/Gethe/Aurora/compare/12.0.5.3...12.0.5.4
[12.0.5.3]: https://github.com/Gethe/Aurora/compare/12.0.5.2...12.0.5.3
[12.0.5.2]: https://github.com/Gethe/Aurora/compare/12.0.5.1...12.0.5.2
[12.0.5.1]: https://github.com/Gethe/Aurora/compare/12.0.5.0...12.0.5.1
[12.0.5.0]: https://github.com/Gethe/Aurora/compare/12.0.1.31...12.0.5.0
[12.0.1.31]: https://github.com/Gethe/Aurora/compare/12.0.1.30...12.0.1.31
[12.0.1.30]: https://github.com/Gethe/Aurora/compare/12.0.1.29...12.0.1.30
[12.0.1.29]: https://github.com/Gethe/Aurora/compare/12.0.1.28...12.0.1.29
[12.0.1.28]: https://github.com/Gethe/Aurora/compare/12.0.1.27...12.0.1.28
[12.0.1.27]: https://github.com/Gethe/Aurora/compare/12.0.1.26...12.0.1.27
[12.0.1.26]: https://github.com/Gethe/Aurora/compare/12.0.1.25...12.0.1.26
[12.0.1.25]: https://github.com/Gethe/Aurora/compare/12.0.1.24...12.0.1.25
[12.0.1.24]: https://github.com/Gethe/Aurora/compare/12.0.1.23...12.0.1.24
[12.0.1.23]: https://github.com/Gethe/Aurora/compare/12.0.1.22...12.0.1.23
[12.0.1.22]: https://github.com/Gethe/Aurora/compare/12.0.1.21...12.0.1.22
[12.0.1.21]: https://github.com/Gethe/Aurora/compare/12.0.1.20...12.0.1.21
[12.0.1.20]: https://github.com/Gethe/Aurora/compare/12.0.1.19...12.0.1.20
[12.0.1.19]: https://github.com/Gethe/Aurora/compare/12.0.1.18...12.0.1.19
[12.0.1.18]: https://github.com/Gethe/Aurora/compare/12.0.1.17...12.0.1.18
[12.0.1.17]: https://github.com/Gethe/Aurora/compare/12.0.1.16...12.0.1.17
[12.0.1.16]: https://github.com/Gethe/Aurora/compare/12.0.1.15...12.0.1.16
[12.0.1.15]: https://github.com/Gethe/Aurora/compare/12.0.1.14...12.0.1.15
[12.0.1.14]: https://github.com/Gethe/Aurora/compare/12.0.1.13...12.0.1.14
[12.0.1.13]: https://github.com/Gethe/Aurora/compare/12.0.1.12...12.0.1.13
[12.0.1.12]: https://github.com/Gethe/Aurora/compare/12.0.1.11...12.0.1.12
[12.0.1.11]: https://github.com/Gethe/Aurora/compare/12.0.1.10...12.0.1.11
[12.0.1.10]: https://github.com/Gethe/Aurora/compare/12.0.1.9...12.0.1.10
[12.0.1.9]: https://github.com/Gethe/Aurora/compare/12.0.1.8...12.0.1.9
[12.0.1.8]: https://github.com/Gethe/Aurora/compare/12.0.1.7...12.0.1.8
[12.0.1.7]: https://github.com/Gethe/Aurora/compare/12.0.1.6...12.0.1.7
[12.0.1.6]: https://github.com/Gethe/Aurora/compare/12.0.1.5...12.0.1.6
[12.0.1.5]: https://github.com/Gethe/Aurora/compare/12.0.1.4...12.0.1.5
[12.0.1.4]: https://github.com/Gethe/Aurora/compare/12.0.1.3...12.0.1.4
[12.0.1.3]: https://github.com/Gethe/Aurora/compare/12.0.1.2...12.0.1.3
[12.0.1.2]: https://github.com/Gethe/Aurora/compare/12.0.1.1...12.0.1.2
[12.0.1.1]: https://github.com/Gethe/Aurora/compare/12.0.1.0...12.0.1.1
[12.0.1.0]: https://github.com/Gethe/Aurora/compare/12.0.0.2...12.0.1.0
[12.0.0.2]: https://github.com/Gethe/Aurora/compare/12.0.0.1...12.0.0.2
[12.0.0.1]: https://github.com/Gethe/Aurora/compare/12.0.0.0...12.0.0.1
[12.0.0.0]: https://github.com/Gethe/Aurora/compare/11.2.7.2...12.0.0.0
