local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals setmetatable

--[[ Core ]]
local Aurora = private.Aurora
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

do --[[ AddOns\Blizzard_Channels.lua ]]
    do --[[ ChannelList.lua ]]
        --[[ Channel list headers (taint audit 2026-10-06, B170 follow-up)
            NOTE: Do NOT replace headerButtonPool.Acquire. The old skin did,
            so every AddHeaderButton inside ChannelListMixin:Update ran
            Aurora's closure and the rest of the list build (voice channels,
            community streams, CommunitiesFrame favourites) ran tainted. The
            headers are now restyled in place from this post-hook, after
            Blizzard's Update has finished: colours on the existing Normal and
            Highlight textures, no new regions, no fields on the button, no
            per-button hook. Blizzard's own plus/minus atlas stays. ]]
        local styledHeaders = setmetatable({}, {__mode = "k"})
        function Hook.ChannelListUpdate(self)
            for header in self.headerButtonPool:EnumerateActive() do
                if not styledHeaders[header] then
                    styledHeaders[header] = true
                    Skin.ChannelButtonHeaderTemplate(header)
                end
            end
        end
    end
    do --[[ RosterButton.lua ]]
        Hook.ChannelRosterButtonMixin = {}
        function Hook.ChannelRosterButtonMixin:Update()
            if self:IsConnected() ~= false and self.playerLocation then
                local _, classToken = _G.C_PlayerInfo.GetClass(self.playerLocation)
                if classToken then
                    self.Name:SetTextColor(_G.CUSTOM_CLASS_COLORS[classToken]:GetRGB())
                end
            end

        end
    end
end

do --[[ AddOns\Blizzard_Channels.xml ]]
    do --[[ ChannelButton.xml ]]
        function Skin.ChannelButtonBaseTemplate(Button)
            Skin.FrameTypeButton(Button)
        end
        -- In place only (see Hook.ChannelListUpdate): a flat band on the
        -- existing Normal texture and a highlight wash; Blizzard's Update only
        -- touches NormalTexture's alpha, never its texture.
        function Skin.ChannelButtonHeaderTemplate(Button)
            local r, g, b = Color.button:GetRGB()
            Button.NormalTexture:SetColorTexture(r, g, b, 0.6)
            Util.SetHighlightColor(Button.HighlightTexture, 0.25)
        end
        function Skin.ChannelButtonTemplate(Button)
            Skin.ChannelButtonBaseTemplate(Button)
        end
        function Skin.ChannelButtonTextTemplate(Button)
            Skin.ChannelButtonTemplate(Button)
        end
        function Skin.ChannelButtonVoiceTemplate(Button)
            Skin.ChannelButtonTemplate(Button)
        end
        function Skin.ChannelButtonCommunityTemplate(Button)
            Skin.ChannelButtonTemplate(Button)
        end
    end
    do --[[ RosterButton.xml ]]
        Skin.ChannelRosterButtonTemplate = private.nop
        function Skin.ChannelRosterButtonTemplate(Button)
            Util.Mixin(Button, Hook.ChannelRosterButtonMixin)
        end
    end
    do --[[ CreateChannelPopup.xml ]]
        function Skin.CreateChannelPopupEditBoxTemplate(EditBox)
            Skin.InputBoxTemplate(EditBox)
        end
        function Skin.CreateChannelPopupButtonTemplate(Button)
            Skin.UIPanelButtonTemplate(Button)
        end
    end
    do --[[ ChannelList.xml ]]
        function Skin.ChannelListTemplate(ScrollFrame)
            -- Headers: post-hook on the list's Update, never the pool's
            -- Acquire (taint audit 2026-10-06, see Hook.ChannelListUpdate).
            _G.hooksecurefunc(ScrollFrame, "Update", Hook.ChannelListUpdate)
            if private.isRetail then
                Skin.ScrollFrameTemplate(ScrollFrame)
            else
                Skin.UIPanelScrollBarTemplate(ScrollFrame.ScrollBar)
            end
        end
    end
    do --[[ ChannelRoster.xml ]]
        function Skin.ChannelRosterTemplate(Frame)
            -- WowScrollBoxList (Base.SetBackdrop) and MinimalScrollBar
            -- (CreateTexture/CreateFrame) are taint-unsafe: roster buttons
            -- inside the ScrollBox call VoiceActivityManager:
            -- RegisterFrameForVoiceActivityNotifications(), and storing
            -- values in a tainted context produces secret numbers that
            -- break MatchesUser() comparisons.
            if not private.isRetail then
                Skin.HybridScrollBarTemplate(Frame.ScrollFrame.scrollBar)
            end
        end
    end
end

function private.AddOns.Blizzard_Channels()
    ----====####################====----
    --           VoiceUtils           --
    ----====####################====----

    -------------
    -- Section --
    -------------


    ----====#####################====----
    --          ChannelButton          --
    ----====#####################====----


    ----====####################====----
    --          RosterButton          --
    ----====####################====----


    ----====####################====----
    --       CreateChannelPopup       --
    ----====####################====----
    local CreateChannelPopup = _G.CreateChannelPopup

    if private.isRetail then
        Skin.DialogHeaderTemplate(CreateChannelPopup.Header)
        Skin.DialogBorderTemplate(CreateChannelPopup.BG)
    else
        CreateChannelPopup.Title:ClearAllPoints()
        CreateChannelPopup.Title:SetPoint("TOPLEFT")
        CreateChannelPopup.Title:SetPoint("BOTTOMRIGHT", CreateChannelPopup, "TOPRIGHT", 0, -private.FRAME_TITLE_HEIGHT)

        CreateChannelPopup.Titlebar:Hide()
        CreateChannelPopup.Corner:Hide()

        Skin.DialogBorderTemplate(CreateChannelPopup)
    end
    Skin.CreateChannelPopupEditBoxTemplate(CreateChannelPopup.Name)
    Skin.CreateChannelPopupEditBoxTemplate(CreateChannelPopup.Password)
    Skin.UICheckButtonTemplate(CreateChannelPopup.UseVoiceChat)
    Skin.UIPanelCloseButton(CreateChannelPopup.CloseButton)
    Skin.CreateChannelPopupButtonTemplate(CreateChannelPopup.OKButton)
    Skin.CreateChannelPopupButtonTemplate(CreateChannelPopup.CancelButton)


    ----====#####################====----
    --           ChannelList           --
    ----====#####################====----


    ----====#####################====----
    --          ChannelRoster          --
    ----====#####################====----


    ----====#####################====----
    --         VoiceChatPrompt         --
    ----====#####################====----


    ----====####################====----
    --          ChannelFrame          --
    ----====####################====----
    local ChannelFrame = _G.ChannelFrame
    Skin.ButtonFrameTemplate(ChannelFrame)
    ChannelFrame.Icon:Hide()

    Skin.UIPanelButtonTemplate(ChannelFrame.NewButton)
    ChannelFrame.NewButton:SetPoint("BOTTOMLEFT", 5, 5)
    Skin.UIPanelButtonTemplate(ChannelFrame.SettingsButton)
    ChannelFrame.SettingsButton:SetPoint("BOTTOMRIGHT", -5, 5)
    Skin.ChannelListTemplate(ChannelFrame.ChannelList)
    ChannelFrame.ChannelList:SetPoint("TOPLEFT", 7, -(private.FRAME_TITLE_HEIGHT + 20))
    Skin.InsetFrameTemplate(ChannelFrame.LeftInset)
    Skin.ChannelRosterTemplate(ChannelFrame.ChannelRoster)
    ChannelFrame.ChannelRoster:SetPoint("TOPRIGHT", -20, -(private.FRAME_TITLE_HEIGHT + 20))
    ChannelFrame.ChannelRoster:SetPoint("BOTTOMRIGHT", -20, 28)
    Skin.InsetFrameTemplate(ChannelFrame.RightInset)
    -- ChannelRoster ScrollBox/ScrollBar skinning removed: taint-unsafe
    -- (see Skin.ChannelRosterTemplate comment above).

    -- Skin.WowScrollBoxList(ChannelFrame.ChannelList.ScrollBox)
    Skin.MinimalScrollBar(ChannelFrame.ChannelList.ScrollBar)


    -- ChannelFrameannelFrame.ChannelRoster

    ----====#####################====----
    --    VoiceActivityNotification    --
    ----====#####################====----


    ----====####################====----
    -- VoiceActivityNotificationParty --
    ----====####################====----


    ----====#####################====----
    -- VoiceActivityNotificationRoster --
    ----====#####################====----


    ----====####################====----
    --      VoiceActivityManager      --
    ----====####################====----
end
