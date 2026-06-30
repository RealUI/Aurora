local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals next ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

-- TBC Classic Anniversary GuildBankUI skin.
--
-- IMPORTANT: In TBC, GuildBankFrame is a plain <Frame> with NO `inherits`
-- attribute (verified against wow-ui-source-tbc Blizzard_GuildBankUI.xml). It
-- does NOT inherit BasicFrameTemplate or ButtonFrameTemplate, so the Mainline
-- skin's `Skin.BasicFrameTemplate(GuildBankFrame)` call is not appropriate here.
-- This file uses manual skinning (hide border/artwork regions, then apply
-- Base.SetBackdrop directly), mirroring the part-2 BankFrame fix.
--
-- GuildBankItemButtonTemplate DOES inherit ItemButtonTemplate in TBC, so
-- Skin.FrameTypeItemButton is safe to call on the column buttons.

local NUM_SLOTS_PER_GUILDBANK_GROUP = 14
local NUM_GUILDBANK_COLUMNS = 7

do --[[ AddOns\Blizzard_GuildBankUI.lua ]]
    Hook.GuildBankPopupFrameMixin = {}
    function Hook.GuildBankPopupFrameMixin:OnShow()
        if _G.GuildBankPopupButton1 and _G.GuildBankPopupFrame and _G.GuildBankPopupFrame.ScrollFrame then
            _G.GuildBankPopupButton1:SetPoint("TOPLEFT", _G.GuildBankPopupFrame.ScrollFrame, 0, -1)
        end
    end
end

do --[[ AddOns\Blizzard_GuildBankUI.xml ]]
    function Skin.GuildBankItemButtonTemplate(ItemButton)
        if not ItemButton then return end
        if Skin.FrameTypeItemButton then
            Skin.FrameTypeItemButton(ItemButton)
        elseif Skin.FrameTypeButton then
            Skin.FrameTypeButton(ItemButton)
        end
        ItemButton:SetBackdropOptions({
            bgFile = [[Interface\PaperDoll\UI-Backpack-EmptySlot]],
            tile = false
        })
        ItemButton:SetBackdropColor(1, 1, 1, 0.75)
        local bg = ItemButton:GetBackdropTexture("bg")
        if bg then
            Base.CropIcon(bg)
        end
    end

    function Skin.GuildBankFrameColumnTemplate(Frame)
        if not Frame then return end
        if Frame.Background then Frame.Background:Hide() end
        Base.SetBackdrop(Frame, Color.gray, 0.5)
        Frame:SetBackdropOption("offsets", {
            left = 2,
            right = 2,
            top = -2,
            bottom = 2,
        })

        if Frame.Buttons then
            for i = 1, NUM_SLOTS_PER_GUILDBANK_GROUP do
                Skin.GuildBankItemButtonTemplate(Frame.Buttons[i])
            end
        end
    end

    function Skin.GuildBankTabTemplate(Frame)
        if not Frame then return end
        if Skin.SideTabTemplate then
            Skin.SideTabTemplate(Frame)
        end
    end

    function Skin.GuildBankFrameTabTemplate(Frame)
        if not Frame then return end
        if Skin.PanelTabButtonTemplate then
            Skin.PanelTabButtonTemplate(Frame)
        elseif Skin.CharacterFrameTabButtonTemplate then
            Skin.CharacterFrameTabButtonTemplate(Frame)
        end
    end

    function Skin.GuildBankPopupButtonTemplate(CheckButton)
        if not CheckButton then return end
        if Skin.PopupButtonTemplate then
            Skin.PopupButtonTemplate(CheckButton)
        end
    end
end

