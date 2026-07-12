local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals CreateFrame

--[[ Core ]]
local Aurora = private.Aurora
local Base, Hook, Skin = Aurora.Base, Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

do --[[ AddOns\Blizzard_Professions ]]
    function Skin.ProfessionsFrameTabTemplate(Button)
        Skin.PanelTabButtonTemplate(Button)
        Button._auroraTabResize = true
    end

    function Skin.NumericInputSpinnerTemplate(EditBox)
        if EditBox.Left then EditBox.Left:Hide() end
        if EditBox.Middle then EditBox.Middle:Hide() end
        if EditBox.Right then EditBox.Right:Hide() end
        Base.SetBackdrop(EditBox, Color.frame, Color.frame.a)
        if EditBox.DecrementButton then Skin.NavButtonPrevious(EditBox.DecrementButton) end
        if EditBox.IncrementButton then Skin.NavButtonNext(EditBox.IncrementButton) end
    end

    function Skin.ProfessionsButtonTemplate(Button)
        if Button.SlotBackground then Button.SlotBackground:SetAlpha(0) end
        if Button.IconBorder then Button.IconBorder:Hide() end
        Button:ClearNormalTexture()
        Base.SetBackdrop(Button, Color.black, Color.frame.a)
        Button._auroraIconBorder = Button
        if Button.Icon then Base.CropIcon(Button.Icon) end
    end

    Hook.ProfessionsRecipeListCategoryMixin = {}
    function Hook.ProfessionsRecipeListCategoryMixin:Init(node)
        if not self._auroraSkinned then
            if self.LeftPiece then self.LeftPiece:SetAlpha(0) end
            if self.RightPiece then self.RightPiece:SetAlpha(0) end
            if self.CenterPiece then self.CenterPiece:SetAlpha(0) end
            self._auroraSkinned = true
        end
    end

    Hook.ProfessionsReagentSlotButtonMixin = {}
    function Hook.ProfessionsReagentSlotButtonMixin:Init()
        Util.SkinOnce(self, Skin.ProfessionsButtonTemplate)
    end

    Hook.ProfessionsButtonMixin = {}
    function Hook.ProfessionsButtonMixin:SetSlotQuality(quality)
        if self._auroraIconBorder then
            if self.IconBorder then self.IconBorder:Hide() end
            Hook.SetItemButtonQuality(self, quality)
        end
    end
end

