local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals next

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Util = Aurora.Util

--[[ TBC (anniversary 2.5.6) action bars: the RETAIL-MODERN system.
    CHROME ONLY, matching retail Aurora precedent — modern action buttons
    are NOT skinned: their art machinery (UpdateButtonArt/SetShowGrid)
    re-applies atlas textures on every state change, so per-button strips
    revert on empty slots and always-on backdrops force-reveal hidden bars
    (both observed in-game 2026-07-13). What we do skin:
    - the MainMenuBar art shell (stone bar + gryphon end caps)
    - MainActionBar border art keys (guarded)
    - the XP/reputation StatusTrackingBar containers (taint-safe widget API)
    Era converged onto the same system in 1.15.9 and resolves this file via
    the TBC skin-dir fallback (aurora-era-1159-convergence). Era-only
    survivors (MainMenuTrackingBar_Configure) are existence-guarded below.
    Micro buttons live in the Blizzard_MicroMenu module on both flavors.
]]

do --[[ StatusTrackingBarTemplate (taint-safe, widget API only) ]]
    local function SkinStatusTrackingBar(Frame)
        local StatusBar = Frame.StatusBar
        if not StatusBar then return end

        StatusBar:SetStatusBarTexture(private.textures.plain)
        local tex = StatusBar:GetStatusBarTexture()
        if tex then
            tex:SetDrawLayer("BORDER")
        end
        if StatusBar.Background then StatusBar.Background:Hide() end
        if StatusBar.Underlay   then StatusBar.Underlay:Hide()   end
        if StatusBar.Overlay    then StatusBar.Overlay:Hide()    end
        if StatusBar.Border     then StatusBar.Border:SetAlpha(0) end
    end
    function Skin.StatusTrackingBarContainerTemplate(Frame)
        if Frame.BarFrameTexture then
            Frame.BarFrameTexture:Hide()
        end
        if Frame.bars then
            for _, bar in next, Frame.bars do
                SkinStatusTrackingBar(bar)
            end
        end
    end
end

function private.AddOns.Blizzard_ActionBar()
    if private.disabled.mainmenubar then return end

    -- Classic art shell: stone bar + gryphon end caps
    local MainMenuBar = _G.MainMenuBar
    if MainMenuBar then
        Util.HideFrameTextures(MainMenuBar)
        for _, child in next, {MainMenuBar:GetChildren()} do
            Util.HideFrameTextures(child)
        end
    end
    for _, name in next, {"MainMenuBarLeftEndCap", "MainMenuBarRightEndCap", "MainMenuBarArtFrame"} do
        local object = _G[name]
        if object then
            if object.SetTexture then
                object:SetTexture("")
            else
                Util.HideFrameTextures(object)
            end
        end
    end

    -- Modern bar border keys, if present
    local MainActionBar = _G.MainActionBar
    if MainActionBar then
        if MainActionBar.EndCaps then MainActionBar.EndCaps:SetAlpha(0) end
        if MainActionBar.BorderArt then MainActionBar.BorderArt:SetAlpha(0) end
        if MainActionBar.Background then MainActionBar.Background:SetAlpha(0) end
    end

    -- XP / reputation tracking bars
    if _G.MainStatusTrackingBarContainer then
        Skin.StatusTrackingBarContainerTemplate(_G.MainStatusTrackingBarContainer)
    end
    if _G.SecondaryStatusTrackingBarContainer then
        Skin.StatusTrackingBarContainerTemplate(_G.SecondaryStatusTrackingBarContainer)
    end

    -- Era survivor (Blizzard_ActionBar\Classic\MainMenuBar.lua): keep the
    -- slimmed tracking-bar heights when the bar is repositioned
    if _G.MainMenuTrackingBar_Configure then
        _G.hooksecurefunc("MainMenuTrackingBar_Configure", function(frame, isOnTop)
            if not frame.StatusBar then return end
            if isOnTop then
                frame.StatusBar:SetHeight(7)
            else
                frame.StatusBar:SetHeight(9)
            end
        end)
    end
end
