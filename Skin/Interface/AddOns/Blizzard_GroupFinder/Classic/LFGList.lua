local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

--[[ Mists (5.5.4) Premade Groups (LFGList) — essentially the retail
    frame (SearchBoxTemplate + WowStyle1 filter/dropdowns, ScrollBox
    lists, smoke CustomBG insets) with classic-only internals: plain
    UIPanelButtonTemplate-based LFGListButtonTemplate instead of
    MagicButtons, texture-array role icons in the data display (retail's
    enumerate hooks would error — skipped), no leaver badges. Adapted
    from the Mainline LFGList skin; retail-only helpers guarded.
    Evidence: wow-ui-source-classic/Interface/AddOns/Blizzard_GroupFinder/
    Classic/LFGList.xml.
]]

do --[[ Blizzard_GroupFinder\Classic\LFGList.lua ]]
    local skinnedResults = 1
    function Hook.LFGListSearchPanel_UpdateAutoComplete(self)
        for i = (skinnedResults + 1), #self.AutoCompleteFrame.Results do
            Skin.LFGListSearchAutoCompleteButtonTemplate(self.AutoCompleteFrame.Results[i])
        end
        skinnedResults = #self.AutoCompleteFrame.Results
    end
    local skinnedCategories = 1
    function Hook.LFGListCategorySelection_AddButton(self, btnIndex)
        -- category buttons are created on demand; the retail atlas remap
        -- is skipped (classic category art stays stock inside the crop)
        local button = self.CategoryButtons and self.CategoryButtons[btnIndex]
        if btnIndex > skinnedCategories and button then
            Skin.LFGListCategoryTemplate(button)
            skinnedCategories = btnIndex
        end
    end
    function Hook.LFGListInviteDialog_Show(self, resultID)
        local _, _, _, _, role = _G.C_LFGList.GetApplicationInfo(resultID)
        if role and self.RoleIcon then
            Base.SetTexture(self.RoleIcon, "icon"..role)
        end
    end
end

do --[[ Blizzard_GroupFinder\Classic\LFGList.xml ]]
    function Skin.LFGListSearchAutoCompleteButtonTemplate(Button)
        Button:ClearNormalTexture()
        Button:ClearPushedTexture()

        local highlight = Button:GetHighlightTexture()
        Util.SetHighlightColor(highlight, Color.frame.a)
    end
    function Skin.LFGListButtonTemplate(Button)
        Skin.UIPanelButtonTemplate(Button)
    end
    function Skin.LFGListRoleButtonTemplate(Button)
        Base.SetTexture(Button:GetNormalTexture(), "icon"..Button.role)
        if Button.CheckButton then
            Skin.UICheckButtonTemplate(Button.CheckButton)
        end
    end
    function Skin.LFGListCategoryTemplate(Button)
        Skin.FrameTypeButton(Button)

        Button.Icon:ClearAllPoints()
        Button.Icon:SetPoint("TOPLEFT", 1, -1)
        Button.Icon:SetPoint("BOTTOMRIGHT", -1, 1)
        Button.Icon:SetTexCoord(0.06006, 0.95495, 0.15625, 0.61458)
        if Button.Cover then
            Button.Cover:Hide()
        end

        local color = Color.highlight
        Button.SelectedTexture:SetColorTexture(color.r, color.g, color.b, Color.frame.a)
        Button.SelectedTexture:SetAllPoints()
    end
    function Skin.LFGListColumnHeaderTemplate(Button)
        if Button.Left then Button.Left:Hide() end
        if Button.Right then Button.Right:Hide() end
        if Button.Middle then Button.Middle:Hide() end
    end
end

local function SkinRefreshButton(RefreshButton)
    if not RefreshButton then return end
    Skin.FrameTypeButton(RefreshButton)
    RefreshButton:SetBackdropOption("offsets", {
        left = 4,
        right = 4,
        top = 5,
        bottom = 5,
    })
end

