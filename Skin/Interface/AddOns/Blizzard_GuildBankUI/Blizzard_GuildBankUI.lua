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
    if not GuildBankFrame then return end

    Skin.BasicFrameTemplate(GuildBankFrame)
    GuildBankFrame:SetBackdropOption("offsets", {
        left = 0,
        right = 0,
        top = 20,
        bottom = 0,
    })
    local bg = GuildBankFrame:GetBackdropTexture("bg")

    if GuildBankFrame.TabTitleBG then GuildBankFrame.TabTitleBG:SetAlpha(0) end
    if GuildBankFrame.TabTitleBGLeft then GuildBankFrame.TabTitleBGLeft:SetAlpha(0) end
    if GuildBankFrame.TabTitleBGRight then GuildBankFrame.TabTitleBGRight:SetAlpha(0) end

    if GuildBankFrame.TabLimitBG then GuildBankFrame.TabLimitBG:SetAlpha(0) end
    if GuildBankFrame.TabLimitBGLeft then GuildBankFrame.TabLimitBGLeft:SetAlpha(0) end
    if GuildBankFrame.TabLimitBGRight then GuildBankFrame.TabLimitBGRight:SetAlpha(0) end

    -- Hide outer/inner border textures (nil-safe)
    local borderNames = {
        "GuildBankFrameBottomLeftOuter", "GuildBankFrameBottomRightOuter",
        "GuildBankFrameTopRightOuter", "GuildBankFrameTopLeftOuter",
        "GuildBankFrameLeftOuter", "GuildBankFrameRightOuter",
        "GuildBankFrameTopOuter", "GuildBankFrameBottomOuter",
        "GuildBankFrameBottomLeftInner", "GuildBankFrameBottomRightInner",
        "GuildBankFrameTopRightInner", "GuildBankFrameTopLeftInner",
        "GuildBankFrameLeftInner", "GuildBankFrameRightInner",
        "GuildBankFrameTopInner", "GuildBankFrameBottomInner",
    }
    for _, name in _G.ipairs(borderNames) do
        if _G[name] then _G[name]:Hide() end
    end

    if GuildBankFrame.RedMarbleBG then GuildBankFrame.RedMarbleBG:Hide() end
    if GuildBankFrame.BlackBG then GuildBankFrame.BlackBG:Hide() end

    if GuildBankFrame.Columns then
        for i = 1, NUM_GUILDBANK_COLUMNS do
            if GuildBankFrame.Columns[i] then
                Skin.GuildBankFrameColumnTemplate(GuildBankFrame.Columns[i])
            end
        end
    end

    if GuildBankFrame.MoneyFrameBG then
        Skin.ThinGoldEdgeTemplate(GuildBankFrame.MoneyFrameBG)
        GuildBankFrame.MoneyFrameBG:ClearAllPoints()
        if bg then
            GuildBankFrame.MoneyFrameBG:SetPoint("TOPLEFT", bg, "BOTTOMLEFT", 5, 28)
            GuildBankFrame.MoneyFrameBG:SetPoint("BOTTOMRIGHT", bg, -5, 5)
        end
        if GuildBankFrame.MoneyFrameBG.LimitLabel then
            GuildBankFrame.MoneyFrameBG.LimitLabel:SetPoint("BOTTOMLEFT", GuildBankFrame.MoneyFrameBG, 5, 5)
        end
    end

    if GuildBankFrame.MoneyFrame then
        Skin.SmallMoneyFrameTemplate(GuildBankFrame.MoneyFrame)
        if GuildBankFrame.MoneyFrameBG then
            GuildBankFrame.MoneyFrame:SetPoint("BOTTOMRIGHT", GuildBankFrame.MoneyFrameBG, 0, 5)
        end
    end
    if GuildBankFrame.WithdrawMoneyFrame then
        Skin.SmallMoneyFrameTemplate(GuildBankFrame.WithdrawMoneyFrame)
    end

    if GuildBankFrame.DepositButton then
        Skin.UIPanelButtonTemplate(GuildBankFrame.DepositButton)
    end
    if GuildBankFrame.WithdrawButton then
        Skin.UIPanelButtonTemplate(GuildBankFrame.WithdrawButton)
    end
    if GuildBankFrame.DepositButton and GuildBankFrame.WithdrawButton and GuildBankFrame.MoneyFrameBG then
        Util.PositionRelative("BOTTOMRIGHT", GuildBankFrame.MoneyFrameBG, "TOPRIGHT", 0, 5, 5, "Left", {
            GuildBankFrame.DepositButton,
            GuildBankFrame.WithdrawButton,
        })
    end

    if GuildBankFrame.Tabs then
        for i = 1, 4 do
            if GuildBankFrame.Tabs[i] then
                Skin.GuildBankFrameTabTemplate(GuildBankFrame.Tabs[i])
            end
        end
        if bg then
            Util.PositionRelative("TOPLEFT", bg, "BOTTOMLEFT", 20, -1, 1, "Right", GuildBankFrame.Tabs)
        end
    end

    if GuildBankFrame.BankTabs then
        for i = 1, 8 do
            if GuildBankFrame.BankTabs[i] then
                Skin.GuildBankTabTemplate(GuildBankFrame.BankTabs[i])
            end
        end
        if bg then
            Util.PositionRelative("TOPLEFT", bg, "TOPRIGHT", 0, -33, -9, "Down", GuildBankFrame.BankTabs)
        end
    end

    -------------
    -- BuyInfo --
    -------------
    local BuyInfo = GuildBankFrame.BuyInfo
    if BuyInfo then
        if _G.GuildBankFrameTabCostMoneyFrame then
            Skin.SmallMoneyFrameTemplate(_G.GuildBankFrameTabCostMoneyFrame)
        end
        if BuyInfo.PurchaseButton then
            Skin.UIPanelButtonTemplate(BuyInfo.PurchaseButton)
        end
    end

    ---------
    -- Log --
    ---------
    local Log = GuildBankFrame.Log
    if Log then
        if Log.MessageFrame and bg then
            Base.SetBackdrop(Log.MessageFrame, Color.gray, 0.5)
            Log.MessageFrame:SetPoint("TOPLEFT", bg, 25, -42)
            Log.MessageFrame:SetPoint("BOTTOMRIGHT", bg, -21, 65)
            Log.MessageFrame:SetBackdropOption("offsets", {
                left = -5,
                right = -5,
                top = -5,
                bottom = -5,
            })
        end

        if Log.ScrollBar then
            Skin.MinimalScrollBar(Log.ScrollBar)
        end
    end

    -------------------
    -- GuildBankInfo --
    -------------------
    local Info = GuildBankFrame.Info
    if Info then
        if Info.SaveButton then
            Skin.UIPanelButtonTemplate(Info.SaveButton)
            if GuildBankFrame.MoneyFrameBG then
                Info.SaveButton:SetPoint("BOTTOMLEFT", GuildBankFrame.MoneyFrameBG, "TOPLEFT", 0, 5)
            end
        end

        if Info.ScrollFrame and bg then
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
        end
    end

    -------------------------
    -- GuildBankPopupFrame --
    -------------------------
    local GuildBankPopupFrame = _G.GuildBankPopupFrame
    if GuildBankPopupFrame then
        Skin.IconSelectorPopupFrameTemplate(GuildBankPopupFrame)
        GuildBankPopupFrame:HookScript("OnShow", Hook.GuildBankPopupFrameMixin.OnShow)
    end

    ------------------------
    -- GuildItemSearchBox --
    ------------------------
    if _G.GuildItemSearchBox then
        Skin.BagSearchBoxTemplate(_G.GuildItemSearchBox)
        if bg then
            _G.GuildItemSearchBox:SetPoint("TOPRIGHT", bg, -30, -9)
        end
    end
end
