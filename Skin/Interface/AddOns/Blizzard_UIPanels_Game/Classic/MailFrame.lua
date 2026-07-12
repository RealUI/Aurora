local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs select

--[[ Core ]]
local Aurora = private.Aurora
local Base, Skin = Aurora.Base, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

--[[ Classic-family MailFrame + OpenMailFrame (era/TBC/Mists share this
    Classic file). Evidence: wow-ui-source-*/Interface/AddOns/
    Blizzard_UIPanels_Game/Classic/MailFrame.xml (MailFrame L264 and
    OpenMailFrame L860, both ButtonFrameTemplate; tabs inherit
    CharacterFrameTabButtonTemplate via FriendsFrameTabTemplate; the mail
    body editor is a modern ScrollingEditBoxTemplate). Mail text colors are
    covered by the Classic fonts file (MailTextFontNormal).
]]

-- Inbox rows: two unnamed MailItemBorder textures + Sender/Subject text +
-- an item CheckButton with parentKey Icon and a named $parentSlot.
local function SkinMailItem(Frame)
    Util.HideFrameTextures(Frame)

    local itemButton = Frame.Button
    if itemButton then
        local name = itemButton:GetName()
        local slot = _G[name.."Slot"]
        if slot then
            slot:SetAlpha(0)
        end
        Base.CropIcon(itemButton.Icon)
        Base.CropIcon(itemButton:GetHighlightTexture())
        Base.CropIcon(itemButton:GetCheckedTexture())
    end
end

-- Classic 32x32 page arrows with a possible unnamed circle-background
-- region; strip every texture that is not a button state texture, then
-- apply the Aurora nav look.
local function SkinPageArrow(Button, isNext)
    local normal = Button:GetNormalTexture()
    local pushed = Button:GetPushedTexture()
    local disabled = Button:GetDisabledTexture()
    local highlight = Button:GetHighlightTexture()
    for i = 1, select("#", Button:GetRegions()) do
        local region = select(i, Button:GetRegions())
        if region:IsObjectType("Texture")
            and region ~= normal and region ~= pushed
            and region ~= disabled and region ~= highlight then
            region:SetTexture("")
        end
    end

    if isNext then
        Skin.NavButtonNext(Button)
    else
        Skin.NavButtonPrevious(Button)
    end
end

local function SkinMoneyInputFrame(Frame)
    local name = Frame:GetName()
    for _, denom in ipairs({"Gold", "Silver", "Copper"}) do
        local box = _G[name..denom]
        if box then
            -- strip the Common-Input border art BEFORE the backdrop is
            -- created, or the sweep would hide Aurora's own textures
            Util.HideFrameTextures(box)
            Skin.FrameTypeEditBox(box)
        end
    end
end

-- Send-side attachment slots: unnamed slot background, no template icon —
-- the icon is the NormalTexture, created at runtime. Force-create it so it
-- can be cropped once (texcoords persist across SetNormalTexture).
local function SkinSendAttachment(Button)
    local highlight = Button:GetHighlightTexture()
    for i = 1, select("#", Button:GetRegions()) do
        local region = select(i, Button:GetRegions())
        if region:IsObjectType("Texture") and region ~= highlight
            and region ~= Button.IconBorder and region ~= Button.IconOverlay then
            region:SetTexture("")
        end
    end

    Base.SetBackdrop(Button, Color.black, Color.frame.a)
    Button:SetNormalTexture("")
    Base.CropIcon(Button:GetNormalTexture())
    Base.CropIcon(highlight)
end

function private.FrameXML.MailFrame()
    local MailFrame = _G.MailFrame

    -- Root strip BEFORE the template skin (package icon art lives on the
    -- root; Aurora's backdrop pieces must not be caught by the sweep)
    Util.HideFrameTextures(MailFrame, true)
    Skin.ButtonFrameTemplate(MailFrame)

    -- Inbox parchment sheet + package art (panel-level, not on the root);
    -- stationery backgrounds are re-SetTextured per letter, so alpha-hide.
    Util.HideFrameTextures(_G.InboxFrame, true)
    Util.HideFrameTextures(_G.SendMailFrame, true)
    for _, name in ipairs({"InboxFrameBg", "SendStationeryBackgroundLeft", "SendStationeryBackgroundRight"}) do
        local texture = _G[name]
        if texture then
            texture:SetAlpha(0)
        end
    end

    -- Inbox
    for i = 1, 7 do
        local item = _G["MailItem"..i]
        if item then
            SkinMailItem(item)
        end
    end
    SkinPageArrow(_G.InboxPrevPageButton, false)
    SkinPageArrow(_G.InboxNextPageButton, true)
    if _G.OpenAllMail then
        Skin.UIPanelButtonTemplate(_G.OpenAllMail)
    end

    -- Send mail (strip border art BEFORE creating the backdrops)
    Util.HideFrameTextures(_G.SendMailNameEditBox)
    Skin.FrameTypeEditBox(_G.SendMailNameEditBox)
    Util.HideFrameTextures(_G.SendMailSubjectEditBox)
    Skin.FrameTypeEditBox(_G.SendMailSubjectEditBox)
    Skin.ScrollingEditBoxTemplate(_G.MailEditBox)
    Skin.WowClassicScrollBar(_G.MailEditBoxScrollBar)

    for i = 1, 16 do
        local attachment = _G["SendMailAttachment"..i]
        if attachment then
            SkinSendAttachment(attachment)
        end
    end

    Skin.UIRadioButtonTemplate(_G.SendMailSendMoneyButton)
    Skin.UIRadioButtonTemplate(_G.SendMailCODButton)
    SkinMoneyInputFrame(_G.SendMailMoney)

    _G.SendMailMoneyInset:Hide()
    Util.HideFrameTextures(_G.SendMailMoneyBg)

    Skin.UIPanelButtonTemplate(_G.SendMailCancelButton)
    Skin.UIPanelButtonTemplate(_G.SendMailMailButton)

    Skin.CharacterFrameTabButtonTemplate(_G.MailFrameTab1)
    Skin.CharacterFrameTabButtonTemplate(_G.MailFrameTab2)

    ------------------
    -- OpenMailFrame --
    ------------------
    local OpenMailFrame = _G.OpenMailFrame
    -- Strip BEFORE the template skin: Aurora's backdrop pieces are unnamed
    -- textures on the frame and must not be caught by the region sweep.
    Util.HideFrameTextures(OpenMailFrame, true)
    Skin.ButtonFrameTemplate(OpenMailFrame)
    for _, name in ipairs({"OpenStationeryBackgroundLeft", "OpenStationeryBackgroundRight"}) do
        local texture = _G[name]
        if texture then
            texture:SetAlpha(0)
        end
    end

    Skin.UIPanelScrollFrameTemplate(_G.OpenMailScrollFrame)

    Skin.FrameTypeItemButton(_G.OpenMailLetterButton)
    Skin.FrameTypeItemButton(_G.OpenMailMoneyButton)
    for i = 1, 16 do
        local attachment = _G["OpenMailAttachmentButton"..i]
        if attachment then
            Skin.FrameTypeItemButton(attachment)
        end
    end

    for _, name in ipairs({"OpenMailReportSpamButton", "OpenMailCancelButton", "OpenMailDeleteButton", "OpenMailReplyButton"}) do
        local button = _G[name]
        if button then
            Skin.UIPanelButtonTemplate(button)
        end
    end
end
