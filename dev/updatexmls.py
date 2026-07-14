import os
import re
import sys

version = '0.2.1'
author = 'Hanshi/arnvid'

# All paths are anchored to this script's location: dev/ inside the Aurora
# repo, with the wow-ui-source trees checked out next to the Aurora repo.
_dev_dir = os.path.dirname(os.path.abspath(__file__))
aurora_path = os.path.join(_dev_dir, '..', 'Skin', 'Interface', 'AddOns')
_trees_root = os.path.normpath(os.path.join(_dev_dir, '..', '..'))

# Flavor configuration — one entry per supported client build.
#   tree:      wow-ui-source checkout for that client (sibling of the Aurora repo)
#   toc_order: the client's TOC suffix search order ('' = suffix-less TOC)
#   family:    what the client substitutes for [Family] in TOC file paths
#   gametypes: tokens this client matches in AllowLoadGameType directives
#   skin_dirs: Aurora skin subfolders searched (most specific first) when a
#              TOC lists a flat path — lets flavor-specific skins live in
#              Mainline/, TBC/, Vanilla/, Mists/ or the classic-shared
#              Classic/ folder even when Blizzard's own path has no subdir
#   adp:       AURORA_DEBUG_PROJECT value (must match Skin/init.lua debugProjectID)
flavors = {
    'Mainline': {
        'tree': os.path.join(_trees_root, 'wow-ui-source'),
        'toc_order': ['Mainline', 'Standard', ''],
        'family': 'Mainline',
        'gametypes': {'mainline', 'standard'},
        'skin_dirs': ['Mainline'],
        'adp': 0,
    },
    'Vanilla': {
        'tree': os.path.join(_trees_root, 'wow-ui-source-era'),
        'toc_order': ['Vanilla', 'Classic', ''],
        'family': 'Classic',
        'gametypes': {'classic', 'vanilla'},
        'skin_dirs': ['Vanilla', 'Classic'],
        'adp': 10,
    },
    'TBC': {
        'tree': os.path.join(_trees_root, 'wow-ui-source-anniversary'),
        'toc_order': ['TBC', 'Classic', ''],
        'family': 'Classic',
        'gametypes': {'classic', 'tbc'},
        'skin_dirs': ['TBC', 'Classic'],
        'adp': 20,
    },
    'Mists': {
        'tree': os.path.join(_trees_root, 'wow-ui-source-classic'),
        'toc_order': ['Mists', 'Classic', ''],
        'family': 'Classic',
        'gametypes': {'classic', 'mists'},
        'skin_dirs': ['Mists', 'Classic'],
        'adp': 50,
    },
}

# Addons whose manifest entries are expanded file-by-file from their TOC.
# All other addons get a single {AddonName}\{AddonName}.lua entry.
aurora_addons = ['Blizzard_FrameXML', 'Blizzard_FrameXMLBase', 'Blizzard_SharedXML', 'Blizzard_SharedXMLBase',
                 'Blizzard_UIPanels_Game', 'Blizzard_UnitPopup', 'Blizzard_UIParent',
                 'Blizzard_GroupFinder', 'Blizzard_QuickJoin', 'Blizzard_ActionBar',
                 'Blizzard_MoneyFrame', 'Blizzard_UIPanelTemplates', 'Blizzard_GarrisonBase', 'Blizzard_ChatFrame',
                 'Blizzard_StaticPopup_Game', 'Blizzard_Menu', 'Blizzard_ChatFrameBase',
                 ]

xml_header = "<Ui xmlns=\"http://www.blizzard.com/wow/ui/\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.blizzard.com/wow/ui/\nhttps://raw.githubusercontent.com/Meorawr/wow-ui-schema/main/UI.xsd\">\n"
xml_script_header = "    <Script>\n        _G.AURORA_DEBUG_PROJECT = %s\n    </Script>\n"
xml_info_addons = "    <!-- This section is added for %s by the Aurora XML Updater -->\n"
xml_info_addons_end = "    <!-- End of section added for %s by the Aurora XML Updater -->\n"
xml_include_lua = "    <Script file=\"%s\"/>\n"
xml_no_include_lua = "    <!--Script file=\"%s\"/-->\n"
xml_space = "\n"
xml_footer = "</Ui>"

processed_lines = {}  # union across all flavors, for the unused-file report


def _app_intro():
    print(f"Aurora XML Updater v{version} by {author} - (c) 2024-2026\n")


def tree_version(tree):
    try:
        with open(os.path.join(tree, 'version.txt'), 'r') as file:
            return file.read().strip()
    except OSError:
        return 'unknown'


def resolve_toc(addon_path, dirname, toc_order):
    """Pick the TOC the client would load, honoring its suffix search order.

    Matching is case-insensitive: Blizzard's own repo has e.g. the directory
    Blizzard_BarbershopUI containing Blizzard_BarberShopUI.toc.
    """
    tocs = {}  # lowercased suffix -> filename
    for f in os.listdir(addon_path):
        if not f.lower().endswith('.toc'):
            continue
        stem = f[:-4]
        if stem.lower() == dirname.lower():
            tocs[''] = f
        elif stem.lower().startswith(dirname.lower() + '_'):
            tocs[stem[len(dirname) + 1:].lower()] = f
    for suffix in toc_order:
        if suffix.lower() in tocs:
            return os.path.join(addon_path, tocs[suffix.lower()])
    return None


def parse_gametypes(value):
    return {t for t in re.split(r'[,\s]+', value.lower()) if t}


