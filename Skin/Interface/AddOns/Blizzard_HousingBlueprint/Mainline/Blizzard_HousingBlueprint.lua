local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals _G ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color = Aurora.Color

--[[ 12.1 Blizzard_HousingBlueprint (LoD; hard dependency of
    Blizzard_HouseEditor and Blizzard_HousingDashboard, so it is loaded
    whenever the housing UI is). Four UIPanel dialogs on hand-rolled housing
    chrome (no NineSlice): parentKeys Background (housing-basic-container),
    Header (…-woodheader), HeaderText, CloseButton. The embedded
    HousingBlueprintCollectionTemplate instances live in HouseEditor's
    StoragePanel and the Dashboard Collection tab — those modules call the
    Skin.* functions defined here.
]]

do --[[ Blizzard_SharedXML\ListTemplates.xml ]]
    -- Options_ListExpand_* three-slice header (same shape serves the CDM
    -- group-buff filter sections)
    function Skin.ListHeaderThreeSliceTemplate(Frame)
        if Frame.Left then Frame.Left:SetAlpha(0) end
        if Frame.Middle then Frame.Middle:SetAlpha(0) end
        if Frame.Right then Frame.Right:SetAlpha(0) end
    end
end

do --[[ Blizzard_HousingBlueprintFrameTemplates.xml ]]
    function Skin.HousingBlueprintBaseFrameTemplate(Frame)
        if Frame.Background then Frame.Background:SetAlpha(0) end
        if Frame.Header then Frame.Header:SetAlpha(0) end
        -- These dialogs float over the 3D house with nothing behind them, so
        -- the user frame alpha read as too light; same fixed alpha as
        -- Skin.DialogBorderDarkTemplate.
        Base.SetBackdrop(Frame, Color.frame, 0.87)
        if Frame.CloseButton then
            Skin.UIPanelCloseButton(Frame.CloseButton)
        end
    end

    -- Skin group/entry rows as the ScrollBox materialises them
    local function SkinListRows(ScrollBox)
        Skin.WowScrollBoxList(ScrollBox)
        _G.hooksecurefunc(ScrollBox, "Update", function(self)
            self:ForEachFrame(function(row)
                if not private.IsSkinned(row) then
                    private.SetSkinned(row, true)
                    if row.Header then -- HousingBlueprint*GroupTemplate
                        Skin.ListHeaderThreeSliceTemplate(row.Header)
                    end
                end
            end)
        end)
    end

    -- InputScrollFrameTemplate share-code box: Skin.InputScrollFrameTemplate
    -- only skins the scroll bar, so the rounded Common-Input-Border pieces
    -- stayed. Swap them for a flat input backdrop here rather than in the
    -- shared helper, whose other callers (Communities, LFG) rely on it as is.
    local inputBorderKeys = {
        "TopLeftTex", "TopRightTex", "TopTex", "BottomLeftTex", "BottomRightTex",
        "BottomTex", "LeftTex", "RightTex", "MiddleTex",
    }
    function Skin.HousingBlueprintShareCodeBox(ScrollFrame)
        Skin.InputScrollFrameTemplate(ScrollFrame)
        for _, key in ipairs(inputBorderKeys) do
            if ScrollFrame[key] then ScrollFrame[key]:SetAlpha(0) end
        end
        Base.SetBackdrop(ScrollFrame, Color.frame)
        ScrollFrame:SetBackdropBorderColor(Color.button)
    end

    function Skin.HousingBlueprintContentSummaryTemplate(Frame)
        -- BudgetsContainer keeps its flat innerblackbox art
        if Frame.ContentsListButton then
            Skin.UIPanelButtonTemplate(Frame.ContentsListButton)
        end
    end

    function Skin.HousingBlueprintCollectionTemplate(Frame)
        if Frame.Divider then Frame.Divider:SetAlpha(0) end
        if Frame.ScrollBox then SkinListRows(Frame.ScrollBox) end
        if Frame.ScrollBar then Skin.MinimalScrollBar(Frame.ScrollBar) end
        -- ResetButton keeps its undo-icon art (functional)
    end

    Skin.HousingBlueprintSkinListRows = SkinListRows
end

function private.AddOns.Blizzard_HousingBlueprint()
    local export = _G.HousingBlueprintExportFrame
    if export then
        Skin.HousingBlueprintBaseFrameTemplate(export)
        local input = export.InputContent
        if input then
            if input.TypeDropdown then Skin.DropdownButton(input.TypeDropdown) end
            if input.NameInputBox then Skin.InputBoxInstructionsTemplate(input.NameInputBox) end
            if input.SaveButton then Skin.UIPanelDynamicResizeButtonTemplate(input.SaveButton) end
        end
        local success = export.SuccessContent
        if success then
            if success.BlueprintsCollectionButton then
                Skin.UIPanelDynamicResizeButtonTemplate(success.BlueprintsCollectionButton)
            end
            if success.ShareCodeBox then Skin.HousingBlueprintShareCodeBox(success.ShareCodeBox) end
            if success.ChatLinkButton then Skin.UIPanelButtonTemplate(success.ChatLinkButton) end
            if success.ClipboardButton then Skin.UIPanelButtonTemplate(success.ClipboardButton) end
        end
    end

    local import = _G.HousingBlueprintImportFrame
    if import then
        Skin.HousingBlueprintBaseFrameTemplate(import)
        local input = import.InputContent
        if input then
            if input.ShareCodeBox then Skin.HousingBlueprintShareCodeBox(input.ShareCodeBox) end
            if input.NextButton then Skin.UIPanelDynamicResizeButtonTemplate(input.NextButton) end
            if input.GearDropdown then Skin.DropdownButton(input.GearDropdown) end
        end
        local validation = import.ValidationContent
        if validation then
            if validation.ContentSummary then
                Skin.HousingBlueprintContentSummaryTemplate(validation.ContentSummary)
            end
            if validation.GearDropdown then Skin.DropdownButton(validation.GearDropdown) end
            if validation.ImportButton then Skin.UIPanelDynamicResizeButtonTemplate(validation.ImportButton) end
        end
    end

    local contentList = _G.HousingBlueprintContentListFrame
    if contentList then
        Skin.HousingBlueprintBaseFrameTemplate(contentList)
        if contentList.MissingOnlyCheckbox and contentList.MissingOnlyCheckbox.Checkbox then
            Skin.UICheckButtonTemplate(contentList.MissingOnlyCheckbox.Checkbox)
        end
        if contentList.ScrollBox then Skin.HousingBlueprintSkinListRows(contentList.ScrollBox) end
        if contentList.ScrollBar then Skin.MinimalScrollBar(contentList.ScrollBar) end
        if contentList.BottomCloseButton then
            Skin.UIPanelDynamicResizeButtonTemplate(contentList.BottomCloseButton)
        end
        -- ScrollBackground (innerblackbox atlas) is already flat — kept
    end

    local rename = _G.HousingBlueprintRenameFrame
    if rename then
        Skin.HousingBlueprintBaseFrameTemplate(rename)
        if rename.NameInputBox then Skin.InputBoxInstructionsTemplate(rename.NameInputBox) end
        if rename.SaveButton then Skin.UIPanelDynamicResizeButtonTemplate(rename.SaveButton) end
    end
end
