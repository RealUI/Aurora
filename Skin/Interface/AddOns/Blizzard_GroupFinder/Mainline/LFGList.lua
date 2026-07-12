local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals bit math strfind

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

do --[[ FrameXML\LFGList.lua ]]
    local skinnedResults = 1
    function Hook.LFGListSearchPanel_UpdateAutoComplete(self)
        for i = (skinnedResults + 1), #self.AutoCompleteFrame.Results do
            Skin.LFGListSearchAutoCompleteButtonTemplate(self.AutoCompleteFrame.Results[i])
        end
        skinnedResults = #self.AutoCompleteFrame.Results
    end
    local skinnedCategories = 1
    function Hook.LFGListCategorySelection_AddButton(self, btnIndex, categoryID, filters)
        local baseFilters = self:GetParent().baseFilters
        local allFilters = bit.bor(baseFilters, filters)

        if filters ~= 0 and #_G.C_LFGList.GetAvailableActivities(categoryID, nil, allFilters) == 0 then
            return btnIndex, false
        end

        local button = self.CategoryButtons[btnIndex]
        if btnIndex > skinnedCategories and button then
            Skin.LFGListCategoryTemplate(button)
            skinnedCategories = btnIndex
        end

        local atlasName
        if bit.band(allFilters, private.Enum.LFGListFilter.Recommended) ~= 0 then
            atlasName = "groupfinder-background-"..(_G.LFG_LIST_CATEGORY_TEXTURES[categoryID] or "raids").."-".._G.LFG_LIST_PER_EXPANSION_TEXTURES[_G.LFGListUtil_GetCurrentExpansion()]
        elseif bit.band(allFilters, private.Enum.LFGListFilter.NotRecommended) ~= 0 then
            atlasName = "groupfinder-background-"..(_G.LFG_LIST_CATEGORY_TEXTURES[categoryID] or "raids").."-".._G.LFG_LIST_PER_EXPANSION_TEXTURES[math.max(0,_G.LFGListUtil_GetCurrentExpansion() - 1)]
        else
            atlasName = "groupfinder-background-"..(_G.LFG_LIST_CATEGORY_TEXTURES[categoryID] or "questing")
        end

        local suffix = ""
        if bit.band(allFilters, private.Enum.LFGListFilter.PvE) ~= 0 then
            suffix = "-pve"
        elseif bit.band(allFilters, private.Enum.LFGListFilter.PvP) ~= 0 then
            suffix = "-pvp"
        end
        --Try with the suffix and then without it
        if not _G.CheckSetAtlas(button.Icon, atlasName..suffix) then
            _G.CheckSetAtlas(button.Icon, atlasName);
        end
    end

    function Hook.LFGListGroupDataDisplayEnumerate_Update(self, numPlayers, displayData, disabled, iconOrder)
        local iconIndex = numPlayers;
        for i=1, #self.Icons do
            local icon = self.Icons[i].RoleIcon
            if  icon._auroraBorder ~= nil then
                if i > numPlayers then
                    icon._auroraBorder:Hide();
                    icon._auroraBG:Hide();
                else
                    icon._auroraBorder:Show();
                    icon._auroraBG:Show();
                end
            -- else
                -- _G.print("Aurora: LFGListGroupDataDisplayEnumerate_Update icon._auroraBorder is nil.")
            end
        end

        for i=1, #iconOrder do
            for j=1, displayData[iconOrder[i]] do
                Base.SetTexture(self.Icons[iconIndex].RoleIcon, "icon"..iconOrder[i])
                self.Icons[iconIndex]:SetSize(14, 14)
                iconIndex = iconIndex - 1;
                if iconIndex < 1 then
                    return;
                end
            end
        end

        for i=1, iconIndex do
            local icon = self.Icons[i].RoleIcon
            icon:SetAlpha(0)
            icon:SetSize(8, 8)
            if  icon._auroraBorder ~= nil then
                icon._auroraBorder:SetColorTexture(0, 0, 0) -- static: not a theme color
                icon._auroraBG:SetColorTexture(Color.button:GetRGB())
            end
        end
    end
    function Hook.LFGListApplicationViewer_UpdateRoleIcons(member, grayedOut, tank, healer, damage, noTouchy, assignedRole)
        for i = 1, 3 do
            local icon = member["RoleIcon"..i]
            if icon.role then
                Base.SetTexture(icon:GetNormalTexture(), "icon"..icon.role)
            end
        end
    end

    local grayedOutStatus = {
        failed = true,
        cancelled = true,
        declined = true,
        declined_full = true,
        declined_delisted = true,
        invitedeclined = true,
        timedout = true,
    }
    function Hook.LFGListApplicationViewer_UpdateApplicantMember(member, appID, memberIdx, status, pendingStatus)
        if not pendingStatus and grayedOutStatus[status] then
            -- grayedOut
            return
        end

        local name, classToken = _G.C_LFGList.GetApplicantMemberInfo(appID, memberIdx)
        local classColor = name and classToken and _G.CUSTOM_CLASS_COLORS[classToken]
        if classColor then
            member.Name:SetTextColor(classColor.r, classColor.g, classColor.b)
        end
    end
    function Hook.LFGListApplicantMember_OnEnter(self)
        local applicantID = self:GetParent().applicantID
        local memberIdx = self.memberIdx
        local name, classToken = _G.C_LFGList.GetApplicantMemberInfo(applicantID, memberIdx)
        local classColor = name and classToken and _G.CUSTOM_CLASS_COLORS[classToken]
        if classColor then
            _G.GameTooltipTextLeft1:SetTextColor(classColor.r, classColor.g, classColor.b)
        end
    end
    function Hook.LFGListUtil_SetSearchEntryTooltip(tooltip, resultID)
        local searchResultData  = _G.C_LFGList.GetSearchResultInfo(resultID)
        local activityInfo = _G.C_LFGList.GetActivityInfoTable(searchResultData.activityIDs[1])
        if activityInfo.displayType ~= _G.Enum.LFGListDisplayType.ClassEnumerate then return end
        if searchResultData.isDelisted or not tooltip:IsShown() then
            -- _G.print("LFGListUtil_SetSearchEntryTooltip is isDelisted or not shown.")
            return
        end
        local name = tooltip:GetName() .. "TextLeft"
        local start
        for i = 4, tooltip:NumLines() do
            if strfind(_G[name..i]:GetText(), _G.LFG_LIST_TOOLTIP_MEMBERS_SIMPLE) then
                start = i
                break
            end
        end
        if start then
            for i = 1, searchResultData.numMembers do
                local _, classToken = _G.C_LFGList.GetSearchResultMemberInfo(resultID, i)
                local classColor = classToken and _G.CUSTOM_CLASS_COLORS[classToken]
                if classColor then
                    _G[name..(start+i)]:SetTextColor(classColor.r, classColor.g, classColor.b)
                end
            end
        end
    end
    function Hook.LFGListInviteDialog_Show(self, resultID, kstringGroupName)
        local _, _, _, _, role = _G.C_LFGList.GetApplicationInfo(resultID)
        Base.SetTexture(self.RoleIcon, "icon"..role)
    end
