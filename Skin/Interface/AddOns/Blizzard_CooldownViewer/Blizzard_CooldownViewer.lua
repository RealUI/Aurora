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

-- NOTE (grid gap): Blizzard's default grid gap (RefreshLayout:
-- childXPadding/Y = iconPadding - 4) nets out to ~1px at the RealUI preset
-- padding values, relying on the IconOverlay decorative ring (which we hide,
-- see HideIconOverlay) for breathing room. Aurora used to compensate by
-- writing container.childXPadding/childYPadding from a RefreshLayout
-- post-hook and re-running container:Layout() — DO NOT reintroduce that.
-- GridLayoutFrameMixin reads childXPadding and oldGridSettings in its secure
-- dirty-check/layout paths (Blizzard_SharedXML/LayoutFrame.lua), so
-- addon-written values there taint the whole CooldownViewer execution and
-- every secret-value comparison downstream errors out ("execution tainted
-- by 'RealUI_Skins'", mass errors at raid-end cinematics). The gap is now
-- provided securely via the EditMode "Icon Padding" setting in RealUI's
-- EditModeTemplates.lua presets instead.

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