function private.AddOns.Blizzard_GuildBankUI()
    local GuildBankFrame = _G.GuildBankFrame
    if not GuildBankFrame then return end

    -- Manual skinning: GuildBankFrame is a plain Frame in TBC.
    -- Hide all border/artwork textures (incl. GuildBankFrameLeft/Right frame
    -- art, Portrait, and the tab title/limit border textures) before applying
    -- the Aurora backdrop.
    for _, region in next, {GuildBankFrame:GetRegions()} do
        if region and region.IsObjectType and region:IsObjectType("Texture") then
            region:Hide()
        end
    end

    -- Named global border art (defense-in-depth; covered by GetRegions above)
    if _G.GuildBankFrameLeft then _G.GuildBankFrameLeft:Hide() end
    if _G.GuildBankFrameRight then _G.GuildBankFrameRight:Hide() end

    -- parentKey textures / decorative frames
    if GuildBankFrame.Portrait then GuildBankFrame.Portrait:Hide() end
    if GuildBankFrame.Emblem then GuildBankFrame.Emblem:Hide() end

    -- Apply Aurora backdrop AFTER hiding textures (ordering rule)
    Base.SetBackdrop(GuildBankFrame, Color.frame, Util.GetFrameAlpha())
    local bg = GuildBankFrame:GetBackdropTexture("bg")

    -- Close button (anonymous UIPanelCloseButton child)
    if _G.GuildBankFrameCloseButton and Skin.UIPanelCloseButton then
        Skin.UIPanelCloseButton(_G.GuildBankFrameCloseButton)
    end

    -- Item button columns (Column1..Column7 / Columns array)
    if GuildBankFrame.Columns then
        for i = 1, NUM_GUILDBANK_COLUMNS do
            if GuildBankFrame.Columns[i] then
                Skin.GuildBankFrameColumnTemplate(GuildBankFrame.Columns[i])
            end
        end
    end

    -- Money frames
    if GuildBankFrame.MoneyFrame and Skin.SmallMoneyFrameTemplate then
        Skin.SmallMoneyFrameTemplate(GuildBankFrame.MoneyFrame)
    end
    if GuildBankFrame.WithdrawMoneyFrame and Skin.SmallMoneyFrameTemplate then
        Skin.SmallMoneyFrameTemplate(GuildBankFrame.WithdrawMoneyFrame)
    end

    -- Deposit / Withdraw buttons
    if GuildBankFrame.DepositButton and Skin.UIPanelButtonTemplate then
        Skin.UIPanelButtonTemplate(GuildBankFrame.DepositButton)
    end
    if GuildBankFrame.WithdrawButton and Skin.UIPanelButtonTemplate then
        Skin.UIPanelButtonTemplate(GuildBankFrame.WithdrawButton)
    end

    -- Frame tabs (GuildBankFrameTab1..4 / FrameTabs array)
    if GuildBankFrame.FrameTabs then
        for i = 1, 4 do
            Skin.GuildBankFrameTabTemplate(GuildBankFrame.FrameTabs[i])
        end
    else
        for i = 1, 4 do
            Skin.GuildBankFrameTabTemplate(_G["GuildBankFrameTab" .. i])
        end
    end

    -- Bank tabs (GuildBankTab1..8 / BankTabs array)
    if GuildBankFrame.BankTabs then
        for i = 1, 8 do
            Skin.GuildBankTabTemplate(GuildBankFrame.BankTabs[i])
        end
    else
        for i = 1, 8 do
            Skin.GuildBankTabTemplate(_G["GuildBankTab" .. i])
        end
    end

    -------------
    -- BuyInfo --
    -------------
    local BuyInfo = GuildBankFrame.BuyInfo
    if BuyInfo then
        if _G.GuildBankFrameTabCostMoneyFrame and Skin.SmallMoneyFrameTemplate then
            Skin.SmallMoneyFrameTemplate(_G.GuildBankFrameTabCostMoneyFrame)
        end
        if BuyInfo.PurchaseButton and Skin.UIPanelButtonTemplate then
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
    end

    -------------------
    -- GuildBankInfo --
    -------------------
    local Info = GuildBankFrame.Info
    if Info then
        if Info.SaveButton and Skin.UIPanelButtonTemplate then
            Skin.UIPanelButtonTemplate(Info.SaveButton)
        end

        if Info.ScrollFrame and Skin.UIPanelScrollFrameTemplate then
            Skin.UIPanelScrollFrameTemplate(Info.ScrollFrame)
        end
    end

    -------------------------
    -- GuildBankPopupFrame --
    -------------------------
    local GuildBankPopupFrame = _G.GuildBankPopupFrame
    if GuildBankPopupFrame then
        for _, region in next, {GuildBankPopupFrame:GetRegions()} do
            if region and region.IsObjectType and region:IsObjectType("Texture") then
                region:Hide()
            end
        end
        if GuildBankPopupFrame.BorderBox then
            for _, region in next, {GuildBankPopupFrame.BorderBox:GetRegions()} do
                if region and region.IsObjectType and region:IsObjectType("Texture") then
                    region:Hide()
                end
            end
        end
        Base.SetBackdrop(GuildBankPopupFrame, Color.frame, Util.GetFrameAlpha())

        if GuildBankPopupFrame.CancelButton and Skin.UIPanelButtonTemplate then
            Skin.UIPanelButtonTemplate(GuildBankPopupFrame.CancelButton)
        end
        if GuildBankPopupFrame.OkayButton and Skin.UIPanelButtonTemplate then
            Skin.UIPanelButtonTemplate(GuildBankPopupFrame.OkayButton)
        end
        if GuildBankPopupFrame.ScrollFrame and Skin.ListScrollFrameTemplate then
            Skin.ListScrollFrameTemplate(GuildBankPopupFrame.ScrollFrame)
        end

        GuildBankPopupFrame:HookScript("OnShow", Hook.GuildBankPopupFrameMixin.OnShow)
    end

    ------------------------
    -- GuildItemSearchBox --
    ------------------------
    if _G.GuildItemSearchBox and Skin.BagSearchBoxTemplate then
        Skin.BagSearchBoxTemplate(_G.GuildItemSearchBox)
        if bg then
            _G.GuildItemSearchBox:SetPoint("TOPRIGHT", bg, -30, -9)
        end
    end
end
