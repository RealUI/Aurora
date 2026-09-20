local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals next

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
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

        -- TabSystemButtonArtTemplate carries *two* looks and shows whichever
        -- Init() selects: the three-slice above for a text tab, and this square
        -- set for an icon tab. Only the text half was handled, which is why the
        -- spellbook's category tabs kept their gold plate -- they are icon tabs.
        for _, key in next, {"SquareBackground", "SquareBackgroundActive",
                             "SquareBackgroundActiveGlow"} do
            local region = Button[key]
            if region then region:SetAlpha(0) end
        end

        -- The icon is masked square by IconMask; Base.CropIcon drops masks
        -- before cropping, which is what is wanted. Only fit it to the backdrop
        -- when there actually is one -- a text tab's Icon is unused and sizing
        -- it would give the tab a phantom square.
        local Icon = Button.Icon
        if Icon and Icon:GetTexture() then
            Base.CropIcon(Icon)

            -- TabSystemButtonArtMixin:SetTabSelected re-adds a CENTER point to
            -- Icon on every select *and* deselect, which conflicts with a
            -- TOPLEFT/BOTTOMRIGHT fit set once. Re-apply the fit after it.
            local function FitIcon()
                Icon:ClearAllPoints()
                Icon:SetPoint("TOPLEFT", bg, 2, -2)
                Icon:SetPoint("BOTTOMRIGHT", bg, -2, 2)
            end
            FitIcon()
            if Button.SetTabSelected then
                _G.hooksecurefunc(Button, "SetTabSelected", FitIcon)
            end
        end

        Button.Text:ClearAllPoints()
        Button.Text:SetAllPoints(bg)
        Button._auroraTabResize = true
    end
end

function private.FrameXML.TabSystemTemplates()

end
