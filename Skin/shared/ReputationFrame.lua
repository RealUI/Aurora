local _, private = ...

-- Shared body for the ReputationFrame skin (D3.1).
--
-- Camelot replaces Blizzard's ReputationFrame.xml, so only one of
-- Blizzard_UIPanels_Game\{Mainline,Camelot}\ReputationFrame.lua is ever in a
-- manifest and the Camelot one cannot delegate to the Mainline one. The row
-- templates and the row-mixin hooks are identical between them, so they live
-- here; each flavor file keeps only its own entry function, which is where the
-- two actually differ (the ScrollBox anchor and the detail pane).
--
-- NOTE: no private.shouldSkip() guard. This file is listed in Skin\skin.xml,
-- which the TOC loads *before* the generated manifest sets
-- _G.AURORA_DEBUG_PROJECT -- so shouldSkip() would be true here on every
-- flavor and the file would bail. None of the other skin.xml files guard
-- either, for the same reason.

--[[ Lua Globals ]]
-- luacheck: globals next type

--[[ Core ]]
local Aurora = private.Aurora
local Base, Hook, Skin = Aurora.Base, Aurora.Hook, Aurora.Skin
local Color = Aurora.Color

do --[[ FrameXML\ReputationFrame.lua ]]
    function Hook.ReputationFrame_OnShow(self)
        -- The TOPRIGHT anchor for ReputationBar1 is set in C code
        _G.ReputationBar1:SetPoint("TOPRIGHT", -34, -(private.FRAME_TITLE_HEIGHT + 22))
    end
    function Hook.ReputationFrame_SetRowType(factionRow, isChild, isHeader, hasRep)
        if isHeader then
            factionRow:SetBackdrop(false)
        else
            factionRow:SetBackdrop(true)
        end
    end
    function Hook.ReputationFrame_InitReputationRow(factionRow, elementData)
        local _, _, _, _, _, _, atWarWith = _G.GetFactionInfo(elementData.index)

        local bd = factionRow._bdFrame or factionRow
        if atWarWith then
            Base.SetBackdropColor(bd, Color.red)
        else
            Base.SetBackdropColor(bd, Color.button)
        end

        if elementData.index == _G.GetSelectedFaction() then
            if _G.ReputationDetailFrame:IsShown() then
                bd:SetBackdropBorderColor(Color.highlight)
            end
        end
    end

    -- At-war factions used to get a red row backdrop, via the pre-ScrollBox
    -- Hook.ReputationFrame_InitReputationRow. Rows are flat now with no
    -- backdrop to colour, and Blizzard gives no list-side indication at all,
    -- so tint the faction name instead. elementData.atWarWith is what the
    -- detail pane's AtWarCheckbox reads.
    function Hook.UpdateReputationEntryState(row)
        local Content = row.Content
        local Name = Content and Content.Name
        if not Name then return end

        local elementData = row.elementData
        if elementData and elementData.atWarWith then
            Name:SetTextColor(Color.red:GetRGB())
        else
            -- Restore whatever the template's font object specifies rather
            -- than hardcoding a colour; headers and entries differ.
            local fontObject = Name:GetFontObject()
            if fontObject then
                Name:SetTextColor(fontObject:GetTextColor())
            end
        end
    end

    local hasShown = false
    function Hook.ReputationFrame_Update(self)
        if not hasShown then
            hasShown = true
            _G.ReputationFrame:Hide()
            _G.ReputationFrame:Show()
            return
        end

        for i = 1, _G.NUM_FACTIONS_DISPLAYED do
            local factionRow = _G["ReputationBar"..i]
            if factionRow.index then
                local _, _, _, _, _, _, atWarWith = _G.GetFactionInfo(factionRow.index)

                local bd = factionRow._bdFrame or factionRow
                if atWarWith then
                    Base.SetBackdropColor(bd, Color.red)
                else
                    Base.SetBackdropColor(bd, Color.button)
                end

                if factionRow.index == _G.C_Reputation.GetSelectedFaction() then
                    if _G.ReputationDetailFrame:IsShown() then
                        bd:SetBackdropBorderColor(Color.highlight)
                    end
                end
            end
        end

        Hook.ReputationFrame_OnShow(self)
    end
end

