local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Base, Skin = Aurora.Base, Aurora.Skin
local Color = Aurora.Color

-- Track skinned state in a weak table instead of writing _auroraSkinned
-- directly onto item frames. CooldownViewer items participate in secure
-- cooldown/aura update paths — writing addon values onto the frame taints
-- the execution context and causes ADDON_ACTION_BLOCKED cascades.
local skinnedFrames = _G.setmetatable({}, { __mode = "k" })

-- Remove the XML-applied MaskTexture from an icon texture.
-- CDM items use <MaskTexture> (a separate region object) rather than
-- texture:SetMask(), so we must use RemoveMaskTexture to detach it.
-- Iterates in reverse so removal doesn't shift indices.
local function RemoveIconMask(iconTexture)
    if not iconTexture or not iconTexture.GetNumMaskTextures then return end
    for i = iconTexture:GetNumMaskTextures(), 1, -1 do
        local mask = iconTexture:GetMaskTexture(i)
        if mask then
            iconTexture:RemoveMaskTexture(mask)
            mask:Hide()
        end
    end
end

-- Hide the decorative atlas overlay ring present on all CDM icon items.
-- The overlay has no parentKey in the XML so we locate it by atlas name
-- by iterating the frame's own direct regions.
local CDM_OVERLAY_ATLAS = "UI-HUD-CoolDownManager-IconOverlay"
local function HideIconOverlay(frame)
    for _, region in ipairs({frame:GetRegions()}) do
        if region.GetAtlas and region:GetAtlas() == CDM_OVERLAY_ATLAS then
            region:Hide()
        end
    end
end

-- Resolve the actual icon Texture for an item frame, across all 4 templates.
--   Essential / Utility / BuffIcon  — frame.Icon is the icon Texture directly
--   BuffBar                         — frame.Icon is a child Frame; icon is frame.Icon.Icon
local function GetItemIconTexture(frame)
    local iconFrame = frame.Icon
    if not iconFrame then return nil end
    if iconFrame.Icon then
        return iconFrame.Icon
    elseif iconFrame.SetTexCoord then
        return iconFrame
    end
end

-- Skin a single cooldown item frame. One-time setup only (guarded by
-- skinnedFrames) — see ReapplyIconCrops for the ongoing texcoord maintenance
-- that has to run every time CDM refreshes the spell texture.
local function SkinItemFrame(frame)
    if not frame or skinnedFrames[frame] then return end
    if frame.IsForbidden and frame:IsForbidden() then return end

    -- ── Icon (all item types) ──────────────────────────────────────────────
    local iconFrame = frame.Icon  -- the Frame or Texture referenced by parentKey="Icon"
    local iconTex = GetItemIconTexture(frame)

    if iconTex then
        RemoveIconMask(iconTex)
        Base.CropIcon(iconTex)
    end

    -- Hide the decorative overlay ring.
    -- For Essential/Utility/BuffIcon it lives at item-frame level.
    -- For BuffBar it lives inside the Icon child frame.
    HideIconOverlay(frame)
    if iconFrame and iconFrame ~= iconTex then
        -- iconFrame is the Icon child Frame (BuffBar path) — check its regions too
        HideIconOverlay(iconFrame)

        -- Shrink the icon to leave a small margin inside the bar (3 px each side).
        local h = frame:GetHeight()
        if h > 0 then
            iconFrame:ClearAllPoints()
            iconFrame:SetPoint("LEFT", frame, "LEFT", 0, 0)
            iconFrame:SetSize(h - 12, h - 12)
        end
    end

    -- ── Cooldown swipe ─────────────────────────────────────────────────────
    -- The XML uses a circular swipe texture (UI-HUD-CoolDownManager-Icon-Swipe)
    -- that no longer matches the square cropped icon. Replace with a plain
    -- square swipe so the cooldown overlay covers the full icon area.
    if frame.Cooldown then
        frame.Cooldown:SetSwipeTexture(private.textures.plain)
    end

    -- ── BuffBar status bar ─────────────────────────────────────────────────
    -- The BuffBar item has a StatusBar (frame.Bar) with an atlas-based fill
    -- (orange, UI-HUD-CoolDownManager-Bar), an atlas background (BarBG),
    -- and a decorative pip (Pip). Replace with Aurora flat styling.
    --
    -- We avoid installing hooksecurefunc on bar instances (Skin.FrameTypeStatusBar
    -- would do this) because CDM refreshes bar state from secure cooldown/aura
    -- update paths. A one-time direct replacement at skin time is sufficient
    -- since CDM only calls SetValue to update the fill amount, not the texture.
    if frame.Bar then
        local bar = frame.Bar

        -- Add Aurora backdrop behind the fill.
        Base.SetBackdrop(bar, Color.button, Color.frame.a)

        -- Replace the atlas bar fill with Aurora's plain texture, tinted highlight.
        local barTex = bar:GetStatusBarTexture()
        if barTex then
            barTex:SetTexture(private.textures.plain)
            barTex:SetVertexColor(Color.highlight:GetRGB())
        end

        -- Suppress the atlas background (sits behind the fill at BACKGROUND layer).
        if bar.BarBG then
            bar.BarBG:SetTexture(nil)
            bar.BarBG:Hide()
        end

        -- Hide the decorative position pip at the right edge of the bar.
        if bar.Pip then
            bar.Pip:SetTexture(nil)
            bar.Pip:Hide()
        end
    end

    skinnedFrames[frame] = true