function private.AddOns.Blizzard_Professions()
    local ProfessionsFrame = _G.ProfessionsFrame

    Skin.PortraitFrameTemplateNoCloseButton(ProfessionsFrame)

    if ProfessionsFrame.Bg then
        ProfessionsFrame.Bg:SetColorTexture(Color.panelBg:GetRGB())
        ProfessionsFrame.Bg:SetAllPoints(ProfessionsFrame.NineSlice)
        ProfessionsFrame.Bg:Show()
    end

    Skin.UIPanelCloseButton(ProfessionsFrame.CloseButton)
    Skin.MaximizeMinimizeButtonFrameTemplate(ProfessionsFrame.MaximizeMinimize)

    for i = 1, 3 do
        local tab = select(i, ProfessionsFrame.TabSystem:GetChildren())
        if tab then
            Skin.ProfessionsFrameTabTemplate(tab)
        end
    end

    -- CraftingPage (Recipes tab) -----------------------------------------
    local CraftingPage = ProfessionsFrame.CraftingPage

    if not CraftingPage._auroraBackground then
        local bg = CraftingPage:CreateTexture(nil, "BACKGROUND", nil, -8)
        bg:SetColorTexture(Color.panelBg:GetRGB())
        bg:SetAllPoints(CraftingPage)
        CraftingPage._auroraBackground = bg
    end

    if CraftingPage.TutorialButton then
        CraftingPage.TutorialButton:Hide()
    end

    local RecipeList = CraftingPage.RecipeList
    if RecipeList then
        if RecipeList.Background then RecipeList.Background:SetAlpha(0) end
        Skin.SearchBoxTemplate(RecipeList.SearchBox)
        Skin.DropdownButton(RecipeList.FilterDropdown)
    end

    Util.Mixin(_G.ProfessionsRecipeListCategoryMixin, Hook.ProfessionsRecipeListCategoryMixin)

    if CraftingPage.MinimizedSearchBox then
        Skin.SearchBoxTemplate(CraftingPage.MinimizedSearchBox)
    end

    local SchematicForm = CraftingPage.SchematicForm
    if SchematicForm then
        local function HideSchematicBg(self)
            if self.Background then self.Background:SetAlpha(0) end
            if self.MinimalBackground then self.MinimalBackground:SetAlpha(0) end
            if self.NineSlice then
                for _, region in pairs({self.NineSlice:GetRegions()}) do
                    if region:IsObjectType("Texture") then region:SetAlpha(0) end
                end
            end
            local Details = self.Details
            if Details then
                if Details.BackgroundTop then Details.BackgroundTop:SetAlpha(0) end
                if Details.BackgroundBottom then Details.BackgroundBottom:SetAlpha(0) end
                if Details.BackgroundMiddle then Details.BackgroundMiddle:SetAlpha(0) end
                if Details.BackgroundMinimized then Details.BackgroundMinimized:SetAlpha(0) end
            end
        end
        HideSchematicBg(SchematicForm)
        SchematicForm:HookScript("OnShow", HideSchematicBg)
        if _G.ProfessionsRecipeSchematicFormMixin then
            _G.hooksecurefunc(_G.ProfessionsRecipeSchematicFormMixin, "Init", HideSchematicBg)
        end
        if _G.ProfessionsRecipeCrafterDetailsMixin then
            _G.hooksecurefunc(_G.ProfessionsRecipeCrafterDetailsMixin, "SetStats", function(self)
                if self.BackgroundTop then self.BackgroundTop:SetAlpha(0) end
                if self.BackgroundBottom then self.BackgroundBottom:SetAlpha(0) end
                if self.BackgroundMiddle then self.BackgroundMiddle:SetAlpha(0) end
                if self.BackgroundMinimized then self.BackgroundMinimized:SetAlpha(0) end
            end)
        else
            local frame = CreateFrame("Frame")
            frame:RegisterEvent("ADDON_LOADED")
            frame:SetScript("OnEvent", function(f, _, name)
                if name == "Blizzard_ProfessionsTemplates" and _G.ProfessionsRecipeCrafterDetailsMixin then
                    _G.hooksecurefunc(_G.ProfessionsRecipeCrafterDetailsMixin, "SetStats", function(self)
                        if self.BackgroundTop then self.BackgroundTop:SetAlpha(0) end
                        if self.BackgroundBottom then self.BackgroundBottom:SetAlpha(0) end
                        if self.BackgroundMiddle then self.BackgroundMiddle:SetAlpha(0) end
                        if self.BackgroundMinimized then self.BackgroundMinimized:SetAlpha(0) end
                    end)
                    f:UnregisterEvent("ADDON_LOADED")
                end
            end)
        end

        if SchematicForm.OutputIcon then
            Skin.CircularGiantItemButtonTemplate(SchematicForm.OutputIcon)
        end

        if SchematicForm.TrackRecipeCheckbox then
            Skin.UICheckButtonTemplate(SchematicForm.TrackRecipeCheckbox)
        end
        if SchematicForm.AllocateBestQualityCheckbox then
            Skin.UICheckButtonTemplate(SchematicForm.AllocateBestQualityCheckbox)
        end

        local Details = SchematicForm.Details
        if Details then
            local CraftingChoices = Details.CraftingChoicesContainer
            local ConcentrateContainer = CraftingChoices and CraftingChoices.ConcentrateContainer
            if ConcentrateContainer and ConcentrateContainer.ConcentrateToggleButton then
                local Btn = ConcentrateContainer.ConcentrateToggleButton
                Btn:ClearNormalTexture()
                Btn:ClearPushedTexture()
                Btn:ClearHighlightTexture()
                if Btn.CheckedTexture then Btn.CheckedTexture:SetAlpha(0) end
                if Btn.DisabledTexture then Btn.DisabledTexture:SetAlpha(0) end
                Base.SetBackdrop(Btn, Color.black, Color.frame.a)
                Btn._auroraIconBorder = Btn
                if Btn.Icon then Base.CropIcon(Btn.Icon) end
            end
        end
    end

    Util.Mixin(_G.ProfessionsReagentSlotButtonMixin, Hook.ProfessionsReagentSlotButtonMixin)
    Util.Mixin(_G.ProfessionsButtonMixin, Hook.ProfessionsButtonMixin)

    Skin.UIPanelButtonTemplate(CraftingPage.CreateButton)
    Skin.UIPanelButtonTemplate(CraftingPage.CreateAllButton)
    if CraftingPage.ViewGuildCraftersButton then
        Skin.UIPanelButtonTemplate(CraftingPage.ViewGuildCraftersButton)
    end

    if CraftingPage.CreateMultipleInputBox then
        Skin.NumericInputSpinnerTemplate(CraftingPage.CreateMultipleInputBox)
    end

    if CraftingPage.InventorySlots then
        for _, slot in ipairs(CraftingPage.InventorySlots) do
            Skin.FrameTypeItemButton(slot)
        end
    end

    if CraftingPage.LinkButton then
        local btn = CraftingPage.LinkButton
        btn:SetSize(19, 19)
        btn:ClearNormalTexture()
        btn:ClearPushedTexture()
        if btn.Texture then btn.Texture:Hide() end
        Base.SetBackdrop(btn, Color.button)
        btn:ClearAllPoints()
        btn:SetPoint("LEFT", CraftingPage.RankBar, "RIGHT", 0, -3)
        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetTexture([[Interface\Buttons\UI-LinkProfession-Up]])
        icon:SetTexCoord(.35, .65, .35, .65)
        icon:SetSize(8, 8)
        icon:SetPoint("CENTER")
        local pushedIcon = btn:CreateTexture(nil, "ARTWORK")
        pushedIcon:SetTexture([[Interface\Buttons\UI-LinkProfession-Down]])
        pushedIcon:SetTexCoord(.35, .65, .35, .65)
        pushedIcon:SetSize(8, 8)
        pushedIcon:SetPoint("CENTER")
        pushedIcon:Hide()
        btn:HookScript("OnMouseDown", function() icon:Hide(); pushedIcon:Show() end)
        btn:HookScript("OnMouseUp",   function() pushedIcon:Hide(); icon:Show() end)
    end

    local RankBar = CraftingPage.RankBar
    if RankBar then
        if RankBar.Background then RankBar.Background:SetAlpha(0) end
        if RankBar.Border then RankBar.Border:SetAlpha(0) end
        local dropdown = RankBar.ExpansionDropdownButton
        if dropdown then
            Skin.DropdownButton(dropdown)
            dropdown:SetFrameStrata("HIGH")
            dropdown:SetFrameLevel(5)
        end

        if RankBar.Rank then
            RankBar.Rank:SetFrameStrata("HIGH")
            RankBar.Rank:SetFrameLevel(10)
        end

        if RankBar.Fill then RankBar.Fill:Hide() end
        if RankBar.Flare then RankBar.Flare:Hide() end

        local bar = CreateFrame("Frame", nil, RankBar)
        bar:SetFrameStrata("HIGH")
        bar:SetFrameLevel(1)
        bar:SetPoint("TOPLEFT",     RankBar, "TOPLEFT",     0,  -3)
        bar:SetPoint("BOTTOMRIGHT", RankBar, "BOTTOMRIGHT", -31, -4)

        local bg = bar:CreateTexture(nil, "BACKGROUND", nil, -1)
        bg:SetColorTexture(Color.black:GetRGBA())
        bg:SetAllPoints(bar)

        local r, g, b = Color.blue:GetRGB()
        local fill = bar:CreateTexture(nil, "BACKGROUND", nil, 0)
        fill:SetColorTexture(r, g, b, 1)
        fill:SetPoint("TOPLEFT")
        fill:SetPoint("BOTTOMLEFT")

        RankBar._auroraBar = {container = bar, fill = fill}

        _G.hooksecurefunc(RankBar, "Update", function(self, professionInfo)
            if self.Fill then self.Fill:Hide() end
            if self.Flare then self.Flare:Hide() end

            local ratio = 0
            if professionInfo.maxSkillLevel > 0 then
                ratio = math.min(professionInfo.skillLevel / professionInfo.maxSkillLevel, 1)
            end
            local a = self._auroraBar
            local w = a.container:GetWidth()
            if w == 0 then w = self:GetWidth() - 2 end
            if ratio > 0 and w > 0 then
                a.fill:SetWidth(w * ratio)
                a.fill:Show()
            else
                a.fill:Hide()
            end
        end)
    end

    -- SpecPage -----------------------------------------------------------
    local SpecPage = ProfessionsFrame.SpecPage

    if not SpecPage._auroraBackground then
        local bg = SpecPage:CreateTexture(nil, "BACKGROUND", nil, -8)
        bg:SetColorTexture(Color.panelBg:GetRGB())
        bg:SetAllPoints(SpecPage)
        SpecPage._auroraBackground = bg
    end

    if SpecPage.Background then SpecPage.Background:SetAlpha(0) end
    if SpecPage.BlackBG then SpecPage.BlackBG:Hide() end

    if SpecPage.PanelFooter then
        for _, region in pairs({SpecPage.PanelFooter:GetRegions()}) do
            if region:IsObjectType("Texture") then
                region:SetAlpha(0)
            end
        end
    end

    local function SkinSpecTab(tab)
        if tab._auroraSkinned then return end
        tab._auroraSkinned = true
        Skin.TabSystemButtonTemplate(tab)
        if tab.BottomBorderGlow then tab.BottomBorderGlow:SetAlpha(0) end
    end
    if SpecPage.ButtonsParent then
        for _, child in ipairs({SpecPage.ButtonsParent:GetChildren()}) do
            if child.Left and child.LeftActive then
                SkinSpecTab(child)
            end
        end
    end
    if _G.ProfessionSpecTabMixin then
        _G.hooksecurefunc(_G.ProfessionSpecTabMixin, "OnLoad", SkinSpecTab)
    end

    if SpecPage.UndoButton then Skin.SquareIconButtonTemplate(SpecPage.UndoButton) end

    local TreeView = SpecPage.TreeView
    if TreeView and TreeView.Background then TreeView.Background:SetAlpha(0) end

    local TreePreview = SpecPage.TreePreview
    if TreePreview and TreePreview.Background then
        TreePreview.Background:SetColorTexture(Color.panelBg:GetRGB())
    end

    local DetailedView = SpecPage.DetailedView
    if DetailedView then
        if DetailedView.Background then DetailedView.Background:SetAlpha(0) end
        if DetailedView.SpendPointsButton then
            Skin.UIPanelButtonTemplate(DetailedView.SpendPointsButton)
        end
        if DetailedView.UnlockPathButton then
            Skin.UIPanelButtonTemplate(DetailedView.UnlockPathButton)
        end
    end

    if SpecPage.UnspentPoints and SpecPage.UnspentPoints.CurrencyBackground then
        SpecPage.UnspentPoints.CurrencyBackground:SetAlpha(0)
    end

    for _, divider in ipairs({SpecPage.VerticalDivider, SpecPage.TopDivider}) do
        if divider then
            for _, region in pairs({divider:GetRegions()}) do
                if region:IsObjectType("Texture") then region:SetAlpha(0) end
            end
        end
    end

    if SpecPage.ApplyButton then Skin.UIPanelButtonTemplate(SpecPage.ApplyButton) end
    if SpecPage.UnlockTabButton then Skin.UIPanelButtonTemplate(SpecPage.UnlockTabButton) end
    if SpecPage.ViewTreeButton then Skin.UIPanelButtonTemplate(SpecPage.ViewTreeButton) end
    if SpecPage.BackToPreviewButton then Skin.UIPanelButtonTemplate(SpecPage.BackToPreviewButton) end
    if SpecPage.ViewPreviewButton then Skin.UIPanelButtonTemplate(SpecPage.ViewPreviewButton) end
    if SpecPage.BackToFullTreeButton then Skin.UIPanelButtonTemplate(SpecPage.BackToFullTreeButton) end

    if SpecPage.UpdateSpecBackground then
        _G.hooksecurefunc(SpecPage, "UpdateSpecBackground", function(self)
            if self.Background then self.Background:SetAlpha(0) end
            if self.BlackBG then self.BlackBG:Hide() end
        end)
    end

    -- OrdersPage ---------------------------------------------------------
    local OrdersPage = ProfessionsFrame.OrdersPage

    if not OrdersPage._auroraBackground then
        local bg = OrdersPage:CreateTexture(nil, "BACKGROUND", nil, -8)
        bg:SetColorTexture(Color.panelBg:GetRGB())
        bg:SetAllPoints(OrdersPage)
        OrdersPage._auroraBackground = bg
    end

    local BrowseFrame = OrdersPage.BrowseFrame
    if BrowseFrame then
        local BrowseRecipeList = BrowseFrame.RecipeList
        if BrowseRecipeList then
            if BrowseRecipeList.Background then BrowseRecipeList.Background:SetAlpha(0) end
            if BrowseRecipeList.SearchBox then Skin.SearchBoxTemplate(BrowseRecipeList.SearchBox) end
            if BrowseRecipeList.CollapseAllButton then
                Skin.UIPanelButtonTemplate(BrowseRecipeList.CollapseAllButton)
            end
            if BrowseRecipeList.FilterDropdown then
                Skin.DropdownButton(BrowseRecipeList.FilterDropdown)
            end
        end

        if BrowseFrame.FavoritesSearchButton then
            Skin.SquareIconButtonTemplate(BrowseFrame.FavoritesSearchButton)
        end

        if BrowseFrame.SearchButton then Skin.UIPanelButtonTemplate(BrowseFrame.SearchButton) end
        if BrowseFrame.BackButton then Skin.UIPanelButtonTemplate(BrowseFrame.BackButton) end

        local function HideOrderTypeTabLayers(tab)
            if tab.Glow then tab.Glow:SetAlpha(0) end
            if tab.LeftActive then tab.LeftActive:SetAlpha(0) end
            if tab.MiddleActive then tab.MiddleActive:SetAlpha(0) end
            if tab.RightActive then tab.RightActive:SetAlpha(0) end
            if tab.LeftHighlight then tab.LeftHighlight:SetAlpha(0) end
            if tab.MiddleHighlight then tab.MiddleHighlight:SetAlpha(0) end
            if tab.RightHighlight then tab.RightHighlight:SetAlpha(0) end
        end

        local function SkinOrderTypeTab(tab)
            if not tab._auroraSkinned then
                tab._auroraSkinned = true
                Skin.TabSystemButtonTemplate(tab)

                -- Store Aurora's intended size for CraftSim resilience
                tab._auroraTabWidth, tab._auroraTabHeight = tab:GetSize()

                -- Clamp back if another addon oversizes the tab (>150% of Aurora's values)
                _G.hooksecurefunc(tab, "SetSize", function(self, newW, newH)
                    if self._auroraTabWidth and (newW > self._auroraTabWidth * 1.5 or newH > self._auroraTabHeight * 1.5) then
                        self:SetSize(self._auroraTabWidth, self._auroraTabHeight)
                    end
                end)

                if tab.SetTabSelected then
                    _G.hooksecurefunc(tab, "SetTabSelected", HideOrderTypeTabLayers)
                end
            end

            HideOrderTypeTabLayers(tab)
        end
        for _, tab in ipairs({
            BrowseFrame.PublicOrdersButton,
            BrowseFrame.GuildOrdersButton,
            BrowseFrame.NpcOrdersButton,
            BrowseFrame.PersonalOrdersButton,
        }) do
            if tab then SkinOrderTypeTab(tab) end
        end
        if BrowseFrame.orderTypeTabs then
            for _, tab in ipairs(BrowseFrame.orderTypeTabs) do
                SkinOrderTypeTab(tab)
            end
        end

        -- OrderList area
        local OrderList = BrowseFrame.OrderList
        if OrderList then
            if OrderList.Background then OrderList.Background:SetAlpha(0) end
            if OrderList.NineSlice then
                for _, region in pairs({OrderList.NineSlice:GetRegions()}) do
                    if region:IsObjectType("Texture") then region:SetAlpha(0) end
                end
            end
        end

        local ORD = BrowseFrame.OrdersRemainingDisplay
        if ORD then
            if ORD.Background then ORD.Background:SetAlpha(0) end
            Base.SetBackdrop(ORD, Color.frame)
        end
    end

    local OrderView = OrdersPage.OrderView
    if OrderView then
        local OrderInfo = OrderView.OrderInfo
        if OrderInfo then
            if OrderInfo.Background then OrderInfo.Background:SetAlpha(0) end
            if OrderInfo.NineSlice then
                for _, region in pairs({OrderInfo.NineSlice:GetRegions()}) do
                    if region:IsObjectType("Texture") then region:SetAlpha(0) end
                end
            end
            if OrderInfo.CutDivider then OrderInfo.CutDivider:SetAlpha(0) end

            local NoteBox = OrderInfo.NoteBox
            if NoteBox and NoteBox.Background and NoteBox.Background.Border then
                NoteBox.Background.Border:SetAlpha(0)
            end

            local NPCRewardsFrame = OrderInfo.NPCRewardsFrame
            if NPCRewardsFrame and NPCRewardsFrame.Background then
                NPCRewardsFrame.Background:SetAlpha(0)
            end

            if OrderInfo.SocialDropdown then
                Base.SetBackdrop(OrderInfo.SocialDropdown, Color.button)
            end

            if OrderInfo.BackButton then Skin.UIPanelButtonTemplate(OrderInfo.BackButton) end
            if OrderInfo.StartOrderButton then Skin.UIPanelButtonTemplate(OrderInfo.StartOrderButton) end
            if OrderInfo.DeclineOrderButton then Skin.UIPanelButtonTemplate(OrderInfo.DeclineOrderButton) end
            if OrderInfo.ReleaseOrderButton then Skin.UIPanelButtonTemplate(OrderInfo.ReleaseOrderButton) end
        end

        local OrderDetails = OrderView.OrderDetails
        if OrderDetails then
            if OrderDetails.Background then OrderDetails.Background:SetAlpha(0) end
            if OrderDetails.NineSlice then
                for _, region in pairs({OrderDetails.NineSlice:GetRegions()}) do
                    if region:IsObjectType("Texture") then region:SetAlpha(0) end
                end
            end
            local FulfillmentForm = OrderDetails.FulfillmentForm
            if FulfillmentForm then
                local NoteEditBox = FulfillmentForm.NoteEditBox
                if NoteEditBox and NoteEditBox.Border then
                    NoteEditBox.Border:SetAlpha(0)
                end
            end
        end

        local OVRankBar = OrderView.RankBar
        if OVRankBar then
            if OVRankBar.Background then OVRankBar.Background:SetAlpha(0) end
            if OVRankBar.Border then OVRankBar.Border:SetAlpha(0) end
            local ovDropdown = OVRankBar.ExpansionDropdownButton
            if ovDropdown then
                Skin.DropdownButton(ovDropdown)
                ovDropdown:SetFrameStrata("HIGH")
                ovDropdown:SetFrameLevel(5)
            end
            if OVRankBar.Rank then
                OVRankBar.Rank:SetFrameStrata("HIGH")
                OVRankBar.Rank:SetFrameLevel(10)
            end
            if OVRankBar.Fill then OVRankBar.Fill:Hide() end
            if OVRankBar.Flare then OVRankBar.Flare:Hide() end

            local ovBar = CreateFrame("Frame", nil, OVRankBar)
            ovBar:SetFrameStrata("HIGH")
            ovBar:SetFrameLevel(1)
            ovBar:SetPoint("TOPLEFT",     OVRankBar, "TOPLEFT",     0,  -3)
            ovBar:SetPoint("BOTTOMRIGHT", OVRankBar, "BOTTOMRIGHT", -31, -4)
            local ovBg = ovBar:CreateTexture(nil, "BACKGROUND", nil, -1)
            ovBg:SetColorTexture(Color.black:GetRGBA())
            ovBg:SetAllPoints(ovBar)
            local r, g, b = Color.blue:GetRGB()
            local ovFill = ovBar:CreateTexture(nil, "BACKGROUND", nil, 0)
            ovFill:SetColorTexture(r, g, b, 1)
            ovFill:SetPoint("TOPLEFT")
            ovFill:SetPoint("BOTTOMLEFT")
            OVRankBar._auroraBar = {container = ovBar, fill = ovFill}

            _G.hooksecurefunc(OVRankBar, "Update", function(self, professionInfo)
                if self.Fill then self.Fill:Hide() end
                if self.Flare then self.Flare:Hide() end
                local ratio = 0
                if professionInfo.maxSkillLevel > 0 then
                    ratio = math.min(professionInfo.skillLevel / professionInfo.maxSkillLevel, 1)
                end
                local a = self._auroraBar
                local w = a.container:GetWidth()
                if w == 0 then w = self:GetWidth() - 2 end
                if ratio > 0 and w > 0 then
                    a.fill:SetWidth(w * ratio)
                    a.fill:Show()
                else
                    a.fill:Hide()
                end
            end)
        end

        if OrderView.CreateButton then Skin.UIPanelButtonTemplate(OrderView.CreateButton) end
        if OrderView.CompleteOrderButton then Skin.UIPanelButtonTemplate(OrderView.CompleteOrderButton) end
        if OrderView.StartRecraftButton then Skin.UIPanelButtonTemplate(OrderView.StartRecraftButton) end
        if OrderView.StopRecraftButton then Skin.UIPanelButtonTemplate(OrderView.StopRecraftButton) end

        local DeclineOrderDialog = OrderView.DeclineOrderDialog
        if DeclineOrderDialog then
            if DeclineOrderDialog.Background then DeclineOrderDialog.Background:SetAlpha(0) end
            local DODNote = DeclineOrderDialog.NoteEditBox
            if DODNote and DODNote.Border then DODNote.Border:SetAlpha(0) end
            if DeclineOrderDialog.CancelButton then
                Skin.UIPanelButtonTemplate(DeclineOrderDialog.CancelButton)
            end
            if DeclineOrderDialog.ConfirmButton then
                Skin.UIPanelButtonTemplate(DeclineOrderDialog.ConfirmButton)
            end
        end
    end

    if _G.ProfessionsCraftingOrderPageMixin then
        _G.hooksecurefunc(_G.ProfessionsCraftingOrderPageMixin, "Refresh", function(self)
            local bg = self.OrderView and self.OrderView.OrderDetails and self.OrderView.OrderDetails.Background
            if bg then bg:SetAlpha(0) end
        end)
    end
end
