local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals next ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Util = Aurora.Util

--[[ Vanilla-style Group Finder (era-only addon).
    Evidence: wow-ui-source-era/Interface/AddOns/Blizzard_GroupFinder_VanillaStyle/
    Blizzard_LFGVanilla_{ParentFrame,Browse,Listing}.xml — LFGParentFrame is a
    plain 384x512 shell (chrome art lives on the Browse/Listing child panels
    as UI-LFG-FRAME sheets + a groupfinder-background-classic parchment inset);
    two CharacterFrameTab buttons, an unnamed UIPanelCloseButton, the animated
    LFG eye as portrait. Legacy UIDropDownMenu dropdowns; modern
    WowScrollBoxList + WowClassicScrollBar lists.

    NOT touched: the LFGListingComment EditBox (Blizzard secure-references it
    and disables SetText/paste — anti-automation hardening; only its
    UIPanelInputScrollFrameTemplate container is skinned), the role icon
    buttons and gear OptionsButtons (meaningful icon art), and the LFG eye
    animation (active-queue indicator).
]]

--[[ Row templates (deferred in the first pass; added 2026-09-13).

    All three row families are recycled by their container, so each is skinned
    from an update/add hook rather than once at load:
      * Browse results   -- WowScrollBoxList + LFGBrowseSearchEntryTemplate
                            (Blizzard_LFGVanilla_Browse.lua:58-65)
      * Listing rows     -- CreateScrollBoxListTreeListView + LFGListingActivityRowTemplate
                            (Blizzard_LFGVanilla_Listing.lua:741+)
      * Category buttons -- created lazily into CategoryView.CategoryButtons by
                            LFGListingCategorySelection_AddButton (Listing.lua:704-716)

    ScrollBox:ForEachFrame hands the callback `(frame, elementData)` with no
    owner (ScrollBoxListView.lua:152), so these take the frame first.

    Kept, per the "NOT touched" policy above: the party/class/newcomer icons on
    a result row, the Enumerate and Solo role art, and the category icons --
    all of it carries meaning. What gets recoloured is the ADD-blended
    highlight/selected bars, the parts that actually fight the theme; the blend
    reset plus Aurora's highlight colour is the same treatment the classic
    AuctionUI rows use (Blizzard_AuctionUI/Classic/Blizzard_AuctionUI.lua:32-41).
]]
local function SkinHighlight(texture, alpha)
    if not texture then return end
    texture:SetBlendMode("BLEND")
    Util.SetHighlightColor(texture, alpha)
end

local function SkinRoleCount(Frame)
    -- RoleCountNoScriptsTemplate. Skin.RoleCountNoScriptsTemplate is Mainline-only,
    -- so the three swaps are inlined; the parentKeys match the era template at
    -- Blizzard_UIPanelTemplates/Classic/UIPanelTemplates.xml:323. Base.SetTexture
    -- is safe to repeat on a recycled frame (texture.lua tracks what it built).
    if not Frame then return end
    if Frame.TankIcon then Base.SetTexture(Frame.TankIcon, "iconTANK") end
    if Frame.HealerIcon then Base.SetTexture(Frame.HealerIcon, "iconHEALER") end
    if Frame.DamagerIcon then Base.SetTexture(Frame.DamagerIcon, "iconDAMAGER") end
end

local function SkinSearchEntry(Button)
    if not Button or private.IsSkinned(Button) then return end
    private.SetSkinned(Button, true)

    -- groupfinder-highlightbar-yellow / -blue
    SkinHighlight(Button.Selected, 0.5)
    SkinHighlight(Button.Highlight, 0.2)

    if Button.DataDisplay then
        SkinRoleCount(Button.DataDisplay.RoleCount)
    end
end

local function SkinActivityRow(Frame)
    if not Frame or private.IsSkinned(Frame) then return end
    private.SetSkinned(Frame, true)

    -- Raw CheckButton carrying the stock UI-CheckBox-* art, which is what the
    -- classic Skin.UICheckButtonTemplate expects even though the XML does not
    -- inherit the template (Blizzard_LFGVanilla_Listing.xml:168).
    if Frame.CheckButton then
        Skin.UICheckButtonTemplate(Frame.CheckButton)
    end

    -- ExpandOrCollapseButton left alone: Skin.ExpandOrCollapse is Mainline-only
    -- and the stock +/- art stays legible against the dark backdrop, so a
    -- half-port would look worse than none.
end

local function SkinCategoryButton(Button)
    if not Button or private.IsSkinned(Button) then return end
    private.SetSkinned(Button, true)

    if Button.Cover then
        Button.Cover:SetAlpha(0)  -- groupfinder-button-cover gradient over the icon
    end
    SkinHighlight(Button.SelectedTexture, 0.5)
    SkinHighlight(Button.HighlightTexture or Button:GetHighlightTexture(), 0.2)
end

