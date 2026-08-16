local _, private = ...
if private.shouldSkip() then return end

local Aurora = private.Aurora
local _, Hook = Aurora.Base, Aurora.Hook

do --[[ AddOns\Blizzard_ContentTracking.lua ]]
    -- ContentTrackingElementMixin dynamically creates a ContentTrackingCheckmark
    -- texture via CreateTexture when SetTrackingCheckmarkShown is first called
    -- with shouldShow=true. Hook that method to guard against duplicate skinning.
    Hook.ContentTrackingElementMixin = {}
    function Hook.ContentTrackingElementMixin:SetTrackingCheckmarkShown(shouldShow)
        local checkmark = self.ContentTrackingCheckmark
        if checkmark and not private.IsSkinned(checkmark) then
            private.SetSkinned(checkmark, true)
            -- The checkmark is a small atlas texture ("checkmark-minimal").
            -- Strip any Blizzard decorative sub-regions on the parent element
            -- frame if they haven't been handled yet.
        end
    end
end

function private.AddOns.Blizzard_ContentTracking()
    -- ContentTrackingElementMixin is a virtual template mixed into other
    -- addon frames (e.g. EncounterJournal loot buttons). The mixin itself
    -- has no standalone top-level frame. Hook the mixin method so that any
    -- frame using ContentTrackingElementTemplate gets its dynamically
    -- created checkmark guarded with _auroraSkinned.
    if _G.ContentTrackingElementMixin and _G.ContentTrackingElementMixin.SetTrackingCheckmarkShown then
        _G.hooksecurefunc(_G.ContentTrackingElementMixin, "SetTrackingCheckmarkShown", Hook.ContentTrackingElementMixin.SetTrackingCheckmarkShown)
    end
end
