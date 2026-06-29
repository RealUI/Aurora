local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

function private.AddOns.Blizzard_ChatFrame()
    ---------------------
    -- ChatConfigFrame --
    ---------------------
    local ChatConfigFrame = _G.ChatConfigFrame
    if not ChatConfigFrame then return end

    Base.SetBackdrop(ChatConfigFrame, Color.frame, Util.GetFrameAlpha())

    -- Hide background textures
    local background = _G.ChatConfigFrameBackground
    if background then
        background:SetAlpha(0)
    end
    if _G.ChatConfigFrameHeader then
        _G.ChatConfigFrameHeader:SetAlpha(0)
    end

    -- Skin category list buttons (ChatConfigCategoryFrameButton1 through N)
    for i = 1, 10 do
        local button = _G["ChatConfigCategoryFrameButton" .. i]
        if button then
            Skin.FrameTypeButton(button)
            Base.SetHighlight(button)
        end
    end

    --------------------------
    -- Chat Settings Panels --
    --------------------------

    -- Skin checkboxes in ChatConfigChatSettingsLeft
    local chatSettingsLeft = _G.ChatConfigChatSettingsLeft
    if chatSettingsLeft then
        local name = chatSettingsLeft:GetName()
        if name then
            for i = 1, 30 do
                local checkBox = _G[name .. "Checkbox" .. i]
                if checkBox then
                    local cb = checkBox.CheckButton or checkBox.checkButton
                    if cb then
                        Skin.UICheckButtonTemplate(cb)
                    end
                end
            end
        end
    end

    -- Skin checkboxes in ChatConfigChannelSettingsLeft
    local channelSettingsLeft = _G.ChatConfigChannelSettingsLeft
    if channelSettingsLeft then
        local name = channelSettingsLeft:GetName()
        if name then
            for i = 1, 30 do
                local checkBox = _G[name .. "Checkbox" .. i]
                if checkBox then
                    local cb = checkBox.CheckButton or checkBox.checkButton
                    if cb then
                        Skin.UICheckButtonTemplate(cb)
                    end
                end
            end
        end
    end

    -- Skin Other Settings panels
    local otherPanels = {
        _G.ChatConfigOtherSettingsCombat,
        _G.ChatConfigOtherSettingsPVP,
        _G.ChatConfigOtherSettingsSystem,
        _G.ChatConfigOtherSettingsCreature,
    }
    for _, panel in _G.ipairs(otherPanels) do
        if panel then
            local name = panel:GetName()
            if name then
                for i = 1, 20 do
                    local checkBox = _G[name .. "Checkbox" .. i]
                    if checkBox then
                        local cb = checkBox.CheckButton or checkBox.checkButton
                        if cb then
                            Skin.UICheckButtonTemplate(cb)
                        end
                    end
                end
            end
        end
    end

    -------------------------
    -- Combat Log Settings --
    -------------------------
    local combatSettings = _G.ChatConfigCombatSettingsFilters
    if combatSettings then
        -- Skin filter buttons
        if _G.ChatConfigCombatSettingsFiltersDeleteButton then
            Skin.UIPanelButtonTemplate(_G.ChatConfigCombatSettingsFiltersDeleteButton)
        end
        if _G.ChatConfigCombatSettingsFiltersAddFilterButton then
            Skin.UIPanelButtonTemplate(_G.ChatConfigCombatSettingsFiltersAddFilterButton)
        end
        if _G.ChatConfigCombatSettingsFiltersCopyFilterButton then
            Skin.UIPanelButtonTemplate(_G.ChatConfigCombatSettingsFiltersCopyFilterButton)
        end
    end

    -- Formatting checkboxes
    local formattingChecks = {
        _G.CombatConfigFormattingShowTimeStamp,
        _G.CombatConfigFormattingShowBraces,
        _G.CombatConfigFormattingUnitNames,
        _G.CombatConfigFormattingSpellNames,
        _G.CombatConfigFormattingItemNames,
        _G.CombatConfigFormattingFullText,
    }
    for _, cb in _G.ipairs(formattingChecks) do
        if cb then
            Skin.UICheckButtonTemplate(cb)
        end
    end

    -- Settings panel
    if _G.CombatConfigSettingsNameEditBox then
        Skin.InputBoxTemplate(_G.CombatConfigSettingsNameEditBox)
    end
    if _G.CombatConfigSettingsSaveButton then
        Skin.UIPanelButtonTemplate(_G.CombatConfigSettingsSaveButton)
    end

    local settingsChecks = {
        _G.CombatConfigSettingsShowQuickButton,
        _G.CombatConfigSettingsSolo,
        _G.CombatConfigSettingsParty,
        _G.CombatConfigSettingsRaid,
    }
    for _, cb in _G.ipairs(settingsChecks) do
        if cb then
            Skin.UICheckButtonTemplate(cb)
        end
    end

    --------------------
    -- Bottom Buttons --
    --------------------

    -- Default button
    if ChatConfigFrame.DefaultButton then
        Skin.UIPanelButtonTemplate(ChatConfigFrame.DefaultButton)
    end

    -- Okay button
    if ChatConfigFrame.OkayButton then
        Skin.UIPanelButtonTemplate(ChatConfigFrame.OkayButton)
    elseif _G.ChatConfigFrameOkayButton then
        Skin.UIPanelButtonTemplate(_G.ChatConfigFrameOkayButton)
    end

    -- Close button
    if _G.ChatConfigFrameCloseButton then
        Skin.UIPanelCloseButton(_G.ChatConfigFrameCloseButton)
    end
end
