local _, private = ...
if private.shouldSkip() then
    return
end

--[[ Lua Globals ]]
-- luacheck: globals ipairs select

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

--[[ Mists (5.5.4) achievement UI — the Cata-generation frame (metal
    shield design, 2920-line diff vs retail: FORK). Translated from the
    ORIGINAL MoP-era Aurora skin (repo history,
    AddOns/Blizzard_AchievementUI.lua) with modern API + guards; magic
    region indexes replaced with texture sweeps. Evidence:
    wow-ui-source-classic/Interface/AddOns/Blizzard_AchievementUI/Cata/.
]]
local function SkinScrollBar(bar)
    if not bar then
        return
    end
    if bar.Track and Skin.WowTrimScrollBar then
        Skin.WowTrimScrollBar(bar)
    else
        Skin.UIPanelScrollBarTemplate(bar)
    end
end

-- shared row treatment for achievement plates (list, summary, comparison)
local function SkinAchievementPlate(button, name)
    if private.IsSkinned(button) then
        return
    end
    private.SetSkinned(button, true)

    button:DisableDrawLayer("BORDER")
    if button.background then
        button.background:SetColorTexture(0, 0, 0, 0.25)
    end
    for _, suffix in ipairs(
        {
            "TitleBackground",
            "Glow",
            "RewardBackground",
            "PlusMinus",
            "Highlight",
            "IconOverlay",
            "GuildCornerL",
            "GuildCornerR"
        }
    ) do
        local texture = _G[name .. suffix]
        if texture then
            texture:SetAlpha(0)
        end
    end
    if button.description then
        button.description:SetTextColor(Color.grayLight:GetRGB())
        button.description:SetShadowOffset(1, -1)
    end
    local icon = button.icon and (button.icon.texture or button.icon)
    if icon and icon.SetTexCoord then
        Base.CropIcon(icon)
    end
    local iconTexture = _G[name .. "IconTexture"]
    if iconTexture then
        Base.CropIcon(iconTexture)
    end

    -- tracked checkbox
    if button.tracked then
        Skin.UICheckButtonTemplate(button.tracked)
    end
end

do
    --[[ AddOns\Blizzard_AchievementUI.lua ]]
    function Hook.AchievementButton_DisplayAchievement(button, category, achievement)
        local _, _, _, completed = _G.GetAchievementInfo(category, achievement)
        if not button.label then
            return
        end
        if completed then
            if button.accountWide then
                button.label:SetTextColor(0, 0.6, 1)
            else
                button.label:SetTextColor(Color.grayLight:GetRGB())
            end
        else
            if button.accountWide then
                button.label:SetTextColor(0, 0.3, 0.5)
            else
                button.label:SetTextColor(Color.gray:GetRGB())
            end
        end
        if button.description then
            button.description:SetTextColor(Color.grayLight:GetRGB())
        end
    end
    function Hook.AchievementObjectives_DisplayCriteria(objectivesFrame, id)
        if not id then
            return
        end
        for i = 1, _G.GetAchievementNumCriteria(id) do
            local name = _G["AchievementFrameCriteria" .. i .. "Name"]
            if name and _G.select(2, name:GetTextColor()) == 0 then
                name:SetTextColor(Color.white:GetRGB())
            end
            local meta = _G["AchievementFrameMeta" .. i]
            if meta and meta.label and _G.select(2, meta.label:GetTextColor()) == 0 then
                meta.label:SetTextColor(Color.white:GetRGB())
            end
        end
    end
    function Hook.AchievementButton_GetProgressBar(index)
        local bar = _G["AchievementFrameProgressBar" .. index]
        if bar and not private.IsSkinned(bar) then
            private.SetSkinned(bar, true)
            Skin.FrameTypeStatusBar(bar)
            local name = "AchievementFrameProgressBar" .. index
            if _G[name .. "BG"] then
                _G[name .. "BG"]:SetColorTexture(0, 0, 0, 0.25)
            end
            for _, suffix in ipairs({"BorderLeft", "BorderCenter", "BorderRight"}) do
                if _G[name .. suffix] then
                    _G[name .. suffix]:Hide()
                end
            end
        end
    end
    function Hook.AchievementFrameSummary_UpdateAchievements()
        local index = 1
        local button = _G["AchievementFrameSummaryAchievement" .. index]
        while button do
            SkinAchievementPlate(button, "AchievementFrameSummaryAchievement" .. index)
            if button.label then
                if button.accountWide then
                    button.label:SetTextColor(0, 0.6, 1)
                else
                    button.label:SetTextColor(Color.grayLight:GetRGB())
                end
            end
            local description = _G["AchievementFrameSummaryAchievement" .. index .. "Description"]
            if description then
                description:SetTextColor(Color.grayLight:GetRGB())
            end
            index = index + 1
            button = _G["AchievementFrameSummaryAchievement" .. index]
        end
    end
