local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base, Hook, Skin = Aurora.Base, Aurora.Hook, Aurora.Skin
local Util = Aurora.Util

do --[[ AddOns\Blizzard_EndOfMatchUI.lua ]]
    Hook.EndOfMatchFrameMixin = {}
    function Hook.EndOfMatchFrameMixin:TryUpdateMatchDetails()
        -- Post-hook: skin detail frames and action buttons acquired from pools.
        -- Pools are already wrapped via Util.WrapPoolAcquire, but we also
        -- strip the DetailsBackgroundContainer decorative atlas textures
        -- each time results are refreshed.
        local bgContainer = self.DetailsBackgroundContainer
        if bgContainer and not private.IsSkinned(bgContainer) then
            Base.StripBlizzardTextures(bgContainer)
            private.SetSkinned(bgContainer, true)
        end
    end
end

--[[ AddOns\Blizzard_EndOfMatchUI.xml ]]
-- Detail and button templates are skinned dynamically via pool wrapping.

function private.AddOns.Blizzard_EndOfMatchUI()
    ------------------------------------------------
    -- Hook mixin prototypes via Util.Mixin
    ------------------------------------------------
    Util.Mixin(_G.EndOfMatchFrameMixin, Hook.EndOfMatchFrameMixin)

    ------------------------------------------------
    -- Skin the EndOfMatchFrame
    ------------------------------------------------
    local frame = _G.EndOfMatchFrame
    if not frame then return end

    -- Apply Aurora frame backdrop using Color.frame for consistency
    -- with the existing Blizzard_PVPMatch skin
    Skin.FrameTypeFrame(frame)

    -- Strip the fullscreen background textures and decorative atlas elements
    Base.StripBlizzardTextures(frame)

    -- Strip the screen overlay container (solid black overlay)
    local overlayContainer = frame.ScreenOverlayContainer
    if overlayContainer then
        Base.StripBlizzardTextures(overlayContainer)
    end

    -- Strip the decorative background container (swords, dividers, fade)
    local bgContainer = frame.DetailsBackgroundContainer
    if bgContainer then
        Base.StripBlizzardTextures(bgContainer)
        private.SetSkinned(bgContainer, true)
    end

    ------------------------------------------------
    -- Wrap pools with Util.WrapPoolAcquire
    ------------------------------------------------
    -- Detail pool: skin each MatchDetailFrameTemplate frame
    if frame.detailPool then
        Util.WrapPoolAcquire(frame.detailPool, function(detailFrame)
            if not detailFrame or private.IsSkinned(detailFrame) then return end
            -- Crop the detail icon
            if detailFrame.Icon then
                Base.CropIcon(detailFrame.Icon)
            end
            -- Strip the detail background texture
            if detailFrame.Background then
                detailFrame.Background:SetTexture("")
            end
            private.SetSkinned(detailFrame, true)
        end)
    end

    -- Action button pool: skin EndOfMatchButtonBaseTemplate buttons
    if frame.actionsButtonPool then
        Util.WrapPoolAcquire(frame.actionsButtonPool, function(button)
            if not button or private.IsSkinned(button) then return end
            Skin.FrameTypeButton(button)
            private.SetSkinned(button, true)
        end)
    end

    -- Gold action button pool: skin EndOfMatchButtonGoldButtonBaseTemplate buttons
    if frame.goldActionsButtonPool then
        Util.WrapPoolAcquire(frame.goldActionsButtonPool, function(button)
            if not button or private.IsSkinned(button) then return end
            Skin.FrameTypeButton(button)
            private.SetSkinned(button, true)
        end)
    end
end
