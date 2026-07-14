local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs select

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

--[[ Mists (5.5.4) PvP UI — the MoP PVPQueueFrame inside PVEFrame:
    4 category buttons (bluemenu plaque + ring + circle icon, texcoord
    selection — same machinery as the Group Finder category column),
    HonorQueueFrame (casual: role inset, legacy type dropdown, bonus BG
    plates), ConquestQueueFrame (rated: arena/ratedBG plates, conquest
    cap bar kept stock) and WarGamesQueueFrame (hybrid scroll list).
    Role buttons stay stock (Mainline-only skin chain). Evidence:
    wow-ui-source-classic/Interface/AddOns/Blizzard_PVPUI/Mists/
    Blizzard_PVPUI.{xml,lua}; structural reference: the retail-era
    Aurora Blizzard_PVPUI skin (repo history) whose template treatment
    still maps onto these frames.
]]

local highlightR, highlightG, highlightB

-- flat plate covering its parent; Blizzard's show/hide logic keeps
-- driving it (PvPMegaQueue plate art overflows and clashes otherwise)
local function FlattenStateTexture(texture, parent, r, g, b, a)
    if not texture then return end
    texture:SetBlendMode("BLEND")
    texture:SetColorTexture(r, g, b, a)
    if parent then
        texture:ClearAllPoints()
        texture:SetAllPoints(parent)
    end
end

-- bonus BG / conquest bracket plate buttons: PvPMegaQueue NormalTexture
-- plate + SelectedTexture + Highlight
local function SkinPlateButton(Button)
    local normal = Button.NormalTexture or Button:GetNormalTexture()
    if normal then
        normal:SetAlpha(0)
    end
    Base.SetBackdrop(Button, Color.frame, Color.frame.a)
    FlattenStateTexture(Button.SelectedTexture, Button, highlightR, highlightG, highlightB, 0.2)
    FlattenStateTexture(Button.HighlightTexture or Button:GetHighlightTexture(), Button, highlightR, highlightG, highlightB, 0.1)
end

-- anonymous plain-Frame children carry decorative art (talent-pane lesson)
local function SweepAnonymousChildFrames(Frame)
    for i = 1, _G.select("#", Frame:GetChildren()) do
        local child = _G.select(i, Frame:GetChildren())
        if child:GetObjectType() == "Frame" and not child:GetName() then
            Util.HideFrameTextures(child)
        end
    end
end

do --[[ AddOns\Blizzard_PVPUI.lua ]]
    function Hook.PVPQueueFrame_SelectButton(index)
        for i = 1, 4 do
            local button = _G.PVPQueueFrame["CategoryButton"..i]
            if button and button.Background then
                button.Background:SetShown(i == index)
            end
        end
    end
end

do --[[ AddOns\Blizzard_PVPUI.xml ]]
    function Skin.PVPQueueFrameButtonTemplate(Button)
        Skin.FrameTypeButton(Button)
        Button:SetBackdropOption("offsets", {
            left = 2,
            right = 0,
            top = -3,
            bottom = -5,
        })

        local bg = Button:GetBackdropTexture("bg")
        Util.SetHighlightColor(Button.Background, Color.frame.a)
        Button.Background:SetAllPoints(bg)
        Button.Background:Hide()

        Button.Ring:Hide()
        Base.CropCircularIcon(Button.Icon)
    end
end

