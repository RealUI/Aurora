local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals select

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

local NUM_SLOTS_PER_GUILDBANK_GROUP = 14;
local NUM_GUILDBANK_COLUMNS = 7;

do --[[ AddOns\Blizzard_GuildBankUI.lua ]]
    Hook.GuildBankPopupFrameMixin = {}
    function Hook.GuildBankPopupFrameMixin:OnShow()
        --_G.GuildBankPopupButton1:SetPoint("TOPLEFT", 25, -30)
        _G.GuildBankPopupButton1:SetPoint("TOPLEFT", _G.GuildBankPopupFrame.ScrollFrame, 0, -1)
    end
end

do --[[ AddOns\Blizzard_GuildBankUI.xml ]]
    function Skin.GuildBankItemButtonTemplate(ItemButton)
        Skin.FrameTypeItemButton(ItemButton)
        ItemButton:SetBackdropOptions({
            bgFile = [[Interface\PaperDoll\UI-Backpack-EmptySlot]],
            tile = false
        })
        ItemButton:SetBackdropColor(1, 1, 1, 0.75)
        Base.CropIcon(ItemButton:GetBackdropTexture("bg"))
    end
    function Skin.GuildBankFrameColumnTemplate(Frame)
        Frame.Background:Hide()
        Base.SetBackdrop(Frame, Color.gray, 0.5)
        Frame:SetBackdropOption("offsets", {
            left = 2,
            right = 2,
            top = -2,
            bottom = 2,
        })

        for i = 1, NUM_SLOTS_PER_GUILDBANK_GROUP do
            Skin.GuildBankItemButtonTemplate(Frame.Buttons[i])
        end
    end
    function Skin.GuildBankTabTemplate(Frame)
        Skin.SideTabTemplate(Frame)
    end
    function Skin.GuildBankFrameTabTemplate(Frame)
        Skin.PanelTabButtonTemplate(Frame)
    end
    function Skin.GuildBankPopupButtonTemplate(CheckButton)
        Skin.PopupButtonTemplate(CheckButton)
    end
end

