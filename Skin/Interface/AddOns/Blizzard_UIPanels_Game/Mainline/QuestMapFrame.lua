local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals select next setmetatable

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

do --[[ FrameXML\QuestMapFrame.lua ]]
    --[[ Quest log headers (B170 follow-up, 2026-10-06)
        Restyled in place from this post-hook, which runs after Blizzard's
        QuestLogQuests_Update has finished, never from the header pools'
        Acquire. The pools are acquired inside QuestLogQuests_Update while the
        map opens; the old Acquire skins added frames, textures, backdrop
        methods and _aurora* fields to each header, Blizzard kept using the
        header in the same execution, and the quest log build ran tainted.
        Campaign headers are laid out first, and their quests' QuestCache
        entries are the ones the objective tracker's Campaign module reads
        (the B168 chain). So: colours and textures on existing regions only,
        no new regions, no size or anchor change, no field on Blizzard's
        frames; skin state lives in the weak table below. Blizzard re-applies
        the campaign and callings texture kits on every update, so those are
        restyled on every pass. ]]
    local styledHeaders = setmetatable({}, {__mode = "k"})

    -- CampaignHeaderDisplayTemplate's Background is 304x69, mostly transparent
    -- atlas below the title. The colour band covers its top 47px, inset 6 and
    -- 5 like the old clip frame, drawn with vertex offsets (1 upper-left,
    -- 2 lower-left, 3 upper-right, 4 lower-right) so the region keeps its size
    -- and anchors. HighlightTexture is anchored to Background and gets the same.
    local function SetCampaignBand(texture, r, g, b, a)
        texture:SetColorTexture(r, g, b, a)
        texture:SetVertexOffset(1, 6, 0)
        texture:SetVertexOffset(2, 6, 22)
        texture:SetVertexOffset(3, -5, 0)
        texture:SetVertexOffset(4, -5, 22)
    end
    function Skin.CampaignHeaderInPlace(header)
        local campaign = header:GetCampaign()
        if not campaign then return end

        local kit = Util.GetTextureKit(campaign.uiTextureKit, true)
        local r, g, b = kit.color:GetRGB()
        SetCampaignBand(header.Background, r, g, b, 1)
        SetCampaignBand(header.HighlightTexture, Color.white.r, Color.white.g, Color.white.b, Color.frame.a)
        if header.TopFiligree then
            header.TopFiligree:SetTexture("")
        end
    end

    -- QuestLogHeaderTemplate (ListHeaderVisualTemplate): a flat band on the
    -- existing Normal and Highlight textures, as on the objective tracker's
    -- headers. Blizzard never re-sets them, so once per header.
    local function StyleListHeader(header)
        if styledHeaders[header] then return end
        styledHeaders[header] = true

        local normal = header:GetNormalTexture()
        if normal then
            local r, g, b = Color.button:GetRGB()
            normal:SetColorTexture(r, g, b, 0.6)
        end
        local highlight = header:GetHighlightTexture()
        if highlight then
            local r, g, b = Color.highlight:GetRGB()
            highlight:SetColorTexture(r, g, b, 0.25)
        end
    end

    -- A pool that does not exist on this flavor enumerates nothing.
    local function NoActive() end
    local function Active(pool)
        if pool then
            return pool:EnumerateActive()
        end
        return NoActive
    end

    function Hook.QuestLogQuests_Update(_poiTable)
        local scrollFrame = _G.QuestScrollFrame

        for header in Active(scrollFrame.headerFramePool) do
            StyleListHeader(header)
        end

        for header in Active(scrollFrame.campaignHeaderFramePool) do
            Skin.CampaignHeaderInPlace(header)
        end

        for header in Active(scrollFrame.campaignHeaderMinimalFramePool) do
            if not styledHeaders[header] then
                styledHeaders[header] = true
                if header.Background then
                    header.Background:SetTexture("")
                end
                if header.Highlight then
                    header.Highlight:SetColorTexture(1, 1, 1, Color.frame.a) -- static: not a theme color
                end
            end
        end

        -- UpdateBG re-atlases Background and HighlightTexture on every update.
        for header in Active(scrollFrame.covenantCallingsHeaderFramePool) do
            StyleListHeader(header)
            header.Background:SetColorTexture(Util.uiTextureKits.alt.color:GetRGB())
            header.HighlightTexture:SetColorTexture(Color.white.r, Color.white.g, Color.white.b, Color.frame.a)
            if header.Divider then
                header.Divider:SetTexture("")
            end
        end
    end

    local sessionCommandToButtonAtlas = {
        [_G.Enum.QuestSessionCommand.Start] = "QuestSharing-DialogIcon",
        [_G.Enum.QuestSessionCommand.Stop] = "QuestSharing-Stop-DialogIcon",
    }
    Hook.QuestSessionManagementMixin = {}
    function Hook.QuestSessionManagementMixin:UpdateExecuteCommandAtlases(command)
        self.ExecuteSessionCommand:ClearNormalTexture()
        self.ExecuteSessionCommand:ClearPushedTexture()
        self.ExecuteSessionCommand:ClearDisabledTexture()

        local atlas = sessionCommandToButtonAtlas[command]
        if atlas then
            self.ExecuteSessionCommand._auroraIcon:SetAtlas(atlas)
        end
    end

    local EventsFrameHookedElements = {}
    local function EventsFrameBackgroundNormal(element, _texture)
        -- _G.print(texture)
        -- FIXLATER
    end
    local EventsFrameFunctions = {
        function(element) -- 1: OngoingHeader
            if not element.Background.backdrop then
                element.Background:SetAlpha(0)
            end
            element.Label:SetTextColor(1, 0.8, 0)
        end,
        function(element) -- 2: OngoingEvent
            if not EventsFrameHookedElements[element] then
                _G.hooksecurefunc(element.Background, "SetAtlas", EventsFrameBackgroundNormal)
                EventsFrameHookedElements[element] = element.Background
            end
        end,
        function(element) -- 3: ScheduledHeader
            if not element.Background.backdrop then
                element.Background:SetAlpha(0)
            end
        end,
        function(element) -- 4: ScheduledEvent
            if element.Highlight then
                element.Highlight:SetAlpha(0)
            end
        end
    }
    function Hook.EventsFrameCallback(_, frame, elementData)
        if not elementData.data then return end
        local func = EventsFrameFunctions[elementData.data.entryType]
        if func then
            func(frame)
        end
    end

    local function SkinIfExists(tab, stripShapedArt)
        if tab and not tab._auroraSkinnedQuestMapTab then
            Skin.QuestMapFrameTabTemplate(tab, stripShapedArt)
        end
    end

    local function IsTabLikeButton(frame)
        if not frame or frame._auroraSkinnedQuestMapTab or not frame.GetObjectType then
            return false
        end

        -- Quest title rows are pooled buttons with icons, but must stay fully
        -- Blizzard-owned. Skinning them taints the tooltip owner used by
        -- QuestMapLogTitleButton_OnEnter.
        if frame.Checkbox and frame.Text and (frame.TaskIcon or frame.StorylineTexture or frame.TagTexture) then
            return false
        end

        local objectType = frame:GetObjectType()
        if objectType ~= "Button" and objectType ~= "CheckButton" then
            return false
        end

        local name = frame.GetName and frame:GetName()
        local hasTabName = name and name:find("Tab")
        local checkedTexture = frame.GetCheckedTexture and frame:GetCheckedTexture()
        local hasTabTraits = frame.Background or frame.SelectedTexture or checkedTexture
        local hasIcon = frame.IconTexture or frame.Icon or (frame.GetNormalTexture and frame:GetNormalTexture())

        return hasIcon and (hasTabName or hasTabTraits)
    end

    local function SkinTabChildren(parent)
        for _, child in next, {parent:GetChildren()} do
            if IsTabLikeButton(child) then
                SkinIfExists(child)
            end

            if child and child.GetNumChildren and child:GetNumChildren() > 0 then
                SkinTabChildren(child)
            end
        end
    end

    function Skin.SkinQuestMapFrameTabs(QuestMapFrame)
        -- Always skin Blizzard's built-in tabs first.
        SkinIfExists(QuestMapFrame.QuestsTab, true)
        SkinIfExists(QuestMapFrame.MapLegendTab, true)
        SkinIfExists(QuestMapFrame.EventsTab, true)

        -- Then skin any tab-like descendants (including addon-added tabs).
        SkinTabChildren(QuestMapFrame)
    end
