local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals select ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color = Aurora.Color

do --[[ AddOns\Blizzard_ItemSocketingUI.lua ]]
    local default = {
        coords = {0.11627906976744, 0.88372093023256, 0.11627906976744, 0.88372093023256},
        color = Color.grayLight,
    }
    local GEM_TYPE_INFO = {
        Yellow = {
            coords = default.coords,
            color = Color.yellow,
        },
        Red = {
            coords = default.coords,
            color = Color.red,
        },
        Blue = {
            coords = default.coords,
            color = Color.blue,
        },
        Meta = {
            coords = {0.18965517241379, 0.77586206896552, 0.16981132075472, 0.81132075471698},
            color = Color.grayLight,
        },
        Hydraulic = {
            coords = default.coords,
            color = Color.grayDark,
        },
        Cogwheel = {
            coords = default.coords,
            color = Color.yellow,
        },
        Prismatic = {
            coords = default.coords,
            color = Color.white,
        },
        PunchcardRed = {
            coords = default.coords,
            color = Color.red,
        },
        PunchcardYellow = {
            coords = default.coords,
            color = Color.yellow,
        },
        PunchcardBlue = {
            coords = default.coords,
            color = Color.blue,
        },
        Domination = {
            coords = default.coords,
            color = Color.white,
        },
    }

    function Hook.ItemSocketingFrame_Update()
        for i, socket in ipairs(_G.ItemSocketingFrame.SocketingContainer) do
            local gemInfo = GEM_TYPE_INFO[_G.C_ItemSocketInfo.GetSocketTypes(i)] or default
            socket.Background:SetTexCoord(gemInfo.coords[1], gemInfo.coords[2], gemInfo.coords[3], gemInfo.coords[4])
            socket:SetBackdropBorderColor(gemInfo.color, 1)
        end

        local num = _G.C_ItemSocketInfo.GetNumSockets()
        if num == 3 then
            _G.ItemSocketingFrame.SocketingContainer['Socket1']:SetPoint("BOTTOM", _G.ItemSocketingFrame, "BOTTOM", -80, 39)
        elseif num == 2 then
            _G.ItemSocketingFrame.SocketingContainer['Socket1']:SetPoint("BOTTOM", _G.ItemSocketingFrame, "BOTTOM", -40, 39)
        else
            _G.ItemSocketingFrame.SocketingContainer['Socket1']:SetPoint("BOTTOM", _G.ItemSocketingFrame, "BOTTOM", 0, 39)
        end
    end
end

do --[[ AddOns\Blizzard_ItemSocketingUI.xml ]]
    function Skin.ItemSocketingSocketButtonTemplate(Button, index)
        local LeftFiligree = Button.LeftFiligree
        local RightFiligree = Button.RightFiligree
        if LeftFiligree then LeftFiligree:Hide() end
        if RightFiligree then RightFiligree:Hide() end
        LeftFiligree:SetAlpha(0)
        RightFiligree:SetAlpha(0)
        select(2, Button:GetRegions()):Hide() -- drop shadow

        Base.CreateBackdrop(Button, {
            edgeSize = 1,
            bgFile = [["Interface\ItemSocketingFrame\UI-ItemSockets"]],
            insets = {left = 1, right = 1, top = 1, bottom = 1}
        }, {bg = Button.Background})

        Base.CropIcon(Button.Icon)
        Button.Icon:ClearAllPoints()
        Button.Icon:SetPoint("TOPLEFT", 1, -1)
        Button.Icon:SetPoint("BOTTOMRIGHT", -1, 1)

        local shine = Button.Shine
        shine:ClearAllPoints()
        shine:SetAllPoints(Button.icon)

        local BracketFrame = Button.BracketFrame
        BracketFrame:ClearAllPoints()
        BracketFrame:SetPoint("TOPLEFT", -4, 4)
        BracketFrame:SetPoint("BOTTOMRIGHT", 4, -4)
        BracketFrame.ClosedBracket:SetAllPoints()
        BracketFrame.OpenBracket:SetAllPoints()

        Base.CropIcon(Button:GetPushedTexture())
        Base.CropIcon(Button:GetHighlightTexture())
    end
end

function private.AddOns.Blizzard_ItemSocketingUI()
    _G.hooksecurefunc("ItemSocketingFrame_Update", Hook.ItemSocketingFrame_Update)
    local ItemSocketingFrame = _G.ItemSocketingFrame

    Skin.ButtonFrameTemplate(ItemSocketingFrame)
    do -- Hide textures
        ItemSocketingFrame["ParchmentFrame-Top"]:Hide()
        ItemSocketingFrame["ParchmentFrame-Bottom"]:Hide()
        ItemSocketingFrame["ParchmentFrame-Left"]:Hide()
        ItemSocketingFrame["ParchmentFrame-Right"]:Hide()

        ItemSocketingFrame["SocketFrame-Left"]:Hide()
        ItemSocketingFrame["SocketFrame-Right"]:Hide()

        ItemSocketingFrame["ButtonFrame-Left"]:Hide()
        ItemSocketingFrame["ButtonFrame-Right"]:Hide()
        ItemSocketingFrame["ButtonBorder-Mid"]:Hide()

        ItemSocketingFrame["GoldBorder-BottomRight"]:Hide()
        ItemSocketingFrame["GoldBorder-BottomLeft"]:Hide()
        ItemSocketingFrame["GoldBorder-TopRight"]:Hide()
        ItemSocketingFrame["GoldBorder-TopLeft"]:Hide()
        ItemSocketingFrame["GoldBorder-Left"]:Hide()
        ItemSocketingFrame["GoldBorder-Right"]:Hide()
        ItemSocketingFrame["GoldBorder-Top"]:Hide()
        ItemSocketingFrame["GoldBorder-Bottom"]:Hide()

        ItemSocketingFrame.BackgroundColor:Hide()
        ItemSocketingFrame.BackgroundHighlight:Hide()

        ItemSocketingFrame["BorderShadow-TopLeftCorner"]:Hide()
        ItemSocketingFrame["BorderShadow-TopRightCorner"]:Hide()
        ItemSocketingFrame["BorderShadow-BottomLeftCorner"]:Hide()
        ItemSocketingFrame["BorderShadow-BottomRightCorner"]:Hide()
        ItemSocketingFrame["BorderShadow-Top"]:Hide()
        ItemSocketingFrame["BorderShadow-Left"]:Hide()
        ItemSocketingFrame["BorderShadow-Bottom"]:Hide()
        ItemSocketingFrame["BorderShadow-Right"]:Hide()

        ItemSocketingFrame.BottomLeftNub:Hide()
        ItemSocketingFrame.BottomRightNub:Hide()
        ItemSocketingFrame.MiddleLeftNub:Hide()
        ItemSocketingFrame.MiddleRightNub:Hide()
        ItemSocketingFrame.TopLeftNub:Hide()
        ItemSocketingFrame.TopRightNub:Hide()
    end

    Skin.ScrollFrameTemplate(_G.ItemSocketingScrollFrame)
    for i = 1, _G.MAX_NUM_SOCKETS do
        Skin.ItemSocketingSocketButtonTemplate(_G.ItemSocketingFrame.SocketingContainer['Socket'..i], i)
    end
    local ApplySocketsButton = ItemSocketingFrame.SocketingContainer.ApplySocketsButton
    Skin.UIPanelButtonTemplate(ApplySocketsButton)
end
