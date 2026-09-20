local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals next

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

-- Camelot-only surface: the Skills tab (mode tab 3 of the character panel).
-- Retail has no SkillsFrame at all, so there is nothing to port -- but Camelot
-- clearly built it by cloning its own Reputation tab, and the two are
-- structurally the same:
--
--   ReputationFrame            SkillsFrame
--   ---------------            -----------
--   ScrollBox / ScrollBar      ScrollBox / ScrollBar
--   ReputationDetailFrame      SkillDetailFrame   (both CharacterFrameSidePaneTemplate)
--   Reputation{Header,Entry,SubHeader}Template    Skills{...}Template
--   ReputationBarTemplate      SkillsBarTemplate  (both ColoredProgressBarTemplate)
--   Mixin:Initialize per row   same
--
-- So this mirrors Skin\shared\ReputationFrame.lua rather than inventing a
-- second idiom. It is not shared with it because none of these names exist on
-- any other flavor.

local function SkinSkillsBar(bar)
    if not bar then return end

    -- SkillsBarTemplate is declared <StatusBar> but inherits
    -- ColoredProgressBarTemplate, and ColoredProgressBarMixin drives its Fill
    -- texture directly -- it never sets a status bar texture. So the element
    -- type says StatusBar while the behaviour is a progress bar, and
    -- Skin.FrameTypeStatusBar is the wrong treatment: it assigns WHITE8x8 as
    -- the bar texture and then logs "Missing color for status bar asset"
    -- because no colour is registered for it. Route by behaviour.
    if Skin.ColoredProgressBarTemplate then
        Skin.ColoredProgressBarTemplate(bar)
    end
end

do --[[ FrameXML\SkillsFrame.xml ]]
    function Skin.SkillsHeaderTemplate(Button)
        -- The header's own art is two common-button-list-collapseExpand
        -- textures: one on BACKGROUND (the bar) and one on HIGHLIGHT (hover).
        -- Hide the first, recolour the second so hover feedback survives.
        --
        -- StateIcon is deliberately left alone. It is the collapse/expand
        -- glyph and, despite the name, a **Texture** -- passing it to
        -- Skin.ExpandOrCollapse, which expects a Button, is what threw
        -- "attempt to call a nil value" here.
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

    function Skin.SkillsEntryTemplate(Button)
        local Content = Button.Content
        if not Content then return end

        -- Sub-header rows carry the expand/collapse toggle; plain entries do not.
        local toggle = Button.ToggleCollapseButton
        if toggle and not private.IsSkinned(toggle) then
            private.SetSkinned(toggle, true)
            Skin.ExpandOrCollapse(toggle)
            toggle:SetSize(14, 14)
        end

        SkinSkillsBar(Content.SkillsBar)

        -- charactercreate-customize-dropdown-linemouseover-* three-slice, the
        -- same hover art the reputation rows use.
        local BackgroundHighlight = Content.BackgroundHighlight
        if BackgroundHighlight then
            for _, region in next, (BackgroundHighlight.TextureRegions or {}) do
                region:SetAlpha(0)
            end
        end
    end

    -- SkillsSubHeaderTemplate inherits SkillsEntryTemplate, so the layout is
    -- identical -- exactly as ReputationSubHeaderTemplate does.
    Skin.SkillsSubHeaderTemplate = Skin.SkillsEntryTemplate
end

function private.FrameXML.SkillsFrame()
    local SkillsFrame = _G.SkillsFrame
    if not SkillsFrame then return end

    Skin.WowScrollBoxList(SkillsFrame.ScrollBox)
    Skin.MinimalScrollBar(SkillsFrame.ScrollBar)

    -- Decorative UI-Character-Info-ScrollLine-Long rules framing the list.
    if SkillsFrame.ScrollBox then
        for _, child in next, {SkillsFrame.ScrollBox:GetChildren()} do
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

    -- SkillDetailFrame is a CharacterFrameSidePaneTemplate, like the reputation
    -- detail pane: it slides into the right pane rather than floating, so there
    -- is no border or close button to skin.
    local SkillDetailFrame = SkillsFrame.SkillDetailFrame
    if SkillDetailFrame then
        SkinSkillsBar(SkillDetailFrame.RankBar)
    end

    -- Rows are pooled and re-Initialize'd on every refresh, so skin once per
    -- frame and let the guard absorb the rest. Hooking the mixin tables works
    -- because the ScrollBox creates its rows lazily, after this runs.
    local function HookRowMixin(mixin, skinFunc)
        if not mixin or not mixin.Initialize or not skinFunc then return end

        _G.hooksecurefunc(mixin, "Initialize", function(row)
            if private.IsSkinned(row) then return end
            private.SetSkinned(row, true)
            skinFunc(row)
        end)
    end

    HookRowMixin(_G.SkillsHeaderMixin, Skin.SkillsHeaderTemplate)
    HookRowMixin(_G.SkillsEntryMixin, Skin.SkillsEntryTemplate)
    HookRowMixin(_G.SkillsSubHeaderMixin, Skin.SkillsSubHeaderTemplate)
end
