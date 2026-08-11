local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals _G ipairs unpack

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin

--[[ Classic-family micro menu (era 1.15.9 convergence / TBC / Mists):
    Blizzard extracted the micro buttons from the action bar into the new
    Blizzard_MicroMenu addon. The classic buttons keep their old named
    globals and UI-MicroButton-* texture style
    (Classic\MainMenuBarMicroButtons.xml); layout is owned by the
    GridLayoutFrame MicroMenu (Shared\MicroMenuContainer.lua —
    MicroMenuMixin:AddButton / Layout), so this skin only restyles the
    buttons and NEVER repositions them (the old PositionRelative treatment
    would fight MicroMenu:Layout). Per-flavor overrides pick which buttons
    the menu shows; every button defined in the XML is skinned, hidden ones
    are harmless. Salvaged from the pre-1.15.9
    Blizzard_ActionBarController\Classic skin.
]]

local function SetTexture(texture, anchor, left, right, top, bottom)
    if left then
        texture:SetTexCoord(left, right, top, bottom)
    end
    texture:ClearAllPoints()
    texture:SetPoint("TOPLEFT", anchor, 1, -1)
    texture:SetPoint("BOTTOMRIGHT", anchor, -1, 1)
end

local microButtonPrefix = [[Interface\Buttons\UI-MicroButton-]]
local function SetMicroButton(button, info)
    local bg = button:GetBackdropTexture("bg")
    local left, right, top, bottom

    if info.texture then
        if info.coords then
            left, right, top, bottom = unpack(info.coords)
        else
            -- crop region aspect-matched to the ~23x33 plate interior so
            -- square icons don't stretch
            left, right, top, bottom = 0.2, 0.8, 0.08, 0.92
        end

        button:SetNormalTexture(info.texture)
        SetTexture(button:GetNormalTexture(), bg, left, right - 0.04, top + 0.04, bottom)

        button:SetPushedTexture(info.texture)
        button:GetPushedTexture():SetVertexColor(0.5, 0.5, 0.5) -- static: not a theme color
        SetTexture(button:GetPushedTexture(), bg, left + 0.04, right, top, bottom - 0.04)

        button:SetDisabledTexture(info.texture)
        button:GetDisabledTexture():SetDesaturated(true)
        SetTexture(button:GetDisabledTexture(), bg, left, right, top, bottom)
    elseif info.icon then
        left, right, top, bottom = 0.1875, 0.8125, 0.46875, 0.90625

        button:SetNormalTexture(microButtonPrefix..info.icon.."-Up")
        SetTexture(button:GetNormalTexture(), bg, left, right, top, bottom)

        button:SetPushedTexture(microButtonPrefix..info.icon.."-Down")
        SetTexture(button:GetPushedTexture(), bg, left, right, top, bottom)

        button:SetDisabledTexture(microButtonPrefix..info.icon.."-Disabled")
        SetTexture(button:GetDisabledTexture(), bg, left, right, top, bottom)
    end
end

function Skin.MainMenuBarMicroButton(Button, info)
    Skin.FrameTypeButton(Button)
    -- The Blizzard_MicroMenu buttons are 29x37 FULL-art: Blizzard now
    -- crops the legacy texture's transparent top itself
    -- (LoadMicroButtonTextures texCoords {0, 1, 0.359375, 1}), so the old
    -- 28x58 hit-rect/backdrop insets (art-in-bottom-part) no longer apply.
    -- The grid overlaps neighbors by 3px (MicroMenu childXPadding = -3,
    -- Classic\MicroMenuContainer.xml — the stock textures absorb it with
    -- transparent edges); 2px side insets clear the overlap with a 1px
    -- visible gap between plates. Don't touch the layout values — the
    -- container is EditMode-managed.
    Button:SetBackdropOption("offsets", {
        left = 2,
        right = 2,
        top = 1,
        bottom = 1,
    })

    local bg = Button:GetBackdropTexture("bg")
    if Button.Flash then
        Button.Flash:SetPoint("TOPLEFT", bg, 1, -1)
        Button.Flash:SetPoint("BOTTOMRIGHT", bg, -1, 1)
        Button.Flash:SetTexCoord(.1818, .7879, .175, .875)
    end

    if info then
        SetMicroButton(Button, info)
    end
end

local buttonInfo = {
    SpellbookMicroButton = {
        texture = [[Interface\Icons\INV_Misc_Book_09]]
    },
    TalentMicroButton = {
        texture = [[Interface\Icons\Ability_Marksmanship]]
    },
    QuestLogMicroButton = {
        icon = "Quest"
    },
    SocialsMicroButton = {
        icon = "Socials"
    },
    GuildMicroButton = {
        texture = [[Interface\Icons\INV_Shirt_GuildTabard_01]]
    },
    WorldMapMicroButton = {
        texture = [[Interface\WorldMap\WorldMap-Icon]],
        coords = {0.21875, 0.6875, 0.109375, 0.8125}
    },
    MainMenuMicroButton = {
        icon = "MainMenu"
    },
    HelpMicroButton = {
        texture = [[Interface\Icons\INV_Misc_QuestionMark]]
    },
    -- Achievement/Collections/PVP/LFG/EJ/Store (TBC/Mists-only buttons)
    -- deliberately have no info entry: they keep Blizzard's own textures
    -- (set by LoadMicroButtonTextures / their mixins) under the Aurora
    -- backdrop, instead of guessed replacement icons.
}

-- Every button the classic XML defines, across all classic flavors; the
-- per-flavor MicroMenuContainerOverrides decide which are actually shown.
local microButtons = {
    "CharacterMicroButton",
    "SpellbookMicroButton",
    "TalentMicroButton",
    "QuestLogMicroButton",
    "SocialsMicroButton",
    "GuildMicroButton",
    "WorldMapMicroButton",
    "MainMenuMicroButton",
    "HelpMicroButton",
    "AchievementMicroButton",
    "CollectionsMicroButton",
    "PVPMicroButton",
    "LFGMicroButton",
    "EJMicroButton",
    "StoreMicroButton",
}

function private.AddOns.Blizzard_MicroMenu()
    for _, name in ipairs(microButtons) do
        local button = _G[name]
        if button then
            Skin.MainMenuBarMicroButton(button, buttonInfo[name])
        end
    end

    if _G.MicroButtonPortrait and _G.CharacterMicroButton then
        SetTexture(_G.MicroButtonPortrait, _G.CharacterMicroButton:GetBackdropTexture("bg"))
    end
end
