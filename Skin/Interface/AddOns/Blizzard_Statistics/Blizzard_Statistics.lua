local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals next

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

-- Forever-only addon (## AllowLoadGameType: camelot): the Statistics tab, mode
-- tab 6 of the character panel. Retail has no counterpart -- achievements
-- absorbed statistics there -- so there is nothing to port.
--
-- Camelot built it by cloning its own Skills tab, which was itself a clone of
-- its Reputation tab, so this is the third appearance of one row idiom:
--
--   header       Button, common-button-list-collapseExpand on BACKGROUND and
--                HIGHLIGHT, plus a StateIcon that is a *Texture* despite the
--                name -- the trap that threw in SkillsFrame
--   entry        Button with Content.BackgroundHighlight.TextureRegions, the
--                charactercreate-customize-dropdown-linemouseover three-slice
--   sub-header   inherits entry, adds a real ToggleCollapseButton
--   rows         pooled, skinned from a Mixin:Initialize hook
--
-- Duplicated rather than shared: about sixty lines, under D3.1's threshold, and
-- extracting it would mean reworking two surfaces that are already verified
-- in-game. If a fourth clone turns up, share it then.

do --[[ AddOns\StatisticsFrame.xml ]]
    function Skin.StatisticsHeaderTemplate(Button)
        -- StateIcon is the collapse/expand glyph and a Texture, so it must not
        -- reach Skin.ExpandOrCollapse. Left alone; the two collapseExpand
        -- textures around it are the chrome.
        for _, region in next, {Button:GetRegions()} do
            if region:IsObjectType("Texture") and region ~= Button.StateIcon then
                local atlas = region:GetAtlas()
                if atlas and atlas:find("common%-button%-list%-collapseExpand") then
                    if region:GetDrawLayer() == "HIGHLIGHT" then
                        Util.SetHighlightColor(region, 0.2)
                    else
                        region:SetAlpha(0)
                    end
                end
            end
        end

        Base.SetBackdrop(Button, Color.button)
    end

    function Skin.StatisticsEntryTemplate(Button)
        local Content = Button.Content
        if not Content then return end

        -- Only sub-headers carry the toggle; plain statistic rows do not. This
        -- one is a genuine Button with Normal/Pushed atlases, unlike StateIcon.
        local toggle = Button.ToggleCollapseButton
        if toggle and not private.IsSkinned(toggle) then
            private.SetSkinned(toggle, true)
            Skin.ExpandOrCollapse(toggle)
            toggle:SetSize(14, 14)
        end

        local BackgroundHighlight = Content.BackgroundHighlight
        if BackgroundHighlight then
            for _, region in next, (BackgroundHighlight.TextureRegions or {}) do
                region:SetAlpha(0)
            end
        end
    end

    Skin.StatisticsSubHeaderTemplate = Skin.StatisticsEntryTemplate
end

function private.AddOns.Blizzard_Statistics()
    local StatisticsFrame = _G.StatisticsFrame
    if not StatisticsFrame then return end

    Skin.WowScrollBoxList(StatisticsFrame.ScrollBox)
    Skin.MinimalScrollBar(StatisticsFrame.ScrollBar)

    -- Two decorative UI-Character-Info-ScrollLine-Long rules, one anchored to
    -- the top of the ScrollBox and one to the bottom, each in its own 1x1 frame.
    if StatisticsFrame.ScrollBox then
        for _, child in next, {StatisticsFrame.ScrollBox:GetChildren()} do
            for _, region in next, {child:GetRegions()} do
                if region:IsObjectType("Texture") then
                    local atlas = region:GetAtlas()
                    if atlas and atlas:find("UI%-Character%-Info%-ScrollLine") then
                        region:Hide()
                    end
                end
            end
        end
    end

    -- Rows are pooled and re-Initialize'd on every refresh, so skin once per
    -- frame and let the guard absorb the rest. StatisticsSubHeaderMixin is a
    -- CreateFromMixins copy of StatisticsEntryMixin with its own Initialize, so
    -- both tables need hooking; its Initialize also calls the entry one
    -- directly, which the guard makes harmless.
    local function HookRowMixin(mixin, skinFunc)
        if not mixin or not mixin.Initialize or not skinFunc then return end

        _G.hooksecurefunc(mixin, "Initialize", function(row)
            if private.IsSkinned(row) then return end
            private.SetSkinned(row, true)
            skinFunc(row)
        end)
    end

    HookRowMixin(_G.StatisticsHeaderMixin, Skin.StatisticsHeaderTemplate)
    HookRowMixin(_G.StatisticsEntryMixin, Skin.StatisticsEntryTemplate)
    HookRowMixin(_G.StatisticsSubHeaderMixin, Skin.StatisticsSubHeaderTemplate)
end