end

-- Blizzard's default grid gap (RefreshLayout: childXPadding/Y = iconPadding - 4)
-- nets out to ~1px even at 100% Icon Size, relying on the IconOverlay
-- decorative ring (which we hide, see HideIconOverlay) to fake breathing room
-- between icons. On top of that, each item frame is scaled by viewer.iconScale
-- (the Edit Mode "Icon Size" % setting) via itemFrame:SetScale, so above 100%
-- the gap goes negative and bare square icons bleed into their neighbor.
-- Restore a minimum gap always, plus extra proportional to how much the
-- scale grows the frame beyond 100%.
local MIN_ICON_GAP = 3

-- Nominal (unscaled) icon size per item template, taken from CooldownViewer.xml.
-- BuffBar's item frame itself is a 220x30 bar, but the icon portion (frame.Icon,
-- a 30x30 child, or h-12 after Aurora resizes it) is what actually overlaps —
-- use its size, not the full bar width.
--
-- These are hardcoded rather than read via itemFrame/icon:GetWidth()/GetHeight()
-- because for aura-backed items (BuffIcon/BuffBar, tied to auraSpellID/
-- auraInstanceID) Blizzard's newer "secret value" protections can make those
-- live geometry queries return secret-poisoned numbers — merely comparing one
-- (e.g. `w > 0`) from addon code throws "execution tainted by 'RealUI_Skins'".
-- Static constants sidestep that entirely.
local NOMINAL_ICON_SIZE = {
    CooldownViewerEssentialItemTemplate = 50,
    CooldownViewerUtilityItemTemplate   = 30,
    CooldownViewerBuffIconItemTemplate  = 40,
    CooldownViewerBuffBarItemTemplate   = 30,
}

local function CompensateGridPaddingForScale(viewer)
    local scale = viewer.iconScale or 1

    local container = viewer.GetItemContainerFrame and viewer:GetItemContainerFrame()
    if not container then return end

    local size = NOMINAL_ICON_SIZE[viewer.itemTemplate]
    if not size then return end

    local scaleGap = (scale > 1) and (scale - 1) * size or 0
    local gap = MIN_ICON_GAP + scaleGap
    container.childXPadding = (container.childXPadding or 0) + gap
    container.childYPadding = (container.childYPadding or 0) + gap

    -- RefreshLayout already called container:Layout() with the old padding
    -- before this post-hook ran; force a fresh pass so our values take effect now.
    if container.Layout then
        container:Layout()
    end
end

-- Skin all current children of a viewer frame.
-- Called at skin-function time (catches pre-existing items) and from OnShow
-- hooks (catches items materialised after the first display).
local function SkinViewerChildren(viewer)
    if not viewer then return end
    for _, child in next, {viewer:GetChildren()} do
        SkinItemFrame(child)
    end
end

