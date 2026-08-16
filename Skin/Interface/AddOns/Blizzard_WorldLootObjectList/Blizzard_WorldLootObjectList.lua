local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base, Hook, Skin = Aurora.Base, Aurora.Hook, Aurora.Skin
local Util = Aurora.Util

-- Shared helper: skin a single loot object list entry
local function SkinListEntry(frame)
    if not frame or private.IsSkinned(frame) then return end
    private.SetSkinned(frame, true)
end

do --[[ AddOns\Blizzard_WorldLootObjectList.lua ]]
    Hook.WorldLootObjectListMixin = {}
    function Hook.WorldLootObjectListMixin:OnLoad()
        -- Post-hook: wrap the ScrollBox acquired frame callback so
        -- every list entry created by the linear view is guarded.
        local scrollBox = self.ScrollBox
        if scrollBox then
            _G.ScrollUtil.AddAcquiredFrameCallback(scrollBox, function(o, frame)
                SkinListEntry(frame)
            end, self)
        end
    end
end

--[[ AddOns\Blizzard_WorldLootObjectList.xml ]]
-- List entry templates are skinned dynamically via the ScrollBox
-- acquired frame callback registered in the OnLoad hook.

function private.AddOns.Blizzard_WorldLootObjectList()
    ------------------------------------------------
    -- Hook mixin prototypes via Util.Mixin
    ------------------------------------------------
    Util.Mixin(_G.WorldLootObjectListMixin, Hook.WorldLootObjectListMixin)

    ------------------------------------------------
    -- Skin the WorldLootObjectList container
    ------------------------------------------------
    local listFrame = _G.WorldLootObjectList
    if not listFrame then return end

    Skin.FrameTypeFrame(listFrame)
    Base.StripBlizzardTextures(listFrame)

    -- Skin any already-visible list entries in the ScrollBox
    local scrollBox = listFrame.ScrollBox
    if scrollBox then
        scrollBox:ForEachFrame(function(frame)
            SkinListEntry(frame)
        end)
    end
end
