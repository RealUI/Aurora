local _, private = ...

-- [[ Lua Globals ]]
-- luacheck: globals next type pairs _G

-- Configuration Management Module
-- Handles configuration data model, defaults, validation, sanitization, and migration

local Config = {}
private.Config = Config

-- Configuration defaults with all themeable options
Config.defaults = {
    acknowledgedSplashScreen = false,

    -- Component toggles
    bags = true,
    banks = true,
    chat = true,
    loot = true,
    mainmenubar = false,
    fonts = true,
    tooltips = true,
    chatBubbles = true,
    chatBubbleNames = true,
    characterSheet = true,
    objectiveTracker = true,
    talentArtBackground = true,
    -- Diagnostic (delve tracker taint bisect, see Skin/api.lua Base.SetFont).
    -- false = inactive; a "lo-hi" string keeps only that range of font
    -- replacements. In defaults so removeInvalidSettings doesn't strip it.
    fontBisect = false,
    -- Diagnostic (delve tracker taint bisect, chat-skin round; see
    -- Skin/Interface/AddOns/Blizzard_ChatFrameBase/Mainline/FloatingChatFrame.lua).
    -- false = inactive (chat skin stays force-disabled); a "lo-hi" string lifts
    -- the force-disable and applies only the chat-skin components numbered
    -- lo..hi. In defaults so removeInvalidSettings doesn't strip it.
    chatBisect = false,
    heroTalentsCustomAnchor = false,
    heroTalentsAnchorPreset = "default",

    -- Visual customization
    buttonsHaveGradient = true,
    customHighlight = {
        enabled = false,
        r = 0.243,
        g = 0.570,
        b = 1
    },
    alpha = 0.5,

    -- System flags
    hasAnalytics = true,
    customClassColors = {},

    -- GC tuning mode: "smooth" (aggressive incremental), "default" (Lua defaults), "combat" (pause in combat)
    gcMode = "smooth",

    -- Color mode preset: controls neutral palette and class color highlight boost
    colorMode = "Normal",

    -- DEV: run Blizzard's original GameTooltip_InsertFrame instead of Aurora's
    -- replacement.  Aurora owning that global taints it for every secure
    -- reader, which blocks C_ItemUpgrade.UpgradeItem().  Toggle with
    -- /aurora insertframe to A/B whether the replacement is still needed.
    devRestoreInsertFrame = false,
}

-- Deprecated settings mapping for migration
-- Maps old setting names to new setting names or migration functions
Config.deprecatedSettings = {
    useButtonGradientColour = "buttonsHaveGradient",
    enableFont = "fonts",
    customColour = function(value, config)
        config.customHighlight = value
        return true
    end,
    useCustomColour = function(value, config)
        if config.customHighlight then
            config.customHighlight.enabled = value
        end
        return true
    end,
    -- Guard for future colorMode key renames. If an old key is ever introduced,
    -- add a migration entry here: oldColorModeKey = "colorMode"
}

-- Validation rules for configuration values
Config.validationRules = {
    -- Boolean settings
    acknowledgedSplashScreen = "boolean",
    bags = "boolean",
    banks = "boolean",
    chat = "boolean",
    loot = "boolean",
    mainmenubar = "boolean",
    fonts = "boolean",
    tooltips = "boolean",
    chatBubbles = "boolean",
    chatBubbleNames = "boolean",
    buttonsHaveGradient = "boolean",
    hasAnalytics = "boolean",
    characterSheet = "boolean",
    objectiveTracker = "boolean",
    talentArtBackground = "boolean",
    heroTalentsCustomAnchor = "boolean",

    heroTalentsAnchorPreset = function(value)
        if type(value) ~= "string" then
            return false, "heroTalentsAnchorPreset must be a string"
        end
        local valid = {
            default = true,
            topcenter = true,
            centercenter = true,
            left = true,
            lower = true,
            compact = true,
        }
        if not valid[value] then
            return false, "heroTalentsAnchorPreset must be 'default', 'topcenter', 'centercenter', 'left', 'lower', or 'compact'"
        end
        return true
    end,

    -- Number settings with ranges
    alpha = {type = "number", min = 0, max = 1},

    -- Complex object validation
    customHighlight = function(value)
        if type(value) ~= "table" then
            return false, "customHighlight must be a table"
        end
        if type(value.enabled) ~= "boolean" then
            return false, "customHighlight.enabled must be boolean"
        end
        if type(value.r) ~= "number" or value.r < 0 or value.r > 1 then
            return false, "customHighlight.r must be number between 0 and 1"
        end
        if type(value.g) ~= "number" or value.g < 0 or value.g > 1 then
            return false, "customHighlight.g must be number between 0 and 1"
        end
        if type(value.b) ~= "number" or value.b < 0 or value.b > 1 then
            return false, "customHighlight.b must be number between 0 and 1"
        end
        return true
    end,

    customClassColors = function(value)
        if type(value) ~= "table" then
            return false, "customClassColors must be a table"
        end
        return true
    end,

    gcMode = function(value)
        if type(value) ~= "string" then
            return false, "gcMode must be a string"
        end
        local valid = { smooth = true, default = true, combat = true }
        if not valid[value] then
            return false, "gcMode must be 'smooth', 'default', or 'combat'"
        end
        return true
    end,

    colorMode = function(value)
        if type(value) ~= "string" then
            return false, "colorMode must be a string"
        end
        local valid = { Normal = true, HDR = true, Deuteranopia = true, Protanopia = true, Tritanopia = true }
        if not valid[value] then
            return false, "colorMode must be 'Normal', 'HDR', 'Deuteranopia', 'Protanopia', or 'Tritanopia'"
        end
        return true
    end,
}


