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
        -- C_ItemSocketInfo is the modern API; TBC uses GetSocketTypes() directly
        local GetSocketTypes = _G.C_ItemSocketInfo and _G.C_ItemSocketInfo.GetSocketTypes or _G.GetSocketTypes
        local GetNumSockets = _G.C_ItemSocketInfo and _G.C_ItemSocketInfo.GetNumSockets or _G.GetNumSockets

        if not GetSocketTypes or not _G.ItemSocketingFrame.SocketingContainer then return end

        for i, socket in ipairs(_G.ItemSocketingFrame.SocketingContainer) do
            local gemInfo = GEM_TYPE_INFO[GetSocketTypes(i)] or default
            if socket.Background then
                socket.Background:SetTexCoord(gemInfo.coords[1], gemInfo.coords[2], gemInfo.coords[3], gemInfo.coords[4])
            end
            if socket.SetBackdropBorderColor then
                socket:SetBackdropBorderColor(gemInfo.color, 1)
            end
        end

        local num = GetNumSockets and GetNumSockets() or 0
        local socket1 = _G.ItemSocketingFrame.SocketingContainer['Socket1']
        if socket1 then
            if num == 3 then
                socket1:SetPoint("BOTTOM", _G.ItemSocketingFrame, "BOTTOM", -80, 39)
            elseif num == 2 then
                socket1:SetPoint("BOTTOM", _G.ItemSocketingFrame, "BOTTOM", -40, 39)
            else
                socket1:SetPoint("BOTTOM", _G.ItemSocketingFrame, "BOTTOM", 0, 39)
            end
        end
    end
end

do --[[ AddOns\Blizzard_ItemSocketingUI.xml ]]
    function Skin.ItemSocketingSocketButtonTemplate(Button, index)
        local LeftFiligree = Button.LeftFiligree
        local RightFiligree = Button.RightFiligree
        if LeftFiligree then
            LeftFiligree:Hide()
            LeftFiligree:SetAlpha(0)
        end
        if RightFiligree then
            RightFiligree:Hide()
            RightFiligree:SetAlpha(0)
        end
        select(2, Button:GetRegions()):Hide() -- drop shadow

        Base.CreateBackdrop(Button, {
            edgeSize = 1,
            bgFile = [["Interface\ItemSocketingFrame\UI-ItemSockets"]],
            insets = {left = 1, right = 1, top = 1, bottom = 1}
        }, {bg = Button.Background})

        if Button.Icon then
            Base.CropIcon(Button.Icon)
            Button.Icon:ClearAllPoints()
            Button.Icon:SetPoint("TOPLEFT", 1, -1)
            Button.Icon:SetPoint("BOTTOMRIGHT", -1, 1)
        end

        local shine = Button.Shine
        if shine then
            shine:ClearAllPoints()
            shine:SetAllPoints(Button.icon or Button.Icon)
        end

        local BracketFrame = Button.BracketFrame
        if BracketFrame then
            BracketFrame:ClearAllPoints()
            BracketFrame:SetPoint("TOPLEFT", -4, 4)
            BracketFrame:SetPoint("BOTTOMRIGHT", 4, -4)
            if BracketFrame.ClosedBracket then
                BracketFrame.ClosedBracket:SetAllPoints()
            end
            if BracketFrame.OpenBracket then
                BracketFrame.OpenBracket:SetAllPoints()
            end
        end

        Base.CropIcon(Button:GetPushedTexture())
        Base.CropIcon(Button:GetHighlightTexture())
    end
end

function private.AddOns.Blizzard_ItemSocketingUI()
    if _G.ItemSocketingFrame_Update then
        _G.hooksecurefunc("ItemSocketingFrame_Update", Hook.ItemSocketingFrame_Update)
    end
    local ItemSocketingFrame = _G.ItemSocketingFrame
    if not ItemSocketingFrame then return end

    Skin.ButtonFrameTemplate(ItemSocketingFrame)
    do -- Hide textures (nil-safe)
        local texNames = {
            "ParchmentFrame-Top", "ParchmentFrame-Bottom", "ParchmentFrame-Left", "ParchmentFrame-Right",
            "SocketFrame-Left", "SocketFrame-Right",
            "ButtonFrame-Left", "ButtonFrame-Right", "ButtonBorder-Mid",
            "GoldBorder-BottomRight", "GoldBorder-BottomLeft", "GoldBorder-TopRight", "GoldBorder-TopLeft",
            "GoldBorder-Left", "GoldBorder-Right", "GoldBorder-Top", "GoldBorder-Bottom",
            "BorderShadow-TopLeftCorner", "BorderShadow-TopRightCorner",
            "BorderShadow-BottomLeftCorner", "BorderShadow-BottomRightCorner",
            "BorderShadow-Top", "BorderShadow-Left", "BorderShadow-Bottom", "BorderShadow-Right",
        }
        for _, name in ipairs(texNames) do
            if ItemSocketingFrame[name] then
                ItemSocketingFrame[name]:Hide()
            end
        end

        if ItemSocketingFrame.BackgroundColor then ItemSocketingFrame.BackgroundColor:Hide() end
        if ItemSocketingFrame.BackgroundHighlight then ItemSocketingFrame.BackgroundHighlight:Hide() end
        if ItemSocketingFrame.BottomLeftNub then ItemSocketingFrame.BottomLeftNub:Hide() end
        if ItemSocketingFrame.BottomRightNub then ItemSocketingFrame.BottomRightNub:Hide() end
        if ItemSocketingFrame.MiddleLeftNub then ItemSocketingFrame.MiddleLeftNub:Hide() end
        if ItemSocketingFrame.MiddleRightNub then ItemSocketingFrame.MiddleRightNub:Hide() end
        if ItemSocketingFrame.TopLeftNub then ItemSocketingFrame.TopLeftNub:Hide() end
        if ItemSocketingFrame.TopRightNub then ItemSocketingFrame.TopRightNub:Hide() end
    end

    if _G.ItemSocketingScrollFrame then
        Skin.ScrollFrameTemplate(_G.ItemSocketingScrollFrame)
    end
    if ItemSocketingFrame.SocketingContainer then
        for i = 1, _G.MAX_NUM_SOCKETS or 3 do
            local socket = ItemSocketingFrame.SocketingContainer['Socket'..i]
            if socket then
                Skin.ItemSocketingSocketButtonTemplate(socket, i)
            end
        end
        local ApplySocketsButton = ItemSocketingFrame.SocketingContainer.ApplySocketsButton
        if ApplySocketsButton then
            Skin.UIPanelButtonTemplate(ApplySocketsButton)
        end
    end
end