end

do --[[ FrameXML\LFGList.xml ]]
    function Skin.LFGListGroupDataDisplayTemplate(Frame)
        Skin.RoleCountNoScriptsTemplate(Frame.RoleCount)
        for i = 1, #Frame.Enumerate.Icons do
            Base.SetTexture(Frame.Enumerate.Icons[i].RoleIcon, "iconTANK")
        end
    end
    function Skin.LFGListSearchAutoCompleteButtonTemplate(Button)
        Button:ClearNormalTexture()
        Button:ClearPushedTexture()

        local highlight = Button:GetHighlightTexture()
        Util.SetHighlightColor(highlight, Color.frame.a)
    end
    function Skin.LFGListApplicantMemberTemplate(Button)
        if private.isDev then
            _G.print("Aurora: LFGListApplicantMemberTemplate is called by:".._G.debugstack(2, 1, 0):gsub("\n", " "):gsub("Interface\\FrameXML\\LFGList.lua:", ""))
        end
    end
    function Skin.LFGListApplicantTemplate(Button)
        Skin.LFGListApplicantMemberTemplate(Button.Member1)
        Skin.UIMenuButtonStretchTemplate(Button.DeclineButton)
        Skin.UIMenuButtonStretchTemplate(Button.InviteButton)
    end
    function Skin.LFGListRoleButtonTemplate(Button)
        Base.SetTexture(Button:GetNormalTexture(), "icon"..Button.role)
        Skin.UICheckButtonTemplate(Button.CheckButton)
    end
    function Skin.LFGListCategoryTemplate(Button)
        Skin.FrameTypeButton(Button)

        Button.Icon:ClearAllPoints()
        Button.Icon:SetPoint("TOPLEFT", 1, -1)
        Button.Icon:SetPoint("BOTTOMRIGHT", -1, 1)
        Button.Icon:SetTexCoord(0.06006, 0.95495, 0.15625, 0.61458)
        Button.Cover:Hide()

        local color = Color.highlight
        Button.SelectedTexture:SetColorTexture(color.r, color.g, color.b, Color.frame.a)
        Button.SelectedTexture:SetAllPoints()
    end
    function Skin.LFGListMagicButtonTemplate(Button)
        Skin.MagicButtonTemplate(Button)
    end
    function Skin.LFGListEditBoxTemplate(Button)
        Skin.InputBoxInstructionsTemplate(Button)
    end
    function Skin.LFGListOptionCheckButtonTemplate(Frame)
        Skin.UICheckButtonTemplate(Frame.CheckButton) -- BlizzWTF: This doesn't use the template, but it should
    end
    function Skin.LFGListRequirementTemplate(Frame)
        Skin.UICheckButtonTemplate(Frame.CheckButton) -- BlizzWTF: This doesn't use the template, but it should
        Skin.LFGListEditBoxTemplate(Frame.EditBox)
    end
    function Skin.LFGListColumnHeaderTemplate(Button)
        Button.Left:Hide()
        Button.Right:Hide()
        Button.Middle:Hide()
    end
    function Skin.LFGListSearchEntryTemplate(Button)
        Skin.LFGListGroupDataDisplayTemplate(Button.DataDisplay)
        Skin.UIMenuButtonStretchTemplate(Button.CancelButton)
    end