-- SetTexture() resets a texture's texcoords to 0,0,1,1, so CDM's own icon
-- refresh (whenever the tracked spell/aura changes) undoes our crop and it
-- needs re-applying. We do NOT hook CDM's RefreshSpellTexture/OnLoad mixin
-- methods for this (previously via Util.Mixin -> hooksecurefunc on the
-- shared item mixins): that runs our code *synchronously inside* Blizzard's
-- own OnLoad/RefreshData dispatch, and WoW's "secret value" protections
-- (cooldown charges, totem state, aura fields) mark the touched item frame
-- as tainted from then on — any later Blizzard-internal secret comparison on
-- that same frame object can fail, even from a completely unrelated event
-- far downstream. This project's own CHANGELOG has hit the identical lesson
-- repeatedly elsewhere (nameplate widgets, MapCanvas, GameTooltip widgets:
-- "writing an addon-owned slot on the mixin taints the execution context").
-- Instead, re-apply the crop unconditionally from an independent ticker,
-- fully decoupled from any Blizzard call chain.
local function ReapplyIconCrops(viewer)
    if not viewer then return end
    for _, child in next, {viewer:GetChildren()} do
        local iconTex = GetItemIconTexture(child)
        if iconTex and iconTex.SetTexCoord then
            pcall(iconTex.SetTexCoord, iconTex, .08, .92, .08, .92)
        end
    end
end

function private.AddOns.Blizzard_CooldownViewer()
    -- Item pools are lazy, so GetChildren() usually returns nothing at load
    -- time; the initial scan plus OnShow hook catch most cases, and the
    -- ticker below catches new items materialising while the viewer stays
    -- shown (OnShow doesn't re-fire for that) and re-crops texture resets.
    local viewers = {
        _G.EssentialCooldownViewer,
        _G.UtilityCooldownViewer,
        _G.BuffIconCooldownViewer,
        _G.BuffBarCooldownViewer,
    }
    for _, viewer in ipairs(viewers) do
        if viewer then
            SkinViewerChildren(viewer)
            viewer:HookScript("OnShow", function(self)
                SkinViewerChildren(self)
            end)
            _G.hooksecurefunc(viewer, "RefreshLayout", CompensateGridPaddingForScale)
        end
    end

    _G.C_Timer.NewTicker(0.2, function()
        for _, viewer in ipairs(viewers) do
            if viewer then
                SkinViewerChildren(viewer)
                ReapplyIconCrops(viewer)
            end
        end
    end)

    ------------------------------------------------
    -- Skin the CooldownViewerSettings dialog
    -- Inherits ButtonFrameTemplate — use the full template skin so the
    -- NineSlice, TopTileStreaks, Bg, and Inset are all properly handled.
    ------------------------------------------------
    local settings = _G.CooldownViewerSettings
    if settings then
        Skin.ButtonFrameTemplate(settings)
        if settings.UndoButton then
            Skin.FrameTypeButton(settings.UndoButton)
        end
    end

    ------------------------------------------------
    -- Skin the layout / import dialogs
    ------------------------------------------------
    local layoutDialog = _G.CooldownViewerLayoutDialog
    if layoutDialog then
        Base.SetBackdrop(layoutDialog, Color.frame)
        if layoutDialog.AcceptButton then Skin.FrameTypeButton(layoutDialog.AcceptButton) end
        if layoutDialog.CancelButton then Skin.FrameTypeButton(layoutDialog.CancelButton) end
        local layoutCB = layoutDialog.CharacterSpecificLayoutCheckButton
        if layoutCB and layoutCB.Button then Skin.FrameTypeCheckButton(layoutCB.Button) end
    end

    local importDialog = _G.CooldownViewerImportLayoutDialog
    if importDialog then
        Base.SetBackdrop(importDialog, Color.frame)
        if importDialog.AcceptButton then Skin.FrameTypeButton(importDialog.AcceptButton) end
        if importDialog.CancelButton then Skin.FrameTypeButton(importDialog.CancelButton) end
        local importCB = importDialog.CharacterSpecificLayoutCheckButton
        if importCB and importCB.Button then Skin.FrameTypeCheckButton(importCB.Button) end
    end
end
