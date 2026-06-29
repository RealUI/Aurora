local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals tinsert max

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color = Aurora.Color

--do --[[ AddOns\Blizzard_StaticPopup_Game\GameDialog.lua ]]
--end

do --[[ AddOns\Blizzard_StaticPopup_Game\GameDialog.lua ]]
    -- TAINT-SAFE: StaticPopup buttons trigger protected functions in
    -- OnAccept callbacks (e.g. UpgradeItem, JoinBattlefield).
    -- FrameTypeButton writes SetButtonColor/GetButtonColor + calls
    -- Base.SetBackdrop directly onto button tables, marking them as
    -- addon-modified → taint propagates through the callback chain.
    function Skin.StaticPopupButtonTemplate(Button)
        Skin.TaintSafeUIPanelButtonTemplate(Button)
    end

    function Skin.StaticPopupTemplate(Frame)
        if not Frame then
            if private.isDev then
                _G.print("ReportError: Frame is nil in StaticPopupTemplate - Report to Aurora developers.")
            end
            return
        end
        local background = Frame.BG
        if background and background.Top then
            background.Top:SetTexture("")
        end

        -- Modern (11.0+) ButtonContainer pattern
        local ButtonContainer = Frame.ButtonContainer
        if ButtonContainer then
            if ButtonContainer.Button1 then Skin.StaticPopupButtonTemplate(ButtonContainer.Button1) end
            if ButtonContainer.Button2 then Skin.StaticPopupButtonTemplate(ButtonContainer.Button2) end
            if ButtonContainer.Button3 then Skin.StaticPopupButtonTemplate(ButtonContainer.Button3) end
            if ButtonContainer.Button4 then Skin.StaticPopupButtonTemplate(ButtonContainer.Button4) end

            if ButtonContainer.Buttons then
                for i = 1, #ButtonContainer.Buttons do
                    Skin.StaticPopupButtonTemplate(ButtonContainer.Buttons[i])
                end
            end
        end

        if Frame.ExtraButton then
            Skin.StaticPopupButtonTemplate(Frame.ExtraButton)
        end
        if Frame.CloseButton then
            Skin.StaticPopupButtonTemplate(Frame.CloseButton)
        end

        -- EditBox now uses parentKey (not global string lookup) and TooltipBackdropTemplate
        -- (no Left/Right/Middle textures), so FrameTypeEditBox handles it directly.
        if Frame.EditBox then
            Skin.FrameTypeEditBox(Frame.EditBox)
        end

        -- Progress bar used for dialogs with countdown timers (e.g. cinematic skip).
        local border = Frame.ProgressBarBorder
        local fill   = Frame.ProgressBarFill
        if border and fill then
            border:SetAtlas("")
            border:SetTexture("Interface\\Buttons\\White8x8")
            border:SetVertexColor(Color.button:GetRGB())
            border:SetTexCoord(0, 1, 0, 1)

            fill:SetDrawLayer("BACKGROUND", -4)
            fill:SetAtlas("")
            fill:SetTexture("Interface\\Buttons\\White8x8")
            fill:SetVertexColor(Color.highlight:GetRGB())
        end

        if Frame.MoneyFrame then
            Skin.SmallMoneyFrameTemplate(Frame.MoneyFrame)
        end
        if Frame.MoneyInputFrame then
            Skin.MoneyInputFrameTemplate(Frame.MoneyInputFrame)
        end

        local ItemFrame = Frame.ItemFrame
        if ItemFrame then
            local nameFrame = ItemFrame.NameFrame
            Skin.FrameTypeFrame(ItemFrame)
            if nameFrame then nameFrame:Hide() end

            if ItemFrame.Item then
                Skin.FrameTypeItemButton(ItemFrame.Item)
                if ItemFrame.Item.IconBorder then
                    ItemFrame.Item.IconBorder:Hide()
                end
                local nameBG = _G.CreateFrame("Frame", nil, ItemFrame)
                nameBG:SetPoint("TOPLEFT", ItemFrame.Item, "TOPRIGHT", 2, 1)
                nameBG:SetPoint("BOTTOMLEFT", ItemFrame.Item, "BOTTOMRIGHT", 2, -1)
                nameBG:SetPoint("RIGHT", -4, 0)
                Base.SetBackdrop(nameBG, Color.frame)
            end
        end
    end
end

function private.FrameXML.Blizzard_StaticPopup_Game_GameDialog()
    if _G.StaticPopup1 then Skin.StaticPopupTemplate(_G.StaticPopup1) end
    if _G.StaticPopup2 then Skin.StaticPopupTemplate(_G.StaticPopup2) end
    if _G.StaticPopup3 then Skin.StaticPopupTemplate(_G.StaticPopup3) end
    if _G.StaticPopup4 then Skin.StaticPopupTemplate(_G.StaticPopup4) end
end
