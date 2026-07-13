local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color = Aurora.Color

--[[ Classic-family static popups (era/TBC/Mists). The dialog XML is the
    FLAT/shared Blizzard_StaticPopup_Game/GameDialog.xml — 1.15+ uses the
    same modern structure as retail (ButtonContainer parentArray, parentKey
    EditBox/MoneyFrame/ItemFrame, TooltipBackdropTemplate edit box), so this
    is a near-copy of the Mainline skin with classic-layer dependencies.
]]

do --[[ Blizzard_StaticPopup_Game\GameDialog.xml ]]
    -- TAINT-SAFE: popup buttons trigger protected functions in OnAccept
    -- callbacks — no FrameTypeButton table writes.
    function Skin.StaticPopupButtonTemplate(Button)
        Skin.TaintSafeUIPanelButtonTemplate(Button)
    end

    function Skin.StaticPopupTemplate(Frame)
        local background = Frame.BG
        if background and background.Top then
            background.Top:SetTexture("")
        end

        local ButtonContainer = Frame.ButtonContainer
        Skin.StaticPopupButtonTemplate(ButtonContainer.Button1)
        Skin.StaticPopupButtonTemplate(ButtonContainer.Button2)
        Skin.StaticPopupButtonTemplate(ButtonContainer.Button3)
        Skin.StaticPopupButtonTemplate(ButtonContainer.Button4)

        Skin.StaticPopupButtonTemplate(Frame.ExtraButton)
        Skin.StaticPopupButtonTemplate(Frame.CloseButton)

        local Buttons = ButtonContainer.Buttons
        if Buttons then
            for i = 1, #Buttons do
                Skin.StaticPopupButtonTemplate(Buttons[i])
            end
        end

        if Frame.EditBox then
            Skin.FrameTypeEditBox(Frame.EditBox)
        end

        -- Countdown progress bar: raise the fill above the (now solid)
        -- border texture, same trick as the Mainline skin
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

        -- Money frames: skins live in Blizzard_MoneyFrame (not yet ported
        -- on classic) — guarded until then
        if Skin.SmallMoneyFrameTemplate and Frame.MoneyFrame then
            Skin.SmallMoneyFrameTemplate(Frame.MoneyFrame)
        end
        if Skin.MoneyInputFrameTemplate and Frame.MoneyInputFrame then
            Skin.MoneyInputFrameTemplate(Frame.MoneyInputFrame)
        end

        local ItemFrame = Frame.ItemFrame
        if ItemFrame then
            Skin.FrameTypeFrame(ItemFrame)
            if ItemFrame.NameFrame then
                ItemFrame.NameFrame:Hide()
            end

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

function private.FrameXML.Blizzard_StaticPopup_Game_GameDialog()
    Skin.StaticPopupTemplate(_G.StaticPopup1)
    Skin.StaticPopupTemplate(_G.StaticPopup2)
    Skin.StaticPopupTemplate(_G.StaticPopup3)
    Skin.StaticPopupTemplate(_G.StaticPopup4)
end
