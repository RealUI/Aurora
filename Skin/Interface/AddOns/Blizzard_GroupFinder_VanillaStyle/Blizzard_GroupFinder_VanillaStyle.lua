local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals next ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin

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
    animation (active-queue indicator). Row templates left for iteration.
]]

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
        -- Container chrome only — the EditBox inside is secure (see header)
        if ActivityView.Comment then
            Skin.UIPanelInputScrollFrameTemplate(ActivityView.Comment)
        end
    end
end
