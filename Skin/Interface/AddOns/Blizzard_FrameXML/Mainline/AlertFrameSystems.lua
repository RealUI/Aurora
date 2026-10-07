local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals next

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color = Aurora.Color

do --[[ FrameXML\AlertFrameSystems.lua ]]
    -- The setters run inside the alert's SetUp (or Coalesce), before Blizzard
    -- anchors the rewards, and set the icon texture themselves. Restyle the
    -- reward button in place; see Skin.DungeonCompletionAlertFrameRewardTemplate.
    local function StyleReward(frame)
        Skin.DungeonCompletionAlertFrameRewardTemplate(frame)
    end
    Hook.DungeonCompletionAlertFrameReward_SetRewardMoney = StyleReward
    Hook.DungeonCompletionAlertFrameReward_SetRewardXP = StyleReward
    Hook.DungeonCompletionAlertFrameReward_SetRewardItem = StyleReward
    Hook.DungeonCompletionAlertFrameReward_SetReward = StyleReward
end

do --[[ FrameXML\AlertFrameSystems.xml ]]
    --[[ Taint audit 2026-10-06 (B170 follow-up): every alert and its reward
        buttons are skinned in place. The setUpFunction post-hook runs inside
        AlertFrameQueueMixin:ShowAlert, which goes on to AddAlertFrame
        (UpdateAnchors, SetParent, AlertFrame_ShowNewAlert) with the same
        frame, and the reward setters run inside SetUp itself, before
        StandardRewardAlertFrame_AdjustRewardAnchors. The old skins wrote
        backdrop methods, _aurora* and _title fields, icon border textures and
        new anchors and sizes onto the alert mid-execution, and AlertFrames.lua
        re-ran them from an AddAlertFrame post-hook. Now: colours, texcoords
        and vertex offsets on existing regions only, state in this weak table,
        no FrameTypeFrame (so RealUI's stripes are not added to alerts). Where
        SetUp re-sets art on every show (Achievement, LootWon, RAF rewards,
        garrison followers) the same C-only calls are repeated per show.
        Blizzard's ADD-mode glow and shine flashes are left as they are. ]]
    local styled = setmetatable({}, {__mode = "k"})

    -- Shape an existing texture into a flat Color.frame band with vertex
    -- offsets (1 upper-left, 2 lower-left, 3 upper-right, 4 lower-right), so
    -- the region keeps its size and anchors. Both rects are in the alert's
    -- space from its top-left corner, y downwards: the region's own rect, then
    -- the band. Where the alert's icon is drawn below the art the band starts
    -- right of the icon and is as tall as it, like the quest reward buttons;
    -- where the icon is drawn above it the band sits behind icon and text.
    local function SetBand(texture, rectLeft, rectTop, rectRight, rectBottom, left, top, right, bottom)
        local r, g, b = Color.frame:GetRGB()
        texture:SetColorTexture(r, g, b, Color.frame.a)
        texture:SetVertexOffset(1, left - rectLeft, rectTop - top)
        texture:SetVertexOffset(2, left - rectLeft, rectBottom - bottom)
        texture:SetVertexOffset(3, right - rectRight, rectTop - top)
        texture:SetVertexOffset(4, right - rectRight, rectBottom - bottom)
    end

    -- The rect of a texture anchored CENTER (x 0, y offset) on its alert.
    local function CenteredRect(frame, texture, offsetY)
        local frameW, frameH = frame:GetSize()
        local width, height = texture:GetSize()
        local left, top = (frameW - width) / 2, (frameH - height) / 2 - offsetY
        return left, top, left + width, top + height
    end

    -- Where an anchor point sits in a box, as fractions from its top-left.
    local anchorPoints = {
        TOPLEFT = {0, 0}, TOP = {0.5, 0}, TOPRIGHT = {1, 0},
        LEFT = {0, 0.5}, CENTER = {0.5, 0.5}, RIGHT = {1, 0.5},
        BOTTOMLEFT = {0, 1}, BOTTOM = {0.5, 1}, BOTTOMRIGHT = {1, 1},
    }

    -- SetBand for a region with one anchor on its alert: its rect is read
    -- from that anchor and its size. When it cannot be read (other anchors,
    -- no size yet) the art is only cleared, never moved.
    local function BandRegion(frame, region, left, top, right, bottom)
        local point, relativeTo, relativePoint, x, y = region:GetPoint(1)
        local from, to = anchorPoints[point], anchorPoints[relativePoint]
        local width, height = region:GetSize()
        if region:GetNumPoints() ~= 1 or relativeTo ~= frame or not (from and to)
            or not (width and width > 0 and height and height > 0) then
            region:SetTexture("")
            return
        end

        local frameW, frameH = frame:GetSize()
        local rectLeft = to[1] * frameW + x - from[1] * width
        local rectTop = to[2] * frameH - y - from[2] * height
        SetBand(region, rectLeft, rectTop, rectLeft + width, rectTop + height, left, top, right, bottom)
    end

    -- An unnamed texture, found by its (lower-case) atlas name.
    local function AtlasRegion(frame, atlas)
        for _, region in next, {frame:GetRegions()} do
            if region:IsObjectType("Texture") then
                local name = region:GetAtlas()
                if name and name:lower() == atlas then
                    return region
                end
            end
        end
    end

    -- Reward icons: Base.CropIcon without a parent only drops the circle mask
    -- and crops the icon square; the reward ring is cleared.
    function Skin.DungeonCompletionAlertFrameRewardTemplate(Button)
        if styled[Button] then return end
        styled[Button] = true

        local texture, ring = Button:GetRegions()
        Base.CropIcon(texture)
        ring:SetTexture("")
    end
    Skin.InvasionAlertFrameRewardTemplate = Skin.DungeonCompletionAlertFrameRewardTemplate
    Skin.WorldQuestFrameRewardTemplate = Skin.DungeonCompletionAlertFrameRewardTemplate

    -- SetUp toggles raidArt / dungeonArt and moves the 45px dungeonTexture
    -- (BOTTOMLEFT 13,18 for a dungeon, 26,15 for a raid), so each art gets
    -- the band for its own icon position, once. Blizzard's heroic icon,
    -- glow and shine are left as they are.
    function Skin.DungeonCompletionAlertFrameTemplate(ContainedAlertFrame)
        if styled[ContainedAlertFrame] then return end
        styled[ContainedAlertFrame] = true

        Base.CropIcon(ContainedAlertFrame.dungeonTexture)

        local width, height = ContainedAlertFrame:GetSize()
        local left, top, right, bottom = CenteredRect(ContainedAlertFrame, ContainedAlertFrame.dungeonArt, 0)
        SetBand(ContainedAlertFrame.dungeonArt, left, top, right, bottom, 13 + 45 + 1, height - 18 - 45, width - 7, height - 18)

        left, top, right, bottom = CenteredRect(ContainedAlertFrame, ContainedAlertFrame.raidArt, -3)
        SetBand(ContainedAlertFrame.raidArt, left, top, right, bottom, 26 + 45 + 1, height - 15 - 45, width - 20, height - 15)
    end

    -- Background becomes the old backdrop's band behind the icon and shield
    -- frames; the icon ring is cleared and the black "unlocked" line made
    -- white. SetUp re-sets both atlases and the alert's height (guild 104,
    -- normal 101) on every show, so those are redone per show; the guild band
    -- also takes in the guild name above the old one. Shield, guild banner,
    -- name layout and the glow/shine are Blizzard's.
    function Skin.AchievementAlertFrameTemplate(ContainedAlertFrame)
        if not styled[ContainedAlertFrame] then
            styled[ContainedAlertFrame] = true
            Base.CropIcon(ContainedAlertFrame.Icon.Texture)
            ContainedAlertFrame.Unlocked:SetTextColor(Color.white:GetRGB())
        end

        ContainedAlertFrame.Icon.Overlay:SetTexture("")
        local width, height = ContainedAlertFrame:GetSize()
        local top = ContainedAlertFrame.GuildName:IsShown() and 8 or 18
        BandRegion(ContainedAlertFrame, ContainedAlertFrame.Background, 6, top, width - 8, height - 16)
    end

    -- Background becomes the old backdrop's band behind the icon frame; the
    -- icon ring is cleared, the black "progressed" line made white. SetUp
    -- only sets the name and icon, so once.
    function Skin.CriteriaAlertFrameTemplate(ContainedAlertFrame)
        if styled[ContainedAlertFrame] then return end
        styled[ContainedAlertFrame] = true

        local width, height = ContainedAlertFrame:GetSize()
        BandRegion(ContainedAlertFrame, ContainedAlertFrame.Background, 0, 2, width, height - 8)
        ContainedAlertFrame.Unlocked:SetTextColor(Color.white:GetRGB())
        ContainedAlertFrame.Name:SetTextColor(Color.grayLight:GetRGB())
        Base.CropIcon(ContainedAlertFrame.Icon.Texture)
        ContainedAlertFrame.Icon.Overlay:SetTexture("")
    end

    -- Same layout as Criteria. The icon is an atlas, so it is not cropped.
    function Skin.MonthlyActivityFrameTemplate(ContainedAlertFrame)
        if styled[ContainedAlertFrame] then return end
        styled[ContainedAlertFrame] = true

        local width, height = ContainedAlertFrame:GetSize()
        BandRegion(ContainedAlertFrame, ContainedAlertFrame.Background, 0, 2, width, height - 8)
        ContainedAlertFrame.Unlocked:SetTextColor(Color.white:GetRGB())
        ContainedAlertFrame.Icon.Overlay:SetTexture("")
    end

    -- The toast art (region 2, drawn above the emblem background) becomes a
    -- band right of the 37px guild emblem at LEFT 14,0, at the old backdrop's
    -- height. Blizzard's emblem is left as it is. Once.
    function Skin.GuildChallengeAlertFrameTemplate(ContainedAlertFrame)
        if styled[ContainedAlertFrame] then return end
        styled[ContainedAlertFrame] = true

        local _, toastFrame = ContainedAlertFrame:GetRegions()
        local width, height = ContainedAlertFrame:GetSize()
        BandRegion(ContainedAlertFrame, toastFrame, 14 + 37 + 1, 14, width - 10, height - 15)
    end

    -- Regions: toast art (LEFT, atlas size, drawn above the icon), the 48px
    -- icon at LEFT 15,0, title, ZoneName, BonusStar. In place, once (see the
    -- taint note above SetBand).
    function Skin.ScenarioLegionInvasionAlertFrameTemplate(ContainedAlertFrame)
        if styled[ContainedAlertFrame] then return end
        styled[ContainedAlertFrame] = true

        local toastFrame, icon = ContainedAlertFrame:GetRegions()
        Base.CropIcon(icon)

        local width, height = ContainedAlertFrame:GetSize()
        local toastW, toastH = toastFrame:GetSize()
        local toastTop = (height - toastH) / 2
        local iconTop = (height - 48) / 2
        SetBand(toastFrame, 0, toastTop, toastW, toastTop + toastH, 15 + 48 + 1, iconTop, width - 11, iconTop + 48)
    end
    -- Regions: icon background, the 45px dungeonTexture at LEFT 17,0, the
    -- toast art (all points, drawn above the icon), title, dungeonName,
    -- BonusStar, shine. In place, once.
    function Skin.ScenarioAlertFrameTemplate(ContainedAlertFrame)
        if styled[ContainedAlertFrame] then return end
        styled[ContainedAlertFrame] = true

        local iconBG, _, toastFrame = ContainedAlertFrame:GetRegions()
        iconBG:SetTexture("")
        Base.CropIcon(ContainedAlertFrame.dungeonTexture)

        local width, height = ContainedAlertFrame:GetSize()
        local iconTop = (height - 45) / 2
        SetBand(toastFrame, 0, 0, width, height, 17 + 45 + 1, iconTop, width - 20, iconTop + 45)
    end

    -- Money and honor: Background (all points) becomes the old backdrop's
    -- band behind the icon; the gold icon ring is cleared. SetUp only sets
    -- the amount, so once. The old yellow border is gone with the backdrop.
    function Skin.MoneyWonAlertFrameTemplate(ContainedAlertFrame)
        if styled[ContainedAlertFrame] then return end
        styled[ContainedAlertFrame] = true

        local width, height = ContainedAlertFrame:GetSize()
        SetBand(ContainedAlertFrame.Background, 0, 0, width, height, 11, 10, width - 11, height - 11)
        Base.CropIcon(ContainedAlertFrame.Icon)
        ContainedAlertFrame.IconBorder:SetTexture("")
    end
    Skin.HonorAwardedAlertFrameTemplate = Skin.MoneyWonAlertFrameTemplate

    -- Garrison building and talent: Garr_Toast (drawn above the 40px icon at
    -- LEFT 20,2) becomes a band right of the icon, as tall as it. Once.
    function Skin.GarrisonBuildingAlertFrameTemplate(ContainedAlertFrame)
        if styled[ContainedAlertFrame] then return end
        styled[ContainedAlertFrame] = true

        Base.CropIcon(ContainedAlertFrame.Icon)
        local toastFrame = AtlasRegion(ContainedAlertFrame, "garr_toast")
        if toastFrame then
            local width, height = ContainedAlertFrame:GetSize()
            local iconTop = (height - 40) / 2 - 2
            BandRegion(ContainedAlertFrame, toastFrame, 20 + 40 + 1, iconTop, width - 16, iconTop + 40)
        end
    end
    Skin.GarrisonTalentAlertFrameTemplate = Skin.GarrisonBuildingAlertFrameTemplate

    -- Missions (standard, ship, random): Background becomes a band behind the
    -- mission icon and text; Blizzard's icon art is left. Random missions also
    -- lose the blank plate drawn over it. Once: SetUp only resizes and moves
    -- the icon and text.
    function Skin.GarrisonMissionAlertFrameTemplate(ContainedAlertFrame)
        if styled[ContainedAlertFrame] then return end
        styled[ContainedAlertFrame] = true

        local width, height = ContainedAlertFrame:GetSize()
        BandRegion(ContainedAlertFrame, ContainedAlertFrame.Background, 10, 10, width - 12, height - 10)
        if ContainedAlertFrame.Blank then
            ContainedAlertFrame.Blank:SetTexture("")
        end
    end
    Skin.GarrisonRandomMissionAlertFrameTemplate = Skin.GarrisonMissionAlertFrameTemplate

    -- Followers (standard and ship): the toast art becomes a band behind the
    -- portrait and text, once; Blizzard's portrait is left. SetUp re-sets and
    -- shows FollowerBG, the quality swoosh, on every show, so it is cleared
    -- per show.
    function Skin.GarrisonFollowerAlertFrameTemplate(ContainedAlertFrame)
        if not styled[ContainedAlertFrame] then
            styled[ContainedAlertFrame] = true

            local background = ContainedAlertFrame.Background or AtlasRegion(ContainedAlertFrame, "garr_missiontoast")
            if background then
                local width, height = ContainedAlertFrame:GetSize()
                BandRegion(ContainedAlertFrame, background, 10, 10, width - 12, height - 10)
            end
        end

        ContainedAlertFrame.FollowerBG:SetTexture("")
    end
    Skin.GarrisonStandardFollowerAlertFrameTemplate = Skin.GarrisonFollowerAlertFrameTemplate
    Skin.GarrisonShipFollowerAlertFrameTemplate = Skin.GarrisonFollowerAlertFrameTemplate

    -- The archaeology toast art (region 1) becomes a band behind the race art
    -- and text. The race art is not an icon, so it is left uncropped. Once.
    function Skin.DigsiteCompleteToastFrameTemplate(ContainedAlertFrame)
        if styled[ContainedAlertFrame] then return end
        styled[ContainedAlertFrame] = true

        local toastFrame = ContainedAlertFrame:GetRegions()
        local width, height = ContainedAlertFrame:GetSize()
        BandRegion(ContainedAlertFrame, toastFrame, 10, 14, width - 10, height - 14)
    end

    -- Store delivery: Background (no anchors, so all points) becomes a band
    -- behind the icon and text. Once.
    function Skin.EntitlementDeliveredAlertFrameTemplate(ContainedAlertFrame)
        if styled[ContainedAlertFrame] then return end
        styled[ContainedAlertFrame] = true

        local width, height = ContainedAlertFrame:GetSize()
        SetBand(ContainedAlertFrame.Background, 0, 0, width, height, 13, 12, width - 13, height - 12)
        Base.CropIcon(ContainedAlertFrame.Icon)
    end

    -- RAF rewards: SetUp re-sets and shows either the standard or the fancy
    -- toast atlas on every show, so the shown one becomes the band, per show.
    -- Blizzard's watermark is left.
    function Skin.RafRewardDeliveredAlertFrameTemplate(ContainedAlertFrame)
        if not styled[ContainedAlertFrame] then
            styled[ContainedAlertFrame] = true
            Base.CropIcon(ContainedAlertFrame.Icon)
        end

        local background = ContainedAlertFrame.StandardBackground
        if ContainedAlertFrame.FancyBackground:IsShown() then
            background = ContainedAlertFrame.FancyBackground
        end
        local width, height = ContainedAlertFrame:GetSize()
        BandRegion(ContainedAlertFrame, background, 27, 14, width - 16, height - 8)
    end

    -- LootWon: SetUp shows one of four backgrounds per show (re-setting the
    -- atlas of all but Background), so the shown one becomes a band behind
    -- the loot item and text, per show. The loot item keeps Blizzard's
    -- quality border, as it did before.
    local lootWonBackgrounds = {"Background", "BGAtlas", "PvPBackground", "RatedPvPBackground"}
    function Skin.LootWonAlertFrameTemplate(ContainedAlertFrame)
        local width, height = ContainedAlertFrame:GetSize()
        for i = 1, #lootWonBackgrounds do
            local background = ContainedAlertFrame[lootWonBackgrounds[i]]
            if background:IsShown() then
                BandRegion(ContainedAlertFrame, background, 14, 14, width - 14, height - 14)
            end
        end
    end

    -- LootUpgrade: Background becomes a band behind the icon and text, once.
    -- The base and upgrade quality borders, arrows and sheen are Blizzard's:
    -- they are the upgrade animation.
    function Skin.LootUpgradeFrameTemplate(ContainedAlertFrame)
        if styled[ContainedAlertFrame] then return end
        styled[ContainedAlertFrame] = true

        local width, height = ContainedAlertFrame:GetSize()
        BandRegion(ContainedAlertFrame, ContainedAlertFrame.Background, 14, 14, width - 14, height - 14)
        Base.CropIcon(ContainedAlertFrame.Icon)
    end

    -- Like the dungeon art: ToastBackground (drawn above the 45px quest icon
    -- at BOTTOMLEFT 13,18) becomes a band right of the icon, once. Currency
    -- rewards get their icon from SetUp directly, not through the reward
    -- setters, so the shown reward buttons are styled here as well.
    function Skin.WorldQuestCompleteAlertFrameTemplate(ContainedAlertFrame)
        if not styled[ContainedAlertFrame] then
            styled[ContainedAlertFrame] = true

            Base.CropIcon(ContainedAlertFrame.QuestTexture)
            local width, height = ContainedAlertFrame:GetSize()
            BandRegion(ContainedAlertFrame, ContainedAlertFrame.ToastBackground, 13 + 45 + 1, height - 18 - 45, width - 7, height - 18)
        end

        if ContainedAlertFrame.RewardFrames then
            for _, button in next, ContainedAlertFrame.RewardFrames do
                if button:IsShown() then
                    Skin.WorldQuestFrameRewardTemplate(button)
                end
            end
        end
    end

    -- Background (drawn above the 52px icon at TOPLEFT 48,-32) becomes a band
    -- right of the icon, as tall as it; the ring, star glow and particle
    -- flashes are cleared. The ADD-mode Background2/3 flash is Blizzard's.
    -- Once.
    local legendaryFlashes = {"Ring1", "Starglow", "Particles1", "Particles2", "Particles3"}
    function Skin.LegendaryItemAlertFrameTemplate(ContainedAlertFrame)
        if styled[ContainedAlertFrame] then return end
        styled[ContainedAlertFrame] = true

        Base.CropIcon(ContainedAlertFrame.Icon)
        local width = ContainedAlertFrame:GetWidth()
        BandRegion(ContainedAlertFrame, ContainedAlertFrame.Background, 48 + 52 + 1, 32, width - 18, 32 + 52)
        for i = 1, #legendaryFlashes do
            ContainedAlertFrame[legendaryFlashes[i]]:SetTexture("")
        end
    end

    -- Pet, mount, toy, warband scene, runeforge power and cosmetic toasts:
    -- each subtype's Background becomes a band behind the icon and text.
    -- Blizzard's quality border, re-set on every show (and again when a
    -- cosmetic's item loads), is left, as on the loot toasts. Once.
    function Skin.ItemAlertFrameTemplate(ContainedAlertFrame)
        if styled[ContainedAlertFrame] then return end
        styled[ContainedAlertFrame] = true

        Base.CropIcon(ContainedAlertFrame.Icon)
        if ContainedAlertFrame.Background then
            local width, height = ContainedAlertFrame:GetSize()
            BandRegion(ContainedAlertFrame, ContainedAlertFrame.Background, 15, 12, width - 15, height - 16)
        end
    end
    Skin.NewPetAlertFrameTemplate          = Skin.ItemAlertFrameTemplate
    Skin.NewMountAlertFrameTemplate        = Skin.ItemAlertFrameTemplate
    Skin.NewToyAlertFrameTemplate          = Skin.ItemAlertFrameTemplate
    Skin.NewWarbandSceneAlertFrameTemplate = Skin.ItemAlertFrameTemplate
    Skin.NewRuneforgePowerAlertFrameTemplate = Skin.ItemAlertFrameTemplate
    Skin.NewCosmeticAlertFrameTemplate     = Skin.ItemAlertFrameTemplate

    -- Recipes and specializations: recipetoast-bg (drawn above the 64px icon
    -- at LEFT 18,0) becomes a band right of the icon, as tall as it. SetUp
    -- masks the icon round on every show, so it stays round. Once.
    function Skin.NewRecipeLearnedAlertFrameTemplate(ContainedAlertFrame)
        if styled[ContainedAlertFrame] then return end
        styled[ContainedAlertFrame] = true

        local toastFrame = AtlasRegion(ContainedAlertFrame, "recipetoast-bg")
        if toastFrame then
            local width, height = ContainedAlertFrame:GetSize()
            local iconTop = (height - 64) / 2
            BandRegion(ContainedAlertFrame, toastFrame, 18 + 64 + 1, iconTop, width - 24, iconTop + 64)
        end
    end
    Skin.SkillLineSpecsUnlockedAlertFrameTemplate = Skin.NewRecipeLearnedAlertFrameTemplate

    -- Housing item and endeavor task toasts: Background becomes a band behind
    -- the icon and text; the frame art (both Border textures), leaves,
    -- divider and the ADD-mode glow, light ray and sparkle layers SetUp
    -- animates are cleared. Once: SetUp only sets alphas and plays them.
    local housingArt = {
        "Border", "LeafTL", "LeafL", "LeafBL", "LeafTR", "LeafBR",
        "Divider", "Glow", "LightRays", "LightRays2", "Sparkles",
    }
    function Skin.HousingItemEarnedAlertFrameTemplate(ContainedAlertFrame)
        if styled[ContainedAlertFrame] then return end
        styled[ContainedAlertFrame] = true

        local width, height = ContainedAlertFrame:GetSize()
        BandRegion(ContainedAlertFrame, ContainedAlertFrame.Background, 30, 16, width - 25, height - 10)

        local toastFrame = AtlasRegion(ContainedAlertFrame, "housing-item-toast-frame")
        if toastFrame then
            toastFrame:SetTexture("")
        end
        for i = 1, #housingArt do
            ContainedAlertFrame[housingArt[i]]:SetTexture("")
        end
        if ContainedAlertFrame.Icon then
            Base.CropIcon(ContainedAlertFrame.Icon)
        end
    end
    Skin.InitiativeTaskCompleteAlertFrameTemplate = Skin.HousingItemEarnedAlertFrameTemplate
end

function private.FrameXML.AlertFrameSystems()
    -- Hook each alert system's setUpFunction on the subsystem object directly.
    -- Blizzard stores direct function references in subsystem.setUpFunction before
    -- addons load, so hooksecurefunc on the global function name never fires
    -- (the call goes through the stored reference, bypassing the global wrapper).
    -- By hooking the table entry on the subsystem itself, self.setUpFunction
    -- resolves to the wrapper and the hook fires reliably.

    -- Simple Alerts
    _G.hooksecurefunc(_G.GuildChallengeAlertSystem, "setUpFunction",              function(frame) Skin.GuildChallengeAlertFrameTemplate(frame) end)
    _G.hooksecurefunc(_G.DungeonCompletionAlertSystem, "setUpFunction",           function(frame) Skin.DungeonCompletionAlertFrameTemplate(frame) end)
    _G.hooksecurefunc(_G.ScenarioAlertSystem, "setUpFunction",                    function(frame) Skin.ScenarioAlertFrameTemplate(frame) end)
    _G.hooksecurefunc(_G.InvasionAlertSystem, "setUpFunction",                    function(frame) Skin.ScenarioLegionInvasionAlertFrameTemplate(frame) end)
    _G.hooksecurefunc(_G.GarrisonBuildingAlertSystem, "setUpFunction",            function(frame) Skin.GarrisonBuildingAlertFrameTemplate(frame) end)
    _G.hooksecurefunc(_G.GarrisonMissionAlertSystem, "setUpFunction",             function(frame) Skin.GarrisonMissionAlertFrameTemplate(frame) end)
    _G.hooksecurefunc(_G.GarrisonShipMissionAlertSystem, "setUpFunction",         function(frame) Skin.GarrisonMissionAlertFrameTemplate(frame) end)
    _G.hooksecurefunc(_G.GarrisonRandomMissionAlertSystem, "setUpFunction",       function(frame) Skin.GarrisonRandomMissionAlertFrameTemplate(frame) end)
    _G.hooksecurefunc(_G.GarrisonFollowerAlertSystem, "setUpFunction",            function(frame) Skin.GarrisonStandardFollowerAlertFrameTemplate(frame) end)
    _G.hooksecurefunc(_G.GarrisonShipFollowerAlertSystem, "setUpFunction",        function(frame) Skin.GarrisonShipFollowerAlertFrameTemplate(frame) end)
    _G.hooksecurefunc(_G.GarrisonTalentAlertSystem, "setUpFunction",              function(frame) Skin.GarrisonTalentAlertFrameTemplate(frame) end)
    _G.hooksecurefunc(_G.DigsiteCompleteAlertSystem, "setUpFunction",             function(frame) Skin.DigsiteCompleteToastFrameTemplate(frame) end)
    _G.hooksecurefunc(_G.EntitlementDeliveredAlertSystem, "setUpFunction",        function(frame) Skin.EntitlementDeliveredAlertFrameTemplate(frame) end)
    _G.hooksecurefunc(_G.RafRewardDeliveredAlertSystem, "setUpFunction",          function(frame) Skin.RafRewardDeliveredAlertFrameTemplate(frame) end)
    _G.hooksecurefunc(_G.WorldQuestCompleteAlertSystem, "setUpFunction",          function(frame) Skin.WorldQuestCompleteAlertFrameTemplate(frame) end)
    _G.hooksecurefunc(_G.LegendaryItemAlertSystem, "setUpFunction",               function(frame) Skin.LegendaryItemAlertFrameTemplate(frame) end)

    -- Queued Alerts
    _G.hooksecurefunc(_G.AchievementAlertSystem, "setUpFunction",                 function(frame) Skin.AchievementAlertFrameTemplate(frame) end)
    _G.hooksecurefunc(_G.CriteriaAlertSystem, "setUpFunction",                    function(frame) Skin.CriteriaAlertFrameTemplate(frame) end)
    _G.hooksecurefunc(_G.LootAlertSystem, "setUpFunction",                        function(frame) Skin.LootWonAlertFrameTemplate(frame) end)
    _G.hooksecurefunc(_G.LootUpgradeAlertSystem, "setUpFunction",                 function(frame) Skin.LootUpgradeFrameTemplate(frame) end)
    _G.hooksecurefunc(_G.MoneyWonAlertSystem, "setUpFunction",                    function(frame) Skin.MoneyWonAlertFrameTemplate(frame) end)
    _G.hooksecurefunc(_G.HonorAwardedAlertSystem, "setUpFunction",                function(frame) Skin.HonorAwardedAlertFrameTemplate(frame) end)
    _G.hooksecurefunc(_G.NewRecipeLearnedAlertSystem, "setUpFunction",            function(frame) Skin.NewRecipeLearnedAlertFrameTemplate(frame) end)
    _G.hooksecurefunc(_G.SkillLineSpecsUnlockedAlertSystem, "setUpFunction",      function(frame) Skin.SkillLineSpecsUnlockedAlertFrameTemplate(frame) end)
    _G.hooksecurefunc(_G.NewPetAlertSystem, "setUpFunction",                      function(frame) Skin.NewPetAlertFrameTemplate(frame) end)
    _G.hooksecurefunc(_G.NewMountAlertSystem, "setUpFunction",                    function(frame) Skin.NewMountAlertFrameTemplate(frame) end)
    _G.hooksecurefunc(_G.NewToyAlertSystem, "setUpFunction",                      function(frame) Skin.NewToyAlertFrameTemplate(frame) end)
    _G.hooksecurefunc(_G.NewWarbandSceneAlertSystem, "setUpFunction",             function(frame) Skin.NewWarbandSceneAlertFrameTemplate(frame) end)
    _G.hooksecurefunc(_G.NewRuneforgePowerAlertSystem, "setUpFunction",           function(frame) Skin.NewRuneforgePowerAlertFrameTemplate(frame) end)
    _G.hooksecurefunc(_G.NewCosmeticAlertFrameSystem, "setUpFunction",            function(frame) Skin.NewCosmeticAlertFrameTemplate(frame) end)
    _G.hooksecurefunc(_G.MonthlyActivityAlertSystem, "setUpFunction",             function(frame) Skin.MonthlyActivityFrameTemplate(frame) end)
    _G.hooksecurefunc(_G.HousingItemEarnedAlertFrameSystem, "setUpFunction",      function(frame) Skin.HousingItemEarnedAlertFrameTemplate(frame) end)
    _G.hooksecurefunc(_G.InitiativeTaskCompleteAlertFrameSystem, "setUpFunction", function(frame) Skin.InitiativeTaskCompleteAlertFrameTemplate(frame) end)

    -- DungeonCompletion reward hooks (called via global lookup from within SetUp, so global hook works)
    _G.hooksecurefunc("DungeonCompletionAlertFrameReward_SetRewardMoney", Hook.DungeonCompletionAlertFrameReward_SetRewardMoney)
    _G.hooksecurefunc("DungeonCompletionAlertFrameReward_SetRewardXP", Hook.DungeonCompletionAlertFrameReward_SetRewardXP)
    _G.hooksecurefunc("DungeonCompletionAlertFrameReward_SetRewardItem", Hook.DungeonCompletionAlertFrameReward_SetRewardItem)
    _G.hooksecurefunc("DungeonCompletionAlertFrameReward_SetReward", Hook.DungeonCompletionAlertFrameReward_SetReward)
end