end

function private.FrameXML.LFGList()
    _G.hooksecurefunc("LFGListSearchPanel_UpdateAutoComplete", Hook.LFGListSearchPanel_UpdateAutoComplete)
    _G.hooksecurefunc("LFGListCategorySelection_AddButton", Hook.LFGListCategorySelection_AddButton)
    _G.hooksecurefunc("LFGListGroupDataDisplayEnumerate_Update", Hook.LFGListGroupDataDisplayEnumerate_Update)
    _G.hooksecurefunc("LFGListApplicationViewer_UpdateRoleIcons", Hook.LFGListApplicationViewer_UpdateRoleIcons)
    _G.hooksecurefunc("LFGListApplicationViewer_UpdateApplicantMember", Hook.LFGListApplicationViewer_UpdateApplicantMember)
    _G.hooksecurefunc("LFGListApplicantMember_OnEnter", Hook.LFGListApplicantMember_OnEnter)
    _G.hooksecurefunc("LFGListUtil_SetSearchEntryTooltip", Hook.LFGListUtil_SetSearchEntryTooltip)

    -- do -- GetPlayerStyleString TaintFix
    --     local activityID = 1164;
    --     if (not _G.C_LFGList.IsPlayerAuthenticatedForLFG(activityID)) then
    --         _G.print("Aurora: LFGList Taint Fix not installed.")
    --         return
    --     end
    --     _G.print("Aurora: LFGList Taint Fix installed.")
    --     _G.C_LFGList.GetPlaystyleString = function(playstyle, activityInfo)
    --         if not (activityInfo and playstyle and playstyle ~= 0 and _G.C_LFGList.GetLfgCategoryInfo(activityInfo.categoryID).showPlaystyleDropdown) then
    --             return nil
    --         end
    --         local PlaystyleString
    --         if activityInfo.isMythicPlusActivity then
    --             PlaystyleString = "GROUP_FINDER_PVE_PLAYSTYLE"
    --         elseif activityInfo.isRatedPvpActivity then
    --             PlaystyleString = "GROUP_FINDER_PVP_PLAYSTYLE"
    --         elseif activityInfo.isCurrentRaidActivity then
    --             PlaystyleString = "GROUP_FINDER_PVE_RAID_PLAYSTYLE"
    --         elseif activityInfo.isMythicActivity then
    --             PlaystyleString = "GROUP_FINDER_PVE_MYTHICZERO_PLAYSTYLE"
    --         end
    --         return PlaystyleString and _G[PlaystyleString .. _G.tostring(playstyle)] or nil
    --     end
    --     _G.LFGListEntryCreation_SetTitleFromActivityInfo = function(_) end
    -- end

    ------------------
    -- LFGListFrame --
    ------------------
    local LFGListFrame =_G.LFGListFrame

    -- CategorySelection --
    local CategorySelection = LFGListFrame.CategorySelection
    Skin.InsetFrameTemplate(CategorySelection.Inset)
    CategorySelection.Inset.CustomBG:Hide()

    CategorySelection.CategoryButtons[1]:SetNormalFontObject(_G.GameFontNormal)
    Skin.LFGListCategoryTemplate(CategorySelection.CategoryButtons[1])

    Skin.LFGListMagicButtonTemplate(CategorySelection.FindGroupButton)
    CategorySelection.FindGroupButton:SetPoint("BOTTOMRIGHT", -5, 5)
    Skin.LFGListMagicButtonTemplate(CategorySelection.StartGroupButton)
    CategorySelection.StartGroupButton:SetPoint("BOTTOMLEFT", 5, 5)

    -- NothingAvailable --
    local NothingAvailable = LFGListFrame.NothingAvailable
    Skin.InsetFrameTemplate(NothingAvailable.Inset)

    -- SearchPanel --
    local SearchPanel = LFGListFrame.SearchPanel
    Skin.SearchBoxTemplate(SearchPanel.SearchBox)
    Skin.FilterButton(SearchPanel.FilterButton)

    local AutoCompleteFrame = SearchPanel.AutoCompleteFrame
    Skin.FrameTypeFrame(AutoCompleteFrame)
    AutoCompleteFrame.BottomLeftBorder:Hide()
    AutoCompleteFrame.BottomRightBorder:Hide()
    AutoCompleteFrame.BottomBorder:Hide()
    AutoCompleteFrame.LeftBorder:Hide()
    AutoCompleteFrame.RightBorder:Hide()

    AutoCompleteFrame.Results[1]:SetPoint("TOPLEFT", AutoCompleteFrame, 1, 0)
    AutoCompleteFrame.Results[1]:SetPoint("TOPRIGHT", AutoCompleteFrame, -1, 0)
    Skin.LFGListSearchAutoCompleteButtonTemplate(AutoCompleteFrame.Results[1])

    do -- RefreshButton
        local RefreshButton = SearchPanel.RefreshButton
        Skin.FrameTypeButton(RefreshButton)
        RefreshButton:SetBackdropOption("offsets", {
            left = 4,
            right = 4,
            top = 5,
            bottom = 5,
        })
    end

    Skin.InsetFrameTemplate(SearchPanel.ResultsInset)
    Skin.WowScrollBoxList(SearchPanel.ScrollBox)
    Skin.UIPanelButtonTemplate(SearchPanel.ScrollBox.StartGroupButton)
    Skin.MinimalScrollBar(SearchPanel.ScrollBar)

    Skin.LFGListMagicButtonTemplate(SearchPanel.BackButton)
    Skin.LFGListMagicButtonTemplate(SearchPanel.SignUpButton)

    -- ApplicationViewer --
    local ApplicationViewer = LFGListFrame.ApplicationViewer
    ApplicationViewer.InfoBackground:SetAlpha(0) -- Don't use Hide() - other elements anchor to this texture's size (useAtlasSize)
    Skin.LFGListGroupDataDisplayTemplate(ApplicationViewer.DataDisplay)
    Skin.UICheckButtonTemplate(ApplicationViewer.AutoAcceptButton) -- BlizzWTF: This doesn't use the template, but it should
    --  /run C_LFGList.CanActiveEntryUseAutoAccept = function() return true end

    Skin.InsetFrameTemplate(ApplicationViewer.Inset)
    Skin.LFGListColumnHeaderTemplate(ApplicationViewer.NameColumnHeader)
    Skin.LFGListColumnHeaderTemplate(ApplicationViewer.RoleColumnHeader)
    Skin.LFGListColumnHeaderTemplate(ApplicationViewer.ItemLevelColumnHeader)

    do -- RefreshButton
        local RefreshButton = ApplicationViewer.RefreshButton
        Skin.FrameTypeButton(RefreshButton)
        RefreshButton:SetBackdropOption("offsets", {
            left = 4,
            right = 4,
            top = 5,
            bottom = 5,
        })
    end

    Skin.WowScrollBoxList(ApplicationViewer.ScrollBox)
    Skin.MinimalScrollBar(ApplicationViewer.ScrollBar)
    Skin.LFGListMagicButtonTemplate(ApplicationViewer.RemoveEntryButton)
    Skin.LFGListMagicButtonTemplate(ApplicationViewer.EditButton)
    Skin.LFGListMagicButtonTemplate(ApplicationViewer.BrowseGroupsButton)

    -- EntryCreation --
    local EntryCreation = LFGListFrame.EntryCreation
    Skin.InsetFrameTemplate(EntryCreation.Inset)
    EntryCreation.Inset.CustomBG:Hide()

    do -- ActivityFinder
        local Dialog = EntryCreation.ActivityFinder.Dialog
        EntryCreation.ActivityFinder.Background:SetAlpha(Color.frame.a)
        EntryCreation.ActivityFinder.Background:SetPoint("TOPLEFT")
        EntryCreation.ActivityFinder.Background:SetPoint("BOTTOMRIGHT")

        Dialog.Bg:Hide()
        Skin.DialogBorderTemplate(Dialog.Border)
        Skin.LFGListEditBoxTemplate(Dialog.EntryBox)
        Skin.WowScrollBoxList(Dialog.ScrollBox)
        Skin.MinimalScrollBar(Dialog.ScrollBar)
        Skin.TooltipBackdropTemplate(Dialog.BorderFrame)
        Skin.UIPanelButtonTemplate(Dialog.SelectButton)
        Skin.UIPanelButtonTemplate(Dialog.CancelButton)
    end

    -- Skin.LFGListEditBoxTemplate(EntryCreation.Name)
    Skin.DropdownButton(EntryCreation.GroupDropdown)
    Skin.DropdownButton(EntryCreation.ActivityDropdown)
    -- Skin.InputScrollFrameTemplate(EntryCreation.Description)
    Skin.DropdownButton(EntryCreation.PlayStyleDropdown)
    -- Skin.LFGListRequirementTemplate(EntryCreation.ItemLevel)
    -- Skin.LFGListRequirementTemplate(EntryCreation.PvpItemLevel)
    -- Skin.LFGListRequirementTemplate(EntryCreation.PVPRating)
    -- Skin.LFGListRequirementTemplate(EntryCreation.MythicPlusRating)
    -- Skin.LFGListRequirementTemplate(EntryCreation.VoiceChat)
    -- Skin.LFGListOptionCheckButtonTemplate(EntryCreation.CrossFactionGroup)
    -- Skin.LFGListOptionCheckButtonTemplate(EntryCreation.PrivateGroup)
    -- Skin.LFGListMagicButtonTemplate(EntryCreation.ListGroupButton)
    -- Skin.LFGListMagicButtonTemplate(EntryCreation.CancelButton)

    ------------------------------
    -- LFGListApplicationDialog --
    ------------------------------
    local LFGListApplicationDialog = _G.LFGListApplicationDialog
    Skin.DialogBorderTemplate(LFGListApplicationDialog.Border)
    Skin.LFGListRoleButtonTemplate(LFGListApplicationDialog.HealerButton)
    Skin.LFGListRoleButtonTemplate(LFGListApplicationDialog.TankButton)
    Skin.LFGListRoleButtonTemplate(LFGListApplicationDialog.DamagerButton)
    Skin.InputScrollFrameTemplate(LFGListApplicationDialog.Description)
    Skin.UIPanelButtonTemplate(LFGListApplicationDialog.SignUpButton)
    Skin.UIPanelButtonTemplate(LFGListApplicationDialog.CancelButton)

    -------------------------
    -- LFGListInviteDialog --
    -------------------------
    _G.hooksecurefunc("LFGListInviteDialog_Show", Hook.LFGListInviteDialog_Show)

    local LFGListInviteDialog = _G.LFGListInviteDialog
    Skin.DialogBorderTemplate(LFGListInviteDialog.Border)
    Skin.UIPanelButtonTemplate(LFGListInviteDialog.AcceptButton)
    Skin.UIPanelButtonTemplate(LFGListInviteDialog.DeclineButton)
    Skin.UIPanelButtonTemplate(LFGListInviteDialog.AcknowledgeButton)
end