-- Validate a single configuration value
-- @param key string The configuration key
-- @param value any The value to validate
-- @return boolean success Whether validation passed
-- @return string error Optional user-friendly error message
function Config.validateValue(key, value)
    local rule = Config.validationRules[key]

    if not rule then
        -- No validation rule means any value is acceptable
        return true
    end

    if type(rule) == "string" then
        -- Simple type check
        if type(value) ~= rule then
            return false, ("Setting '%s' must be a %s, but got %s"):format(key, rule, type(value))
        end
        return true
    elseif type(rule) == "table" then
        -- Complex validation with constraints
        if type(value) ~= rule.type then
            return false, ("Setting '%s' must be a %s, but got %s"):format(key, rule.type, type(value))
        end
        if rule.min and value < rule.min then
            return false, ("Setting '%s' value %.2f is below minimum %.2f"):format(key, value, rule.min)
        end
        if rule.max and value > rule.max then
            return false, ("Setting '%s' value %.2f is above maximum %.2f"):format(key, value, rule.max)
        end
        return true
    elseif type(rule) == "function" then
        -- Custom validation function
        return rule(value)
    end

    return true
end

-- Sanitize a configuration value to ensure it's valid
-- @param key string The configuration key
-- @param value any The value to sanitize
-- @return any The sanitized value (or default if invalid)
function Config.sanitizeValue(key, value)
    local valid, err = Config.validateValue(key, value)

    if not valid then
        private.debug("Config", "Invalid value for", key, ":", err, "- using default")
        return Config.defaults[key]
    end

    return value
end

-- Migrate deprecated settings to current format
-- @param config table The configuration table to migrate
-- @return boolean changed Whether any migrations were performed
function Config.migrateDeprecatedSettings(config)
    local changed = false

    for oldKey, migration in pairs(Config.deprecatedSettings) do
        if config[oldKey] ~= nil then
            if type(migration) == "string" then
                -- Simple key rename
                config[migration] = config[oldKey]
                config[oldKey] = nil
                changed = true
                private.debug("Config", "Migrated", oldKey, "to", migration)
            elseif type(migration) == "function" then
                -- Custom migration function
                if migration(config[oldKey], config) then
                    config[oldKey] = nil
                    changed = true
                    private.debug("Config", "Migrated", oldKey, "using custom function")
                end
            end
        end
    end

    return changed
end

-- Remove settings that are no longer valid
-- @param config table The configuration table to clean
-- @return boolean changed Whether any settings were removed
function Config.removeInvalidSettings(config)
    local changed = false

    for key in pairs(config) do
        if Config.defaults[key] == nil then
            config[key] = nil
            changed = true
            private.debug("Config", "Removed invalid setting:", key)
        end
    end

    return changed
end

-- Deep copy a table value
-- @param value any The value to copy
-- @return any The copied value
local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for k, v in pairs(value) do
        copy[k] = deepCopy(v)
    end
    return copy
end

-- Apply default values for missing configuration keys
-- @param config table The configuration table to populate
-- @return boolean changed Whether any defaults were applied
function Config.applyDefaults(config)
    local changed = false

    for key, defaultValue in pairs(Config.defaults) do
        if config[key] == nil then
            config[key] = deepCopy(defaultValue)
            changed = true
            private.debug("Config", "Applied default for:", key)
        end
    end

    return changed
end

