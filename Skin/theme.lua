local _, private = ...

-- [[ Lua Globals ]]
-- luacheck: globals next type pairs ipairs tinsert tremove pcall debugprofilestop table

-- [[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base -- luacheck: ignore
local Color, Util = Aurora.Color, Aurora.Util  -- luacheck: ignore

-- Theme Engine Module
-- Handles frame detection, processing pipeline, and style application coordination
local Theme = {}
Aurora.Theme = Theme

--[[ B261 (task 6.2, AT-D11 b): the frame-pattern route is gone: the pattern
    table, the frame registry and queue, and RegisterFrame, IsFrameProcessed,
    DetectFrameType, ProcessFrame, ProcessQueue, ProcessChildren,
    ProcessRegions, GetStats, ResetStats, ClearProcessedFrames,
    RegisterDynamicHandler and CheckDynamicFrame. Nothing in Aurora or RealUI
    called any of them, so no frame ever entered the registry. ]]

-- Initialize theme engine
function Theme.Initialize()
    private.debug("Theme", "Theme engine initialized")

    -- Hook into common frame creation events
    -- This will be expanded as needed for specific UI components

    return true
end


-- Frame Alpha and Transparency System
-- Handles transparency application and immediate updates

local currentAlpha = 0.5 -- Default alpha value
local alphaCallbacks = {}
local framedAlphaRegistry = {}

--[[ Theme.SetGlobalAlpha(_alpha_)
Set the global alpha value for all themed elements.

**Args:**
* `alpha` - the alpha value (0-1) _(number)_

**Returns:**
* `success` - whether the alpha was set successfully _(boolean)_
--]]
function Theme.SetGlobalAlpha(alpha)
    if type(alpha) ~= "number" then
        private.debug("Theme", "Alpha must be a number")
        return false
    end

    if alpha < 0 or alpha > 1 then
        private.debug("Theme", "Alpha must be between 0 and 1")
        return false
    end

    local oldAlpha = currentAlpha
    currentAlpha = alpha

    -- Update Util module's frame alpha
    Util.SetFrameAlpha(alpha)

    -- Trigger callbacks for immediate updates
    Theme.UpdateAllFrameAlpha()

    private.debug("Theme", "Global alpha changed from", oldAlpha, "to", alpha)
    return true
end

--[[ Theme.GetGlobalAlpha()
Get the current global alpha value.

**Returns:**
* `alpha` - the current alpha value _(number)_
--]]
function Theme.GetGlobalAlpha()
    return currentAlpha
end

--[[ Theme.RegisterAlphaCallback(_callback_)
Register a callback to be called when alpha changes.

**Args:**
* `callback` - function to call on alpha change _(function)_

**Returns:**
* `id` - callback identifier for unregistering _(number)_
--]]
function Theme.RegisterAlphaCallback(callback)
    if type(callback) ~= "function" then
        private.debug("Theme", "Callback must be a function")
        return nil
    end

    local id = #alphaCallbacks + 1
    alphaCallbacks[id] = callback

    return id
end

--[[ Theme.UnregisterAlphaCallback(_id_)
Unregister an alpha change callback.

**Args:**
* `id` - the callback identifier _(number)_
--]]
function Theme.UnregisterAlphaCallback(id)
    if alphaCallbacks[id] then
        alphaCallbacks[id] = nil
        return true
    end
    return false
end

--[[ Theme.RegisterFrameAlpha(_frame, alphaFunc_)
Register a frame for alpha updates with a custom update function.

**Args:**
* `frame` - the frame to register _(Frame)_
* `alphaFunc` - function to call to update frame alpha _(function)_
--]]
function Theme.RegisterFrameAlpha(frame, alphaFunc)
    if not frame then
        return false
    end

    if type(alphaFunc) ~= "function" then
        private.debug("Theme", "Alpha function must be a function")
        return false
    end

    framedAlphaRegistry[frame] = alphaFunc
    return true
end

--[[ Theme.UnregisterFrameAlpha(_frame_)
Unregister a frame from alpha updates.

**Args:**
* `frame` - the frame to unregister _(Frame)_
--]]
function Theme.UnregisterFrameAlpha(frame)
    if framedAlphaRegistry[frame] then
        framedAlphaRegistry[frame] = nil
        return true
    end
    return false
end

--[[ Theme.UpdateFrameAlpha(_frame[, alpha]_)
Update a specific frame's alpha value.

**Args:**
* `frame` - the frame to update _(Frame)_
* `alpha` - optional alpha value, uses global if not provided _(number)_

**Returns:**
* `success` - whether the update succeeded _(boolean)_
--]]
function Theme.UpdateFrameAlpha(frame, alpha)
    if not frame then
        return false
    end

    alpha = alpha or currentAlpha

    -- Use custom alpha function if registered
    if framedAlphaRegistry[frame] then
        local success, err = pcall(framedAlphaRegistry[frame], frame, alpha)
        if not success then
            private.debug("Theme", "Failed to update frame alpha:", err)
            return false
        end
        return true
    end

    -- Default alpha update for frames with backdrop
    if frame.SetBackdropColor then
        local r, g, b = frame:GetBackdropColor()
        frame:SetBackdropColor(r, g, b, alpha)
        return true
    end

    -- Fallback to SetAlpha for frames without backdrop
    if frame.SetAlpha then
        frame:SetAlpha(alpha)
        return true
    end

    return false
end

--[[ Theme.UpdateAllFrameAlpha()
Run the registered alpha callbacks with the current alpha. (It also walked
the frame-pattern route's registry of processed frames, which nothing ever
filled; that route is gone, B261 task 6.2.)

**Returns:**
* `updated` - number of frames updated, always 0 _(number)_
--]]
function Theme.UpdateAllFrameAlpha()
    local updated = 0

    -- Call registered callbacks
    for _, callback in pairs(alphaCallbacks) do
        local success, err = pcall(callback, currentAlpha)
        if not success then
            private.debug("Theme", "Alpha callback failed:", err)
        end
    end

    private.debug("Theme", "Updated alpha for", updated, "frames")
    return updated
end

--[[ Theme.EnsureTextReadability(_frame_)
Ensure text elements in a frame remain readable at current alpha.

**Args:**
* `frame` - the frame to check _(Frame)_

**Returns:**
* `adjusted` - whether adjustments were made _(boolean)_
--]]
function Theme.EnsureTextReadability(frame)
    if not frame or not frame.GetRegions then
        return false
    end

    local adjusted = false
    local regions = {frame:GetRegions()}

    for _, region in ipairs(regions) do
        if region and region.GetObjectType and region:GetObjectType() == "FontString" then
            -- Ensure font strings have sufficient alpha for readability
            local minTextAlpha = 0.9
            if region.SetAlpha then
                local currentTextAlpha = region:GetAlpha()
                if currentTextAlpha < minTextAlpha then
                    region:SetAlpha(minTextAlpha)
                    adjusted = true
                end
            end

            -- Ensure text has sufficient contrast
            if region.SetShadowColor then
                -- Add shadow for better readability at low alpha
                region:SetShadowColor(0, 0, 0, 0.8)
                region:SetShadowOffset(1, -1)
                adjusted = true
            end
        end
    end

    return adjusted
end

--[[ Theme.ApplyAlphaToFrame(_frame[, alpha]_)
Apply alpha to a frame and ensure text readability.

**Args:**
* `frame` - the frame to apply alpha to _(Frame)_
* `alpha` - optional alpha value, uses global if not provided _(number)_

**Returns:**
* `success` - whether the application succeeded _(boolean)_
--]]
function Theme.ApplyAlphaToFrame(frame, alpha)
    if not frame then
        return false
    end

    alpha = alpha or currentAlpha

    -- Update frame alpha
    local success = Theme.UpdateFrameAlpha(frame, alpha)

    -- Ensure text readability
    if success then
        Theme.EnsureTextReadability(frame)
    end

    return success
end

-- Initialize alpha system with current configuration
function Theme.InitializeAlpha(config)
    if config and config.alpha then
        Theme.SetGlobalAlpha(config.alpha)
    end

    private.debug("Theme", "Alpha system initialized with alpha:", currentAlpha)
end


-- Skin Module Coordination System
-- Handles module loading, management, and enable/disable functionality

local skinModules = {}
local moduleStates = {}
local moduleLoadOrder = {}

--[[ Theme.RegisterModule(_name, config_)
Register a skin module with the theme engine.

**Args:**
* `name` - the module name _(string)_
* `config` - module configuration table _(table)_
  * `init` - initialization function _(function)_
  * `enable` - enable function _(function)_
  * `disable` - disable function _(function)_
  * `priority` - load priority (lower = earlier) _(number)_
  * `dependencies` - array of module names this depends on _(table)_

**Returns:**
* `success` - whether registration succeeded _(boolean)_
--]]
function Theme.RegisterModule(name, config)
    if not name or type(name) ~= "string" then
        private.debug("Theme", "Module name must be a string")
        return false
    end

    if skinModules[name] then
        private.debug("Theme", "Module already registered:", name)
        return false
    end

    if not config or type(config) ~= "table" then
        private.debug("Theme", "Module config must be a table")
        return false
    end

    -- Validate required functions
    if config.init and type(config.init) ~= "function" then
        private.debug("Theme", "Module init must be a function")
        return false
    end

    skinModules[name] = {
        name = name,
        init = config.init,
        enable = config.enable,
        disable = config.disable,
        priority = config.priority or 100,
        dependencies = config.dependencies or {},
        initialized = false,
    }

    moduleStates[name] = false -- Disabled by default

    -- Add to load order
    tinsert(moduleLoadOrder, name)

    private.debug("Theme", "Registered module:", name)
    return true
end

--[[ Theme.UnregisterModule(_name_)
Unregister a skin module.

**Args:**
* `name` - the module name _(string)_

**Returns:**
* `success` - whether unregistration succeeded _(boolean)_
--]]
function Theme.UnregisterModule(name)
    if not skinModules[name] then
        return false
    end

    -- Disable module first
    Theme.DisableModule(name)

    skinModules[name] = nil
    moduleStates[name] = nil

    -- Remove from load order
    for i, moduleName in ipairs(moduleLoadOrder) do
        if moduleName == name then
            tremove(moduleLoadOrder, i)
            break
        end
    end

    private.debug("Theme", "Unregistered module:", name)
    return true
end

--[[ Theme.InitializeModule(_name_)
Initialize a skin module.

**Args:**
* `name` - the module name _(string)_

**Returns:**
* `success` - whether initialization succeeded _(boolean)_
* `error` - error message if failed _(string|nil)_
--]]
function Theme.InitializeModule(name)
    local module = skinModules[name]

    if not module then
        return false, "Module not found: " .. name
    end

    if module.initialized then
        return true, "Already initialized"
    end

    -- Check dependencies
    for _, depName in ipairs(module.dependencies) do
        local depModule = skinModules[depName]
        if not depModule then
            return false, "Missing dependency: " .. depName
        end
        if not depModule.initialized then
            local success, err = Theme.InitializeModule(depName)
            if not success then
                return false, "Failed to initialize dependency " .. depName .. ": " .. (err or "unknown error")
            end
        end
    end

    -- Initialize module
    if module.init then
        local success, err = pcall(module.init)
        if not success then
            return false, "Initialization failed: " .. (err or "unknown error")
        end
    end

    module.initialized = true
    private.debug("Theme", "Initialized module:", name)

    return true
end

--[[ Theme.EnableModule(_name_)
Enable a skin module.

**Args:**
* `name` - the module name _(string)_

**Returns:**
* `success` - whether enabling succeeded _(boolean)_
* `error` - error message if failed _(string|nil)_
--]]
function Theme.EnableModule(name)
    local module = skinModules[name]

    if not module then
        return false, "Module not found: " .. name
    end

    if moduleStates[name] then
        return true, "Already enabled"
    end

    -- Initialize if not already done
    if not module.initialized then
        local success, err = Theme.InitializeModule(name)
        if not success then
            return false, err
        end
    end

    -- Enable module
    if module.enable then
        local success, err = pcall(module.enable)
        if not success then
            return false, "Enable failed: " .. (err or "unknown error")
        end
    end

    moduleStates[name] = true
    private.debug("Theme", "Enabled module:", name)

    return true
end

--[[ Theme.DisableModule(_name_)
Disable a skin module.

**Args:**
* `name` - the module name _(string)_

**Returns:**
* `success` - whether disabling succeeded _(boolean)_
* `error` - error message if failed _(string|nil)_
--]]
function Theme.DisableModule(name)
    local module = skinModules[name]

    if not module then
        return false, "Module not found: " .. name
    end

    if not moduleStates[name] then
        return true, "Already disabled"
    end

    -- Disable module
    if module.disable then
        local success, err = pcall(module.disable)
        if not success then
            return false, "Disable failed: " .. (err or "unknown error")
        end
    end

    moduleStates[name] = false
    private.debug("Theme", "Disabled module:", name)

    return true
end

--[[ Theme.IsModuleEnabled(_name_)
Check if a module is enabled.

**Args:**
* `name` - the module name _(string)_

**Returns:**
* `enabled` - whether the module is enabled _(boolean)_
--]]
function Theme.IsModuleEnabled(name)
    return moduleStates[name] == true
end

--[[ Theme.GetModuleState(_name_)
Get the state of a module.

**Args:**
* `name` - the module name _(string)_

**Returns:**
* `state` - module state table or nil _(table|nil)_
--]]
function Theme.GetModuleState(name)
    local module = skinModules[name]
    if not module then
        return nil
    end

    return {
        name = name,
        enabled = moduleStates[name],
        initialized = module.initialized,
        priority = module.priority,
        dependencies = module.dependencies,
    }
end

--[[ Theme.GetAllModules()
Get all registered modules.

**Returns:**
* `modules` - table of module names and states _(table)_
--]]
function Theme.GetAllModules()
    local modules = {}

    for name in pairs(skinModules) do
        modules[name] = Theme.GetModuleState(name)
    end

    return modules
end

--[[ Theme.LoadModulesFromConfig(_config_)
Load and configure modules based on configuration.

**Args:**
* `config` - configuration table with module enable/disable flags _(table)_

**Returns:**
* `loaded` - number of modules loaded _(number)_
* `failed` - number of modules that failed to load _(number)_
--]]
function Theme.LoadModulesFromConfig(config)
    if not config then
        return 0, 0
    end

    local loaded = 0
    local failed = 0

    -- Sort modules by priority
    local sortedModules = {}
    for _, name in ipairs(moduleLoadOrder) do
        tinsert(sortedModules, {name = name, priority = skinModules[name].priority})
    end
    table.sort(sortedModules, function(a, b) return a.priority < b.priority end)

    -- Load modules in priority order
    for _, entry in ipairs(sortedModules) do
        local name = entry.name

        -- Check if module should be enabled based on config
        local shouldEnable = false

        -- Map module names to config keys
        local configKey = name:lower()
        if config[configKey] ~= nil then
            shouldEnable = config[configKey]
        end

        if shouldEnable then
            local success, err = Theme.EnableModule(name)
            if success then
                loaded = loaded + 1
            else
                failed = failed + 1
                private.debug("Theme", "Failed to load module", name, ":", err)
            end
        end
    end

    private.debug("Theme", "Loaded", loaded, "modules,", failed, "failed")
    return loaded, failed
end

--[[ Theme.OptimizeFrameProcessing()
Optimize frame processing for better performance.

**Returns:**
* `optimizations` - number of optimizations applied _(number)_
--]]
function Theme.OptimizeFrameProcessing()
    local optimizations = 0

    -- Clear alpha registry for non-existent frames
    for frame in pairs(framedAlphaRegistry) do
        if not frame or not frame.GetName then
            framedAlphaRegistry[frame] = nil
            optimizations = optimizations + 1
        end
    end

    if optimizations > 0 then
        private.debug("Theme", "Applied", optimizations, "frame processing optimizations")
    end

    return optimizations
end

-- Performance monitoring
local performanceMonitor = {
    enabled = false,
    startTime = 0,
    frameCount = 0,
    totalTime = 0,
}

--[[ Theme.EnablePerformanceMonitoring()
Enable performance monitoring for frame processing.
--]]
function Theme.EnablePerformanceMonitoring()
    performanceMonitor.enabled = true
    performanceMonitor.startTime = debugprofilestop()
    performanceMonitor.frameCount = 0
    performanceMonitor.totalTime = 0

    private.debug("Theme", "Performance monitoring enabled")
end

--[[ Theme.DisablePerformanceMonitoring()
Disable performance monitoring.
--]]
function Theme.DisablePerformanceMonitoring()
    performanceMonitor.enabled = false
    private.debug("Theme", "Performance monitoring disabled")
end

--[[ Theme.GetPerformanceStats()
Get performance statistics.

**Returns:**
* `stats` - performance statistics table _(table)_
--]]
function Theme.GetPerformanceStats()
    if not performanceMonitor.enabled then
        return nil
    end

    local elapsed = debugprofilestop() - performanceMonitor.startTime
    local avgTime = performanceMonitor.frameCount > 0
        and (performanceMonitor.totalTime / performanceMonitor.frameCount)
        or 0

    return {
        enabled = performanceMonitor.enabled,
        elapsedTime = elapsed,
        frameCount = performanceMonitor.frameCount,
        totalProcessingTime = performanceMonitor.totalTime,
        averageFrameTime = avgTime,
    }
end
