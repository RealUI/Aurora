local _, private = ...
if private.shouldSkip() then return end

--[[ Core ]]
local Aurora = private.Aurora
local Base, Skin = Aurora.Base, Aurora.Skin
local Util = Aurora.Util

--[[ Classic Era BankFrame.
    Evidence: wow-ui-source-era/Interface/AddOns/Blizzard_UIPanels_Game/
    Vanilla/BankFrame.xml (root L83: plain sheet, named BankPortraitTexture;
    BankSlotsFrame carries the Bank-Parts slot backgrounds and rivets; item
    and bag slots are ItemButtonTemplate-derived, created for the slots
    frame). Quality borders arrive via the global SetItemButtonQuality hook.
]]

local function SkinBankItemButton(Button)
    Skin.FrameTypeItemButton(Button)

    if Button.IconQuestTexture then
        Base.CropIcon(Button.IconQuestTexture)
    end
    if Button.HighlightFrame and Button.HighlightFrame.HighlightTexture then
        Base.CropIcon(Button.HighlightFrame.HighlightTexture)
    end
end

function private.FrameXML.BankFrame()
    local BankFrame = _G.BankFrame

    Util.HideFrameTextures(BankFrame)
    _G.BankPortraitTexture:SetAlpha(0)

    Skin.FrameTypeFrame(BankFrame)
    -- TBC re-anchored the slot grid ~48px further right than era — content
    -- overflows the classic 30px right art band, so the backdrop hugs the
    -- frame edge instead (bottom from TBC's HitRectInsets)
    BankFrame:SetBackdropOption("offsets", {
        left = 10,
        right = -15,
        top = 0,
        bottom = 70,
    })

    Skin.UIPanelCloseButton(_G.BankCloseButton)

    -- Slot backgrounds and rivets
    Util.HideFrameTextures(_G.BankSlotsFrame)

    local i = 1
    while _G["BankFrameItem"..i] do
        SkinBankItemButton(_G["BankFrameItem"..i])
        i = i + 1
    end

    i = 1
    while _G["BankFrameBag"..i] do
        SkinBankItemButton(_G["BankFrameBag"..i])
        i = i + 1
    end

    if _G.BankFramePurchaseInfo then
        Util.HideFrameTextures(_G.BankFramePurchaseInfo)
    end
    if _G.BankFramePurchaseButton then
        Skin.UIPanelButtonTemplate(_G.BankFramePurchaseButton)
    end
end