do --[[ FrameXML\ReputationFrame.xml ]]
    local function OnEnter(button)
        (button._bdFrame or button):SetBackdropBorderColor(Color.highlight)
    end
    local function OnLeave(button)
        if (_G.C_Reputation.GetSelectedFaction() ~= button.index) or (not _G.ReputationDetailFrame:IsShown()) then
            local _, _, _, _, _, _, atWarWith = _G.C_Reputation.GetFactionInfo(button.index)
            if atWarWith then
                (button._bdFrame or button):SetBackdropBorderColor(Color.red)
            else
                (button._bdFrame or button):SetBackdropBorderColor(Color.button)
            end
        end
    end

    -- 12.x row templates. The frame moved to a ScrollBox whose rows come from
    -- ReputationHeaderTemplate / ReputationEntryTemplate / ReputationSubHeader-
    -- Template, so the legacy ReputationBar1..N buttons below no longer exist.
    function Skin.ReputationHeaderTemplate(Button)
        -- Options_ListExpand_* trio, same as the Housing list headers. Guarded
        -- because the shared helper lives in another module's file.
        if Skin.ListHeaderThreeSliceTemplate then
            Skin.ListHeaderThreeSliceTemplate(Button)
        end

        for _, region in _G.next, (Button.HighlightTextureRegions or {}) do
            region:SetAlpha(0)
        end

        Base.SetBackdrop(Button, Color.button)
    end

    function Skin.ReputationEntryTemplate(Button)
        local Content = Button.Content
        if not Content then return end

        -- Sub-header rows (e.g. Silvermoon Court under The Singularity) carry
        -- the expand/collapse "+" as ToggleCollapseButton, a direct child of
        -- the row — NOT of Content, and not the pre-ScrollBox
        -- ExpandOrCollapseButton key, which no longer exists in 12.x. Absent on
        -- plain entry rows, hence the guard.
        local toggle = Button.ToggleCollapseButton
        if toggle and not private.IsSkinned(toggle) then
            private.SetSkinned(toggle, true)
            Skin.ExpandOrCollapse(toggle)
            -- Blizzard's 20x20 is sized for its atlas artwork and reads oversized
            -- next to the row's other elements once flattened to a plain square.
            toggle:SetSize(14, 14)
        end

        local ReputationBar = Content.ReputationBar
        if ReputationBar then
            Skin.FrameTypeStatusBar(ReputationBar)

            -- ReputationBarTemplate is a StatusBar now, but it still carries
            -- the UI-Character-ReputationBar end caps and a Background fill.
            -- Without hiding these the bar keeps Blizzard's rounded ends and
            -- gradient — the same regions the pre-ScrollBox skin dealt with.
            -- Camelot's ReputationBarTemplate inherits ColoredProgressBarTemplate
            -- and carries none of them, which the guards already absorb.
            if ReputationBar.LeftTexture then ReputationBar.LeftTexture:Hide() end
            if ReputationBar.RightTexture then ReputationBar.RightTexture:Hide() end
            if ReputationBar.Background then ReputationBar.Background:SetAlpha(0) end

            -- Present on the old template; keep the guards in case they return.
            if ReputationBar.Highlight1 then ReputationBar.Highlight1:SetAlpha(0) end
            if ReputationBar.Highlight2 then ReputationBar.Highlight2:SetAlpha(0) end
            if ReputationBar.AtWarHighlight1 then ReputationBar.AtWarHighlight1:SetAlpha(0) end
            if ReputationBar.AtWarHighlight2 then ReputationBar.AtWarHighlight2:SetAlpha(0) end
        end

        -- charactercreate-customize-dropdown-linemouseover-* three-slice
        local BackgroundHighlight = Content.BackgroundHighlight
        if BackgroundHighlight then
            for _, region in _G.next, (BackgroundHighlight.TextureRegions or {}) do
                region:SetAlpha(0)
            end
        end
    end

    -- ReputationSubHeaderTemplate inherits ReputationEntryTemplate, so its
    -- Content/ReputationBar layout is identical.
    Skin.ReputationSubHeaderTemplate = Skin.ReputationEntryTemplate

    function Skin.ReputationBarTemplate(Button)
        Skin.FrameTypeButton(Button, OnEnter, OnLeave)
        Button:SetBackdropOption("offsets", {
            left = 30,
            right = 10,
            top = 0,
            bottom = 0,
        })

        local Container = Button.Container
        Container.Background:SetAlpha(0)

        -- Legacy key, absent in 12.x (see ToggleCollapseButton in
        -- ReputationEntryTemplate). Guarded so this dead pre-ScrollBox path
        -- cannot nil-error if it is ever reached again.
        if Container.ExpandOrCollapseButton then
            Skin.ExpandOrCollapse(Container.ExpandOrCollapseButton)
        end

        local ReputationBar = Container.ReputationBar
        Skin.FrameTypeStatusBar(ReputationBar)
        ReputationBar:ClearAllPoints()
        ReputationBar:SetPoint("TOPRIGHT", -3, -2)
        ReputationBar:SetPoint("BOTTOMLEFT", Button, "BOTTOMRIGHT", -102, 2)

        ReputationBar.AtWarHighlight2:SetAlpha(0)
        ReputationBar.AtWarHighlight1:SetAlpha(0)

        ReputationBar.LeftTexture:Hide()
        ReputationBar.RightTexture:Hide()

        ReputationBar.Highlight2:SetAlpha(0)
        ReputationBar.Highlight1:SetAlpha(0)
    end
