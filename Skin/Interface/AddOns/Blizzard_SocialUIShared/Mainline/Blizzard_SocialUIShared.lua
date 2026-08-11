local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals _G

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Color = Aurora.Color

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
        -- ListHeaderVisualTemplate art (three-slice family)
        if Frame.Left then Frame.Left:SetAlpha(0) end
        if Frame.Middle then Frame.Middle:SetAlpha(0) end
        if Frame.Right then Frame.Right:SetAlpha(0) end
    end

    function Skin.SocialUIActionButtonTemplate(Button)
        -- SharedButtonTemplate with the 128-RedButton art kit
        if Button.Left then Button.Left:SetAlpha(0) end
        if Button.Center then Button.Center:SetAlpha(0) end
        if Button.Right then Button.Right:SetAlpha(0) end
        Skin.FrameTypeButton(Button)
    end

    function Skin.SocialCardActionButtonTemplate(Button)
        -- hand-rolled 34x34 square button (common-button-tertiary-square-*)
        Button:SetNormalTexture("")
        Button:SetPushedTexture("")
        Skin.FrameTypeButton(Button)
        local highlight = Button:GetHighlightTexture()
        if highlight then
            highlight:SetColorTexture(Color.highlight.r, Color.highlight.g, Color.highlight.b, 0.2)
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
        if Frame.ScrollBox then
            Skin.WowScrollBoxList(Frame.ScrollBox)
            -- headers/spacers/cards materialise through the list view;
            -- skin the shared header rows as they appear
            _G.hooksecurefunc(Frame.ScrollBox, "Update", function(self)
                self:ForEachFrame(function(row)
                    if not row._auroraSkinned then
                        row._auroraSkinned = true
                        if row.ButtonText and row.CollapseButton then
                            -- SocialUIScrollableHeaderTemplate row
                            Skin.SocialUIScrollableHeaderTemplate(row)
                        end
                        if row.AcceptButton then -- FriendRequests card
                            Skin.SocialUIActionButtonTemplate(row.AcceptButton)
                        end
                        if row.PartyButton then -- Friends/RecentAllies card
                            Skin.SocialCardActionButtonTemplate(row.PartyButton)
                        end
                    end
                end)
            end)
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
