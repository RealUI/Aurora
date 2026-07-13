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
    Browse.BackgroundArt:SetAlpha(0)

    Skin.UIDropDownMenuTemplate(Browse.CategoryDropDown)
    Skin.UIDropDownMenuTemplate(Browse.ActivityDropDown)

    -- Square refresh button: strip the SquareButton states, keep the icon
    local refresh = Browse.RefreshButton
    refresh:SetNormalTexture("")
    refresh:SetPushedTexture("")
    refresh:SetDisabledTexture("")
    Skin.FrameTypeButton(refresh)

    Skin.WowClassicScrollBar(Browse.ScrollBar)
    Skin.UIPanelButtonTemplate(Browse.SendMessageButton)
    Skin.UIPanelButtonTemplate(Browse.GroupInviteButton)
    Skin.TooltipBackdropTemplate(_G.LFGBrowseSearchEntryTooltip)

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
    Listing.BackgroundArt:SetAlpha(0)

    Skin.UIPanelButtonTemplate(Listing.BackButton)
    Skin.UIPanelButtonTemplate(Listing.PostButton)
    Skin.UIPanelButtonTemplate(Listing.GroupRoleButtons.RolePollButton)
    Skin.UIDropDownMenuTemplate(Listing.GroupRoleButtons.RoleDropDown)

    local ActivityView = Listing.ActivityView
    ActivityView.BarLeft:SetAlpha(0)
    ActivityView.BarMiddle:SetAlpha(0)
    ActivityView.BarRight:SetAlpha(0)
    Skin.WowClassicScrollBar(ActivityView.ScrollBar)
    -- Container chrome only — the EditBox inside is secure (see header)
    Skin.UIPanelInputScrollFrameTemplate(ActivityView.Comment)
end