function private.FrameXML.LFGList()
    if _G.LFGListSearchPanel_UpdateAutoComplete then
        _G.hooksecurefunc("LFGListSearchPanel_UpdateAutoComplete", Hook.LFGListSearchPanel_UpdateAutoComplete)
    end
    if _G.LFGListCategorySelection_AddButton then
        _G.hooksecurefunc("LFGListCategorySelection_AddButton", Hook.LFGListCategorySelection_AddButton)
    end

    local LFGListFrame = _G.LFGListFrame
    if not LFGListFrame then return end

    -- CategorySelection --
    local CategorySelection = LFGListFrame.CategorySelection
    if CategorySelection then
        if CategorySelection.Inset then
            Skin.InsetFrameTemplate(CategorySelection.Inset)
            if CategorySelection.Inset.CustomBG then
                CategorySelection.Inset.CustomBG:Hide()
            end
        end
        if CategorySelection.CategoryButtons and CategorySelection.CategoryButtons[1] then
            CategorySelection.CategoryButtons[1]:SetNormalFontObject(_G.GameFontNormal)
            Skin.LFGListCategoryTemplate(CategorySelection.CategoryButtons[1])
        end
        if CategorySelection.FindGroupButton then
            Skin.LFGListButtonTemplate(CategorySelection.FindGroupButton)
        end
        if CategorySelection.StartGroupButton then
            Skin.LFGListButtonTemplate(CategorySelection.StartGroupButton)
        end
    end

    -- NothingAvailable --
    if LFGListFrame.NothingAvailable and LFGListFrame.NothingAvailable.Inset then
        Skin.InsetFrameTemplate(LFGListFrame.NothingAvailable.Inset)
    end

    -- SearchPanel --
    local SearchPanel = LFGListFrame.SearchPanel
    if SearchPanel then
        if SearchPanel.SearchBox then
            Skin.SearchBoxTemplate(SearchPanel.SearchBox)
        end
        if SearchPanel.FilterButton then
            Skin.FilterButton(SearchPanel.FilterButton)
        end

        local AutoCompleteFrame = SearchPanel.AutoCompleteFrame
        if AutoCompleteFrame then
            Skin.FrameTypeFrame(AutoCompleteFrame)
            for _, key in ipairs({
                "BottomLeftBorder", "BottomRightBorder",
                "BottomBorder", "LeftBorder", "RightBorder",
            }) do
                if AutoCompleteFrame[key] then
                    AutoCompleteFrame[key]:Hide()
                end
            end
            if AutoCompleteFrame.Results and AutoCompleteFrame.Results[1] then
                Skin.LFGListSearchAutoCompleteButtonTemplate(AutoCompleteFrame.Results[1])
            end
        end

        SkinRefreshButton(SearchPanel.RefreshButton)
        if SearchPanel.ResultsInset then
            Skin.InsetFrameTemplate(SearchPanel.ResultsInset)
        end
        if SearchPanel.ScrollBox and Skin.WowScrollBoxList then
            Skin.WowScrollBoxList(SearchPanel.ScrollBox)
            if SearchPanel.ScrollBox.StartGroupButton then
                Skin.UIPanelButtonTemplate(SearchPanel.ScrollBox.StartGroupButton)
            end
        end
        if SearchPanel.ScrollBar and Skin.MinimalScrollBar then
            Skin.MinimalScrollBar(SearchPanel.ScrollBar)
        end
        if SearchPanel.BackButton then
            Skin.LFGListButtonTemplate(SearchPanel.BackButton)
        end
        if SearchPanel.SignUpButton then
            Skin.LFGListButtonTemplate(SearchPanel.SignUpButton)
        end
    end

    -- ApplicationViewer --
    local ApplicationViewer = LFGListFrame.ApplicationViewer
    if ApplicationViewer then
        if ApplicationViewer.InfoBackground then
            -- alpha, not Hide: other elements anchor to this texture
            ApplicationViewer.InfoBackground:SetAlpha(0)
        end
        if ApplicationViewer.AutoAcceptButton then
            Skin.UICheckButtonTemplate(ApplicationViewer.AutoAcceptButton)
        end
        if ApplicationViewer.Inset then
            Skin.InsetFrameTemplate(ApplicationViewer.Inset)
        end
        for _, key in ipairs({"NameColumnHeader", "RoleColumnHeader", "ItemLevelColumnHeader"}) do
            if ApplicationViewer[key] then
                Skin.LFGListColumnHeaderTemplate(ApplicationViewer[key])
            end
        end
        SkinRefreshButton(ApplicationViewer.RefreshButton)
        if ApplicationViewer.ScrollBox and Skin.WowScrollBoxList then
            Skin.WowScrollBoxList(ApplicationViewer.ScrollBox)
        end
        if ApplicationViewer.ScrollBar and Skin.MinimalScrollBar then
            Skin.MinimalScrollBar(ApplicationViewer.ScrollBar)
        end
        for _, key in ipairs({"RemoveEntryButton", "EditButton", "BrowseGroupsButton"}) do
            if ApplicationViewer[key] then
                Skin.LFGListButtonTemplate(ApplicationViewer[key])
            end
        end
    end

    -- EntryCreation --
    local EntryCreation = LFGListFrame.EntryCreation
    if EntryCreation then
        if EntryCreation.Inset then
            Skin.InsetFrameTemplate(EntryCreation.Inset)
            if EntryCreation.Inset.CustomBG then
                EntryCreation.Inset.CustomBG:Hide()
            end
        end

        local ActivityFinder = EntryCreation.ActivityFinder
        if ActivityFinder and ActivityFinder.Dialog then
            local Dialog = ActivityFinder.Dialog
            if ActivityFinder.Background then
                ActivityFinder.Background:SetAlpha(Color.frame.a)
                ActivityFinder.Background:SetPoint("TOPLEFT")
                ActivityFinder.Background:SetPoint("BOTTOMRIGHT")
            end
            if Dialog.Bg then
                Dialog.Bg:Hide()
            end
            if Dialog.Border then
                Skin.DialogBorderTemplate(Dialog.Border)
            end
            if Dialog.EntryBox then
                Skin.InputBoxInstructionsTemplate(Dialog.EntryBox)
            end
            if Dialog.ScrollBox and Skin.WowScrollBoxList then
                Skin.WowScrollBoxList(Dialog.ScrollBox)
            end
            if Dialog.ScrollBar and Skin.MinimalScrollBar then
                Skin.MinimalScrollBar(Dialog.ScrollBar)
            end
            if Dialog.BorderFrame then
                Skin.TooltipBackdropTemplate(Dialog.BorderFrame)
            end
            if Dialog.SelectButton then
                Skin.UIPanelButtonTemplate(Dialog.SelectButton)
            end
            if Dialog.CancelButton then
                Skin.UIPanelButtonTemplate(Dialog.CancelButton)
            end
        end

        for _, key in ipairs({"GroupDropdown", "ActivityDropdown", "PlayStyleDropdown"}) do
            if EntryCreation[key] then
                Skin.DropdownButton(EntryCreation[key])
            end
        end
        if EntryCreation.ListGroupButton then
            Skin.LFGListButtonTemplate(EntryCreation.ListGroupButton)
        end
        if EntryCreation.CancelButton then
            Skin.LFGListButtonTemplate(EntryCreation.CancelButton)
        end
    end

    -- ApplicationDialog --
    local ApplicationDialog = _G.LFGListApplicationDialog
    if ApplicationDialog then
        if ApplicationDialog.Border then
            Skin.DialogBorderTemplate(ApplicationDialog.Border)
        end
        for _, key in ipairs({"HealerButton", "TankButton", "DamagerButton"}) do
            if ApplicationDialog[key] then
                Skin.LFGListRoleButtonTemplate(ApplicationDialog[key])
            end
        end
        if ApplicationDialog.Description and Skin.InputScrollFrameTemplate then
            Skin.InputScrollFrameTemplate(ApplicationDialog.Description)
        end
        if ApplicationDialog.SignUpButton then
            Skin.UIPanelButtonTemplate(ApplicationDialog.SignUpButton)
        end
        if ApplicationDialog.CancelButton then
            Skin.UIPanelButtonTemplate(ApplicationDialog.CancelButton)
        end
    end

    -- InviteDialog --
    local InviteDialog = _G.LFGListInviteDialog
    if InviteDialog then
        if _G.LFGListInviteDialog_Show then
            _G.hooksecurefunc("LFGListInviteDialog_Show", Hook.LFGListInviteDialog_Show)
        end
        if InviteDialog.Border then
            Skin.DialogBorderTemplate(InviteDialog.Border)
        end
        for _, key in ipairs({"AcceptButton", "DeclineButton", "AcknowledgeButton"}) do
            if InviteDialog[key] then
                Skin.UIPanelButtonTemplate(InviteDialog[key])
            end
        end
    end
end
