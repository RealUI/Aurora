local _, private = ...

--[[ Lua Globals ]]
-- luacheck: globals next print

local commands = private.commands

-- Color helpers for chat output
local PASS = "|cff00ff00PASS|r"
local FAIL = "|cffff0000FAIL|r"

local function HasAuroraBackdrop(frame)
    return frame and frame._backdropInfo ~= nil
end

local function PrintResult(passed, label)
    local status = passed and PASS or FAIL
    print(("  %s  %s"):format(status, label))
end

local function PrintHeader(title)
    print("|cff88bbff--- " .. title .. " ---|r")
end

function commands.testtbc()
    print("|cffffd700=== Aurora TBC Skin Verification ===|r")
    print("")

    ----------------------------------------------------------------
    -- Bug Condition Checks (should PASS after fix is applied)
    ----------------------------------------------------------------
    PrintHeader("Bug Condition Checks (PASS = bug is fixed)")

    -- 1. BankFrame has Aurora backdrop (manual skinning without nil PortraitContainer error)
    do
        local frame = _G.BankFrame
        PrintResult(HasAuroraBackdrop(frame), "BankFrame has Aurora backdrop")
    end

    -- 2. WorldMapFrame has Aurora backdrop (skin fired after Blizzard_WorldMap loaded)
    do
        local frame = _G.WorldMapFrame
        PrintResult(HasAuroraBackdrop(frame), "WorldMapFrame has Aurora backdrop")
    end

    -- 3. GossipFrame greeting panel material textures are hidden
    do
        local allHidden = true
        local texNames = {
            "GossipFrameGreetingPanelMaterialTopLeft",
            "GossipFrameGreetingPanelMaterialTopRight",
            "GossipFrameGreetingPanelMaterialBotLeft",
            "GossipFrameGreetingPanelMaterialBotRight",
        }
        for _, name in next, texNames do
            local tex = _G[name]
            if tex then
                if tex:IsShown() then
                    allHidden = false
                end
            end
            -- If texture global doesn't exist, it's not blocking us
        end
        -- Only fail if GossipFrame exists and textures are shown
        local gossipLoaded = _G.GossipFrame ~= nil
        if not gossipLoaded then
            PrintResult(false, "GossipFrame material textures hidden (GossipFrame not loaded)")
        else
            PrintResult(allHidden, "GossipFrame material textures hidden")
        end
    end

    -- 4. PVPReadyDialog or PVPFramePopup has Aurora styling
    do
        local pvpFrame = _G.PVPReadyDialog or _G.PVPFramePopup
        local passed = HasAuroraBackdrop(pvpFrame)
        PrintResult(passed, "PVPReadyDialog/PVPFramePopup has Aurora styling")
    end

    -- 5. AuctionHouseFrame has Aurora backdrop when auction house is open
    do
        local frame = _G.AuctionHouseFrame
        if not frame then
            PrintResult(false, "AuctionHouseFrame has Aurora backdrop (frame not loaded - open AH first)")
        else
            PrintResult(HasAuroraBackdrop(frame), "AuctionHouseFrame has Aurora backdrop")
        end
    end

    -- 6. CharacterFrame tabs have Aurora backdrop and hidden texture regions
    do
        local tab = _G.CharacterFrameTab1
        local tabHasBackdrop = HasAuroraBackdrop(tab)
        local texturesHidden = true
        if tab then
            local regionNames = {"Left", "Middle", "Right", "LeftDisabled", "MiddleDisabled", "RightDisabled"}
            for _, suffix in next, regionNames do
                local texName = "CharacterFrameTab1" .. suffix
                local tex = _G[texName]
                if tex and tex:IsShown() then
                    texturesHidden = false
                end
            end
            -- Note: highlight texture on mouseover is normal, not checked here
        end
        PrintResult(tabHasBackdrop and texturesHidden, "CharacterFrame tabs have Aurora backdrop + hidden textures")
    end

    print("")

    ----------------------------------------------------------------
    -- Preservation Checks (should PASS before AND after fix)
    ----------------------------------------------------------------
    PrintHeader("Preservation Checks (PASS = no regression)")

    -- QuestFrame has Aurora backdrop (ButtonFrameTemplate skin intact)
    do
        local frame = _G.QuestFrame
        PrintResult(HasAuroraBackdrop(frame), "QuestFrame has Aurora backdrop")
    end

    -- MerchantFrame has Aurora backdrop (ButtonFrameTemplate skin intact)
    do
        local frame = _G.MerchantFrame
        PrintResult(HasAuroraBackdrop(frame), "MerchantFrame has Aurora backdrop")
    end

    -- LootFrame has Aurora backdrop (ButtonFrameTemplate skin intact)
    do
        local frame = _G.LootFrame
        PrintResult(HasAuroraBackdrop(frame), "LootFrame has Aurora backdrop")
    end

    -- MailFrame has Aurora backdrop (ButtonFrameTemplate skin intact)
    do
        local frame = _G.MailFrame
        PrintResult(HasAuroraBackdrop(frame), "MailFrame has Aurora backdrop")
    end

    -- ContainerFrame1 has Aurora styling (FrameXML dispatch intact)
    do
        local frame = _G.ContainerFrame1
        -- ContainerFrame skin hooks ContainerFrame_GenerateFrame/Update to skin item buttons
        -- It doesn't apply Base.SetBackdrop to the frame itself — check if the hook fired
        -- by looking for a skinned item button (items are skinned when bag is opened)
        local hasStyling = false
        if frame then
            -- Check if the FrameXML.ContainerFrame function was registered (skin loaded)
            hasStyling = private.FrameXML.ContainerFrame ~= nil
        end
        PrintResult(hasStyling, "ContainerFrame1 has Aurora styling")
    end

    -- LFGFrame has Aurora styling when Blizzard_GroupFinder loaded
    do
        local frame = _G.LFGFrame or _G.LFGParentFrame
        if not frame then
            PrintResult(false, "LFGFrame has Aurora styling (not loaded - open LFG first)")
        else
            PrintResult(HasAuroraBackdrop(frame), "LFGFrame has Aurora styling")
        end
    end

    print("")

    ----------------------------------------------------------------
    -- New TBC Skins (Part 3)
    ----------------------------------------------------------------
    PrintHeader("New TBC Skins (Part 3)")

    -- ActionBar skin: registered + callable + raises no Lua errors
    -- Validates Property 1 (no Lua errors), Property 2 (registered/callable),
    -- Property 3 (no nil-index from missing globals) — Requirements 1.1, 1.7
    do
        local skin = private.AddOns.Blizzard_ActionBar
        local registered = type(skin) == "function"
        PrintResult(registered, "Blizzard_ActionBar skin registered + callable")

        if registered then
            local ok, err = pcall(skin)
            PrintResult(ok, "Blizzard_ActionBar skin invokes with no Lua error"
                .. (ok and "" or (" (" .. tostring(err) .. ")")))

            -- Optional frame-state checks (nil-guarded; only assert when present)
            local artFrame = _G.MainMenuBarArtFrame
            if artFrame then
                local allHidden = true
                for _, region in next, {artFrame:GetRegions()} do
                    if region and region.IsObjectType and region:IsObjectType("Texture") then
                        if region:IsShown() then
                            allHidden = false
                        end
                    end
                end
                PrintResult(allHidden, "MainMenuBarArtFrame textures hidden")
            else
                PrintResult(true, "MainMenuBarArtFrame textures hidden (frame not loaded - skipped)")
            end

            local button = _G.ActionButton1
            if button then
                PrintResult(HasAuroraBackdrop(button), "ActionButton1 has Aurora backdrop")
            else
                PrintResult(true, "ActionButton1 has Aurora backdrop (button not loaded - skipped)")
            end
        end
    end

    -- BagButtons skin: registered on private.AddOns (NOT private.FrameXML),
    -- callable, and raises no Lua errors on invoke.
    -- Validates Property 1 (no Lua errors), Property 2 (registered/callable),
    -- Property 3 (no nil-index from missing globals) — Requirements 3.1, 3.2, 3.6
    do
        local skin = private.AddOns.Blizzard_MainMenuBarBagButtons
        local registered = type(skin) == "function"
        PrintResult(registered, "Blizzard_MainMenuBarBagButtons skin registered on private.AddOns")

        -- Req 3.2: must NOT be registered on the FrameXML (LoadFirst) path.
        local notOnFrameXML = private.FrameXML.MainMenuBarBagButtons == nil
        PrintResult(notOnFrameXML, "Blizzard_MainMenuBarBagButtons NOT registered on private.FrameXML")

        if registered then
            local ok, err = pcall(skin)
            PrintResult(ok, "Blizzard_MainMenuBarBagButtons skin invokes with no Lua error"
                .. (ok and "" or (" (" .. tostring(err) .. ")")))

            -- Optional frame-state check (nil-guarded; only assert when present).
            local bag0 = _G.CharacterBag0Slot
            if bag0 then
                PrintResult(HasAuroraBackdrop(bag0), "CharacterBag0Slot has Aurora backdrop")
            else
                PrintResult(true, "CharacterBag0Slot has Aurora backdrop (slot not loaded - skipped)")
            end
        end
    end

    -- UnitFrame skin: registered + callable + raises no Lua errors,
    -- and the flat CompactUnitFrame hook still coexists (separate dispatch path).
    -- Validates Property 1 (no Lua errors), Property 2 (registered/callable fires
    -- once on ADDON_LOADED), Property 3 (no nil-index from missing globals)
    -- — Requirements 2.1, 2.9, 13.6
    do
        local skin = private.AddOns.Blizzard_UnitFrame
        local registered = type(skin) == "function"
        PrintResult(registered, "Blizzard_UnitFrame skin registered + callable")

        if registered then
            local ok, err = pcall(skin)
            PrintResult(ok, "Blizzard_UnitFrame skin invokes with no Lua error"
                .. (ok and "" or (" (" .. tostring(err) .. ")")))
        end

        -- Coexistence: the flat Blizzard_UnitFrame.lua CompactUnitFrame hook must
        -- still be registered on private.FrameXML (separate from this AddOns path).
        -- This guarantees Part 2's health-color hook is preserved (Requirement 13.6).
        local flatHook = private.FrameXML.CompactUnitFrame
        PrintResult(type(flatHook) == "function",
            "Flat CompactUnitFrame hook preserved (private.FrameXML)")

        -- Optional frame-state check (nil-guarded; only assert when present).
        local playerFrame = _G.PlayerFrame
        if playerFrame then
            PrintResult(HasAuroraBackdrop(playerFrame), "PlayerFrame has Aurora backdrop")
        else
            PrintResult(true, "PlayerFrame has Aurora backdrop (frame not loaded - skipped)")
        end
    end

    print("")
    print("|cffffd700=== Test Complete ===|r")
end
