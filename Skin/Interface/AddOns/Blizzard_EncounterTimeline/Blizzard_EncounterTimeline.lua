local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

-- [[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Util = Aurora.Util

-- Shared helper: skin a single event frame (track or timer)
local function SkinEventFrame(eventFrame)
    if not eventFrame or private.IsSkinned(eventFrame) then return end
    if eventFrame.IsForbidden and eventFrame:IsForbidden() then return end

    -- Crop the ability icon inside the IconContainer
    local iconContainer = eventFrame.IconContainer
    if not iconContainer and eventFrame.GetIconContainer then
        iconContainer = eventFrame:GetIconContainer()
    end
    if iconContainer then
        local iconTexture = iconContainer.IconTexture
        if not iconTexture and iconContainer.GetIconTexture then
            iconTexture = iconContainer:GetIconTexture()
        end
        if iconTexture then
            Base.CropIcon(iconTexture)
        end

        -- Strip decorative overlay/border textures from the icon container.
        -- These are the ring borders around the ability icon.
        for _, key in _G.ipairs({
            "NormalOverlay",
            "DeadlyOverlay",
            "DeadlyOverlayGlow",
            "PausedOverlay",
            "QueuedOverlay",
        }) do
            local tex = iconContainer[key]
            if tex and tex.SetTexture then
                tex:SetTexture("")
                tex:SetAtlas("")
            end
        end
    end

    private.SetSkinned(eventFrame, true)
end

--[[ AddOns\Blizzard_EncounterTimeline.lua ]]
-- No Hook table needed — we use EventRegistry:RegisterCallback
-- to intercept event frame acquisition, which is the canonical
-- lifecycle hook for this addon.

--[[ AddOns\Blizzard_EncounterTimeline.xml ]]
-- Event frame templates are skinned dynamically via the
-- OnEventFrameAcquired callback and Util.WrapPoolAcquire.

-- Helper: wrap all pools in a view's FramePoolCollection
local function WrapViewPools(view)
    if not view then return end
    local poolCollection = view.GetEventFramePoolCollection and view:GetEventFramePoolCollection()
    if not poolCollection then return end

    -- FramePoolCollection exposes EnumeratePools() to iterate all registered pools
    if poolCollection.EnumeratePools then
        for pool in poolCollection:EnumeratePools() do
            Util.WrapPoolAcquire(pool, SkinEventFrame)
        end
    end
end

function private.AddOns.Blizzard_EncounterTimeline()
    ------------------------------------------------
    -- Register for the EventRegistry callback to skin
    -- newly acquired event frames (both track and timer).
    -- This is the primary skinning hook — it fires for
    -- every frame acquired by any view.
    ------------------------------------------------
    _G.EventRegistry:RegisterCallback("EncounterTimeline.OnEventFrameAcquired", function(_, viewFrame, eventFrame, eventID, isNewObject)
        SkinEventFrame(eventFrame)
    end)

    ------------------------------------------------
    -- Skin existing event frames that may already be active
    ------------------------------------------------
    local encounterTimeline = _G.EncounterTimeline
    if not encounterTimeline then return end

    -- Do NOT touch the parent EncounterTimeline frame — it is EditMode-managed.
    -- Only skin child visual elements on event frames.

    -- Wrap event frame pools via Util.WrapPoolAcquire as a secondary guard
    -- so frames acquired outside the EventRegistry path are also skinned.
    if encounterTimeline.EnumerateViews then
        for _, view in encounterTimeline:EnumerateViews() do
            WrapViewPools(view)

            -- Skin any already-active event frames
            if view and view.EnumerateEventFrames then
                for eventFrame in view:EnumerateEventFrames() do
                    SkinEventFrame(eventFrame)
                end
            end
        end
    end
end
