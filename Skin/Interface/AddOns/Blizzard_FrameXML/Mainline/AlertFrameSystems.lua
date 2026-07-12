local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals select next

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

do --[[ FrameXML\AlertFrameSystems.lua ]]
    function Hook.DungeonCompletionAlertFrameReward_SetRewardMoney(frame, optionalMoney)
        frame.texture:SetTexture([[Interface/Icons/inv_misc_coin_02]])
    end
    function Hook.DungeonCompletionAlertFrameReward_SetRewardXP(frame, optionalXP)
        frame.texture:SetTexture([[Interface/Icons/xp_icon]])
    end
    function Hook.DungeonCompletionAlertFrameReward_SetRewardItem(frame, itemLink, texture)
        frame.texture:SetTexture(texture)
    end
    function Hook.DungeonCompletionAlertFrameReward_SetReward(frame, reward)
        frame.texture:SetTexture(reward.texturePath)
    end
end

do --[[ FrameXML\AlertFrameSystems.xml ]]
    --[[
    function Skin.TemplateAlertFrameTemplate(ContainedAlertFrame)
        if not ContainedAlertFrame._auroraTemplate then
            -- Called when created: the main skin
            Skin.FrameTypeFrame(ContainedAlertFrame)
            ContainedAlertFrame:SetBackdropOption("offsets", {
                left = 11,
                right = 11,
                top = 10,
                bottom = 10,
            })

            local bg = ContainedAlertFrame:GetBackdropTexture("bg")
            ContainedAlertFrame.glow:SetPoint("TOPLEFT", bg, -10, 10)
            ContainedAlertFrame.glow:SetPoint("BOTTOMRIGHT", bg, 10, -10)
            ContainedAlertFrame.glow:SetAtlas("Toast-Flash")
            ContainedAlertFrame.glow:SetTexCoord(0, 1, 0, 1)

            ContainedAlertFrame._auroraTemplate = "TemplateAlertFrameTemplate"
        else
            -- Called OnShow: adjustments based on changes made in <AlertFrameSystem>.setUpFunction
        end
    end
    ]]
    function Skin.DungeonCompletionAlertFrameRewardTemplate(Button)
        local texture, ring = Button:GetRegions()
        Base.CropIcon(texture, Button)
        ring:Hide()
    end
    Skin.InvasionAlertFrameRewardTemplate = Skin.DungeonCompletionAlertFrameRewardTemplate
    Skin.WorldQuestFrameRewardTemplate = Skin.DungeonCompletionAlertFrameRewardTemplate

    local heroicTexture = _G.CreateTextureMarkup([[Interface/LFGFrame/UI-LFG-ICON-HEROIC]], 32, 32, 16, 20, 0, 0.5, 0, 0.625, -5, 0)
    function Skin.DungeonCompletionAlertFrameTemplate(ContainedAlertFrame)
        if not ContainedAlertFrame._auroraTemplate then
            Skin.FrameTypeFrame(ContainedAlertFrame)
            local bg = ContainedAlertFrame:GetBackdropTexture("bg")

            Base.CropIcon(ContainedAlertFrame.dungeonTexture, ContainedAlertFrame)
            ContainedAlertFrame.raidArt:SetAlpha(0)
            ContainedAlertFrame.dungeonArt:SetAlpha(0)

            local title = select(7, ContainedAlertFrame:GetRegions())
            title:SetPoint("LEFT", ContainedAlertFrame.dungeonTexture, "RIGHT", 5, 0)
            title:SetPoint("RIGHT", bg, -5, 0)

            ContainedAlertFrame.instanceName:SetPoint("LEFT", ContainedAlertFrame.dungeonTexture, "RIGHT", 5, 0)
            ContainedAlertFrame.instanceName:SetPoint("RIGHT", bg, -5, 0)
            ContainedAlertFrame.heroicIcon:SetAlpha(0)

            ContainedAlertFrame.glowFrame.glow:SetPoint("TOPLEFT", bg, -10, 10)
            ContainedAlertFrame.glowFrame.glow:SetPoint("BOTTOMRIGHT", bg, 10, -10)
            ContainedAlertFrame.glowFrame.glow:SetAtlas("Toast-Flash")
            ContainedAlertFrame.glowFrame.glow:SetTexCoord(0, 1, 0, 1)

            ContainedAlertFrame.shine:SetHeight(55)
            ContainedAlertFrame.shine:SetTexCoord(0.794921875, 0.96484375, 0.06640625, 0.23046875)
            --ContainedAlertFrame.shine:SetTexCoord(0.78125, 0.912109375, 0.06640625, 0.23046875)

            ContainedAlertFrame._auroraTemplate = "DungeonCompletionAlertFrameTemplate"
        else
            local rewardData = ContainedAlertFrame.rewardData
            if rewardData.subtypeID == _G.LFG_SUBTYPEID_RAID then
                ContainedAlertFrame:SetBackdropOption("offsets", {
                    left = 20,
                    right = 20,
                    top = 14,
                    bottom = 9,
                })
                ContainedAlertFrame.shine:SetPoint("BOTTOMLEFT", 0, 10)
            else
                ContainedAlertFrame:SetBackdropOption("offsets", {
                    left = 7,
                    right = 7,
                    top = 11,
                    bottom = 12,
                })
                ContainedAlertFrame.shine:SetPoint("BOTTOMLEFT", 0, 13)
            end

            for i, button in next, ContainedAlertFrame.RewardFrames do
                Util.SkinOnce(button, Skin.DungeonCompletionAlertFrameRewardTemplate)
            end

            if rewardData.subtypeID == _G.LFG_SUBTYPEID_HEROIC then
                ContainedAlertFrame.instanceName:SetText(heroicTexture .. rewardData.name)
            end
        end
    end
    function Skin.AchievementAlertFrameTemplate(ContainedAlertFrame)
        if not ContainedAlertFrame._auroraTemplate then
            Skin.FrameTypeFrame(ContainedAlertFrame)
            local bg = ContainedAlertFrame:GetBackdropTexture("bg")

            ContainedAlertFrame.Background:Hide()
            ContainedAlertFrame.Unlocked:SetPoint("LEFT", ContainedAlertFrame.Icon.Texture, "RIGHT", 5, 0)
            ContainedAlertFrame.Unlocked:SetPoint("RIGHT", ContainedAlertFrame.Shield.Icon, "LEFT", -5, 0)
            ContainedAlertFrame.Unlocked:SetTextColor(1, 1, 1)
            ContainedAlertFrame.Name:SetSize(0, 0)

            local guildBG = ContainedAlertFrame:CreateTexture(nil, "BACKGROUND")
            guildBG:SetTexture([[Interface\LFGFrame\UI-LFG-SEPARATOR]])
            guildBG:SetTexCoord(0, 0.6640625, 0, 0.25)
            guildBG:SetVertexColor(0, 0, 0) -- static: not a theme color
            guildBG:SetPoint("BOTTOM", bg, "TOP", 0, -1)
            guildBG:SetSize(170, 32)
            ContainedAlertFrame._auroraGuildBG = guildBG

            ContainedAlertFrame.glow:SetPoint("TOPLEFT", bg, -10, 10)
            ContainedAlertFrame.glow:SetPoint("BOTTOMRIGHT", bg, 10, -10)
            ContainedAlertFrame.glow:SetAtlas("Toast-Flash")

            Base.CropIcon(ContainedAlertFrame.Icon.Texture, ContainedAlertFrame)
            ContainedAlertFrame.Icon.Texture:SetSize(44, 44)
            ContainedAlertFrame.Icon.Overlay:Hide()
            ContainedAlertFrame._auroraTemplate = "AchievementAlertFrameTemplate"
        else
            local bg = ContainedAlertFrame:GetBackdropTexture("bg")

            -- Re-hide textures that Blizzard's SetUp re-applies via SetAtlas
            ContainedAlertFrame.Background:Hide()
            ContainedAlertFrame.Icon.Overlay:Hide()

            ContainedAlertFrame.Unlocked:SetPoint("RIGHT", ContainedAlertFrame.Shield.Icon, "LEFT", -5, 0)
            ContainedAlertFrame.Name:ClearAllPoints()
            ContainedAlertFrame.Name:SetPoint("TOP", ContainedAlertFrame.Unlocked, "BOTTOM", -2, 0)
            ContainedAlertFrame.Name:SetPoint("LEFT", ContainedAlertFrame.Icon.Texture, "RIGHT", 5, 0)
            ContainedAlertFrame.Name:SetPoint("RIGHT", ContainedAlertFrame.Shield.Icon, "LEFT", -5, 0)
            ContainedAlertFrame.Name:SetPoint("BOTTOM", bg, 0, 5)
            ContainedAlertFrame.glow:SetAtlas("Toast-Flash")

            ContainedAlertFrame.shine:SetPoint("TOP", bg)
            ContainedAlertFrame.shine:SetPoint("BOTTOM", bg)

            if ContainedAlertFrame.GuildName:IsShown() then
                ContainedAlertFrame:SetBackdropOption("offsets", {
                    left = 6,
                    right = 9,
                    top = 32,
                    bottom = 16,
                })
                ContainedAlertFrame._auroraGuildBG:Show()
                ContainedAlertFrame.Icon:SetPoint("TOPLEFT", 0, -21)
                ContainedAlertFrame.shine:SetTexCoord(0, 1, 0.27777777777778, 0.87777777777778)
            else
                ContainedAlertFrame:SetBackdropOption("offsets", {
                    left = 6,
                    right = 8,
                    top = 18,
                    bottom = 16,
                })
                ContainedAlertFrame._auroraGuildBG:Hide()
                ContainedAlertFrame.shine:SetTexCoord(0, 1, 0.21176470588235, 0.87058823529412)

                if not ContainedAlertFrame.Shield.Icon:IsShown() then
                    ContainedAlertFrame.Unlocked:SetPoint("RIGHT", bg, -5, 0)
                    ContainedAlertFrame.Name:SetPoint("LEFT", ContainedAlertFrame.Icon.Texture, "RIGHT", 5, 0)
                    ContainedAlertFrame.Name:SetPoint("RIGHT", bg, -5, 0)
                end
            end
        end
    end
    function Skin.CriteriaAlertFrameTemplate(ContainedAlertFrame)
        if not ContainedAlertFrame._auroraTemplate then
            Skin.FrameTypeFrame(ContainedAlertFrame)
            ContainedAlertFrame:SetBackdropOption("offsets", {
                left = 0,
                right = 0,
                top = 2,
                bottom = 8,
            })

            local bg = ContainedAlertFrame:GetBackdropTexture("bg")
            ContainedAlertFrame.Background:Hide()
            ContainedAlertFrame.Unlocked:SetTextColor(Color.white:GetRGB())
            ContainedAlertFrame.Name:SetTextColor(Color.grayLight:GetRGB())

            ContainedAlertFrame.glow:SetPoint("TOPLEFT", bg, -10, 10)
            ContainedAlertFrame.glow:SetPoint("BOTTOMRIGHT", bg, 10, -10)
            ContainedAlertFrame.glow:SetAtlas("Toast-Flash")
            ContainedAlertFrame.glow:SetTexCoord(0, 1, 0, 1)
            ContainedAlertFrame.shine:SetTexCoord(0.78125, 0.912109375, 0.0703125, 0.2265625)
            ContainedAlertFrame.shine:SetPoint("TOPLEFT", 18, -3)
            ContainedAlertFrame.shine:SetHeight(40)

            Base.CropIcon(ContainedAlertFrame.Icon.Texture, ContainedAlertFrame)
            ContainedAlertFrame.Icon.Texture:SetSize(40, 40)
            ContainedAlertFrame.Icon.Overlay:Hide()
            ContainedAlertFrame._auroraTemplate = "CriteriaAlertFrameTemplate"
        else
            -- Re-hide textures that Blizzard's SetUp re-applies
            ContainedAlertFrame.Background:Hide()
            ContainedAlertFrame.Icon.Overlay:Hide()
        end
    end
    function Skin.GuildChallengeAlertFrameTemplate(ContainedAlertFrame)
        if not ContainedAlertFrame._auroraTemplate then
            Skin.FrameTypeFrame(ContainedAlertFrame)
            ContainedAlertFrame:SetBackdropOption("offsets", {
                left = 9,
                right = 10,
                top = 14,
                bottom = 15,
            })

            local bg = ContainedAlertFrame:GetBackdropTexture("bg")
            local line = select(2, ContainedAlertFrame:GetRegions())
            line:SetColorTexture(1, 1, 1, 0.5) -- static: not a theme color
            line:ClearAllPoints()
            line:SetPoint("TOPLEFT", ContainedAlertFrame.EmblemBackground, "TOPRIGHT", 10, -20)
            line:SetPoint("BOTTOMRIGHT", bg, -75, 20)

            ContainedAlertFrame.EmblemBackground:SetPoint("TOPLEFT", 14, -19)
            ContainedAlertFrame.EmblemBackground:SetTexCoord(0.060546875, 0.1328125, 0.00390625, 0.14453125)
            ContainedAlertFrame.EmblemBorder:SetAllPoints(ContainedAlertFrame.EmblemBackground)
            ContainedAlertFrame.EmblemBorder:SetTexCoord(0.060546875, 0.1328125, 0.15234375, 0.29296875)

            ContainedAlertFrame.glow:SetPoint("TOPLEFT", bg, -10, 10)
            ContainedAlertFrame.glow:SetPoint("BOTTOMRIGHT", bg, 10, -10)
            ContainedAlertFrame.glow:SetAtlas("Toast-Flash")
            ContainedAlertFrame.glow:SetTexCoord(0, 1, 0, 1)

            ContainedAlertFrame._auroraTemplate = "GuildChallengeAlertFrameTemplate"
        end
    end
    function Skin.ScenarioLegionInvasionAlertFrameTemplate(ContainedAlertFrame)
        if not ContainedAlertFrame._auroraTemplate then
            local toastFrame, icon, title = ContainedAlertFrame:GetRegions()
            Skin.FrameTypeFrame(ContainedAlertFrame)
            ContainedAlertFrame:SetBackdropOption("offsets", {
                left = 11,
                right = 11,
                top = 10,
                bottom = 10,
            })

            toastFrame:Hide()
            Base.CropIcon(icon, ContainedAlertFrame)

            local bg = ContainedAlertFrame:GetBackdropTexture("bg")
            title:SetPoint("TOP", bg, 0, -15)
            title:SetPoint("LEFT", icon, "RIGHT", 5, 0)
            title:SetPoint("RIGHT", bg, -5, 0)
            ContainedAlertFrame._title = title

            ContainedAlertFrame.ZoneName:ClearAllPoints()
            ContainedAlertFrame.ZoneName:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
            ContainedAlertFrame.ZoneName:SetPoint("TOPRIGHT", title, "BOTTOMRIGHT", 0, -2)

            ContainedAlertFrame._auroraTemplate = "ScenarioLegionInvasionAlertFrameTemplate"
        else
            for i, button in next, ContainedAlertFrame.RewardFrames do
                Util.SkinOnce(button, Skin.InvasionAlertFrameRewardTemplate)
            end

            local bg = ContainedAlertFrame:GetBackdropTexture("bg")
            if ContainedAlertFrame.BonusStar:IsShown() then
                ContainedAlertFrame._title:SetPoint("RIGHT", bg, -45, 0)
            else
                ContainedAlertFrame._title:SetPoint("RIGHT", bg, -5, 0)
            end
        end
    end
    function Skin.ScenarioAlertFrameTemplate(ContainedAlertFrame)
        if not ContainedAlertFrame._auroraTemplate then
            Skin.FrameTypeFrame(ContainedAlertFrame)
            ContainedAlertFrame:SetBackdropOption("offsets", {
                left = 11,
                right = 20,
                top = 10,
                bottom = 11,
            })

            select(1, ContainedAlertFrame:GetRegions()):Hide() -- iconBG
            ContainedAlertFrame.dungeonTexture:ClearAllPoints()
            ContainedAlertFrame.dungeonTexture:SetPoint("TOPLEFT", 17, -16)
            Base.CropIcon(ContainedAlertFrame.dungeonTexture, ContainedAlertFrame)
            select(3, ContainedAlertFrame:GetRegions()):Hide() -- toastFrame

            local bg = ContainedAlertFrame:GetBackdropTexture("bg")
            local title = select(4, ContainedAlertFrame:GetRegions())
            title:SetPoint("TOP", bg, 0, -15)
            title:SetPoint("LEFT", ContainedAlertFrame.dungeonTexture, "RIGHT", 5, 0)
            title:SetPoint("RIGHT", bg, -5, 0)
            ContainedAlertFrame._title = title

            ContainedAlertFrame.dungeonName:SetPoint("TOP", title, "BOTTOM", 0, -2)
            ContainedAlertFrame.dungeonName:SetPoint("LEFT", ContainedAlertFrame.dungeonTexture, "RIGHT", 5, 0)
            ContainedAlertFrame.dungeonName:SetPoint("RIGHT", bg, -5, 0)

            ContainedAlertFrame.glowFrame.glow:SetPoint("TOPLEFT", bg, -10, 10)
            ContainedAlertFrame.glowFrame.glow:SetPoint("BOTTOMRIGHT", bg, 10, -10)
            ContainedAlertFrame.glowFrame.glow:SetAtlas("Toast-Flash")
            ContainedAlertFrame.glowFrame.glow:SetTexCoord(0, 1, 0, 1)

            ContainedAlertFrame.shine:SetTexCoord(0.794921875, 0.96484375, 0.06640625, 0.23046875)

            ContainedAlertFrame._auroraTemplate = "ScenarioAlertFrameTemplate"
        else
            for i, button in next, ContainedAlertFrame.RewardFrames do
                Util.SkinOnce(button, Skin.DungeonCompletionAlertFrameRewardTemplate)
            end

            local bg = ContainedAlertFrame:GetBackdropTexture("bg")
            if ContainedAlertFrame.BonusStar:IsShown() then
                ContainedAlertFrame._title:SetPoint("RIGHT", bg, -45, 0)
            else
                ContainedAlertFrame._title:SetPoint("RIGHT", bg, -5, 0)
            end
        end
    end
    function Skin.MoneyWonAlertFrameTemplate(ContainedAlertFrame)
        if not ContainedAlertFrame._auroraTemplate then
            Skin.FrameTypeFrame(ContainedAlertFrame)
            ContainedAlertFrame:SetBackdropBorderColor(Color.yellow)
            ContainedAlertFrame:SetBackdropOption("offsets", {
                left = 11,
                right = 11,
                top = 10,
                bottom = 11,
            })

            ContainedAlertFrame.Background:Hide()
            Base.CropIcon(ContainedAlertFrame.Icon, ContainedAlertFrame)
            ContainedAlertFrame.IconBorder:Hide()

            ContainedAlertFrame.Label:SetPoint("TOPLEFT", ContainedAlertFrame.Icon, "TOPRIGHT", 10, -2)
            ContainedAlertFrame.Amount:SetPoint("BOTTOMLEFT", ContainedAlertFrame.Icon, "BOTTOMRIGHT", 10, 2)

            ContainedAlertFrame._auroraTemplate = "MoneyWonAlertFrameTemplate"
        end
    end
    function Skin.HonorAwardedAlertFrameTemplate(ContainedAlertFrame)
        if not ContainedAlertFrame._auroraTemplate then
            -- Called when created: the main skin
            Skin.FrameTypeFrame(ContainedAlertFrame)
            ContainedAlertFrame:SetBackdropBorderColor(Color.yellow)
            ContainedAlertFrame:SetBackdropOption("offsets", {
                left = 11,
                right = 11,
                top = 10,
                bottom = 11,
            })

            ContainedAlertFrame.Background:Hide()
            Base.CropIcon(ContainedAlertFrame.Icon, ContainedAlertFrame)
            ContainedAlertFrame.IconBorder:Hide()

            ContainedAlertFrame.Label:SetPoint("TOPLEFT", ContainedAlertFrame.Icon, "TOPRIGHT", 10, -2)
            ContainedAlertFrame.Amount:SetPoint("BOTTOMLEFT", ContainedAlertFrame.Icon, "BOTTOMRIGHT", 10, 2)

            ContainedAlertFrame._auroraTemplate = "HonorAwardedAlertFrameTemplate"
        end
    end

    -- Garrison: Building and Talent share the same layout (Garr_Toast bg + Icon + Title + Name)
    function Skin.GarrisonBuildingAlertFrameTemplate(frame)
        if not frame._auroraTemplate then
            Skin.FrameTypeFrame(frame)
            select(1, frame:GetRegions()):SetTexture("") -- Garr_Toast background
            Base.CropIcon(frame.Icon, frame)
            frame._auroraTemplate = "GarrisonBuildingAlertFrameTemplate"
        end
    end
    Skin.GarrisonTalentAlertFrameTemplate = Skin.GarrisonBuildingAlertFrameTemplate

    -- Garrison: Mission (no background atlas on frame itself, just MissionType icon + text)
    function Skin.GarrisonMissionAlertFrameTemplate(frame)
        if not frame._auroraTemplate then
            Skin.FrameTypeFrame(frame)
            frame._auroraTemplate = "GarrisonMissionAlertFrameTemplate"
        end
    end
    Skin.GarrisonRandomMissionAlertFrameTemplate = Skin.GarrisonMissionAlertFrameTemplate

    -- Garrison: Follower (FollowerBG shown/hidden dynamically per quality; always hide it in Aurora)
    function Skin.GarrisonFollowerAlertFrameTemplate(frame)
        if not frame._auroraTemplate then
            Skin.FrameTypeFrame(frame)
            frame.FollowerBG:Hide()
            frame._auroraTemplate = "GarrisonFollowerAlertFrameTemplate"
        else
            frame.FollowerBG:Hide()
        end
    end
    Skin.GarrisonStandardFollowerAlertFrameTemplate = Skin.GarrisonFollowerAlertFrameTemplate
    Skin.GarrisonShipFollowerAlertFrameTemplate = Skin.GarrisonFollowerAlertFrameTemplate

    -- Digsite: archeology toast bg (no parentKey, region 1) + DigsiteTypeTexture icon
    function Skin.DigsiteCompleteToastFrameTemplate(frame)
        if not frame._auroraTemplate then
            Skin.FrameTypeFrame(frame)
            select(1, frame:GetRegions()):SetTexture("") -- Archaeology toast background
            Base.CropIcon(frame.DigsiteTypeTexture, frame)
            frame._auroraTemplate = "DigsiteCompleteToastFrameTemplate"
        end
    end

    -- Entitlement / RAF Reward: store/raf background + Icon
    function Skin.EntitlementDeliveredAlertFrameTemplate(frame)
        if not frame._auroraTemplate then
            Skin.FrameTypeFrame(frame)
            frame.Background:Hide()
            Base.CropIcon(frame.Icon, frame)
            frame._auroraTemplate = "EntitlementDeliveredAlertFrameTemplate"
        else
            frame.Background:Hide()
        end
    end
    function Skin.RafRewardDeliveredAlertFrameTemplate(frame)
        if not frame._auroraTemplate then
            Skin.FrameTypeFrame(frame)
            frame.StandardBackground:Hide()
            frame.FancyBackground:Hide()
            Base.CropIcon(frame.Icon, frame)
            frame._auroraTemplate = "RafRewardDeliveredAlertFrameTemplate"
        else
            -- SetUp shows one of these each call
            frame.StandardBackground:Hide()
            frame.FancyBackground:Hide()
        end
    end

    -- LootWon: multiple conditional backgrounds shown by SetUp; hide them all after
    function Skin.LootWonAlertFrameTemplate(frame)
        if not frame._auroraTemplate then
            Skin.FrameTypeFrame(frame)
            frame._auroraTemplate = "LootWonAlertFrameTemplate"
        end
        -- These are toggled by SetUp every call, so always re-hide
        frame.Background:Hide()
        frame.PvPBackground:Hide()
        frame.RatedPvPBackground:Hide()
        frame.BGAtlas:Hide()
    end

    -- LootUpgrade: quality-coloured bg + item borders
    function Skin.LootUpgradeFrameTemplate(frame)
        if not frame._auroraTemplate then
            Skin.FrameTypeFrame(frame)
            frame.Background:Hide()
            frame._auroraTemplate = "LootUpgradeFrameTemplate"
        end
        -- Borders are re-set via SetAtlas each call
        frame.BaseQualityBorder:Hide()
        frame.UpgradeQualityBorder:Hide()
    end

    -- WorldQuestComplete: lfg dungeon-toast bg + QuestTexture icon
    function Skin.WorldQuestCompleteAlertFrameTemplate(frame)
        if not frame._auroraTemplate then
            Skin.FrameTypeFrame(frame)
            frame.ToastBackground:Hide()
            Base.CropIcon(frame.QuestTexture, frame)
            frame._auroraTemplate = "WorldQuestCompleteAlertFrameTemplate"
        end
        -- RewardFrames are created/shown dynamically; skin each unskinned one
        if frame.RewardFrames then
            for _, button in next, frame.RewardFrames do
                if button:IsShown() and not button._auroraSkinned then
                    Skin.WorldQuestFrameRewardTemplate(button)
                    button._auroraSkinned = true
                end
            end
        end
    end

    -- LegendaryItem: particle/ring textures + Icon
    function Skin.LegendaryItemAlertFrameTemplate(frame)
        if not frame._auroraTemplate then
            Skin.FrameTypeFrame(frame)
            frame.Background:Hide()
            frame.Ring1:Hide()
            frame.Starglow:Hide()
            frame.Particles1:Hide()
            frame.Particles2:Hide()
            frame.Particles3:Hide()
            Base.CropIcon(frame.Icon, frame)
            frame._auroraTemplate = "LegendaryItemAlertFrameTemplate"
        end
    end

    -- ItemAlertFrameTemplate base (Pet / Mount / Toy / Warband / Runforge / Cosmetic)
    -- Each subtype only adds a Background atlas on top of this
    function Skin.ItemAlertFrameTemplate(frame)
        if not frame._auroraTemplate then
            Skin.FrameTypeFrame(frame)
            if frame.Background then frame.Background:Hide() end
            frame.IconBorder:Hide()
            Base.CropIcon(frame.Icon, frame)
            frame._auroraTemplate = "ItemAlertFrameTemplate"
        else
            if frame.Background then frame.Background:Hide() end
        end
    end
    Skin.NewPetAlertFrameTemplate          = Skin.ItemAlertFrameTemplate
    Skin.NewMountAlertFrameTemplate        = Skin.ItemAlertFrameTemplate
    Skin.NewToyAlertFrameTemplate          = Skin.ItemAlertFrameTemplate
    Skin.NewWarbandSceneAlertFrameTemplate = Skin.ItemAlertFrameTemplate
    Skin.NewRuneforgePowerAlertFrameTemplate = Skin.ItemAlertFrameTemplate
    Skin.NewCosmeticAlertFrameTemplate     = Skin.ItemAlertFrameTemplate

    -- NewRecipeLearned / SkillLineSpecsUnlocked: recipetoast-bg (no parentKey, region 1) + Icon
    -- Note: SetUp applies SetMask and SetTexture to Icon each call; CropIcon coexists fine.
    function Skin.NewRecipeLearnedAlertFrameTemplate(frame)
        if not frame._auroraTemplate then
            Skin.FrameTypeFrame(frame)
            select(1, frame:GetRegions()):SetTexture("") -- recipetoast-bg
            Base.CropIcon(frame.Icon, frame)
            frame._auroraTemplate = "NewRecipeLearnedAlertFrameTemplate"
        end
    end
    Skin.SkillLineSpecsUnlockedAlertFrameTemplate = Skin.NewRecipeLearnedAlertFrameTemplate

    -- MonthlyActivity: achievement-mini bg + Icon.Texture/Overlay (same structure as CriteriaAlertFrame)
    function Skin.MonthlyActivityFrameTemplate(frame)
        if not frame._auroraTemplate then
            Skin.FrameTypeFrame(frame)
            frame.Background:Hide()
            frame.Icon.Overlay:Hide()
            frame.Icon.Bling:Hide()
            Base.CropIcon(frame.Icon.Texture, frame)
            frame._auroraTemplate = "MonthlyActivityFrameTemplate"
        end
    end

    -- HousingItemEarned: decorative housing frame with leaves + Icon
    function Skin.HousingItemEarnedAlertFrameTemplate(frame)
        if not frame._auroraTemplate then
            Skin.FrameTypeFrame(frame)
            frame.Background:Hide()
            frame.Border:Hide()
            frame.LeafTL:Hide()
            frame.LeafL:Hide()
            frame.LeafBL:Hide()
            frame.LeafTR:Hide()
            frame.LeafBR:Hide()
            Base.CropIcon(frame.Icon, frame)
            frame._auroraTemplate = "HousingItemEarnedAlertFrameTemplate"
        end
    end

    -- InitiativeTaskComplete: same housing-style decorative frame, no icon to crop
    function Skin.InitiativeTaskCompleteAlertFrameTemplate(frame)
        if not frame._auroraTemplate then
            Skin.FrameTypeFrame(frame)
            frame.Background:Hide()
            frame.Border:Hide()
            frame.LeafTL:Hide()
            frame.LeafL:Hide()
            frame.LeafBL:Hide()
            frame.LeafTR:Hide()
            frame.LeafBR:Hide()
            frame._auroraTemplate = "InitiativeTaskCompleteAlertFrameTemplate"
        end
    end
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
