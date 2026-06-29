local _, private = ...

-- [[ Lua Globals ]]
-- luacheck: globals next type
local wago = _G.LibStub("WagoAnalytics"):Register("JZKbRK19")
private.wago = wago

-- [[ Core ]]
local Aurora = private.Aurora
local _, C = _G.unpack(Aurora)
local Config = private.Config
local Analytics = private.Analytics
local Compatibility = private.Compatibility
local Integration = private.Integration

-- [[ Constants and settings ]]
local AuroraConfig

C.frames = {}
-- Maintain C.defaults for backward compatibility
C.defaults = Config.defaults

function private.OnLoad()
    -- Initialize integration system first
    Integration.Initialize()

    -- Load and initialize configuration using the Config module with error handling
    local configSuccess, configResult = pcall(function()
        return Config.load(wago)
    end)

    if configSuccess then
        AuroraConfig = configResult
    else
        Integration.HandleError("Config", configResult, {phase = "load", recoverable = true})
        AuroraConfig = Config.defaults
    end

    -- Initialize compatibility system with error handling
    local compatSuccess, compatErr = pcall(Compatibility.initialize, AuroraConfig)
    if not compatSuccess then
        Integration.HandleError("Compatibility", compatErr, {phase = "initialize", recoverable = false})
    end

    -- Initialize analytics system with user consent and error handling
    local analyticsSuccess, analyticsErr = pcall(Analytics.initialize, wago, AuroraConfig)
    if not analyticsSuccess then
        Integration.HandleError("Analytics", analyticsErr, {phase = "initialize", recoverable = false})
    end

    -- Check if configuration needs recovery
    local needsRecovery, reason = Config.needsRecovery(AuroraConfig)
    if needsRecovery then
        private.debug("Config", "Recovery needed:", reason)
        local recoverSuccess, recoverResult = pcall(Config.recover)
        if recoverSuccess then
            AuroraConfig = recoverResult
        else
            Integration.HandleError("Config", recoverResult, {phase = "recovery", recoverable = false})
        end
    end

    -- Setup colors
    local Color, Util = Aurora.Color, Aurora.Util
    local Theme = Aurora.Theme
    local customClassColors = AuroraConfig.customClassColors

    -- Initialize theme engine
    Theme.Initialize()
    Theme.InitializeAlpha(AuroraConfig)

    function private.updateHighlightColor()
        --print("updateHighlightColor override")
        -- Use the enhanced color management system with dynamic updates
        Color.RefreshHighlightColor(AuroraConfig)

        -- Update deprecated references
        C.r, C.g, C.b = Color.highlight:GetRGB()
    end
    _G.CUSTOM_CLASS_COLORS:RegisterCallback(function()
        --print("aurora CCC:RegisterCallback")
        private.updateHighlightColor()
        _G.AuroraOptions.refresh()
    end)
    private.setColorCache(customClassColors)

    -- Apply the saved color mode palette before skin registration
    Color.SetMode(AuroraConfig.colorMode)

    if AuroraConfig.buttonsHaveGradient then
        Color.button:SetRGB(.4, .4, .4)
    end

    -- Store frame alpha from saved vars
    Util.SetFrameAlpha(AuroraConfig.alpha)

    -- Create API hooks
    local Hook = Aurora.Hook
    local Skin = Aurora.Skin

    _G.hooksecurefunc(Skin, "FrameTypeButton", function(Button)
        if AuroraConfig.buttonsHaveGradient and Button.SetBackdropGradient then
            Button:SetBackdropGradient()
        end
    end)

    local characterPanelSkinState = {
        CharacterFrame = false,
        PaperDollFrame = false,
        ReputationFrame = false,
        Blizzard_TokenUI = false,
    }

    -- Only mark as skinned when the relevant global frame actually exists at
    -- call time. The initial fileOrder loop may call these skin functions before
    -- demand-loaded addons (Blizzard_UIPanels_Game, Blizzard_TokenUI) have
    -- created their frames. Without this guard the deferred retry would see the
    -- state already set to true and incorrectly skip the real skin pass.
    local characterPanelFrameGlobals = {
        CharacterFrame  = "CharacterFrame",
        PaperDollFrame  = "PaperDollFrame",
        ReputationFrame = "ReputationFrame",
        Blizzard_TokenUI = "TokenFrame",
    }
    local function MarkCharacterPanelSkinned(name)
        local globalName = characterPanelFrameGlobals[name]
        if globalName and _G[globalName] then
            characterPanelSkinState[name] = true
        end
    end

    if type(private.FrameXML.CharacterFrame) == "function" then
        _G.hooksecurefunc(private.FrameXML, "CharacterFrame", function()
            MarkCharacterPanelSkinned("CharacterFrame")
        end)
    end
    if type(private.FrameXML.PaperDollFrame) == "function" then
        _G.hooksecurefunc(private.FrameXML, "PaperDollFrame", function()
            MarkCharacterPanelSkinned("PaperDollFrame")
        end)
    end
    if type(private.FrameXML.ReputationFrame) == "function" then
        _G.hooksecurefunc(private.FrameXML, "ReputationFrame", function()
            MarkCharacterPanelSkinned("ReputationFrame")
        end)
    end
    if type(private.FrameXML.Blizzard_TokenUI) == "function" then
        _G.hooksecurefunc(private.FrameXML, "Blizzard_TokenUI", function()
            MarkCharacterPanelSkinned("Blizzard_TokenUI")
        end)
    end

    local function SafeApplyCharacterPanelSkin(name)
        if characterPanelSkinState[name] then
            return
        end

        local fn = private.FrameXML[name]
        if type(fn) ~= "function" then
            return
        end

        local ok, err = pcall(fn)
        if not ok then
            Integration.HandleError("Skin", err, {phase = "deferred-"..name, recoverable = true})
        end
    end

    local function ApplyCharacterPanelSkins()
        if not AuroraConfig.characterSheet then
            return
        end

        if _G.CharacterFrame then
            SafeApplyCharacterPanelSkin("CharacterFrame")
        end
        if _G.PaperDollFrame then
            SafeApplyCharacterPanelSkin("PaperDollFrame")
        end
        if _G.ReputationFrame then
            SafeApplyCharacterPanelSkin("ReputationFrame")
        end
        if _G.TokenFrame then
            SafeApplyCharacterPanelSkin("Blizzard_TokenUI")
        end
    end

    local function QueueCharacterPanelSkinApply()
        _G.C_Timer.After(0, ApplyCharacterPanelSkins)
    end

    local panelSkinEventFrame = _G.CreateFrame("Frame")
    panelSkinEventFrame:RegisterEvent("ADDON_LOADED")
    panelSkinEventFrame:SetScript("OnEvent", function(_, _, addonName)
        if addonName == "Blizzard_UIPanels_Game" or addonName == "Blizzard_TokenUI" then
            QueueCharacterPanelSkinApply()
        end
    end)

    if _G.C_AddOns.IsAddOnLoaded("Blizzard_UIPanels_Game") then
        QueueCharacterPanelSkinApply()
    end
    if _G.C_AddOns.IsAddOnLoaded("Blizzard_TokenUI") then
        QueueCharacterPanelSkinApply()
    end

    if _G.ToggleCharacter then
        _G.hooksecurefunc("ToggleCharacter", function(tabName)
            if tabName == "PaperDollFrame" or tabName == "ReputationFrame" or tabName == "TokenFrame" then
                QueueCharacterPanelSkinApply()
            end
        end)
    end

    -- Skip CharacterFrame modifications if Chonky Character Sheet is loaded
    if AuroraConfig.characterSheet and not _G.C_AddOns.IsAddOnLoaded("ChonkyCharacterSheet") then
        if type(private.FrameXML.CharacterFrame) == "function" then
            _G.hooksecurefunc(private.FrameXML, "CharacterFrame", function()
                -- CharacterStatsPane.ItemLevelFrame only exists on Retail
                if not _G.CharacterStatsPane or not _G.CharacterStatsPane.ItemLevelFrame then return end

                _G.CharacterStatsPane.ItemLevelFrame:SetPoint("TOP", 0, -12)
                _G.CharacterStatsPane.ItemLevelFrame.Background:Hide()
                _G.CharacterStatsPane.ItemLevelFrame.Value:SetFontObject("SystemFont_Outline_WTF2")

                _G.hooksecurefunc("PaperDollFrame_UpdateStats", function()
                    if ( _G.UnitLevel("player") >= _G.MIN_PLAYER_LEVEL_FOR_ITEM_LEVEL_DISPLAY ) then
                        _G.CharacterStatsPane.ItemLevelCategory:Hide()
                        _G.CharacterStatsPane.AttributesCategory:SetPoint("TOP", 0, -40)
                    end
                end)
            end)
        end
    end

    if type(private.FrameXML.FriendsFrame) == "function" then
        _G.hooksecurefunc(private.FrameXML, "FriendsFrame", function()
        local FriendsFrame = _G.FriendsFrame
        local titleText = FriendsFrame.TitleText or FriendsFrame:GetTitleText()

        local BNetFrame = _G.FriendsFrameBattlenetFrame
        BNetFrame.Tag:SetParent(FriendsFrame)
        BNetFrame.Tag:SetAllPoints(titleText)
        local BroadcastFrame = BNetFrame.BroadcastFrame
        local EditBox = BroadcastFrame.EditBox
        EditBox:SetParent(FriendsFrame)
        EditBox:ClearAllPoints()
        EditBox:SetSize(239, 25)
        EditBox:SetPoint("TOPLEFT", 57, -28)
        EditBox:SetScript("OnEnterPressed", function()
            BroadcastFrame:SetBroadcast()
        end)
        _G.hooksecurefunc("FriendsFrame_Update", function()
            local selectedTab = _G.PanelTemplates_GetSelectedTab(FriendsFrame) or _G.FRIEND_TAB_FRIENDS
            local isFriendsTab = selectedTab == _G.FRIEND_TAB_FRIENDS

            titleText:SetShown(not isFriendsTab)
            BNetFrame.Tag:SetShown(isFriendsTab)
            EditBox:SetShown(_G.BNConnected() and isFriendsTab)
        end)
        _G.hooksecurefunc("FriendsFrame_CheckBattlenetStatus", function()
            if _G.BNFeaturesEnabled() then
                if _G.BNConnected() then
                    BNetFrame:Hide()
                    EditBox:Show()
                    BroadcastFrame:UpdateBroadcast()
                else
                    EditBox:Hide()
                end
            end
        end)
    end)
    end

    -- Disable skins as per user settings
    private.disabled.bags = not AuroraConfig.bags
    private.disabled.banks = not AuroraConfig.banks
    private.disabled.chat = not AuroraConfig.chat
    private.disabled.fonts = not AuroraConfig.fonts
    private.disabled.tooltips = not AuroraConfig.tooltips
    private.disabled.mainmenubar = not AuroraConfig.mainmenubar
    if not AuroraConfig.chatBubbles then
        Hook.ChatBubble_OnEvent = private.nop
        Hook.ChatBubble_OnUpdate = private.nop
    end
    if not AuroraConfig.chatBubbleNames then
        Hook.ChatBubble_SetName = private.nop
    end
    if not AuroraConfig.loot then
        private.FrameXML.LootFrame = private.nop
    end

    local function SetupGUI()
        if not private.SetupGUI then
            return
        end

        local ok, err = pcall(private.SetupGUI)
        if not ok then
            Integration.HandleError("GUI", err, {phase = "setup", recoverable = true})
        end
    end

    SetupGUI()

    -- Keep backward compatibility for any callers that expect this addon skin hook.
    function private.AddOns.Aurora()
        SetupGUI()
    end

    -- Show splash screen for first time users after GUI skinning has been applied.
    if not AuroraConfig.acknowledgedSplashScreen and _G.AuroraSplashScreen then
        _G.AuroraSplashScreen:Show()
    end
end
