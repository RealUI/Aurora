local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals next

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color = Aurora.Color

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

    -- SkillsBarTemplate is a StatusBar that inherits ColoredProgressBarTemplate,
    -- so it takes the normal status bar path but still carries that template's
    -- own common-stat-bar-BG chrome underneath. Matched by atlas so Aurora's
    -- freshly created backdrop textures are never caught by the sweep.
    Skin.FrameTypeStatusBar(bar)

    for _, region in next, {bar:GetRegions()} do
        if region:IsObjectType("Texture") then
            local atlas = region:GetAtlas()
            if atlas and atlas:find("common%-stat%-bar%-BG") then
                region:Hide()
            end
        end
    end
end

do --[[ FrameXML\SkillsFrame.xml ]]
    function Skin.SkillsHeaderTemplate(Button)
        -- StateIcon is the common-button-list-collapseExpand glyph; Aurora has
        -- a skin for that shape already.
        if Button.StateIcon and Skin.ExpandOrCollapse then
            if not private.IsSkinned(Button.StateIcon) then
                private.SetSkinned(Button.StateIcon, true)
                Skin.ExpandOrCollapse(Button.StateIcon)
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