end

do --[[ FrameXML\QuestMapFrame.xml ]]
    -- QuestLogHeaderTemplate, CovenantCallingsHeaderTemplate and the
    -- QuestLogTitle/Objective templates are pooled by the quest log and are
    -- no longer skinned on Acquire: see Hook.QuestLogQuests_Update above.
    function Skin.QuestMapFrameTabTemplate(Button, stripShapedArt)
        local CheckButton = Button.Button or Button

        local function HideAndLockTextureRegion(region)
            if not region then return end

            if region.SetTexture then
                region:SetTexture("")
            end
            if region.SetAtlas then
                region:SetAtlas("")
            end
            region:Hide()

            if not region._auroraHideLocked then
                _G.hooksecurefunc(region, "Show", region.Hide)
                region._auroraHideLocked = true
            end
        end

        local function StripNonIconTextures(frame, iconTexture)
            if not iconTexture then return end

            for _, region in next, {frame:GetRegions()} do
                if region and region.GetObjectType and region:GetObjectType() == "Texture" and region ~= iconTexture then
                    region:SetTexture("")
                    region:Hide()
                end
            end
        end

        local hasCustomIcon = Button.CustomIcon or CheckButton.CustomIcon
        local icon = hasCustomIcon or Button.IconTexture or CheckButton.IconTexture
        if not icon then
            icon = Button.Icon or CheckButton.Icon or (CheckButton.GetNormalTexture and CheckButton:GetNormalTexture())
        end

        -- If addon provides a dedicated custom icon, force-hide Blizzard fallback
        -- icon textures so their beveled frame art can't bleed through.
        if hasCustomIcon and icon then
            if Button.Icon and Button.Icon ~= icon then Button.Icon:Hide() end
            if Button.IconTexture and Button.IconTexture ~= icon then Button.IconTexture:Hide() end
            if CheckButton.Icon and CheckButton.Icon ~= icon then CheckButton.Icon:Hide() end
            if CheckButton.IconTexture and CheckButton.IconTexture ~= icon then CheckButton.IconTexture:Hide() end
        end

        if icon then
            if stripShapedArt then
                if CheckButton.ClearNormalTexture and CheckButton.ClearPushedTexture and CheckButton.ClearHighlightTexture and CheckButton.ClearDisabledTexture then
                    CheckButton:ClearNormalTexture()
                    CheckButton:ClearPushedTexture()
                    CheckButton:ClearHighlightTexture()
                    CheckButton:ClearDisabledTexture()
                elseif CheckButton.SetNormalTexture and CheckButton.SetPushedTexture and CheckButton.SetHighlightTexture and CheckButton.SetDisabledTexture then
                    CheckButton:SetNormalTexture("")
                    CheckButton:SetPushedTexture("")
                    CheckButton:SetHighlightTexture("")
                    CheckButton:SetDisabledTexture("")
                end

                StripNonIconTextures(CheckButton, icon)
            else
                -- Preserve addon icon sources, but suppress odd state-only art.
                local highlightTexture = CheckButton.GetHighlightTexture and CheckButton:GetHighlightTexture()
                if highlightTexture and highlightTexture ~= icon then
                    highlightTexture:SetTexture("")
                    highlightTexture:Hide()
                end

                local pushedTexture = CheckButton.GetPushedTexture and CheckButton:GetPushedTexture()
                if pushedTexture and pushedTexture ~= icon then
                    pushedTexture:SetTexture("")
                    pushedTexture:Hide()
                end

                local checkedTexture = CheckButton.GetCheckedTexture and CheckButton:GetCheckedTexture()
                if checkedTexture and checkedTexture ~= icon then
                    checkedTexture:SetTexture("")
                    checkedTexture:Hide()
                end

                -- Some custom tabs keep additional unnamed texture regions for
                -- selected/hover states. Hide any non-icon texture regions.
                for _, region in next, {Button:GetRegions()} do
                    if region and region.GetObjectType and region:GetObjectType() == "Texture"
                        and region ~= icon
                        and region ~= Button._auroraHoverTex
                        and region ~= Button._auroraCheckedTex
                        and region ~= Button._auroraIconBG
                    then
                        HideAndLockTextureRegion(region)
                    end
                end
                if CheckButton ~= Button then
                    for _, region in next, {CheckButton:GetRegions()} do
                        if region and region.GetObjectType and region:GetObjectType() == "Texture"
                            and region ~= icon
                            and region ~= Button._auroraHoverTex
                            and region ~= Button._auroraCheckedTex
                            and region ~= Button._auroraIconBG
                        then
                            HideAndLockTextureRegion(region)
                        end
                    end
                end
            end

            if hasCustomIcon then
                -- Keep custom addon icon size consistent with Blizzard tabs.
                -- Prefer anchoring to the original icon region geometry.
                local fallbackIcon = (Button.Icon and Button.Icon ~= icon and Button.Icon)
                    or (Button.IconTexture and Button.IconTexture ~= icon and Button.IconTexture)
                    or (CheckButton.Icon and CheckButton.Icon ~= icon and CheckButton.Icon)
                    or (CheckButton.IconTexture and CheckButton.IconTexture ~= icon and CheckButton.IconTexture)

                icon:ClearAllPoints()
                if fallbackIcon then
                    icon:SetAllPoints(fallbackIcon)
                else
                    icon:SetPoint("TOPLEFT", Button, 8, -8)
                    icon:SetPoint("BOTTOMRIGHT", Button, -8, 8)
                end
            end

            Button._auroraIconBG = Base.CropIcon(icon, Button)

            if not Button._auroraHoverTex then
                local hover = Button:CreateTexture(nil, "OVERLAY")
                hover:SetPoint("TOPLEFT", icon, -1, 1)
                hover:SetPoint("BOTTOMRIGHT", icon, 1, -1)
                hover:SetColorTexture(Color.white.r, Color.white.g, Color.white.b, 0.18)
                hover:Hide()
                Button._auroraHoverTex = hover

                Button:HookScript("OnEnter", function()
                    if Button._auroraHoverTex then
                        Button._auroraHoverTex:Show()
                    end
                end)
                Button:HookScript("OnLeave", function()
                    if Button._auroraHoverTex then
                        Button._auroraHoverTex:Hide()
                    end
                end)
            end

            -- Ensure the hover border doesn't stay visible between updates.
            Button._auroraHoverTex:Hide()

            if CheckButton.GetChecked and not Button._auroraCheckedTex then
                local checked = Button:CreateTexture(nil, "ARTWORK")
                checked:SetPoint("TOPLEFT", icon, -1, 1)
                checked:SetPoint("BOTTOMRIGHT", icon, 1, -1)
                checked:SetColorTexture(1, 0.85, 0, 0.2) -- static: not a theme color
                checked:SetShown(CheckButton:GetChecked())
                Button._auroraCheckedTex = checked

                CheckButton:HookScript("OnClick", function(self)
                    Button._auroraCheckedTex:SetShown(self:GetChecked())
                end)
            end

            icon:Show()
        end

        if CheckButton.SetCheckedTexture then
            CheckButton:SetCheckedTexture("")
        end

        HideAndLockTextureRegion(Button.Background)
        HideAndLockTextureRegion(Button.SelectedTexture)
        HideAndLockTextureRegion(CheckButton.Background)
        HideAndLockTextureRegion(CheckButton.SelectedTexture)

        Button._auroraSkinnedQuestMapTab = true
    end