function private.AddOns.Blizzard_GroupFinder_VanillaStyle()
    local LFGParentFrame = _G.LFGParentFrame

    Skin.FrameTypeFrame(LFGParentFrame)
    -- Art bounds of the classic 384x512 sheet (from the frame's HitRectInsets)
    LFGParentFrame:SetBackdropOption("offsets", {
        left = 0,
        right = 30,
        top = 0,
        bottom = 74,
    })

    Skin.CharacterFrameTabButtonTemplate(_G.LFGParentFrameTab1)
    Skin.CharacterFrameTabButtonTemplate(_G.LFGParentFrameTab2)

    -- The close button is the only unnamed direct Button child
    for _, child in next, {LFGParentFrame:GetChildren()} do
        if child:GetObjectType() == "Button" and not child:GetName() then
            Skin.UIPanelCloseButton(child)
        end
    end

    -- Portrait ring behind the animated LFG eye (the eye itself is kept)
    if _G.LFGParentFramePortraitIcon then
        _G.LFGParentFramePortraitIcon:SetAlpha(0)
    end

    ------------
    -- Browse --
    ------------
    local Browse = _G.LFGBrowseFrame
    for _, name in ipairs({"LFGBrowseFrameFrameBackgroundTop", "LFGBrowseFrameFrameBackgroundMiddle", "LFGBrowseFrameFrameBackgroundBottom"}) do
        local texture = _G[name]
        if texture then
            texture:SetTexture("")
        end
    end
    if Browse.BackgroundArt then
        Browse.BackgroundArt:SetAlpha(0)
    end

    -- era: legacy UIDropDownMenus (CategoryDropDown); anniversary 2.5.6:
    -- modern WowStyle1 dropdowns with lowercase-d parentKeys
    if Browse.CategoryDropDown then
        Skin.UIDropDownMenuTemplate(Browse.CategoryDropDown)
        Skin.UIDropDownMenuTemplate(Browse.ActivityDropDown)
    else
        if Browse.CategoryDropdown then
            Skin.DropdownButton(Browse.CategoryDropdown)
        end
        if Browse.ActivityDropdown then
            Skin.DropdownButton(Browse.ActivityDropdown)
        end
    end

    -- Square refresh button: strip the SquareButton states, keep the icon
    local refresh = Browse.RefreshButton
    if refresh then
        refresh:SetNormalTexture("")
        refresh:SetPushedTexture("")
        refresh:SetDisabledTexture("")
        Skin.FrameTypeButton(refresh)
    end

    if Browse.ScrollBar then
        Skin.WowClassicScrollBar(Browse.ScrollBar)
    end
    if Browse.ScrollBox then
        Skin.WowScrollBoxList(Browse.ScrollBox)
        _G.hooksecurefunc(Browse.ScrollBox, "Update", function(self)
            self:ForEachFrame(SkinSearchEntry)
        end)
    end
    if Browse.SendMessageButton then
        Skin.UIPanelButtonTemplate(Browse.SendMessageButton)
    end
    if Browse.GroupInviteButton then
        Skin.UIPanelButtonTemplate(Browse.GroupInviteButton)
    end
    if _G.LFGBrowseSearchEntryTooltip then
        Skin.TooltipBackdropTemplate(_G.LFGBrowseSearchEntryTooltip)
    end

    -------------
    -- Listing --
    -------------
    local Listing = _G.LFGListingFrame
    for _, name in ipairs({"LFGListingFrameFrameBackgroundTop", "LFGListingFrameFrameBackgroundBottom"}) do
        local texture = _G[name]
        if texture then
            texture:SetTexture("")
        end
    end
    if Listing.BackgroundArt then
        Listing.BackgroundArt:SetAlpha(0)
    end

    for _, key in ipairs({"BackButton", "PostButton"}) do
        if Listing[key] then
            Skin.UIPanelButtonTemplate(Listing[key])
        end
    end
    local roleButtons = Listing.GroupRoleButtons
    if roleButtons then
        if roleButtons.RolePollButton then
            Skin.UIPanelButtonTemplate(roleButtons.RolePollButton)
        end
        if roleButtons.RoleDropDown then
            Skin.UIDropDownMenuTemplate(roleButtons.RoleDropDown)
        elseif roleButtons.RoleDropdown then
            Skin.DropdownButton(roleButtons.RoleDropdown)
        end
    end

    local ActivityView = Listing.ActivityView
    if ActivityView then
        for _, key in ipairs({"BarLeft", "BarMiddle", "BarRight"}) do
            if ActivityView[key] then
                ActivityView[key]:SetAlpha(0)
            end
        end
        if ActivityView.ScrollBar then
            Skin.WowClassicScrollBar(ActivityView.ScrollBar)
        end
        if ActivityView.ScrollBox then
            Skin.WowScrollBoxList(ActivityView.ScrollBox)
            _G.hooksecurefunc(ActivityView.ScrollBox, "Update", function(self)
                self:ForEachFrame(SkinActivityRow)
            end)
        end
        -- Container chrome only — the EditBox inside is secure (see header)
        if ActivityView.Comment then
            Skin.UIPanelInputScrollFrameTemplate(ActivityView.Comment)
        end
    end

    -- Category buttons are built on demand, so catch them as they are added and
    -- sweep any that already exist (a no-op at load, a re-skin on reload).
    if _G.LFGListingCategorySelection_AddButton then
        _G.hooksecurefunc("LFGListingCategorySelection_AddButton", function(self, btnIndex)
            local buttons = self and self.CategoryButtons
            if buttons then
                SkinCategoryButton(buttons[btnIndex])
            end
        end)
    end
    local CategoryView = Listing.CategoryView
    if CategoryView and CategoryView.CategoryButtons then
        for _, button in ipairs(CategoryView.CategoryButtons) do
            SkinCategoryButton(button)
        end
    end
end
