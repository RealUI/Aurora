local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals _G

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

do --[[ FrameXML\WardrobeCustomSets.xml ]]
    function Skin.WardrobeCustomSetButtonButtonTemplate(Frame)
        local parent = Frame:GetParent()
        local selection = Frame.Selection
        if selection then
            selection:SetColorTexture(Color.gray.r, Color.gray.g, Color.gray.b, 0.5)
            selection:ClearAllPoints()
            selection:SetPoint("LEFT", parent, 1, 0)
            selection:SetPoint("RIGHT", parent, -1, 0)
            selection:SetPoint("TOP", 0, 0)
            selection:SetPoint("BOTTOM", 0, 0)
        end

        local highlight = Frame.Highlight
        if highlight then
            Util.SetHighlightColor(highlight, 0.2)
            highlight:ClearAllPoints()
            highlight:SetPoint("LEFT", parent, 1, 0)
            highlight:SetPoint("RIGHT", parent, -1, 0)
            highlight:SetPoint("TOP", 0, 0)
            highlight:SetPoint("BOTTOM", 0, 0)
        end

        if Frame.Icon then
            Base.CropIcon(Frame.Icon)
        end
    end

    function Skin.WardrobeCustomSetDropdownTemplate(Frame)
        Skin.DropdownButton(Frame)

        local offsets = Frame:GetBackdropOption("offsets")
        Frame:SetBackdropOption("offsets", {
            left = offsets.left,
            right = offsets.right,
            top = offsets.top,
            bottom = -1,
        })

        Skin.UIPanelButtonTemplate(Frame.SaveButton)
    end
end

function private.FrameXML.WardrobeCustomSets()
    if not private.isMidnight then
        local WardrobeCustomSetEditFrame = _G.WardrobeCustomSetEditFrame
        if WardrobeCustomSetEditFrame then
            Skin.DialogBorderTemplate(WardrobeCustomSetEditFrame.Border)

            local EditBox = WardrobeCustomSetEditFrame.EditBox
            Skin.FrameTypeEditBox(EditBox)
            EditBox:SetBackdropOption("offsets", {
                left = -5,
                right = 3,
                top = 3,
                bottom = 3,
            })

            EditBox.LeftTexture:Hide()
            EditBox.RightTexture:Hide()
            EditBox.MiddleTexture:Hide()
            Skin.UIPanelButtonTemplate(WardrobeCustomSetEditFrame.AcceptButton)
            Skin.UIPanelButtonTemplate(WardrobeCustomSetEditFrame.CancelButton)
            Skin.UIPanelButtonTemplate(WardrobeCustomSetEditFrame.DeleteButton)
        end
    end
end