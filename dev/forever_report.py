import os
import re
import sys
import glob
import importlib.util

version = '0.1.0'
author = 'Hanshi/arnvid'

# Camelot-vs-Mainline gap report for Aurora on WoW Forever.
#
# Everything here is derived from updatexmls.py's own TOC resolution, so the
# file lists match exactly what each client loads and what each manifest
# emits. The narrative version of this output, with the reasoning behind each
# section, is docs/Aurora-Forever-Camelot-Divergence.md; this script exists so
# the numbers can be refreshed after every repo_sync instead of going stale.
#
# Usage:  python dev/forever_report.py [--donors] [--section N[,N...]]
#   --donors    also run section 8 (donor fit); slow, globs every source tree
#   --section   run only the listed sections

_dev_dir = os.path.dirname(os.path.abspath(__file__))
_spec = importlib.util.spec_from_file_location('updatexmls', os.path.join(_dev_dir, 'updatexmls.py'))
uxm = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(uxm)

aurora_path = uxm.aurora_path
BASELINE = 'Mainline'
TARGET = 'Forever'

# Trees searched for a donor skin in section 8, in the order they are reported.
donor_trees = ['Vanilla', 'TBC', 'Mists', 'Mainline']

name_attr = re.compile(r'name="([A-Za-z_][A-Za-z0-9_]*)"')
script_on = re.compile(r'\s*<Script file="([^"]+)"/>')
script_off = re.compile(r'\s*<!--Script file="([^"]+)"/-->')


def _app_intro():
    print(f"Aurora Forever Report v{version} by {author} - (c) 2026\n")


def load_set(flavor):
    """{addon: (toc filename, [file entries])} for everything that loads."""
    cfg = uxm.flavors[flavor]
    base = os.path.join(cfg['tree'], 'Interface', 'AddOns')
    out = {}
    for dirname in sorted(os.listdir(base), key=str.lower):
        addon_path = os.path.join(base, dirname)
        if not os.path.isdir(addon_path):
            continue
        toc_file = uxm.resolve_toc(addon_path, dirname, cfg['toc_order'])
        if toc_file is None:
            continue
        loads_here, files = uxm.parse_toc(toc_file, cfg['family'], cfg['gametypes'],
                                          cfg.get('game', flavor))
        if not loads_here:
            continue
        out[dirname] = (os.path.basename(toc_file), files)
    return out


def manifest(flavor):
    """[(entry path, enabled)] in manifest order."""
    path = os.path.join(aurora_path, f"AddOns_{flavor}.xml")
    entries = []
    with open(path, 'r', encoding='utf-8') as file:
        for line in file:
            match = script_on.match(line)
            if match:
                entries.append((match.group(1), True))
                continue
            match = script_off.match(line)
            if match:
                entries.append((match.group(1), False))
    return entries


def skin_key(entry):
    """(addon, basename) -- the granularity at which two flavors' skins match."""
    parts = entry.split('\\')
    return parts[0], parts[-1].lower()


def frame_names(path):
    """Frame names an XML declares, excluding $parent-relative ones.

    The $parent forms are generic region names (Middle, Right, Bg) that appear
    in every file and swamp the signal.
    """
    if not os.path.isfile(path):
        return set()
    with open(path, 'r', encoding='utf-8', errors='replace') as file:
        return set(name_attr.findall(file.read()))


def enabled_skin_sources(flavor):
    """{manifest entry: file text} for every skin the flavor's manifest enables."""
    sources = {}
    for entry, enabled in manifest(flavor):
        if not enabled:
            continue
        path = os.path.join(aurora_path, entry.replace('\\', os.sep))
        if os.path.isfile(path):
            with open(path, 'r', encoding='utf-8', errors='replace') as file:
                sources[entry] = file.read()
    return sources


xml_include = re.compile(r'<(?:Script|Include)\s+file="([^"]+)"', re.IGNORECASE)


def tree_words(flavor, loads):
    """Every identifier appearing in the files that flavor's client loads.

    A TOC entry is often an XML that pulls its Lua in with <Script file="...">,
    so following those is not optional: without it, every mixin and frame
    defined behind an XML looks absent from the client and section 6 reports a
    wall of false positives (AdventureMapMixin, GarrisonLandingPageMixin and
    LandingSoulbind were all flagged this way before this was fixed).
    """
    cfg = uxm.flavors[flavor]
    base = os.path.join(cfg['tree'], 'Interface', 'AddOns')
    words = set()
    seen = set()

    def absorb(path):
        path = os.path.normpath(path)
        key = path.lower()
        if key in seen or not os.path.isfile(path):
            return
        seen.add(key)
        with open(path, 'r', encoding='utf-8', errors='replace') as file:
            text = file.read()
        words.update(re.findall(r'[A-Za-z_][A-Za-z0-9_]*', text))
        if path.lower().endswith('.xml'):
            for ref in xml_include.findall(text):
                absorb(os.path.join(os.path.dirname(path), ref.replace('\\', os.sep)))

    for addon, (_, files) in loads.items():
        for rel in files:
            absorb(os.path.join(base, addon, rel.replace('\\', os.sep)))
    return words


