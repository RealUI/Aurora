local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals next select type

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

do --[[ SharedXML\FriendsFrame.lua ]]
    Hook.FriendsBroadcastFrameMixin = {}
    function Hook.FriendsBroadcastFrameMixin:ShowFrame()
        -- self.BroadcastButton:LockHighlight()
    end
    function Hook.FriendsBroadcastFrameMixin:HideFrame()
        -- self.BroadcastButton:UnlockHighlight()
    end

    function Hook.WhoList_InitButton(button, elementData)
        local info = elementData.info
        if info.filename then
            button.Class:SetTextColor(_G.CUSTOM_CLASS_COLORS[info.filename]:GetRGB())
        end
    end
    function Hook.WhoList_Update()
        local buttons = _G.WhoListScrollFrame.buttons
        local numButtons = #buttons

        for i = 1, numButtons do
            local button = buttons[i]
            if button.index then
                local info = _G.C_FriendList.GetWhoInfo(button.index)
                if info.filename then
                    button.Class:SetTextColor(_G.CUSTOM_CLASS_COLORS[info.filename]:GetRGB())
                end
            end
        end
    end
end

do --[[ SharedXML\FriendsFrame.xml ]]
    function Skin.FriendsTabTemplate(Button)
        Skin.TabSystemButtonTemplate(Button)
    end
    function Skin.FriendsFrameSlider(Slider)
        Skin.HybridScrollBarTrimTemplate(Slider)
    end
    function Skin.FriendsFrameScrollFrame(ScrollFrame)
        Skin.FriendsFrameSlider(ScrollFrame.scrollBar)
    end
    function Skin.FriendsFrameHeaderTemplate(Frame)
    end
    function Skin.FriendsFrameButtonTemplate(Button)
        Skin.UIPanelButtonTemplate(Button)
    end
    --[[ Skin.FriendsListButtonTemplate(_Button_)
    B261 (aurora-taint-pass, AT-D25): the travel pass (invite) button at the
    right end of a Battle.net friend's row, on the Layer 2 panel. Replaces
    the Layer 1 template that was never called (a FrameTypeButton backdrop,
    SetSize on the button, a `_bg` field on the game icon and a hook in the
    list update to show and hide it).

    Blizzard re-stamps the button's three state atlases through its own
    keys (`NormalTexture`, `PushedTexture`, `DisabledTexture`) on every list
    update, for the default, Horde and Alliance looks
    (Blizzard_FriendsFrame/Mainline/FriendsFrame.lua:2078-2091; Forever
    Camelot/FriendsFrame.lua:1819-1832). So the pressed, disabled and hover
    looks go on textures of Aurora's own, put in the button's state slots,
    and Blizzard's four keyed textures are kept at alpha 0, which SetAtlas
    does not change (rule 2). The engine still shows pressed, disabled and
    hover itself: Blizzard enables the button only when the friend can be
    invited (:2015-2019), with no script and no Aurora code involved.

    The game icon beside it stays Blizzard's: Blizzard sets its texture, its
    alpha and whether it shows on every list update (:1998-2010), so a crop
    and a border that follow it would need code in that update.

    Nothing is written on the row or the button: no field, no hook, no
    script, no SetPoint, SetSize or frame level on Blizzard's frames.
    --]]
    local TRAVEL_PASS_BOX = 22
    local TRAVEL_PASS_STATES = {"Pushed", "Disabled", "Highlight"}
    function Skin.FriendsListButtonTemplate(Button)
        local travelPassButton = Button.travelPassButton
        local panel = Skin.TaintSafeFrameTypeButton(travelPassButton, "panel")

        -- A square box in the middle of the 24x32 button; the button keeps
        -- Blizzard's size and hit rect. The state textures are anchored to
        -- the panel's border, so they follow.
        panel:ClearAllPoints()
        panel:SetPoint("CENTER", travelPassButton)
        panel:SetSize(TRAVEL_PASS_BOX, TRAVEL_PASS_BOX)

        local icon = panel:CreateTexture(nil, "ARTWORK")
        icon:SetTexture([[Interface\FriendsFrame\PlusManz-PlusManz]])
        icon:SetPoint("CENTER")
        icon:SetSize(TRAVEL_PASS_BOX - 2, TRAVEL_PASS_BOX - 2)
        icon:SetAlpha(0.75)

        -- Move each state into a texture of Aurora's own, painted and
        -- anchored as the primitive left it, so Blizzard's re-stamp cannot
        -- reach it.
        for i = 1, #TRAVEL_PASS_STATES do
            local stateName = TRAVEL_PASS_STATES[i]
            local getter = travelPassButton["Get" .. stateName .. "Texture"]
            local setter = travelPassButton["Set" .. stateName .. "Texture"]
            local painted = getter(travelPassButton)

            local layer, sublevel = painted:GetDrawLayer()
            local own = travelPassButton:CreateTexture(nil, layer, nil, sublevel)
            own:SetTexture(private.textures.plain)
            own:SetBlendMode(painted:GetBlendMode())
            own:SetVertexColor(painted:GetVertexColor())
            own:SetAlpha(painted:GetAlpha())
            for p = 1, painted:GetNumPoints() do
                own:SetPoint(painted:GetPoint(p))
            end
            if stateName == "Highlight" then
                setter(travelPassButton, own, "ADD")
            else
                setter(travelPassButton, own)
            end

            if getter(travelPassButton) == own then
                -- The slot holds Aurora's texture. The one the primitive
                -- painted and Blizzard's keyed one (often the same object)
                -- are out of it: alpha 0, whether or not the engine still
                -- draws them.
                painted:SetAlpha(0)
                local keyed = travelPassButton[stateName .. "Texture"]
                if keyed then
                    keyed:SetAlpha(0)
                end
            else
                -- The client copied instead of taking the texture: keep the
                -- primitive's look and drop the unused one.
                own:Hide()
            end
        end
        -- The primitive leaves no normal texture; Blizzard's keyed one is
        -- re-stamped on every update whether or not it is still in the slot.
        if travelPassButton.NormalTexture then
            travelPassButton.NormalTexture:SetAlpha(0)
        end
    end
    function Skin.WhoFrameColumnHeaderTemplate(Button)
        Button.Left:Hide()
        Button.Right:Hide()
        Button.Middle:Hide()
        Button.HighlightTexture:SetAlpha(0)
    end
    function Skin.FriendsFrameGuildPlayerStatusButtonTemplate(Button)
        Util.SetHighlightColor(Button:GetHighlightTexture(), Color.frame.a)
    end
    function Skin.FriendsFrameGuildStatusButtonTemplate(Button)
        Util.SetHighlightColor(Button:GetHighlightTexture(), Color.frame.a)
    end
    function Skin.GuildFrameColumnHeaderTemplate(Button)
        local name = Button:GetName()
        _G[name.."Left"]:Hide()
        _G[name.."Middle"]:Hide()
        _G[name.."Right"]:Hide()
    end
    function Skin.FriendsFrameTabTemplate(Button)
        Skin.PanelTabButtonTemplate(Button)
        Button._auroraTabResize = true
    end
    function Skin.GuildControlPopupFrameCheckboxTemplate(CheckButton)
        Skin.UICheckButtonTemplate(CheckButton)
    end
