std = "lua51"
quiet = 1 -- suppress report output for files without warnings
max_line_length = false
max_cyclomatic_complexity = 37
self = false
unused_args = false
exclude_files = {
    ".release",
    "libs"
}
globals = {
    "_G"
}

files["Skin/Interface/AddOns/Blizzard_HousingDashboard/Blizzard_HousingDashboard.lua"] = {
    max_cyclomatic_complexity = false,
}

files["Skin/Interface/AddOns/Blizzard_Professions/Blizzard_Professions.lua"] = {
    max_cyclomatic_complexity = false,
}

files["Skin/Interface/AddOns/Blizzard_ProfessionsCustomerOrders/Blizzard_ProfessionsCustomerOrders.lua"] = {
    max_cyclomatic_complexity = false,
}

files["Skin/Interface/AddOns/Blizzard_Transmog/Mainline/Blizzard_Transmog.lua"] = {
    max_cyclomatic_complexity = false,
}

files["Skin/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/QuestMapFrame.lua"] = {
    max_cyclomatic_complexity = false,
}