def header(number, title):
    print()
    print('=' * 78)
    print(f"{number}. {title}")
    print('=' * 78)


def section_1(ml, fv):
    header(1, 'Load sets')
    for flavor, loads in ((BASELINE, ml), (TARGET, fv)):
        tree = uxm.flavors[flavor]['tree']
        print(f"  {flavor:10} v{uxm.tree_version(tree):16} {len(loads)} addons load")
    print(f"  {TARGET}-only: {len(set(fv) - set(ml))}   {BASELINE}-only: {len(set(ml) - set(fv))}")
    for flavor in (BASELINE, TARGET):
        entries = manifest(flavor)
        on = sum(1 for _, enabled in entries if enabled)
        print(f"  AddOns_{flavor}.xml: {on} active / {len(entries) - on} inactive")


def section_2(fv):
    header(2, 'Camelot files by idiom (additive patches base / replaces it)')
    cfg = uxm.flavors[TARGET]
    game, family = cfg.get('game'), cfg['family']
    totals = {'additive': 0, 'replacement': 0}
    for addon, (_, files) in fv.items():
        lowered = {f.lower() for f in files}
        kinds = [(f, uxm.game_overlay_kind(f, lowered, game, family)) for f in files]
        kinds = [(f, k) for f, k in kinds if k]
        if not kinds:
            continue
        counts = {'additive': 0, 'replacement': 0}
        for _, kind in kinds:
            counts[kind] += 1
            totals[kind] += 1
        entry, found = uxm.resolve_skin(addon, f"{addon}.lua", cfg['skin_dirs'])
        print(f"  {addon:38} +{counts['additive']:<3} !{counts['replacement']:<3} "
              f"{'skinned' if found else '-------'}")
    print(f"\n  {totals['additive']} additive, {totals['replacement']} replacement")


def section_3(fv):
    header(3, f"Dead [Game] entries in AddOns_{TARGET}.xml")
    game = uxm.flavors[TARGET].get('game')
    dead = [e for e, enabled in manifest(TARGET)
            if not enabled and f"\\{game}\\".lower() in f"\\{e}".lower()]
    for entry in dead:
        print(f"  {entry}")
    print(f"\n  {len(dead)} inactive {game} entries")


def section_4(ml, fv):
    header(4, 'True regressions (skinned on the baseline, unskinned on the target)')
    baseline_on = {}
    for entry, enabled in manifest(BASELINE):
        if enabled:
            baseline_on[skin_key(entry)] = entry  # keep the spelling for display
    target_on = {skin_key(e) for e, enabled in manifest(TARGET) if enabled}
    target_seen = {skin_key(e)[0] for e, _ in manifest(TARGET)}
    lost = sorted(k for k in set(baseline_on) - target_on if k[0] in target_seen)
    for key in lost:
        print(f"  {baseline_on[key]}")
    print(f"\n  {len(lost)} regressions "
          f"({len(set(baseline_on) - target_on) - len(lost)} more in addons that do not load on {TARGET})")


def section_5(fv):
    header(5, 'Frames the [Game] replacement drops that live skins still touch')
    cfg = uxm.flavors[TARGET]
    base = os.path.join(cfg['tree'], 'Interface', 'AddOns')
    game, family = cfg.get('game'), cfg['family']
    sources = enabled_skin_sources(TARGET)
    hits = 0
    for addon, (_, files) in sorted(fv.items()):
        for rel in files:
            if not rel.lower().endswith('.xml'):
                continue
            if uxm.game_overlay_kind(rel, {f.lower() for f in files}, game, family) != 'replacement':
                continue
            stem = rel.split('\\', 1)[1]
            overlay = frame_names(os.path.join(base, addon, rel.replace('\\', os.sep)))
            for donor_dir in (family, 'Shared', ''):
                donor = os.path.join(base, addon, donor_dir, stem.replace('\\', os.sep))
                names = frame_names(donor)
                if names:
                    break
            gone = sorted(names - overlay)
            touched = [n for n in gone
                       if any(re.search(r'\b' + re.escape(n) + r'\b', text)
                              for text in sources.values())]
            if not touched:
                continue
            hits += len(touched)
            print(f"\n  {addon}\\{rel}")
            for name in touched:
                print(f"      {name}")
    print(f"\n  {hits} dropped frame names are referenced by skins active on {TARGET}")


