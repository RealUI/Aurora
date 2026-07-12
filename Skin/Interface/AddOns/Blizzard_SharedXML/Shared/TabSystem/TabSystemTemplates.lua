local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

do --[[ Blizzard_SharedXML\Mainline\TabSystem\TabSystemTemplates.lua ]]
    function Skin.TabSystemButtonTemplate(Button)
        Skin.FrameTypeButton(Button)
        Button:SetButtonColor(Color.button, Util.GetFrameAlpha(), false)
        Button:SetBackdropOption("offsets", {
            left = 0,
            right = 0,
            top = 0,
            bottom = 0,
        })
    -- isSelected = false
    -- tabID = 1
    -- layoutIndex = 1
    -- isTabOnTop = true
    -- New = Frame {}
    -- RotatedTextures =  {}
    -- Text = FontString {}

        Button.LeftActive:SetAlpha(0)
        Button.RightActive:SetAlpha(0)
        Button.MiddleActive:SetAlpha(0)
        Button.Left:SetAlpha(0)
        Button.Right:SetAlpha(0)
        Button.Middle:SetAlpha(0)

        Button.LeftHighlight:SetAlpha(0)
        Button.RightHighlight:SetAlpha(0)
        Button.MiddleHighlight:SetAlpha(0)

        local bg = Button:GetBackdropTexture("bg")
        Button.Text:ClearAllPoints()
        Button.Text:SetAllPoints(bg)
        Button._auroraTabResize = true
    end
end

function private.FrameXML.TabSystemTemplates()

end
