local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals select ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

function private.FrameXML.MailFrame()
    ---------------
    -- MailFrame --
    ---------------
    local MailFrame = _G.MailFrame
    if not MailFrame then return end

    -- Apply Aurora backdrop
    Base.SetBackdrop(MailFrame, Color.frame, Util.GetFrameAlpha())

    -- Hide portrait and border textures
    for i = 1, MailFrame:GetNumRegions() do
        local region = _G.select(i, MailFrame:GetRegions())
        if region and region.GetObjectType and region:GetObjectType() == "Texture" then
            local texture = region:GetTexture()
            if texture and type(texture) == "string" then
                if texture:find("Mail%-Icon") or texture:find("UI%-Character") then
                    region:Hide()
                end
            end
        end
    end

    -- Skin close button
    if MailFrame.CloseButton then
        Skin.UIPanelCloseButton(MailFrame.CloseButton)
    elseif _G.MailFrameCloseButton then
        Skin.UIPanelCloseButton(_G.MailFrameCloseButton)
    end

    -- Hide trial error styling (keep the font string)
    if MailFrame.trialError then
        MailFrame.trialError:ClearAllPoints()
        MailFrame.trialError:SetPoint("TOP", 20, -30)
    end

    ----------------
    -- InboxFrame --
    ----------------
    local InboxFrame = _G.InboxFrame
    if InboxFrame then
        -- Hide background
        if _G.InboxFrameBg then
            _G.InboxFrameBg:Hide()
        end

        -- Skin inbox items (TBC uses MailItem1-7)
        local INBOXITEMS_TO_DISPLAY = _G.INBOXITEMS_TO_DISPLAY or 7
        for i = 1, INBOXITEMS_TO_DISPLAY do
            local item = _G["MailItem" .. i]
            if item then
                -- Hide the left/right border textures and divider
                for j = 1, item:GetNumRegions() do
                    local region = _G.select(j, item:GetRegions())
                    if region and region.GetObjectType and region:GetObjectType() == "Texture" then
                        local texture = region:GetTexture()
                        if texture and type(texture) == "string" and texture:find("MailItemBorder") then
                            region:Hide()
                        elseif region:GetHeight() and region:GetHeight() < 4 then
                            -- Divider line
                            region:Hide()
                        end
                    end
                end

                -- Skin the item button
                local button = item.Button or _G["MailItem" .. i .. "Button"]
                if button then
                    button:SetSize(39, 39)

                    -- Hide slot background texture
                    local slot = _G["MailItem" .. i .. "ButtonSlot"]
                    if slot then
                        slot:Hide()
                    end

                    -- Crop the icon
                    local icon = button.Icon or _G["MailItem" .. i .. "ButtonIcon"]
                    if icon then
                        Base.CropIcon(icon)
                    end

                    -- Crop highlight and checked textures
                    local highlight = button:GetHighlightTexture()
                    if highlight then
                        Base.CropIcon(highlight)
                    end
                    local checked = button:GetCheckedTexture()
                    if checked then
                        Base.CropIcon(checked)
                    end

                    -- Create backdrop border for item quality
                    local bg = _G.CreateFrame("Frame", nil, item)
                    bg:SetFrameLevel(button:GetFrameLevel() - 1)
                    bg:SetPoint("TOPLEFT", button, -1, 1)
                    bg:SetPoint("BOTTOMRIGHT", button, 1, -1)

                    Base.CreateBackdrop(bg, {
                        bgFile = [[Interface\PaperDoll\UI-Backpack-EmptySlot]],
                        tile = false,
                        insets = {left = 1, right = 1, top = 1, bottom = 1},
                        edgeSize = 1,
                    })
                    Base.CropIcon(bg:GetBackdropTexture("bg"))
                    bg:SetBackdropColor(1, 1, 1, 0.75)
                    bg:SetBackdropBorderColor(Color.frame, 1)
                    button._auroraIconBorder = bg
                end
            end
        end

        -- Skin prev/next page buttons
        if _G.InboxPrevPageButton then
            Skin.NavButtonPrevious(_G.InboxPrevPageButton)
        end
        if _G.InboxNextPageButton then
            Skin.NavButtonNext(_G.InboxNextPageButton)
        end

        -- Skin Open All Mail button
        if _G.OpenAllMail then
            Skin.UIPanelButtonTemplate(_G.OpenAllMail)
        end
    end

    -------------------
    -- SendMailFrame --
    -------------------
    local SendMailFrame = _G.SendMailFrame
    if SendMailFrame then
        -- Hide background textures on send mail frame
        if _G.SendStationeryBackgroundLeft then
            _G.SendStationeryBackgroundLeft:Hide()
        end
        if _G.SendStationeryBackgroundRight then
            _G.SendStationeryBackgroundRight:Hide()
        end

        -- Hide horizontal bar textures
        if _G.SendMailHorizontalBarLeft then
            _G.SendMailHorizontalBarLeft:Hide()
        end
        if _G.SendMailHorizontalBarLeft2 then
            _G.SendMailHorizontalBarLeft2:Hide()
        end
        -- Hide the right parts of horizontal bars
        for i = 1, SendMailFrame:GetNumRegions() do
            local region = _G.select(i, SendMailFrame:GetRegions())
            if region and region.GetObjectType and region:GetObjectType() == "Texture" then
                local texture = region:GetTexture()
                if texture and type(texture) == "string" and texture:find("UI%-ClassTrainer%-HorizontalBar") then
                    region:Hide()
                end
            end
        end

        -- Skin the mail body edit box
        local MailEditBox = _G.MailEditBox
        if MailEditBox then
            if Skin.ScrollingEditBoxTemplate then
                Skin.ScrollingEditBoxTemplate(MailEditBox)
            end
        end

        -- Skin the scroll bar
        local MailEditBoxScrollBar = _G.MailEditBoxScrollBar
        if MailEditBoxScrollBar then
            if Skin.WowClassicScrollBar then
                Skin.WowClassicScrollBar(MailEditBoxScrollBar)
            end
        end

        -- Skin name and subject edit boxes
        local SendMailNameEditBox = _G.SendMailNameEditBox
        if SendMailNameEditBox then
            Skin.FrameTypeEditBox(SendMailNameEditBox)
            SendMailNameEditBox:SetHeight(22)
            -- Hide border textures
            local left = _G.SendMailNameEditBoxLeft
            if left then left:Hide() end
            local mid = _G.SendMailNameEditBoxMiddle
            if mid then mid:Hide() end
            local right = _G.SendMailNameEditBoxRight
            if right then right:Hide() end
        end

        local SendMailSubjectEditBox = _G.SendMailSubjectEditBox
        if SendMailSubjectEditBox then
            Skin.FrameTypeEditBox(SendMailSubjectEditBox)
            SendMailSubjectEditBox:SetHeight(22)
            -- Hide border textures
            local left = _G.SendMailSubjectEditBoxLeft
            if left then left:Hide() end
            local mid = _G.SendMailSubjectEditBoxMiddle
            if mid then mid:Hide() end
            local right = _G.SendMailSubjectEditBoxRight
            if right then right:Hide() end
        end

        -- Skin send mail cost money frame
        if _G.SendMailCostMoneyFrame then
            if Skin.SmallMoneyFrameTemplate then
                Skin.SmallMoneyFrameTemplate(_G.SendMailCostMoneyFrame)
            end
        end

        -- Skin attachment slots (SendMailAttachment1 through ATTACHMENTS_MAX_SEND)
        local ATTACHMENTS_MAX_SEND = _G.ATTACHMENTS_MAX_SEND or 16
        local SendMailAttachments = SendMailFrame.SendMailAttachments
        for i = 1, ATTACHMENTS_MAX_SEND do
            local attachment = (SendMailAttachments and SendMailAttachments[i]) or _G["SendMailAttachment" .. i]
            if attachment then
                -- Hide slot background texture
                local bgTex = attachment:GetRegions()
                if bgTex then
                    bgTex:Hide()
                end

                -- Create backdrop
                local bg = _G.CreateFrame("Frame", nil, attachment)
                bg:SetFrameLevel(attachment:GetFrameLevel() - 1)
                bg:SetPoint("TOPLEFT", -1, 1)
                bg:SetPoint("BOTTOMRIGHT", 1, -1)

                Base.CreateBackdrop(bg, {
                    bgFile = [[Interface\PaperDoll\UI-Backpack-EmptySlot]],
                    tile = false,
                    insets = {left = 1, right = 1, top = 1, bottom = 1},
                    edgeSize = 1,
                })
                Base.CropIcon(bg:GetBackdropTexture("bg"))
                bg:SetBackdropColor(1, 1, 1, 0.75)
                bg:SetBackdropBorderColor(Color.frame, 1)
                attachment._auroraIconBorder = bg

                -- Crop highlight texture
                local highlight = attachment:GetHighlightTexture()
                if highlight then
                    Base.CropIcon(highlight)
                end
            end
        end

        -- Skin money input frame
        if _G.SendMailMoney then
            if Skin.MoneyInputFrameTemplate then
                Skin.MoneyInputFrameTemplate(_G.SendMailMoney)
            end
        end

        -- Skin radio buttons (Send Money / COD)
        if _G.SendMailSendMoneyButton then
            Skin.UIRadioButtonTemplate(_G.SendMailSendMoneyButton)
        end
        if _G.SendMailCODButton then
            Skin.UIRadioButtonTemplate(_G.SendMailCODButton)
        end

        -- Skin money inset and background
        if _G.SendMailMoneyInset then
            if Skin.InsetFrameTemplate then
                Skin.InsetFrameTemplate(_G.SendMailMoneyInset)
            end
        end
        if _G.SendMailMoneyBg then
            if Skin.ThinGoldEdgeTemplate then
                Skin.ThinGoldEdgeTemplate(_G.SendMailMoneyBg)
            end
        end
        if _G.SendMailMoneyFrame then
            if Skin.SmallMoneyFrameTemplate then
                Skin.SmallMoneyFrameTemplate(_G.SendMailMoneyFrame)
            end
        end

        -- Skin send/cancel buttons
        if _G.SendMailCancelButton then
            Skin.UIPanelButtonTemplate(_G.SendMailCancelButton)
        end
        if _G.SendMailMailButton then
            Skin.UIPanelButtonTemplate(_G.SendMailMailButton)
        end
    end

    ------------------
    -- MailFrame Tabs --
    ------------------
    if _G.MailFrameTab1 then
        Skin.FriendsFrameTabTemplate(_G.MailFrameTab1)
    end
    if _G.MailFrameTab2 then
        Skin.FriendsFrameTabTemplate(_G.MailFrameTab2)
    end

    -------------------
    -- OpenMailFrame --
    -------------------
    local OpenMailFrame = _G.OpenMailFrame
    if OpenMailFrame then
        Base.SetBackdrop(OpenMailFrame, Color.frame, Util.GetFrameAlpha())

        -- Hide portrait icon
        if _G.OpenMailFrameIcon then
            _G.OpenMailFrameIcon:Hide()
        end

        -- Hide horizontal bar textures
        if _G.OpenMailHorizontalBarLeft then
            _G.OpenMailHorizontalBarLeft:Hide()
        end
        -- Hide any additional horizontal bar regions
        for i = 1, OpenMailFrame:GetNumRegions() do
            local region = _G.select(i, OpenMailFrame:GetRegions())
            if region and region.GetObjectType and region:GetObjectType() == "Texture" then
                local texture = region:GetTexture()
                if texture and type(texture) == "string" and texture:find("UI%-ClassTrainer%-HorizontalBar") then
                    region:Hide()
                end
            end
        end

        -- Hide stationery backgrounds
        if _G.OpenStationeryBackgroundLeft then
            _G.OpenStationeryBackgroundLeft:Hide()
        end
        if _G.OpenStationeryBackgroundRight then
            _G.OpenStationeryBackgroundRight:Hide()
        end

        -- Skin close button
        if OpenMailFrame.CloseButton then
            Skin.UIPanelCloseButton(OpenMailFrame.CloseButton)
        elseif _G.OpenMailFrameCloseButton then
            Skin.UIPanelCloseButton(_G.OpenMailFrameCloseButton)
        end

        -- Skin scroll frame
        if _G.OpenMailScrollFrame then
            if Skin.UIPanelScrollFrameTemplate then
                Skin.UIPanelScrollFrameTemplate(_G.OpenMailScrollFrame)
            end
        end

        -- Hide scroll bar backgrounds
        if _G.OpenScrollBarBackgroundTop then
            _G.OpenScrollBarBackgroundTop:Hide()
        end

        -- Skin report spam button
        if _G.OpenMailReportSpamButton then
            Skin.UIPanelButtonTemplate(_G.OpenMailReportSpamButton)
        end

        -- Skin letter button
        if _G.OpenMailLetterButton then
            if Skin.FrameTypeItemButton then
                Skin.FrameTypeItemButton(_G.OpenMailLetterButton)
            end
        end

        -- Skin money button
        if _G.OpenMailMoneyButton then
            if Skin.FrameTypeItemButton then
                Skin.FrameTypeItemButton(_G.OpenMailMoneyButton)
            end
        end

        -- Skin open mail attachment buttons
        local ATTACHMENTS_MAX_RECEIVE = _G.ATTACHMENTS_MAX_RECEIVE or 16
        local OpenMailAttachments = OpenMailFrame.OpenMailAttachments
        for i = 1, ATTACHMENTS_MAX_RECEIVE do
            -- TBC instances are named OpenMailAttachmentButton1-16 (not Mainline's OpenMailAttachment1)
            local attachment = (OpenMailAttachments and OpenMailAttachments[i]) or _G["OpenMailAttachmentButton" .. i]
            if attachment then
                if Skin.FrameTypeItemButton then
                    Skin.FrameTypeItemButton(attachment)
                end
            end
        end

        -- Style arithmetic line (invoice separator)
        if _G.OpenMailArithmeticLine then
            _G.OpenMailArithmeticLine:SetColorTexture(Color.grayLight:GetRGB())
            _G.OpenMailArithmeticLine:SetSize(256, 1)
        end

        -- Skin action buttons
        if _G.OpenMailCancelButton then
            Skin.UIPanelButtonTemplate(_G.OpenMailCancelButton)
        end
        if _G.OpenMailDeleteButton then
            Skin.UIPanelButtonTemplate(_G.OpenMailDeleteButton)
        end
        if _G.OpenMailReplyButton then
            Skin.UIPanelButtonTemplate(_G.OpenMailReplyButton)
        end
    end
end