def section_6(ml, fv):
    header(6, 'Globals live skins read that the target client does not define')
    print("  A string-presence test, so it cuts both ways: a name mentioned in a")
    print("  comment or an unrelated file looks present, and section 5 is the")
    print("  authoritative one for frames. Check each hit against the tree before")
    print("  guarding -- and check section 5 before dismissing one.")
    target_words = tree_words(TARGET, fv)
    baseline_words = tree_words(BASELINE, ml)
    rows = []
    for entry, text in enabled_skin_sources(TARGET).items():
        refs = set(re.findall(r'_G\.([A-Za-z_][A-Za-z0-9_]*)', text))
        missing = sorted(n for n in refs if n not in target_words and n in baseline_words)
        if missing:
            rows.append((entry, missing))
    for entry, missing in sorted(rows, key=lambda row: -len(row[1])):
        print(f"\n  {entry}   ({len(missing)})")
        for name in missing:
            print(f"      {name}")
    print(f"\n  {len(rows)} skins, {sum(len(r[1]) for r in rows)} symbols")


def section_7(ml, fv):
    header(7, 'Addons unique to one client')
    target_manifest = {}
    for entry, enabled in manifest(TARGET):
        addon = entry.split('\\')[0]
        target_manifest[addon] = target_manifest.get(addon, False) or enabled
    print(f"  Only on {TARGET}:")
    for addon in sorted(set(fv) - set(ml)):
        print(f"      {'skinned' if target_manifest.get(addon) else '  GAP  '}  {addon}")
    baseline_on = {}
    for entry, enabled in manifest(BASELINE):
        addon = entry.split('\\')[0]
        baseline_on[addon] = baseline_on.get(addon, False) or enabled
    gone = sorted(set(ml) - set(fv))
    print(f"\n  Only on {BASELINE} ({len(gone)}; "
          f"{sum(1 for a in gone if baseline_on.get(a))} of them skinned there, no work needed):")
    for addon in gone:
        print(f"      {'skinned' if baseline_on.get(addon) else '       '}  {addon}")


def section_8(fv):
    header(8, 'Donor fit -- each [Game] XML against the closest file in each tree')
    print("  Jaccard over declared frame names. Weight by the name count: a high")
    print("  score on a 5-name file means much less than a low score on a 25-name one.\n")
    cfg = uxm.flavors[TARGET]
    base = os.path.join(cfg['tree'], 'Interface', 'AddOns')
    game, family = cfg.get('game'), cfg['family']
    trees = [(f, uxm.flavors[f]['tree']) for f in donor_trees if f in uxm.flavors]
    for addon, (_, files) in sorted(fv.items()):
        lowered = {f.lower() for f in files}
        for rel in files:
            if not rel.lower().endswith('.xml'):
                continue
            if not uxm.game_overlay_kind(rel, lowered, game, family):
                continue
            overlay = frame_names(os.path.join(base, addon, rel.replace('\\', os.sep)))
            if not overlay:
                continue
            cells = []
            for flavor, tree in trees:
                root = os.path.join(tree, 'Interface', 'AddOns')
                best, best_path = 0.0, None
                pattern = os.path.join(root, '**', os.path.basename(rel))
                for candidate in glob.glob(pattern, recursive=True):
                    names = frame_names(candidate)
                    if not names:
                        continue
                    score = len(overlay & names) / len(overlay | names)
                    if score > best:
                        best, best_path = score, candidate
                if best_path:
                    cells.append(f"{flavor}={best:.2f}")
            label = f"{addon}\\{rel}"
            print(f"  {label:74} {len(overlay):>3}  {'  '.join(cells) or '-- no counterpart --'}")


skin_def = re.compile(r'function\s+Skin\.([A-Za-z_][A-Za-z0-9_]*)\s*\(|Skin\.([A-Za-z_][A-Za-z0-9_]*)\s*=')
skin_call = re.compile(r'Skin\.([A-Za-z_][A-Za-z0-9_]*)\s*\(')
lua_block_comment = re.compile(r'--\[(=*)\[.*?\]\1\]', re.DOTALL)
lua_line_comment = re.compile(r'--[^\n]*')


def strip_lua_comments(text):
    """Blank out Lua comments so commented-out calls are not reported.

    Without this the call scan matches lines like
        --Skin.SoulbindTreeTemplate(SoulbindViewer.Tree)
    which are deliberately disabled, not broken. Block comments go first so a
    '--' inside one cannot be mistaken for the start of a line comment.
    """
    text = lua_block_comment.sub('', text)
    return lua_line_comment.sub('', text)


