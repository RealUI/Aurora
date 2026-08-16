local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

-- [[ Core ]]
local Aurora = private.Aurora
local Base, Hook, Skin = Aurora.Base, Aurora.Hook, Aurora.Skin
local Util = Aurora.Util

-- Shared helper: skin a single DamageMeter entry frame (source or spell)
local function SkinEntry(frame)
    if not frame or private.IsSkinned(frame) then return end
    if frame.IsForbidden and frame:IsForbidden() then return end

    local statusBar = frame:GetStatusBar()
    if statusBar then
        Skin.FrameTypeStatusBar(statusBar)
    end

    local icon = frame:GetIcon()
    if icon then
        Base.CropIcon(icon)
    end

    private.SetSkinned(frame, true)
end

do --[[ AddOns\Blizzard_DamageMeter.lua ]]
    Hook.DamageMeterSessionWindowMixin = {}
    function Hook.DamageMeterSessionWindowMixin:SetupEntry(frame)
        SkinEntry(frame)
    end

    function Hook.DamageMeterSessionWindowMixin:InitializeScrollBox()
        -- Post-hook: add an acquired frame callback on the ScrollBox so
        -- entry frames created via the internal pool are skinned even if
        -- SetupEntry hasn't run yet for a given frame.
        local scrollBox = self:GetScrollBox()
        if scrollBox then
            _G.ScrollUtil.AddAcquiredFrameCallback(scrollBox, function(o, frame)
                SkinEntry(frame)
            end, self)
        end
    end
end

--[[ AddOns\Blizzard_DamageMeter.xml ]]
-- Entry templates are skinned dynamically via the SetupEntry hook
-- and the ScrollBox acquired frame callback.

function private.AddOns.Blizzard_DamageMeter()
    ------------------------------------------------
    -- Hook mixin prototypes via Util.Mixin
    ------------------------------------------------
    Util.Mixin(_G.DamageMeterSessionWindowMixin, Hook.DamageMeterSessionWindowMixin)

    ------------------------------------------------
    -- Skin existing session windows (if any loaded before us)
    ------------------------------------------------
    local damageMeter = _G.DamageMeter
    if not damageMeter then return end

    -- Do NOT touch the parent DamageMeter frame — it is EditMode-managed.
    -- Only skin child visual elements on session windows.

    local function SkinSessionWindow(sessionWindow)
        if not sessionWindow or private.IsSkinned(sessionWindow) then return end
        if sessionWindow.IsForbidden and sessionWindow:IsForbidden() then return end

        -- Strip decorative textures from the session window background
        local bg = sessionWindow:GetBackground()
        if bg then
            Base.StripBlizzardTextures(bg)
        end

        -- Strip the header atlas texture
        local header = sessionWindow:GetHeader()
        if header then
            header:SetAtlas("")
            header:SetTexture("")
        end

        -- Skin the source window background and wrap its ScrollBox
        local sourceWindow = sessionWindow:GetSourceWindow()
        if sourceWindow then
            local sourceBg = sourceWindow:GetBackground()
            if sourceBg then
                Base.StripBlizzardTextures(sourceBg)
            end

            -- Add acquired frame callback for spell entry frames
            local sourceScrollBox = sourceWindow:GetScrollBox()
            if sourceScrollBox then
                _G.ScrollUtil.AddAcquiredFrameCallback(sourceScrollBox, function(o, frame)
                    SkinEntry(frame)
                end, sourceWindow)

                sourceScrollBox:ForEachFrame(function(frame)
                    SkinEntry(frame)
                end)
            end
        end

        -- Skin the LocalPlayerEntry (static child)
        SkinEntry(sessionWindow:GetLocalPlayerEntry())

        -- Skin any already-visible entry frames in the ScrollBox
        local scrollBox = sessionWindow:GetScrollBox()
        if scrollBox then
            scrollBox:ForEachFrame(function(frame)
                SkinEntry(frame)
            end)
        end

        private.SetSkinned(sessionWindow, true)
    end

    -- Iterate over existing session windows
    if damageMeter.EnumerateSessionWindows then
        for _, sessionWindow in damageMeter:EnumerateSessionWindows() do
            SkinSessionWindow(sessionWindow)
        end
    end

    -- Hook SetupSessionWindow to catch future session windows
    _G.hooksecurefunc(_G.DamageMeterMixin, "SetupSessionWindow", function(self, windowData)
        local sessionWindow = windowData and windowData.sessionWindow
        SkinSessionWindow(sessionWindow)
    end)
end