end

-- gaudy gold status bars (summary categories, comparison summaries)
local function SkinAchievementStatusBar(bar)
    if not bar or private.IsSkinned(bar) then
        return
    end
    private.SetSkinned(bar, true)

    local name = bar:GetName()
    Skin.FrameTypeStatusBar(bar)
    if name then
        for _, suffix in ipairs(
            {"Left", "Middle", "Right", "FillBar", "ButtonHighlight", "BorderLeft", "BorderCenter", "BorderRight"}
        ) do
            if _G[name .. suffix] then
                _G[name .. suffix]:SetAlpha(0)
            end
        end
        if _G[name .. "Title"] then
            _G[name .. "Title"]:SetTextColor(Color.white:GetRGB())
        end
    end
    if bar.text then
        bar.text:SetTextColor(Color.white:GetRGB())
    end
end

function private.AddOns.Blizzard_AchievementUI()
    local AchievementFrame = _G.AchievementFrame
    if not AchievementFrame then
        return
    end

    -- root: metal shield chrome; extend the backdrop ABOVE the frame
    -- rect to make a header band for the title + points
    Util.HideFrameTextures(AchievementFrame, true)
    Base.SetBackdrop(AchievementFrame, Color.frame, Color.frame.a)
    AchievementFrame:SetBackdropOption(
        "offsets",
        {
            left = 0,
            right = 0,
            top = -22,
            bottom = 0
        }
    )
    if _G.AchievementFrameHeader then
        Util.HideFrameTextures(_G.AchievementFrameHeader, true)
    end
    for _, name in ipairs(
        {
            "AchievementFrameHeaderLeftDDLInset",
            "AchievementFrameHeaderRightDDLInset",
            "AchievementFrameSummaryBackground",
            "AchievementFrameAchievementsBackground",
            "AchievementFrameStatsBG",
            "AchievementFrameComparisonBackground",
            "AchievementFrameComparisonHeaderBG",
            "AchievementFrameComparisonHeaderPortrait",
            "AchievementFrameComparisonHeaderPortraitBg",
            "AchievementFrameComparisonDark",
            "AchievementFrameComparisonSummaryPlayerBackground",
            "AchievementFrameComparisonSummaryFriendBackground",
            "AchievementFrameSummaryAchievementsHeaderHeader",
            "AchievementFrameSummaryCategoriesHeaderTexture",
            "AchievementFrameCategoriesContainerScrollBarBG"
        }
    ) do
        if _G[name] then
            _G[name]:SetAlpha(0)
        end
    end
    for _, name in ipairs(
        {
            "AchievementFrameCategories",
            "AchievementFrameSummary",
            "AchievementFrameAchievements",
            "AchievementFrameStats",
            "AchievementFrameComparison"
        }
    ) do
        local frame = _G[name]
        if frame then
            Util.HideFrameTextures(frame, true)
            if frame.SetBackdrop then
                frame:SetBackdrop(nil)
            end
        end
    end

    -- the header (title + points) floats ABOVE the frame body once the
    -- shield chrome is gone — tuck both inside, stacked
    if _G.AchievementFrameHeaderTitle then
        _G.AchievementFrameHeaderTitle:ClearAllPoints()
        _G.AchievementFrameHeaderTitle:SetPoint("TOP", AchievementFrame, "TOP", 0, 18)
    end
    if _G.AchievementFrameHeaderPoints then
        _G.AchievementFrameHeaderPoints:ClearAllPoints()
        if _G.AchievementFrameHeaderTitle then
            _G.AchievementFrameHeaderPoints:SetPoint("TOP", _G.AchievementFrameHeaderTitle, "BOTTOM", 0, -2)
        else
            _G.AchievementFrameHeaderPoints:SetPoint("TOP", AchievementFrame, "TOP", 0, 16)
        end
    end

    if _G.AchievementFrameCloseButton then
        Skin.UIPanelCloseButton(_G.AchievementFrameCloseButton)
    end
    AchievementFrame.maxTabWidth = 150
    local tabs = {}
    for i = 1, 3 do
        local tab = _G["AchievementFrameTab" .. i]
        if tab then
            -- these tabs carry extra angled/selected art beyond the six
            -- standard pieces — sweep first, then the tab skin adds its
            -- backdrop
            for j = 1, _G.select("#", tab:GetRegions()) do
                local region = _G.select(j, tab:GetRegions())
                if region:GetObjectType() == "Texture" then
                    region:SetAlpha(0)
                end
            end
            Skin.CharacterFrameTabButtonTemplate(tab)
            -- these tabs aren't PanelTemplates-resized: drop the
            -- side-width machinery and make the plate fill the button,
            -- whose width we set from the text
            tab._auroraSideWidth = nil
            tab._auroraTabResize = nil
            tab:SetBackdropOption(
                "offsets",
                {
                    left = 0,
                    right = 0,
                    top = 4,
                    bottom = 6
                }
            )
            tabs[#tabs + 1] = tab
        end
    end
    -- stock anchors leave them floating below the frame with a gap, and
    -- AchievementFrame_UpdateTabs re-anchors tab text (CENTER 0,-5/-3)
    -- and tab 3 on EVERY tab click — re-apply both after it
    local function AnchorTabs()
        -- tab 2 is the GUILD tab — hidden when guildless but still in
        -- the chain; anchor only what's shown or the invisible slot
        -- reads as a gap
        local previous
        for i = 1, #tabs do
            local tab = tabs[i]
            local text =
                tab.text or _G["AchievementFrameTab" .. i .. "Text"] or (tab.GetFontString and tab:GetFontString())
            if text then
                text:ClearAllPoints()
                text:SetPoint("CENTER", tab, 0, -1)
                -- the stock buttons are shield-art wide — size to text
                -- (plate now fills the button)
                tab:SetWidth(text:GetStringWidth() + 28)
            end
            -- the plate was anchored to the TEXT (±17 side width) when the
            -- skin first ran — pin it to the button rect explicitly
            local bg = tab.GetBackdropTexture and tab:GetBackdropTexture("bg")
            if bg then
                bg:ClearAllPoints()
                bg:SetPoint("TOPLEFT", tab, 0, -4)
                bg:SetPoint("BOTTOMRIGHT", tab, 0, 6)
            end
            if tab:IsShown() then
                tab:ClearAllPoints()
                if not previous then
                    tab:SetPoint("TOPLEFT", AchievementFrame, "BOTTOMLEFT", 20, -1)
                else
                    tab:SetPoint("LEFT", previous, "RIGHT", 2, 0)
                end
                previous = tab
            end
        end
    end
    local function FixTabs()
        AnchorTabs()
        -- something re-anchors on a later frame — reassert once more
        _G.C_Timer.After(0, AnchorTabs)
    end
    FixTabs()
    if _G.AchievementFrame_UpdateTabs then
        _G.hooksecurefunc("AchievementFrame_UpdateTabs", FixTabs)
    end
    AchievementFrame:HookScript("OnShow", FixTabs)

    -- filter dropdown: the VISIBLE control on live is the modern filter
    -- button — check it first (the legacy global may coexist, unused)
    if AchievementFrame.FilterDropdown and Skin.FilterButton then
        Skin.FilterButton(AchievementFrame.FilterDropdown)
    elseif _G.AchievementFrameFilterDropDown then
        Skin.UIDropDownMenuTemplate(_G.AchievementFrameFilterDropDown)
    end
    if AchievementFrame.searchBox then
        Util.HideFrameTextures(AchievementFrame.searchBox)
        Skin.FrameTypeEditBox(AchievementFrame.searchBox)
    end
    if AchievementFrame.searchPreviewContainer then
        AchievementFrame.searchPreviewContainer:DisableDrawLayer("OVERLAY")
    end
    for i = 1, 5 do
        local preview = AchievementFrame["searchPreview" .. i]
        if preview then
            preview:ClearNormalTexture()
            preview:ClearPushedTexture()
            if preview.iconFrame then
                preview.iconFrame:SetAlpha(0)
            end
            if preview.icon then
                Base.CropIcon(preview.icon)
            end
        end
    end
    if AchievementFrame.showAllSearchResults then
        AchievementFrame.showAllSearchResults:ClearNormalTexture()
        AchievementFrame.showAllSearchResults:ClearPushedTexture()
    end

    -- category rows (created before first update on this client;
    -- hook as backstop)
    local function SkinCategoryRows()
        local index = 1
        local row = _G["AchievementFrameCategoriesContainerButton" .. index]
        while row do
            if not private.IsSkinned(row) then
                private.SetSkinned(row, true)
                if row.background then
                    row.background:Hide()
                end
                Base.SetBackdrop(row, Color.button, 0.25)
                -- rows are taller than their visible plate — inset the
                -- backdrop and pin the hover/selected tint to it
                row:SetBackdropOption(
                    "offsets",
                    {
                        left = 0,
                        right = 0,
                        top = 1,
                        bottom = 2
                    }
                )
                local bg = row:GetBackdropTexture("bg")
                local highlight = row:GetHighlightTexture()
                if highlight then
                    highlight:SetColorTexture(Color.highlight.r, Color.highlight.g, Color.highlight.b, 0.2)
                    if bg then
                        highlight:ClearAllPoints()
                        highlight:SetPoint("TOPLEFT", bg, 1, -1)
                        highlight:SetPoint("BOTTOMRIGHT", bg, -1, 1)
                    end
                end
            end
            index = index + 1
            row = _G["AchievementFrameCategoriesContainerButton" .. index]
        end
    end
    SkinCategoryRows()
    if _G.AchievementFrameCategories_Update then
        _G.hooksecurefunc("AchievementFrameCategories_Update", SkinCategoryRows)
    end

    -- achievement list rows
    local index = 1
    local row = _G["AchievementFrameAchievementsContainerButton" .. index]
    while row do
        SkinAchievementPlate(row, "AchievementFrameAchievementsContainerButton" .. index)
        index = index + 1
        row = _G["AchievementFrameAchievementsContainerButton" .. index]
    end
    if _G.AchievementButton_DisplayAchievement then
        _G.hooksecurefunc("AchievementButton_DisplayAchievement", Hook.AchievementButton_DisplayAchievement)
    end
    if _G.AchievementObjectives_DisplayCriteria then
        _G.hooksecurefunc("AchievementObjectives_DisplayCriteria", Hook.AchievementObjectives_DisplayCriteria)
    end
    if _G.AchievementButton_GetProgressBar then
        _G.hooksecurefunc("AchievementButton_GetProgressBar", Hook.AchievementButton_GetProgressBar)
    end

    -- summary page
    local function SkinSummaryAndStats()
        if _G.AchievementFrameSummary_UpdateAchievements then
            _G.hooksecurefunc(
                "AchievementFrameSummary_UpdateAchievements",
                Hook.AchievementFrameSummary_UpdateAchievements
            )
        end
        SkinAchievementStatusBar(_G.AchievementFrameSummaryCategoriesStatusBar)
        index = 1
        local catBar = _G["AchievementFrameSummaryCategoriesCategory" .. index]
        while catBar do
            SkinAchievementStatusBar(catBar)
            local label = _G["AchievementFrameSummaryCategoriesCategory" .. index .. "Label"]
            if label then
                label:SetTextColor(Color.white:GetRGB())
            end
            index = index + 1
            catBar = _G["AchievementFrameSummaryCategoriesCategory" .. index]
        end

        -- stats rows
        index = 1
        while _G["AchievementFrameStatsContainerButton" .. index .. "BG"] or
            _G["AchievementFrameStatsContainerButton" .. index] do
            local name = "AchievementFrameStatsContainerButton" .. index
            for _, suffix in ipairs({"BG", "HeaderLeft", "HeaderMiddle", "HeaderRight"}) do
                if _G[name .. suffix] then
                    _G[name .. suffix]:SetAlpha(0)
                end
            end
            index = index + 1
        end
    end
    SkinSummaryAndStats()

    -- comparison pane
    local function SkinComparisonPane()
        for _, name in ipairs({"AchievementFrameComparisonSummaryPlayer", "AchievementFrameComparisonSummaryFriend"}) do
            local frame = _G[name]
            if frame then
                if frame.SetBackdrop then
                    frame:SetBackdrop(nil)
                end
                Util.HideFrameTextures(frame, true)
                Base.SetBackdrop(frame, Color.frame, 0.25)
            end
        end
        SkinAchievementStatusBar(_G.AchievementFrameComparisonSummaryPlayerStatusBar)
        SkinAchievementStatusBar(_G.AchievementFrameComparisonSummaryFriendStatusBar)
        index = 1
        while _G["AchievementFrameComparisonContainerButton" .. index .. "Player"] do
            local base = "AchievementFrameComparisonContainerButton" .. index
            for _, side in ipairs({"Player", "Friend"}) do
                local button = _G[base .. side]
                if button then
                    SkinAchievementPlate(button, base .. side)
                end
                local bg = _G[base .. side .. "Background"]
                if bg then
                    bg:SetColorTexture(0, 0, 0, 0.25)
                end
            end
            local description = _G[base .. "PlayerDescription"]
            if description then
                description:SetTextColor(Color.grayLight:GetRGB())
            end
            index = index + 1
        end
    end
    SkinComparisonPane()

    -- scrollbars
    SkinScrollBar(_G.AchievementFrameAchievementsContainerScrollBar)
    SkinScrollBar(_G.AchievementFrameStatsContainerScrollBar)
    SkinScrollBar(_G.AchievementFrameCategoriesContainerScrollBar)
    SkinScrollBar(_G.AchievementFrameComparisonContainerScrollBar)
end