end

function private.FrameXML.QuestMapFrame()
    ------------------------------
    -- QuestLogPopupDetailFrame --
    ------------------------------
    local QuestLogPopupDetailFrame = _G.QuestLogPopupDetailFrame
    local frameBG, _, artBG, _, _, _, _, _, portrait = QuestLogPopupDetailFrame:GetRegions()
    portrait:Hide()

    QuestLogPopupDetailFrame.Bg = frameBG -- Bg from ButtonFrameTemplate
    Skin.ButtonFrameTemplate(QuestLogPopupDetailFrame)
    QuestLogPopupDetailFrame.Bg = artBG -- Bg from QuestFramePanelTemplate
    Skin.QuestFramePanelTemplate(QuestLogPopupDetailFrame)

    Skin.ScrollFrameTemplate(QuestLogPopupDetailFrame.ScrollFrame)
    QuestLogPopupDetailFrame.ScrollFrame:SetPoint("TOPLEFT", 5, -(private.FRAME_TITLE_HEIGHT + 5))
    QuestLogPopupDetailFrame.ScrollFrame:SetPoint("BOTTOMRIGHT", -23, 32)

    local ShowMapButton = QuestLogPopupDetailFrame.ShowMapButton
    ShowMapButton.Texture:Hide()
    ShowMapButton.Highlight:SetTexture("")
    ShowMapButton.Highlight:SetTexture("")

    ShowMapButton.Text:ClearAllPoints()
    ShowMapButton.Text:SetPoint("CENTER", 1, 0)
    ShowMapButton:SetFontString(ShowMapButton.Text)
    ShowMapButton:SetNormalFontObject("GameFontNormal")
    ShowMapButton:SetHighlightFontObject("GameFontHighlight")
    ShowMapButton:SetSize(ShowMapButton.Text:GetStringWidth() + 14, 22)

    ShowMapButton:ClearAllPoints()
    ShowMapButton:SetPoint("TOPRIGHT", -30, -5)
    Base.SetBackdrop(ShowMapButton, Color.button)
    Base.SetHighlight(ShowMapButton)

    Skin.UIPanelButtonTemplate(QuestLogPopupDetailFrame.AbandonButton)
    QuestLogPopupDetailFrame.AbandonButton:SetPoint("BOTTOMLEFT", 5, 5)
    Skin.UIPanelButtonTemplate(QuestLogPopupDetailFrame.TrackButton)
    QuestLogPopupDetailFrame.TrackButton:SetPoint("BOTTOMRIGHT", -5, 5)
    Skin.UIPanelButtonTemplate(QuestLogPopupDetailFrame.ShareButton)
    QuestLogPopupDetailFrame.ShareButton:SetPoint("LEFT", QuestLogPopupDetailFrame.AbandonButton, "RIGHT", 1, 0)
    QuestLogPopupDetailFrame.ShareButton:SetPoint("RIGHT", QuestLogPopupDetailFrame.TrackButton, "LEFT", -1, 0)


    -------------------
    -- QuestMapFrame --
    -------------------
    _G.hooksecurefunc("QuestLogQuests_Update", Hook.QuestLogQuests_Update)

    -- NOTE: Do NOT replace QuestMapLogTitleButton_OnEnter. Aurora wrapped
    -- it in securecallfunction against a secret GetStringWidth() at
    -- QuestMapFrame.lua:2123, but QuestMapFrame.xml:199 binds the title
    -- buttons' OnEnter to the global by name, so every quest title hover ran
    -- Aurora's closure, and securecallfunction called from addon code does
    -- not make the callee secure. The whole OnEnter then ran tainted: the
    -- tooltip, the map's highlighted quest and POI, and quest cache reads
    -- shared with the objective tracker. Removed 2026-10-05 (taint audit,
    -- tracker-widget-taint-rewrite). If the secret-width error returns,
    -- the GameTooltip state it reads is tainted elsewhere: trace that.

    local QuestMapFrame = _G.QuestMapFrame
    if  QuestMapFrame.Background then
        QuestMapFrame.Background:Hide()
    end
    QuestMapFrame.VerticalSeparator:Hide()

    Skin.SkinQuestMapFrameTabs(QuestMapFrame)
    QuestMapFrame:HookScript("OnShow", Skin.SkinQuestMapFrameTabs)
    if QuestMapFrame.ValidateTabs then
        _G.hooksecurefunc(QuestMapFrame, "ValidateTabs", Skin.SkinQuestMapFrameTabs)
    end

    local QuestsFrame = QuestMapFrame.QuestsFrame
    Skin.ScrollFrameTemplate(QuestsFrame.ScrollFrame)
    -- The quest log's pools (titles, objectives, headers, campaign and
    -- callings headers) are not wrapped: their headers are restyled in place
    -- from Hook.QuestLogQuests_Update.

    QuestsFrame.ScrollFrame.Contents.Separator:SetSize(260, 10)
    QuestsFrame.ScrollFrame.Contents.Separator.Divider:SetPoint("TOP", 0, 0)
    QuestsFrame.ScrollFrame.Contents.Separator.Divider:SetColorTexture(Color.white.r, Color.white.g, Color.white.b, 0.5)
    QuestsFrame.ScrollFrame.Contents.Separator.Divider:SetSize(200, 1)

    do -- StoryHeader
        local StoryHeader = QuestsFrame.ScrollFrame.Contents.StoryHeader
        StoryHeader.Text:SetPoint("TOPLEFT", 18, -25)

        local mask = StoryHeader:CreateMaskTexture(nil, "BACKGROUND")
        mask:SetTexture([[Interface/SpellBook/UI-SpellbookPanel-Tab-Highlight]], "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        mask:SetPoint("LEFT", -54, 0)
        mask:SetPoint("RIGHT", 38, 0)
        mask:SetPoint("TOP", StoryHeader.Text, 0, 52)
        mask:SetPoint("BOTTOM", StoryHeader.Progress, 0, -58)

        StoryHeader.Background:AddMaskTexture(mask)
        StoryHeader.Background:SetColorTexture(Color.button:GetRGB())

        StoryHeader.HighlightTexture:AddMaskTexture(mask)
        StoryHeader.HighlightTexture:SetAllPoints(StoryHeader.Background)
        StoryHeader.HighlightTexture:SetColorTexture(Color.white.r, Color.white.g, Color.white.b, Color.frame.a)
    end

    if QuestsFrame.DetailFrame then
        QuestsFrame.DetailFrame.BottomDetail:Hide()
        QuestsFrame.DetailFrame.TopDetail:Hide()
    end
    -- StoryTooltip moved to QuestScrollFrame.StoryTooltip in 11.1.0, inherits TooltipBackdropTemplate
    -- Skin.FrameTypeFrame(QuestScrollFrame.StoryTooltip)

    do -- QuestSessionManagement
        local QuestSessionManagement = QuestMapFrame.QuestSessionManagement
        Util.Mixin(QuestSessionManagement, Hook.QuestSessionManagementMixin)

        local ExecuteSessionCommand = QuestSessionManagement.ExecuteSessionCommand
        Skin.FrameTypeButton(ExecuteSessionCommand)
        local icon = ExecuteSessionCommand:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", 0, 0)
        icon:SetPoint("BOTTOMRIGHT", 0, 0)
        ExecuteSessionCommand._auroraIcon = icon

        QuestSessionManagement.BG:SetColorTexture(Color.frame.r, Color.frame.g, Color.frame.b, 0.5)
    end

    local DetailsFrame = QuestMapFrame.DetailsFrame
    local bg, overlay, _, _ = DetailsFrame:GetRegions()

    bg:Hide()
    overlay:Hide()
    local BorderFrame = DetailsFrame.BorderFrame
    BorderFrame:Hide()

    local BackFrame = DetailsFrame.BackFrame
    Base.StripBlizzardTextures(BackFrame)
    Skin.UIPanelButtonTemplate(BackFrame.BackButton)

    local RewardsFrameContainer = DetailsFrame.RewardsFrameContainer
    local RewardsFrame = RewardsFrameContainer.RewardsFrame
    Base.StripBlizzardTextures(RewardsFrame)
    Skin.ScrollFrameTemplate(DetailsFrame.ScrollFrame)

    Skin.UIPanelButtonTemplate(_G.QuestFrameCompleteButton)
    local QuestFrameCompleteButtonLeft, QuestFrameCompleteButtonRight = select(6, _G.QuestFrameCompleteButton:GetRegions())
    QuestFrameCompleteButtonLeft:Hide()
    QuestFrameCompleteButtonRight:Hide()

    Skin.UIPanelButtonTemplate(DetailsFrame.AbandonButton)
    Skin.UIPanelButtonTemplate(DetailsFrame.ShareButton)
    local ShareButtonLeft, ShareButtonRight = select(6, DetailsFrame.ShareButton:GetRegions())
    ShareButtonLeft:Hide()
    ShareButtonRight:Hide()
    Skin.UIPanelButtonTemplate(DetailsFrame.TrackButton)
    Skin.CampaignOverviewTemplate(QuestMapFrame.QuestsFrame.CampaignOverview)

    local MapLegend = QuestMapFrame.MapLegend
    Skin.ScrollFrameTemplate(MapLegend.ScrollFrame)

    do -- EventsFrame
        local EventsFrame = QuestMapFrame.EventsFrame
        -- Skin.ScrollFrameTemplate(EventsFrame.ScrollFrame)
        Skin.MinimalScrollBar(EventsFrame.ScrollBar)
        _G.ScrollUtil.AddAcquiredFrameCallback(EventsFrame.ScrollBox, Hook.EventsFrameCallback, EventsFrame, true)
    end
end