function private.AddOns.Blizzard_PVPUI()
    highlightR, highlightG, highlightB = Color.highlight:GetRGB()

    local PVPQueueFrame = _G.PVPQueueFrame
    if not PVPQueueFrame then return end

    for i = 1, 4 do
        local button = PVPQueueFrame["CategoryButton"..i]
        if button then
            Skin.PVPQueueFrameButtonTemplate(button)
        end
    end
    _G.hooksecurefunc("PVPQueueFrame_SelectButton", Hook.PVPQueueFrame_SelectButton)

    ------------
    -- Casual --
    ------------
    local Honor = _G.HonorQueueFrame
    if Honor then
        if Honor.RoleInset then
            Skin.InsetFrameTemplate(Honor.RoleInset)
            SweepAnonymousChildFrames(Honor.RoleInset)
        end
        if Honor.Inset then
            Skin.InsetFrameTemplate(Honor.Inset)
        end
        if _G.HonorQueueFrameTypeDropDown then
            Skin.UIDropDownMenuTemplate(_G.HonorQueueFrameTypeDropDown)
        end
        if _G.HonorQueueFrameSpecificFrameScrollBar then
            Skin.HybridScrollBarTemplate(_G.HonorQueueFrameSpecificFrameScrollBar)
        end

        local Bonus = Honor.BonusFrame
        if Bonus then
            for _, key in ipairs({
                "WorldBattlesTexture", "BattlegroundTexture",
                "BattlegroundHeader", "WorldPVPHeader",
            }) do
                if Bonus[key] then
                    Bonus[key]:SetAlpha(0)
                end
            end
            for _, key in ipairs({
                "CallToArmsButton", "RandomBGButton",
                "WorldPVP1Button", "WorldPVP2Button",
            }) do
                if Bonus[key] then
                    SkinPlateButton(Bonus[key])
                end
            end
            if Bonus.ShadowOverlay then
                Util.HideFrameTextures(Bonus.ShadowOverlay)
            end
            -- IncludedBattlegroundsDropDown is NOT skinned: it is an
            -- invisible menu anchor (the exclude-BG list) — skinning it
            -- paints a floating box+arrow next to the dice button
        end

        if Honor.SoloQueueButton then
            Skin.MagicButtonTemplate(Honor.SoloQueueButton)
        end
        if Honor.GroupQueueButton then
            Skin.MagicButtonTemplate(Honor.GroupQueueButton)
        end
    end

    -----------
    -- Rated --
    -----------
    local Conquest = _G.ConquestQueueFrame
    if Conquest then
        for _, key in ipairs({
            "ArenaTexture", "RatedBGTexture",
            "ArenaHeader", "RatedBGHeader",
        }) do
            if Conquest[key] then
                Conquest[key]:SetAlpha(0)
            end
        end
        if Conquest.Inset then
            Skin.InsetFrameTemplate(Conquest.Inset)
        end
        for _, key in ipairs({"Arena2v2", "Arena3v3", "Arena5v5", "RatedBG"}) do
            if Conquest[key] then
                SkinPlateButton(Conquest[key])
            end
        end
        if Conquest.ShadowOverlay then
            Util.HideFrameTextures(Conquest.ShadowOverlay)
        end
        if Conquest.JoinButton then
            Skin.MagicButtonTemplate(Conquest.JoinButton)
        end
        if Conquest.NoSeason and Skin.GlowBoxTemplate then
            Skin.GlowBoxTemplate(Conquest.NoSeason)
        end
        -- ConquestBar (CapProgressBarTemplate) kept stock first pass
    end

    ---------------
    -- War Games --
    ---------------
    local WarGames = _G.WarGamesQueueFrame
    if WarGames then
        if WarGames.InfoBG then
            WarGames.InfoBG:SetAlpha(0)
        end
        if WarGames.RightInset then
            Skin.InsetFrameTemplate(WarGames.RightInset)
        end

        local scrollFrame = WarGames.scrollFrame or _G.WarGamesQueueFrameScrollFrame
        if _G.WarGamesQueueFrameScrollFrameScrollBar then
            Skin.HybridScrollBarTemplate(_G.WarGamesQueueFrameScrollFrameScrollBar)
        end

        local StripStartButton
        local startButton = _G.WarGameStartButton
        if startButton then
            Skin.MagicButtonTemplate(startButton)

            -- live code restores (or recreates) the RedButton plate art on
            -- every list update — snapshot which textures the SKIN added
            -- (they survive), then re-sweep everything else live on every
            -- state-change path
            local auroraTextures = {}
            local highlight = startButton:GetHighlightTexture()
            for i = 1, _G.select("#", startButton:GetRegions()) do
                local region = _G.select(i, startButton:GetRegions())
                if region:GetObjectType() == "Texture"
                    and (region == highlight or region:GetAlpha() > 0) then
                    -- post-skin, only Aurora's backdrop pieces (and the
                    -- hover highlight) are still visible
                    auroraTextures[region] = true
                end
            end

            -- the red plate is a NINE-SLICE of anonymous textures the
            -- client builds ON DEMAND (probe: 9 regions, one fileID,
            -- created after skin time — and a frame LATER than show, so
            -- synchronous hooks fire too early). Sweep live, and always
            -- follow up on the next frame.
            local function SweepStartButton()
                for i = 1, _G.select("#", startButton:GetRegions()) do
                    local region = _G.select(i, startButton:GetRegions())
                    if region:GetObjectType() == "Texture" and not auroraTextures[region] then
                        region:SetAlpha(0)
                    end
                end
                -- the actual plate art lives on ANONYMOUS SIBLING frames
                -- (probe-verified: the button's parent is a live-only
                -- details sub-frame holding the button + two unnamed
                -- Frames carrying the plate) — sweep unnamed plain-Frame
                -- siblings and any unnamed children
                for i = 1, _G.select("#", startButton:GetChildren()) do
                    local child = _G.select(i, startButton:GetChildren())
                    Util.HideFrameTextures(child, true)
                end
                local parent = startButton:GetParent()
                if parent then
                    -- ...their unnamed plain-Frame children, and the
                    -- parent details frame's OWN regions
                    if not parent:GetName() then
                        Util.HideFrameTextures(parent, true)
                    end
                    for i = 1, _G.select("#", parent:GetChildren()) do
                        local child = _G.select(i, parent:GetChildren())
                        if child:GetObjectType() == "Frame" and not child:GetName() then
                            Util.HideFrameTextures(child, true)
                            for j = 1, _G.select("#", child:GetChildren()) do
                                local grandchild = _G.select(j, child:GetChildren())
                                if not grandchild:GetName() then
                                    Util.HideFrameTextures(grandchild, true)
                                end
                            end
                        end
                    end
                end
            end
            StripStartButton = function()
                SweepStartButton()
                _G.C_Timer.After(0, SweepStartButton)
            end
            StripStartButton()
            WarGames:HookScript("OnShow", StripStartButton)
            startButton:HookScript("OnShow", StripStartButton)
            startButton:HookScript("OnEnable", StripStartButton)
            startButton:HookScript("OnDisable", StripStartButton)
            _G.hooksecurefunc(startButton, "Enable", StripStartButton)
            _G.hooksecurefunc(startButton, "Disable", StripStartButton)
            _G.hooksecurefunc(startButton, "SetEnabled", StripStartButton)
            if _G.WarGameStartButton_Update then
                _G.hooksecurefunc("WarGameStartButton_Update", StripStartButton)
            end
        end
        if WarGames.HorizontalBar then
            Util.HideFrameTextures(WarGames.HorizontalBar)
        end

        -- description panel: its ornate scrollbar track art is parentKeyed
        -- on the INFO scroll frame (and reparented onto the scrollbar in
        -- its OnLoad). The bar itself is a live-only HYBRID (Track/Thumb/
        -- Background parentKeys but NO Backplate/Back/Forward —
        -- Skin.WowTrimScrollBar errors on it, module-fatally), so it gets
        -- a minimal hand treatment
        local infoScroll = _G.WarGamesQueueFrameInfoScrollFrame
        if infoScroll then
            for _, key in ipairs({"scrollBarBackground", "scrollBarArtTop", "scrollBarArtBottom"}) do
                if infoScroll[key] then
                    infoScroll[key]:SetAlpha(0)
                end
            end
            local bar = infoScroll.ScrollBar or _G.WarGamesQueueFrameInfoScrollFrameScrollBar
            if bar then
                if bar.Background then
                    if bar.Background.Hide then bar.Background:Hide() end
                end
                local thumb = bar.Track and bar.Track.Thumb
                if thumb then
                    if thumb.Begin then thumb.Begin:Hide() end
                    if thumb.End then thumb.End:Hide() end
                    if thumb.Middle then thumb.Middle:Hide() end
                    Skin.FrameTypeButton(thumb)
                end
            end
        end

        -- rows LAST: least-certain structure, a failure here must not
        -- cost the rest of the pane
        local function SkinWarGameRows()
            -- the start button's on-demand nine-slice gets rebuilt around
            -- list updates — this hook fires on every one of them
            if StripStartButton then
                StripStartButton()
            end
            if not (scrollFrame and scrollFrame.buttons) then return end
            for _, row in ipairs(scrollFrame.buttons) do
                local entry = row.Entry
                if entry then
                    if entry.Bg then entry.Bg:SetAlpha(0) end
                    if entry.Border then entry.Border:SetAlpha(0) end
                    if entry.Icon then Base.CropIcon(entry.Icon) end
                    FlattenStateTexture(entry.SelectedTexture, entry, highlightR, highlightG, highlightB, 0.2)
                    FlattenStateTexture(entry.HighlightTexture, entry, highlightR, highlightG, highlightB, 0.1)
                end
                -- row.Header keeps its stock +/- state icons
            end
        end
        SkinWarGameRows()
        -- hook the FIELD HybridScrollFrame actually calls (glyph lesson)
        if scrollFrame and scrollFrame.update then
            _G.hooksecurefunc(scrollFrame, "update", SkinWarGameRows)
        end
    end
end
