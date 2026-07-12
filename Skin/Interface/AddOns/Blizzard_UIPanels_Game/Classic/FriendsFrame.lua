local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Util = Aurora.Util

--[[ Classic-family FriendsFrame (era/TBC/Mists share this Classic file).
    Evidence: wow-ui-source-*/Interface/AddOns/Blizzard_UIPanels_Game/
    Classic/FriendsFrame.xml (root L732: ButtonFrameTemplate; four tabs via
    FriendsFrameTabTemplate -> CharacterFrameTabButtonTemplate; friends list
    is a HybridScrollFrame — rows auto-skin via the un-swept
    HybridScrollFrame_CreateButtons hook and Skin.FriendsListButtonTemplate;
    Who/Guild lists are FauxScrollFrames with WhoFrame-ColumnTabs headers).
    First pass: guild admin popups (GuildControl), guild LFG checkboxes and
    Promote/Demote art buttons left for iteration.
]]

-- WhoFrame-ColumnTabs column headers ($parentLeft/Middle/Right pieces)
local function SkinColumnHeader(Button)
    local name = Button:GetName()
    _G[name.."Left"]:SetAlpha(0)
    _G[name.."Middle"]:SetAlpha(0)
    _G[name.."Right"]:SetAlpha(0)

    local highlight = Button:GetHighlightTexture()
    if highlight then
        highlight:SetBlendMode("BLEND")
        Util.SetHighlightColor(highlight, 0.2)
    end
end

-- Auto-applied to friends-list rows by the HybridScrollFrame hook
function Skin.FriendsListButtonTemplate(Button)
    if Button.background then
        Button.background:Hide()
    end

    local highlight = Button:GetHighlightTexture()
    if highlight then
        highlight:SetBlendMode("BLEND")
        Util.SetHighlightColor(highlight, 0.2)
    end
end

function private.FrameXML.FriendsFrame()
    local FriendsFrame = _G.FriendsFrame

    Skin.ButtonFrameTemplate(FriendsFrame)

    -- Extra OVERLAY icon on the root ($parentIcon, the scroll-with-seal art)
    -- that sits on top of the hidden portrait
    if _G.FriendsFrameIcon then
        _G.FriendsFrameIcon:SetAlpha(0)
    end

    local i = 1
    while _G["FriendsFrameTab"..i] do
        Skin.CharacterFrameTabButtonTemplate(_G["FriendsFrameTab"..i])
        i = i + 1
    end

    -----------------
    -- Friends tab --
    -----------------
    Util.HideFrameTextures(_G.FriendsListFrame)
    Skin.UIPanelButtonTemplate(_G.FriendsFrameAddFriendButton)
    Skin.UIPanelButtonTemplate(_G.FriendsFrameSendMessageButton)
    if _G.FriendsFrameStatusDropdown then
        Skin.DropdownButton(_G.FriendsFrameStatusDropdown)
    end
    -- The friends list scrollbar is a MinimalHybridScrollBarTemplate (era XML
    -- L1360), NOT HybridScrollBarTemplate — the latter's skin indexes
    -- Slider.ScrollUpButton which doesn't exist here and aborts the module.
    local friendsScrollBar = _G.FriendsFrameFriendsScrollFrame.scrollBar
        or _G.FriendsFrameFriendsScrollFrameScrollBar
    if friendsScrollBar then
        Skin.MinimalHybridScrollBarTemplate(friendsScrollBar)
    end
    -- Ornate track art lives on the scroll frame itself, not the scrollbar
    for _, name in ipairs({"FriendsFrameFriendsScrollFrameTop", "FriendsFrameFriendsScrollFrameMiddle", "FriendsFrameFriendsScrollFrameBottom"}) do
        local texture = _G[name]
        if texture then
            texture:SetAlpha(0)
        end
    end

    ----------------
    -- Ignore tab --
    ----------------
    Util.HideFrameTextures(_G.IgnoreListFrame)
    Skin.UIPanelButtonTemplate(_G.FriendsFrameIgnorePlayerButton)
    Skin.UIPanelButtonTemplate(_G.FriendsFrameUnsquelchButton)
    Skin.FauxScrollFrameTemplate(_G.FriendsFrameIgnoreScrollFrame)

    -------------
    -- Who tab --
    -------------
    Util.HideFrameTextures(_G.WhoFrame)
    Skin.SearchBoxTemplate(_G.WhoFrameEditBox)
    Skin.InsetFrameTemplate(_G.WhoFrameListInset)
    for n = 1, 5 do
        local header = _G["WhoFrameColumnHeader"..n]
        if header then
            SkinColumnHeader(header)
        end
    end
    if _G.WhoFrameDropdown then
        Skin.DropdownButton(_G.WhoFrameDropdown)
    end
    Skin.UIPanelButtonTemplate(_G.WhoFrameGroupInviteButton)
    Skin.UIPanelButtonTemplate(_G.WhoFrameAddFriendButton)
    Skin.UIPanelButtonTemplate(_G.WhoFrameWhoButton)
    Skin.FauxScrollFrameTemplate(_G.WhoListScrollFrame)

    local n = 1
    while _G["WhoFrameButton"..n] do
        local highlight = _G["WhoFrameButton"..n]:GetHighlightTexture()
        if highlight then
            highlight:SetBlendMode("BLEND")
            Util.SetHighlightColor(highlight, 0.2)
        end
        n = n + 1
    end

    ---------------
    -- Guild tab --
    ---------------
    Util.HideFrameTextures(_G.GuildFrame)
    for m = 1, 4 do
        local header = _G["GuildFrameColumnHeader"..m]
        if header then
            SkinColumnHeader(header)
        end
    end
    for _, name in ipairs({"GuildFrameControlButton", "GuildFrameAddMemberButton", "GuildFrameGuildInformationButton", "GuildFrameImpeachButton"}) do
        local button = _G[name]
        if button then
            Skin.UIPanelButtonTemplate(button)
        end
    end
    Skin.FauxScrollFrameTemplate(_G.GuildListScrollFrame)
end