def parse_toc(toc_file, family, gametypes, game):
    """Return (loads_here, [file entries]) for one TOC as seen by one client.

    Header handling: '## AllowLoad: Glue' addons never load in-game and
    '## AllowLoadGameType:' must include one of the client's gametype tokens.
    Line handling: '[AllowLoadGameType ...]' directives filter lines the
    same way; other bracket directives are ignored. [Family] and [Game] are
    substituted with the client's family/game dir before directives are
    parsed ([Game] observed on the 2.5.6 anniversary TOCs, e.g.
    Blizzard_UIPanels_Game's `[Game]\\QuestInfo.lua`).
    """
    entries = []
    with open(toc_file, 'r', encoding='utf-8-sig', errors='replace') as file:
        for line in file:
            line = line.strip()
            if not line:
                continue
            if line.startswith('#'):
                m = re.match(r'##\s*AllowLoadGameType:\s*(.+)', line, re.IGNORECASE)
                if m and not (parse_gametypes(m.group(1)) & gametypes):
                    return False, []
                m = re.match(r'##\s*AllowLoad:\s*(\S+)', line, re.IGNORECASE)
                if m and m.group(1).lower() == 'glue':
                    return False, []
                continue
            line = line.replace('[Family]', family).replace('[Game]', game)
            path, _, directives = line.partition(' ')
            allowed = True
            for directive in re.findall(r'\[([^\]]+)\]', directives):
                m = re.match(r'AllowLoadGameType\s+(.+)', directive, re.IGNORECASE)
                if m and not (parse_gametypes(m.group(1)) & gametypes):
                    allowed = False
            if allowed and path:
                entries.append(path.replace('/', '\\'))
    return True, entries


def resolve_skin(dirname, path, skin_dirs):
    """Locate Aurora's skin file for one TOC entry: (manifest path, found).

    An exact mirror of the TOC path wins. A flat TOC path (no subfolder) is
    then also searched in the flavor's skin subfolders, most specific first,
    so a skin can be split per flavor even when Blizzard's path is flat.
    """
    candidates = [f"{dirname}\\{path}"]
    if '\\' not in path:
        candidates += [f"{dirname}\\{sub}\\{path}" for sub in skin_dirs]
    for entry in candidates:
        if os.path.exists(os.path.join(aurora_path, entry)):
            return entry, True
    return candidates[0], False


def entry_line(entry, found):
    processed_lines[entry.replace('\\', '/')] = True
    if found:
        return xml_include_lua % entry
    return xml_no_include_lua % entry


def generate_manifest(flavor, cfg):
    addons_base = os.path.join(cfg['tree'], 'Interface', 'AddOns')
    out_path = os.path.join(aurora_path, f"AddOns_{flavor}.xml")
    print(f"Creating {out_path} from {addons_base} (v{tree_version(cfg['tree'])})")

    seen = set()
    out = [xml_header, xml_space, xml_script_header % cfg['adp'], xml_space]
    for dirname in sorted(os.listdir(addons_base), key=str.lower):
        addon_path = os.path.join(addons_base, dirname)
        if not os.path.isdir(addon_path):
            continue
        toc_file = resolve_toc(addon_path, dirname, cfg['toc_order'])
        if toc_file is None:
            continue
        loads_here, files = parse_toc(toc_file, cfg['family'], cfg['gametypes'], flavor)
        if not loads_here:
            continue
        if dirname in aurora_addons:
            out.append(xml_info_addons % dirname)
            for path in files:
                lua_path = f"{os.path.splitext(path)[0]}.lua"
                entry, found = resolve_skin(dirname, lua_path, cfg['skin_dirs'])
                if entry.lower() not in seen:
                    seen.add(entry.lower())
                    out.append(entry_line(entry, found))
            out.append(xml_info_addons_end % dirname)
        else:
            entry, found = resolve_skin(dirname, f"{dirname}.lua", cfg['skin_dirs'])
            if entry.lower() not in seen:
                seen.add(entry.lower())
                out.append(entry_line(entry, found))
    out.append(xml_space)
    out.append(xml_footer)
    out.append(xml_space)
    with open(out_path, 'w') as file:
        file.write(''.join(out))


def find_and_list_unused_files():
    print("\nSearching for unused .lua files in the Aurora path...")
    all_lua_files = set()
    for root, dirs, files in os.walk(aurora_path):
        for file in files:
            if file.endswith('.lua'):
                rel_path = os.path.relpath(os.path.join(root, file), aurora_path)
                all_lua_files.add(rel_path.replace('\\', '/'))

    processed = {k.lower() for k in processed_lines}
    unused_files = [f for f in sorted(all_lua_files) if f.lower() not in processed]
    if unused_files:
        print("Unused .lua files found (not referenced by any generated manifest):")
        for file in unused_files:
            print(f"- {file}")
    else:
        print("No unused .lua files found.")


_app_intro()
requested = sys.argv[1:]
unknown = [f for f in requested if f not in flavors]
if unknown:
    print(f"Unknown flavor(s): {', '.join(unknown)} — choose from: {', '.join(flavors)}")
    sys.exit(1)

ran = []
for flavor, cfg in flavors.items():
    if requested and flavor not in requested:
        continue
    if not os.path.isdir(os.path.join(cfg['tree'], 'Interface', 'AddOns')):
        print(f"Skipping {flavor}: source tree not found at {cfg['tree']}")
        continue
    generate_manifest(flavor, cfg)
    ran.append(flavor)

if ran:
    find_and_list_unused_files()
print(f"\nGenerated manifests: {', '.join(ran) if ran else 'none'}")