-- Validate entire configuration object
-- @param config table The configuration to validate
-- @return boolean valid Whether the configuration is valid
-- @return table errors List of validation errors
function Config.validateConfig(config)
    local errors = {}

    for key, value in pairs(config) do
        local valid, err = Config.validateValue(key, value)
        if not valid then
            errors[#errors + 1] = {key = key, error = err}
        end
    end

    return #errors == 0, errors
end

-- Sanitize entire configuration object
-- @param config table The configuration to sanitize
-- @return table The sanitized configuration
function Config.sanitizeConfig(config)
    local sanitized = {}

    for key, value in pairs(config) do
        sanitized[key] = Config.sanitizeValue(key, value)
    end

    return sanitized
end

-- Settings Persistence Layer
-- Handles SavedVariables integration, loading, saving, and recovery

-- Initialize configuration from SavedVariables
-- @param wago table Optional WagoAnalytics instance for tracking
-- @return table The initialized configuration
function Config.load(wago)
    -- Initialize or get existing SavedVariables
    _G.AuroraConfig = _G.AuroraConfig or {}
    local config = _G.AuroraConfig

    -- Step 1: Migrate deprecated settings
    local migrated = Config.migrateDeprecatedSettings(config)

    -- Step 2: Remove invalid/unknown settings
    local cleaned = Config.removeInvalidSettings(config)

    -- Step 3: Track analytics for existing settings (before applying defaults)
    if wago and config.hasAnalytics == nil then
        for key, value in pairs(config) do
            if key ~= "acknowledgedSplashScreen" then
                if key == "customHighlight" then
                    wago:Switch(key, value.enabled)
                elseif key == "alpha" then
                    wago:SetCounter(key, value)
                else
                    wago:Switch(key, value)
                end
            end
        end
    end

    -- Step 4: Apply defaults for missing keys
    local defaultsApplied = Config.applyDefaults(config)

    -- Step 5: Validate and sanitize all values
    local valid, errors = Config.validateConfig(config)
    if not valid then
        private.debug("Config", "Configuration validation errors:")
        for _, err in pairs(errors) do
            private.debug("Config", "  -", err.key, ":", err.error)
        end
        -- Sanitize invalid values
        for _, err in pairs(errors) do
            config[err.key] = Config.sanitizeValue(err.key, config[err.key])
        end
    end

    if migrated or cleaned or defaultsApplied then
        private.debug("Config", "Configuration updated during load")
    end

    return config
end

-- Save configuration to SavedVariables
-- @param config table The configuration to save (optional, uses global if not provided)
function Config.save(config)
    config = config or _G.AuroraConfig

    if not config then
        private.debug("Config", "No configuration to save")
        return
    end

    -- Validate before saving
    local valid, errors = Config.validateConfig(config)
    if not valid then
        private.debug("Config", "Cannot save invalid configuration:")
        for _, err in pairs(errors) do
            private.debug("Config", "  -", err.key, ":", err.error)
        end
        return false
    end

    -- SavedVariables are automatically persisted by WoW
    -- We just need to ensure the global reference is correct
    _G.AuroraConfig = config

    private.debug("Config", "Configuration saved")
    return true
end

-- Reset configuration to defaults
-- @param preserveAcknowledgment boolean Whether to preserve splash screen acknowledgment
-- @return table The reset configuration
function Config.reset(preserveAcknowledgment)
    local config = _G.AuroraConfig or {}

    -- Preserve splash screen acknowledgment if requested
    local acknowledged = preserveAcknowledgment and config.acknowledgedSplashScreen

    -- Clear all settings
    for key in pairs(config) do
        config[key] = nil
    end

    -- Apply all defaults
    for key, value in pairs(Config.defaults) do
        config[key] = deepCopy(value)
    end

    -- Restore acknowledgment if needed
    if acknowledged then
        config.acknowledgedSplashScreen = true
    end

    _G.AuroraConfig = config

    private.debug("Config", "Configuration reset to defaults")
    return config
end

-- Get a configuration value with fallback to default
-- @param key string The configuration key
-- @param config table Optional config table (uses global if not provided)
-- @return any The configuration value
function Config.get(key, config)
    config = config or _G.AuroraConfig

    if config and config[key] ~= nil then
        return config[key]
    end

    return Config.defaults[key]
end

-- Set a configuration value with validation
-- @param key string The configuration key
-- @param value any The value to set
-- @param config table Optional config table (uses global if not provided)
-- @return boolean success Whether the value was set successfully
-- @return string error Optional error message if failed
function Config.set(key, value, config)
    config = config or _G.AuroraConfig

    if not config then
        return false, "No configuration available"
    end

    -- Validate the value
    local valid, err = Config.validateValue(key, value)
    if not valid then
        return false, err
    end

    -- Set the value
    config[key] = value

    -- Dispatch configuration change event if integration is available
    if private.Integration and private.Integration.DispatchEvent then
        private.Integration.DispatchEvent("CONFIG_CHANGED", key, value)
    end

    private.debug("Config", "Set", key, "to", value)
    return true
end

-- Check if configuration needs recovery (corrupted or missing)
-- @param config table The configuration to check
-- @return boolean needsRecovery Whether recovery is needed
-- @return string reason The reason recovery is needed
function Config.needsRecovery(config)
    if not config then
        return true, "Configuration is nil"
    end

    if type(config) ~= "table" then
        return true, "Configuration is not a table"
    end

    -- Check if critical settings are present
    local criticalSettings = {"bags", "banks", "chat", "tooltips", "alpha"}
    for _, key in pairs(criticalSettings) do
        if config[key] == nil then
            return true, "Missing critical setting: " .. key
        end
    end

    return false, nil
end

-- Recover configuration from corruption
-- @return table The recovered configuration
function Config.recover()
    private.debug("Config", "Attempting configuration recovery")

    local oldConfig = _G.AuroraConfig
    local config = {}

    -- Try to salvage valid settings from old config
    if type(oldConfig) == "table" then
        for key, value in pairs(oldConfig) do
            if Config.defaults[key] ~= nil then
                local valid = Config.validateValue(key, value)
                if valid then
                    config[key] = value
                end
            end
        end
    end

    -- Apply defaults for missing keys
    Config.applyDefaults(config)

    _G.AuroraConfig = config

    private.debug("Config", "Configuration recovered")
    return config
end