function private.AddOns.Blizzard_GuildBankUI()
    local GuildBankFrame = _G.GuildBankFrame
    Skin.BasicFrameTemplate(GuildBankFrame)
    GuildBankFrame:SetBackdropOption("offsets", {
        left = 0,
        right = 0,
        top = 20,
        bottom = 0,
    })
    local bg = GuildBankFrame:GetBackdropTexture("bg")

    GuildBankFrame.TabTitleBG:SetAlpha(0)
    GuildBankFrame.TabTitleBGLeft:SetAlpha(0)
    GuildBankFrame.TabTitleBGRight:SetAlpha(0)

    GuildBankFrame.TabLimitBG:SetAlpha(0)
    GuildBankFrame.TabLimitBGLeft:SetAlpha(0)
    GuildBankFrame.TabLimitBGRight:SetAlpha(0)

    _G.GuildBankFrameBottomLeftOuter:Hide()
    _G.GuildBankFrameBottomRightOuter:Hide()
    _G.GuildBankFrameTopRightOuter:Hide()
    _G.GuildBankFrameTopLeftOuter:Hide()
    _G.GuildBankFrameLeftOuter:Hide()
    _G.GuildBankFrameRightOuter:Hide()
    _G.GuildBankFrameTopOuter:Hide()
    _G.GuildBankFrameBottomOuter:Hide()

    _G.GuildBankFrameBottomLeftInner:Hide()
    _G.GuildBankFrameBottomRightInner:Hide()
    _G.GuildBankFrameTopRightInner:Hide()
    _G.GuildBankFrameTopLeftInner:Hide()
    _G.GuildBankFrameLeftInner:Hide()
    _G.GuildBankFrameRightInner:Hide()
    _G.GuildBankFrameTopInner:Hide()
    _G.GuildBankFrameBottomInner:Hide()

    GuildBankFrame.RedMarbleBG:Hide()
    GuildBankFrame.BlackBG:Hide()

    for i = 1, NUM_GUILDBANK_COLUMNS do
        Skin.GuildBankFrameColumnTemplate(GuildBankFrame.Columns[i])
    end

    Skin.ThinGoldEdgeTemplate(GuildBankFrame.MoneyFrameBG)
    GuildBankFrame.MoneyFrameBG:ClearAllPoints()
    GuildBankFrame.MoneyFrameBG:SetPoint("TOPLEFT", bg, "BOTTOMLEFT", 5, 28)
    GuildBankFrame.MoneyFrameBG:SetPoint("BOTTOMRIGHT", bg, -5, 5)
    GuildBankFrame.MoneyFrameBG.LimitLabel:SetPoint("BOTTOMLEFT", GuildBankFrame.MoneyFrameBG, 5, 5)

    Skin.SmallMoneyFrameTemplate(GuildBankFrame.MoneyFrame)
    GuildBankFrame.MoneyFrame:SetPoint("BOTTOMRIGHT", GuildBankFrame.MoneyFrameBG, 0, 5)
    Skin.SmallMoneyFrameTemplate(GuildBankFrame.WithdrawMoneyFrame)

    Skin.UIPanelButtonTemplate(GuildBankFrame.DepositButton)
    Skin.UIPanelButtonTemplate(GuildBankFrame.WithdrawButton)
    Util.PositionRelative("BOTTOMRIGHT", GuildBankFrame.MoneyFrameBG, "TOPRIGHT", 0, 5, 5, "Left", {
        GuildBankFrame.DepositButton,
        GuildBankFrame.WithdrawButton,
    })

    for i = 1, 4 do
        Skin.GuildBankFrameTabTemplate(GuildBankFrame.Tabs[i])
    end
    Util.PositionRelative("TOPLEFT", bg, "BOTTOMLEFT", 20, -1, 1, "Right", GuildBankFrame.Tabs)

    for i = 1, 8 do
        Skin.GuildBankTabTemplate(GuildBankFrame.BankTabs[i])
    end
    Util.PositionRelative("TOPLEFT", bg, "TOPRIGHT", 0, -33, -9, "Down", GuildBankFrame.BankTabs)

    -------------
    -- BuyInfo --
    -------------
    local BuyInfo = GuildBankFrame.BuyInfo
    Skin.SmallMoneyFrameTemplate(_G.GuildBankFrameTabCostMoneyFrame)
    Skin.UIPanelButtonTemplate(BuyInfo.PurchaseButton)

    ---------
    -- Log --
    ---------
    local Log = GuildBankFrame.Log
    Base.SetBackdrop(Log.MessageFrame, Color.gray, 0.5)
    Log.MessageFrame:SetPoint("TOPLEFT", bg, 25, -42)
    Log.MessageFrame:SetPoint("BOTTOMRIGHT", bg, -21, 65)
    Log.MessageFrame:SetBackdropOption("offsets", {
        left = -5,
        right = -5,
        top = -5,
        bottom = -5,
    })

    Skin.MinimalScrollBar(Log.ScrollBar)

    -------------------
    -- GuildBankInfo --
    -------------------
    local Info = GuildBankFrame.Info
    Skin.UIPanelButtonTemplate(Info.SaveButton)
    Info.SaveButton:SetPoint("BOTTOMLEFT", GuildBankFrame.MoneyFrameBG, "TOPLEFT", 0, 5)

    Skin.ScrollFrameTemplate(Info.ScrollFrame)
    Base.SetBackdrop(Info.ScrollFrame, Color.gray, 0.5)
    Info.ScrollFrame:SetPoint("TOPLEFT", bg, 25, -42)
    Info.ScrollFrame:SetPoint("BOTTOMRIGHT", bg, -40, 65)
    Info.ScrollFrame:SetBackdropOption("offsets", {
        left = -5,
        right = -24,
        top = -5,
        bottom = -5,
    })

    -------------------------
    -- GuildBankPopupFrame --
    -------------------------
    local GuildBankPopupFrame = _G.GuildBankPopupFrame
    Skin.IconSelectorPopupFrameTemplate(GuildBankPopupFrame)
    GuildBankPopupFrame:HookScript("OnShow", Hook.GuildBankPopupFrameMixin.OnShow)

    ------------------------
    -- GuildItemSearchBox --
    ------------------------
    Skin.BagSearchBoxTemplate(_G.GuildItemSearchBox)
    _G.GuildItemSearchBox:SetPoint("TOPRIGHT", bg, -30, -9)
end
