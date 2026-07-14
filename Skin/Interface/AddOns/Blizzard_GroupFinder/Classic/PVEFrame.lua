local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

--[[ Mists (5.5.4) PVE frame — the MoP Group Finder shell: classic
    PortraitFrameTemplate root piled with bluemenu column art (named
    corners/verts/filigrees + BlueBg), 3 CharacterFrameTabButtonTemplate
    tabs, and the left category column (groupButton1-4: bluemenu plaque +
    ring + circle-masked icon). Selection swaps the plaque's TEXCOORDS
    (not visibility) — with the plaque flattened to a color, a hook
    drives visibility instead. Evidence: wow-ui-source-classic/Interface/
    AddOns/Blizzard_GroupFinder/Classic/PVEFrame.{xml,lua}; structural
    reference: original MoP-era Aurora FrameXML/PVEFrame.lua (repo
    history). Loads at boot (no LoadOnDemand) — FrameXML dispatch is
    safe, same as the active Shared\RaidFinder.lua.
]]

do --[[ Blizzard_GroupFinder\Classic\PVEFrame.lua ]]
    function Hook.GroupFinderFrame_SelectGroupButton(index)
        local GroupFinderFrame = _G.GroupFinderFrame
        for i = 1, 4 do
            local button = GroupFinderFrame["groupButton"..i]
            if button and button.bg then
                button.bg:SetShown(i == index)
            end
        end
    end
end

do --[[ Blizzard_GroupFinder\Classic\PVEFrame.xml ]]
    function Skin.GroupFinderGroupButtonTemplate(Button)
        Skin.FrameTypeButton(Button)
        Button:SetBackdropOption("offsets", {
            left = 2,
            right = 0,
            top = -3,
            bottom = -5,
        })

        local bg = Button:GetBackdropTexture("bg")
        Util.SetHighlightColor(Button.bg, Color.frame.a)
        Button.bg:SetAllPoints(bg)
        Button.bg:Hide()

        Button.ring:Hide()
        Base.CropCircularIcon(Button.icon)
    end
end

function private.FrameXML.PVEFrame()
    local PVEFrame = _G.PVEFrame

    -- bluemenu column art: BlueBg, corners, vertical lines, gold border
    -- tiles, filigrees — sweep, then chrome
    Util.HideFrameTextures(PVEFrame, true)
    Skin.PortraitFrameTemplate(PVEFrame)

    if PVEFrame.shadows then
        Util.HideFrameTextures(PVEFrame.shadows)
    end
    if PVEFrame.Inset then
        Skin.InsetFrameTemplate(PVEFrame.Inset)
    end

    PVEFrame.maxTabWidth = 150
    for i = 1, 3 do
        local tab = _G["PVEFrameTab"..i]
        if tab then
            Skin.CharacterFrameTabButtonTemplate(tab)
        end
    end

    local GroupFinderFrame = _G.GroupFinderFrame
    if GroupFinderFrame then
        for i = 1, 4 do
            local button = GroupFinderFrame["groupButton"..i]
            if button then
                Skin.GroupFinderGroupButtonTemplate(button)
            end
        end
    end
    _G.hooksecurefunc("GroupFinderFrame_SelectGroupButton", Hook.GroupFinderFrame_SelectGroupButton)
end