def core_skin_files():
    """The hand-written Skin\\*.lua that skin.xml loads on every flavor."""
    # aurora_path carries an unresolved 'dev\..' segment, so normalise before
    # walking up, or the '..'s eat one component too many.
    skin_dir = os.path.normpath(os.path.join(os.path.normpath(aurora_path), '..', '..'))
    xml = os.path.join(skin_dir, 'skin.xml')
    out = []
    if os.path.isfile(xml):
        with open(xml, 'r', encoding='utf-8', errors='replace') as file:
            for ref in re.findall(r'<Script file="([^"]+)"', file.read()):
                out.append(os.path.join(skin_dir, ref.replace('\\', os.sep)))
    return out


def section_9(fv):
    header(9, 'Skin templates called on the target but registered nowhere it loads')
    print("  Gap class E: Aurora's own cross-file registrations. A Skin.<Template> is")
    print("  defined by the skin file matching the Blizzard file that declares it, so")
    print("  when the target loads a different set of Blizzard addons the definition")
    print("  can go missing while the callers keep loading. No comparison of the two")
    print("  Blizzard trees can see this -- it is a property of the manifest.\n")

    # Everything the target actually loads: the generated manifest plus the
    # hand-written core files from skin.xml.
    loaded = [os.path.join(aurora_path, e.replace('\\', os.sep))
              for e, enabled in manifest(TARGET) if enabled]
    loaded += core_skin_files()
    loaded = [p for p in loaded if os.path.isfile(p)]

    available, sources = set(), {}
    for path in loaded:
        with open(path, 'r', encoding='utf-8', errors='replace') as file:
            for match in skin_def.finditer(strip_lua_comments(file.read())):
                available.add(match.group(1) or match.group(2))

    # Where each name IS defined, across the whole skin tree.
    for root, _, files in os.walk(aurora_path):
        for name in files:
            if not name.endswith('.lua'):
                continue
            path = os.path.join(root, name)
            with open(path, 'r', encoding='utf-8', errors='replace') as file:
                for match in skin_def.finditer(strip_lua_comments(file.read())):
                    key = match.group(1) or match.group(2)
                    sources.setdefault(key, set()).add(
                        os.path.relpath(path, aurora_path))

    missing = {}
    for path in loaded:
        with open(path, 'r', encoding='utf-8', errors='replace') as file:
            text = strip_lua_comments(file.read())
        for match in skin_call.finditer(text):
            name = match.group(1)
            if name in available:
                continue
            rel = os.path.relpath(path, aurora_path)
            missing.setdefault(name, set()).add(rel)

    for name in sorted(missing):
        where = sorted(sources.get(name, []))
        print(f"\n  Skin.{name}")
        print(f"      defined in: {', '.join(where) if where else '*** NOWHERE -- broken on every flavor ***'}")
        for caller in sorted(missing[name]):
            print(f"      called by:  {caller}")
    print(f"\n  {len(missing)} template(s) called but unavailable on {TARGET}")


sections = {
    1: ('load sets', lambda ml, fv: section_1(ml, fv)),
    2: ('camelot idioms', lambda ml, fv: section_2(fv)),
    3: ('dead manifest entries', lambda ml, fv: section_3(fv)),
    4: ('true regressions', lambda ml, fv: section_4(ml, fv)),
    5: ('dropped frames', lambda ml, fv: section_5(fv)),
    6: ('missing globals', lambda ml, fv: section_6(ml, fv)),
    7: ('unique addons', lambda ml, fv: section_7(ml, fv)),
    8: ('donor fit', lambda ml, fv: section_8(fv)),
    9: ('missing skin templates', lambda ml, fv: section_9(fv)),
}


def main():
    _app_intro()
    args = sys.argv[1:]
    wanted = set(sections) - {8}
    if '--donors' in args:
        wanted.add(8)
        args.remove('--donors')
    if args and args[0] == '--section':
        if len(args) < 2:
            print("--section needs a comma-separated list, e.g. --section 4,5")
            sys.exit(1)
        try:
            wanted = {int(n) for n in args[1].split(',')}
        except ValueError:
            print(f"Not a section list: {args[1]}")
            sys.exit(1)
        unknown = wanted - set(sections)
        if unknown:
            print(f"Unknown section(s): {sorted(unknown)} -- choose from {sorted(sections)}")
            sys.exit(1)

    for flavor in (BASELINE, TARGET):
        tree = uxm.flavors[flavor]['tree']
        if not os.path.isdir(os.path.join(tree, 'Interface', 'AddOns')):
            print(f"Missing source tree for {flavor}: {tree}")
            sys.exit(1)

    ml, fv = load_set(BASELINE), load_set(TARGET)
    for number in sorted(wanted):
        sections[number][1](ml, fv)
    print()


if __name__ == '__main__':
    main()
