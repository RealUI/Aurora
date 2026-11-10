local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals _G

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

--[[ 12.1 Blizzard_SocialUIShared: shared templates for the Social UI hub
    (SocialUISharedTemplates.xml). This file only defines Skin.* functions —
    the Blizzard_SocialUI module applies them to SocialUIFrame's content
    frames; each tab's list rows come from the per-feature addons
    (FriendsFrame/RecentAllies/QuickJoin/RecruitAFriend/RaidFrame).
    NOTE: this surface churned in the late 12.1 PTR window — everything is
    nil-guarded so template drift degrades to stock, not errors.
]]

do --[[ SocialUISharedTemplates.xml ]]
    function Skin.SocialUISearchBoxTemplate(Frame)
        Skin.SearchBoxNineSliceTemplate(Frame)
    end

    function Skin.SocialUIFilterBarTemplate(Frame)
        if Frame.SearchFilterDropdown then
            Skin.FilterButton(Frame.SearchFilterDropdown)
        end
        if Frame.SearchBar then
            Skin.SocialUISearchBoxTemplate(Frame.SearchBar)
        end
    end

    function Skin.SocialUIScrollableHeaderTemplate(Frame)
        -- B223: the brown bar is ListHeaderVisualTemplate's NormalTexture, not
        -- a Left/Middle/Right three-slice (none exist on this template).
        Skin.ListHeaderVisualTemplate(Frame)
    end

    function Skin.SocialUIActionButtonTemplate(Button)
        -- SharedButtonTemplate with the 128-RedButton art kit.
        -- B223: ThreeSliceButtonMixin re-sets the three slices on every state
        -- change, so hiding them once left "Add New Friend" red on Forever.
        -- The shared skin hooks UpdateButton and clears them each time.
        if Skin.SharedButtonTemplate then
            Skin.SharedButtonTemplate(Button)
            return
        end
        if Button.Left then Button.Left:SetAlpha(0) end
        if Button.Center then Button.Center:SetAlpha(0) end
        if Button.Right then Button.Right:SetAlpha(0) end
        Skin.FrameTypeButton(Button)
    end

    function Skin.SocialCardActionButtonTemplate(Button)
        -- hand-rolled 34x34 square button (common-button-tertiary-square-*)
        Button:SetNormalTexture("")
        Button:SetPushedTexture("")
        -- B223: the square art is a parentKey'd region; blank it directly so
        -- FrameTypeButton's Clear* path cannot leave the atlas drawn.
        if Button.NormalTexture then Button.NormalTexture:SetTexture("") end
        if Button.PushedTexture then Button.PushedTexture:SetTexture("") end
        Skin.FrameTypeButton(Button)
        local highlight = Button:GetHighlightTexture()
        if highlight then
            highlight:SetColorTexture(Color.highlight.r, Color.highlight.g, Color.highlight.b, 0.2)
        end
    end

    -- B223: the card templates (FriendsList, FriendRequests, RecentAllies,
    -- RecruitAFriend) pick one of three gradient atlases for Background on
    -- every initialise. Swap each for a flat tint in Blizzard's own friends
    -- palette, the one the classic list rows use.
    local cardColors = {
        ["friends-card-battleNet"] = "FRIENDS_BNET_BACKGROUND_COLOR",
        ["friends-card-default"] = "FRIENDS_WOW_BACKGROUND_COLOR",
        ["friends-card-disabled"] = "FRIENDS_OFFLINE_BACKGROUND_COLOR",
    }
    local CARD_ALPHA = 0.15
    local skinnedRows = _G.setmetatable({}, {__mode = "k"})
    local function SkinContactsRow(row)
        -- In place only (Background is Blizzard's own region): no new
        -- textures or geometry on the pooled rows.
        local bg = row.Background
        local atlas = bg and bg.GetAtlas and bg:GetAtlas()
        local color = atlas and _G[cardColors[atlas] or ""]
        if color then
            bg:SetColorTexture(color.r, color.g, color.b, CARD_ALPHA)
        end

        if skinnedRows[row] then return end
        skinnedRows[row] = true

        if row.ButtonText and row.CollapseButton then
            -- SocialUIScrollableHeaderTemplate row
            Skin.SocialUIScrollableHeaderTemplate(row)
        end
        if color then
            -- friends-card-selected (ADD) serves hover and the locked selection
            local highlight = row:GetHighlightTexture()
            if highlight then
                Util.SetHighlightColor(highlight, 0.25)
                highlight:SetBlendMode("BLEND")
            end
        end
        if row.AcceptButton then -- FriendRequests card
            Skin.SocialUIActionButtonTemplate(row.AcceptButton)
        end
        if row.PartyButton then -- Friends/RecentAllies card
            Skin.SocialCardActionButtonTemplate(row.PartyButton)
        end
        if row.RAFSummonButton then -- B223: Friends card, RAF builds only
            Skin.SocialCardActionButtonTemplate(row.RAFSummonButton)
        end
    end

    function Skin.SocialUIContactsFrameTemplate(Frame)
        -- shared base of the FriendsList/RecentAllies/QuickJoin/
        -- FriendRequests/RecruitAFriend tab content frames
        if Frame.FilterBar then
            Skin.SocialUIFilterBarTemplate(Frame.FilterBar)
        end
        if Frame.TopDivider then Frame.TopDivider:SetAlpha(0) end
        if Frame.BottomDivider then Frame.BottomDivider:SetAlpha(0) end
        if Frame.ActionButton then
            Skin.SocialUIActionButtonTemplate(Frame.ActionButton)
        end
        if Frame.ScrollBox and _G.ScrollUtil and _G.ScrollUtil.AddInitializedFrameCallback then
            local ScrollBox = Frame.ScrollBox
            Skin.WowScrollBoxList(ScrollBox)
            -- B223: rows (headers, spacers, cards) come from the list view's
            -- factory. Skin each once, and flatten the card plate on every
            -- (re)initialise, after Blizzard's initializer has returned (same
            -- OnInitializedFrame path as the trainer and community lists).
            _G.ScrollUtil.AddInitializedFrameCallback(ScrollBox, function(_, row)
                SkinContactsRow(row)
            end, ScrollBox)
            ScrollBox:ForEachFrame(SkinContactsRow)
        elseif Frame.ScrollBox then
            Skin.WowScrollBoxList(Frame.ScrollBox)
        end
        if Frame.ScrollBar then
            Skin.MinimalScrollBar(Frame.ScrollBar)
        end
    end

    function Skin.SocialUIIgnoreListFrameTemplate(Frame)
        Skin.ButtonFrameTemplate(Frame)
        if Frame.BlockButton then Skin.UIPanelButtonTemplate(Frame.BlockButton) end
        if Frame.UnblockButton then Skin.UIPanelButtonTemplate(Frame.UnblockButton) end
        if Frame.ScrollBox then Skin.WowScrollBoxList(Frame.ScrollBox) end
        if Frame.ScrollBar then Skin.MinimalScrollBar(Frame.ScrollBar) end
    end
end