end

-- The row plumbing, identical on both flavors: the dead pre-ScrollBox hooks,
-- and the 12.x mixin hooks that skin pooled rows as the ScrollBox creates them.
function private.SharedSkins.ReputationRows()
    -- Legacy pre-ScrollBox path. The four ReputationFrame_* globals hooked
    -- here are gone in 12.x, and NUM_FACTIONS_DISPLAYED with them, so the
    -- guarded hooks and the ReputationBar1..N loop below were both silent
    -- no-ops — which is why rows rendered completely unskinned.
    if _G.ReputationFrame_OnShow then
        _G.hooksecurefunc("ReputationFrame_OnShow", Hook.ReputationFrame_OnShow)
    end
    if _G.ReputationFrame_SetRowType then
        _G.hooksecurefunc("ReputationFrame_SetRowType", Hook.ReputationFrame_SetRowType)
    end
    if _G.ReputationFrame_InitReputationRow then
        _G.hooksecurefunc("ReputationFrame_InitReputationRow", Hook.ReputationFrame_InitReputationRow)
    end
    if _G.ReputationFrame_Update then
        _G.hooksecurefunc("ReputationFrame_Update", Hook.ReputationFrame_Update)
    end

    local maxRows = _G.NUM_FACTIONS_DISPLAYED or 0
    for i = 1, maxRows do
        local factionRow = _G["ReputationBar"..i]
        if factionRow and not private.IsSkinned(factionRow) then
            Skin.ReputationBarTemplate(factionRow)
            private.SetSkinned(factionRow, true)
        end
    end

    -- 12.x path: rows are pooled by the ScrollBox and re-Initialize'd on every
    -- data refresh, so skin once per frame and let the guard absorb the rest.
    -- Hooking the mixin tables works because the ScrollBox creates its rows
    -- lazily, after this runs.
    local function HookRowMixin(mixin, skinFunc, stateFunc)
        if not mixin or not mixin.Initialize or not skinFunc then return end

        _G.hooksecurefunc(mixin, "Initialize", function(row)
            if not private.IsSkinned(row) then
                private.SetSkinned(row, true)
                skinFunc(row)
            end

            -- Structure is skinned once, but per-faction state has to be
            -- re-applied on every Initialize: the ScrollBox reuses rows, so a
            -- given frame shows a different faction after each data refresh.
            if stateFunc then
                stateFunc(row)
            end
        end)
    end

    -- Collapse-state glyph. Skin.ExpandOrCollapse toggles its plus overlay from
    -- hooks on Button:SetNormalTexture/SetNormalAtlas, but this button's
    -- RefreshIcon calls self:GetNormalTexture():SetAtlas(...) — setting the
    -- atlas on the texture object, which those hooks never see. Without this
    -- the button stayed a "+" even while expanded.
    if _G.ReputationSubHeaderToggleCollapseButtonMixin then
        _G.hooksecurefunc(_G.ReputationSubHeaderToggleCollapseButtonMixin, "RefreshIcon", function(self)
            local normal = self:GetNormalTexture()
            if normal then normal:SetAlpha(0) end

            local pushed = self:GetPushedTexture()
            if pushed then pushed:SetAlpha(0) end

            if self._plus then
                local header = self.GetHeader and self:GetHeader()
                self._plus:SetShown(not header or header:IsCollapsed())
            end
        end)
    end

    HookRowMixin(_G.ReputationHeaderMixin, Skin.ReputationHeaderTemplate)
    HookRowMixin(_G.ReputationEntryMixin, Skin.ReputationEntryTemplate, Hook.UpdateReputationEntryState)
    HookRowMixin(_G.ReputationSubHeaderMixin, Skin.ReputationSubHeaderTemplate, Hook.UpdateReputationEntryState)
end