end

function private.FrameXML.FriendsFrame()
    -- WhoList_InitButton lives in Mainline\FriendsFrame.lua, which Camelot
    -- excludes; the Who list does not exist on Forever. This hook sits above
    -- the guarded WhoFrame block below, so without this check it throws before
    -- that guard is ever reached and the whole FriendsFrame skin is lost.
    if type(_G.WhoList_InitButton) == "function" then
        _G.hooksecurefunc("WhoList_InitButton", Hook.WhoList_InitButton)
    end

    local FriendsFrame = _G.FriendsFrame
    Skin.ButtonFrameTemplate(FriendsFrame)
    _G.FriendsFrameIcon:Hide()

    ----------------------
    -- FriendsTabHeader --
    ----------------------
    local BNetFrame = _G.FriendsFrameBattlenetFrame
    BNetFrame:GetRegions():Hide() -- BattleTag background
    BNetFrame:SetWidth(250)
    BNetFrame:SetPoint("TOP", 0, -26)
    Base.SetBackdrop(BNetFrame, _G.FRIENDS_BNET_BACKGROUND_COLOR, Color.frame.a)

    do -- BNetFrame.BroadcastButton
        local Button = BNetFrame.ContactsMenuButton
        Skin.FrameTypeButton(Button)
        Button:GetNormalTexture():SetAlpha(0)
        Button:GetPushedTexture():SetAlpha(0)
        Button:SetBackdropOption("offsets", {
            left = 5,
            right = 5,
            top = 5,
            bottom = 5,
        })

        local icon = Button:CreateTexture(nil, "ARTWORK")
        icon:SetTexture([[Interface\FriendsFrame\MenuIcon]])
        icon:SetSize(16, 16)
        icon:SetPoint("CENTER")
    end

    Skin.UIPanelInfoButton(BNetFrame.UnavailableInfoButton)

    local BroadcastFrame = BNetFrame.BroadcastFrame
    BroadcastFrame:SetPoint("TOPLEFT", -55, -24)

    -- Util.Mixin(BroadcastFrame, Hook.FriendsBroadcastFrameMixin)
    Skin.DialogBorderOpaqueTemplate(BroadcastFrame.Border)

    local EditBox = BroadcastFrame.EditBox
    Base.CreateBackdrop(EditBox, private.backdrop, {
        tl = EditBox.TopLeftBorder,
        tr = EditBox.TopRightBorder,
        t = EditBox.TopBorder,

        bl = EditBox.BottomLeftBorder,
        br = EditBox.BottomRightBorder,
        b = EditBox.BottomBorder,

        l = EditBox.LeftBorder,
        r = EditBox.RightBorder,

        bg = EditBox.MiddleBorder
    })
    Skin.FrameTypeEditBox(EditBox)
    EditBox:SetBackdropOption("offsets", {
        left = -7,
        right = -5,
        top = 0,
        bottom = 0,
    })

    Skin.FriendsFrameButtonTemplate(BroadcastFrame.UpdateButton)
    Skin.FriendsFrameButtonTemplate(BroadcastFrame.CancelButton)

    Skin.DialogBorderTemplate(BNetFrame.UnavailableInfoFrame)
    local _, blizzIcon = select(11, BNetFrame.UnavailableInfoFrame:GetRegions())
    blizzIcon:SetTexture([[Interface\Glues\MainMenu\Glues-BlizzardLogo]])

    local FriendsFrameStatusDropdown = _G.FriendsFrameStatusDropdown
    if FriendsFrameStatusDropdown then
        FriendsFrameStatusDropdown:ClearAllPoints()
        Skin.DropdownButton(FriendsFrameStatusDropdown)
        FriendsFrameStatusDropdown:SetPoint("TOPLEFT", 5, -27)
        FriendsFrameStatusDropdown:SetWidth(50)
    end

    local FriendsTabHeader = _G.FriendsTabHeader
    for _, tab in next, {FriendsTabHeader.TabSystem:GetChildren()} do
        Util.SkinOnce(tab, Skin.FriendsTabTemplate)
    end

    ----------------------
    -- FriendsListFrame --
    ----------------------
    local FriendsListFrame = _G.FriendsListFrame
    Skin.FriendsFrameButtonTemplate(_G.FriendsFrameAddFriendButton)
    Skin.FriendsFrameButtonTemplate(_G.FriendsFrameSendMessageButton)
    if FriendsListFrame.FilterDropdown then
        Skin.DropdownButton(FriendsListFrame.FilterDropdown)
    end
    Skin.UIPanelButtonTemplate(FriendsListFrame.RIDWarning:GetChildren()) -- ContinueButton
    Skin.WowScrollBoxList(FriendsListFrame.ScrollBox)
    Skin.MinimalScrollBar(FriendsListFrame.ScrollBar)

    do -- the friends rows' travel pass buttons (B261, AT-D25)
        -- The rows are pooled. OnAcquiredFrame fires when the view takes a
        -- row from the pool, before Blizzard's initializer fills it
        -- (ScrollBoxListView.lua:392), through the callback registry's
        -- secureexecuterange (CallbackRegistry.lua:207-213), so nothing here
        -- taints the list update that goes on. Each row is skinned once and
        -- remembered in a weak table of this file's; later acquisitions of
        -- the same row stop at that read. Only friend rows have the button;
        -- the divider and invite rows of the same list do not.
        local skinnedRows = _G.setmetatable({}, {__mode = "k"})
        local function SkinFriendRow(Button)
            if skinnedRows[Button] or not Button.travelPassButton then
                return
            end
            skinnedRows[Button] = true
            Skin.FriendsListButtonTemplate(Button)
        end
        _G.ScrollUtil.AddAcquiredFrameCallback(FriendsListFrame.ScrollBox, function(_, Button)
            SkinFriendRow(Button)
        end, skinnedRows)
        FriendsListFrame.ScrollBox:ForEachFrame(SkinFriendRow)
    end


    ----------------------
    -- IgnoreListWindow --
    ----------------------
    local IgnoreListWindow = FriendsFrame.IgnoreListWindow
    Skin.NineSlicePanelTemplate(IgnoreListWindow.NineSlice)
    Skin.WowScrollBoxList(IgnoreListWindow.ScrollBox)
    Skin.MinimalScrollBar(IgnoreListWindow.ScrollBar)
    Skin.UIPanelCloseButton(IgnoreListWindow.CloseButton)
    Skin.MagicButtonTemplate(IgnoreListWindow.UnignorePlayerButton)
    -- FIXLATER - it is a bit dark,....

    -----------------------
    -- RecentAlliesFrame --
    -----------------------
    local RecentAlliesFrame = _G.RecentAlliesFrame
    local ScrollBox = RecentAlliesFrame.List.ScrollBox
    local ScrollBar = RecentAlliesFrame.List.ScrollBar
    Skin.WowScrollBoxList(ScrollBox)
    Skin.MinimalScrollBar(ScrollBar)

    --------------
    -- WhoFrame --
    --------------
    -- WoW Forever (Camelot FriendsFrame.xml) ships no Who tab at all: no
    -- WhoFrame, no FriendsFrameTab2. Everything below must survive that.
    local WhoFrame = _G.WhoFrame
    if WhoFrame then
        Skin.InsetFrameTemplate(_G.WhoFrameListInset)
        Skin.WhoFrameColumnHeaderTemplate(_G.WhoFrameColumnHeader1)
        Skin.WhoFrameColumnHeaderTemplate(_G.WhoFrameColumnHeader2)

        Skin.DropdownButton(_G.WhoFrameDropdown)
        Skin.WhoFrameColumnHeaderTemplate(_G.WhoFrameColumnHeader3)
        Skin.WhoFrameColumnHeaderTemplate(_G.WhoFrameColumnHeader4)

        Skin.FriendsFrameButtonTemplate(_G.WhoFrameGroupInviteButton)
        Skin.MagicButtonTemplate(_G.WhoFrameAddFriendButton)
        Skin.MagicButtonTemplate(_G.WhoFrameWhoButton)

        _G.WhoFrameGroupInviteButton:SetPoint("BOTTOMRIGHT", -5, 5)
        _G.WhoFrameWhoButton:ClearAllPoints()
        _G.WhoFrameWhoButton:SetPoint("BOTTOMLEFT", 5, 5)
        _G.WhoFrameAddFriendButton:ClearAllPoints()
        _G.WhoFrameAddFriendButton:SetPoint("BOTTOMLEFT", _G.WhoFrameWhoButton, "BOTTOMRIGHT", 1, 0)
        _G.WhoFrameAddFriendButton:SetPoint("BOTTOMRIGHT", _G.WhoFrameGroupInviteButton, "BOTTOMLEFT", -1, 0)

        Skin.FrameTypeEditBox(_G.WhoFrameEditBox)
        _G.WhoFrameEditBox:ClearAllPoints()
        _G.WhoFrameEditBox:SetPoint("BOTTOMLEFT", _G.WhoFrameWhoButton, "TOPLEFT", 2, -2)
        _G.WhoFrameEditBox:SetPoint("BOTTOMRIGHT", _G.WhoFrameGroupInviteButton, "TOPRIGHT", -2, -2)
        _G.WhoFrameEditBox:SetBackdropOption("offsets", {
            left = -2,
            right = -2,
            top = 7,
            bottom = 7,
        })

        Skin.WowScrollBoxList(WhoFrame.ScrollBox)
        Skin.MinimalScrollBar(WhoFrame.ScrollBar)
    end

    ----------------------
    -- FriendsFrameMisc --
    ----------------------
    local tabs = {}
    for i = 1, 4 do
        local tab = _G["FriendsFrameTab" .. i]
        if tab then
            Skin.FriendsFrameTabTemplate(tab)
            tabs[#tabs + 1] = tab
        end
    end
    Util.PositionRelative("TOPLEFT", FriendsFrame, "BOTTOMLEFT", 20, -1, 1, "Right", tabs)

    if not private.disabled.tooltips then
        Skin.FrameTypeFrame(_G.FriendsTooltip)
    end

    --------------------
    -- AddFriendFrame --
    --------------------
    local AddFriendFrame = _G.AddFriendFrame
    -- Dark variant: the dialog opens over the contacts list, and at the user
    -- frame alpha the friend names showed through its text.
    Skin.DialogBorderDarkTemplate(AddFriendFrame.Border)
    -- AddFriendInfoFrame has no ContinueButton parentKey in either tree
    -- (Blizzard_AddFriend\AddFriendTemplates.xml declares OkayButton /
    -- CancelButton / AcceptButton), so this has been nil on retail too. It only
    -- surfaced on Forever because the WhoList_InitButton guard above let
    -- execution reach it. Guarded rather than repointed: which of the three
    -- buttons the original meant is a guess, and skinning the wrong one is
    -- worse than skinning none.
    if _G.AddFriendInfoFrame.ContinueButton then
        Skin.FrameTypeButton(_G.AddFriendInfoFrame.ContinueButton)
    end
    Skin.UIPanelInfoButton(_G.AddFriendEntryFrameInfoButton)
    do -- AddFriendNameEditBox
        Skin.FrameTypeEditBox(_G.AddFriendNameEditBox)
        _G.AddFriendNameEditBoxLeft:Hide()
        _G.AddFriendNameEditBoxRight:Hide()
        _G.AddFriendNameEditBoxMiddle:Hide()
    end
    Skin.UIPanelCloseButton(AddFriendFrame.CloseButton)
    Skin.UIPanelButtonTemplate(_G.AddFriendEntryFrameAcceptButton)
    Skin.UIPanelButtonTemplate(_G.AddFriendEntryFrameCancelButton)
    -------------------------
    -- FriendsFriendsFrame --
    -------------------------
    local FriendsFriendsFrame = _G.FriendsFriendsFrame
    Skin.DialogBorderTemplate(FriendsFriendsFrame.Border)
    Skin.DropdownButton(_G.FriendsFriendsFrameDropdown)
    Util.HideNineSlice(FriendsFriendsFrame.ScrollFrameBorder)
    Skin.WowScrollBoxList(FriendsFriendsFrame.ScrollBox)
    Skin.MinimalScrollBar(FriendsFriendsFrame.ScrollBar)
    Skin.UIPanelButtonTemplate(FriendsFriendsFrame.SendRequestButton)
    Skin.UIPanelButtonTemplate(FriendsFriendsFrame.CloseButton)

    --------------------------
    -- BattleNetInviteFrame --
    --------------------------
    -- 12.1: BattleTagInviteFrame deleted; replaced by BattleNetInviteFrame
    -- (Blizzard_AddFriend, a hard dependency of Blizzard_FriendsFrame, so
    -- it exists at this ADDON_LOADED). Proper parentKeys now — no more
    -- positional GetChildren.
    local BattleNetInviteFrame = _G.BattleNetInviteFrame
    if BattleNetInviteFrame then
        Skin.DialogBorderTemplate(BattleNetInviteFrame.Border)
        Skin.UIPanelButtonTemplate(BattleNetInviteFrame.SendButton)
        Skin.UIPanelButtonTemplate(BattleNetInviteFrame.CancelButton)
    end
end
