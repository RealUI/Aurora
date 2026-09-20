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
    -- Side of a square icon tab, replacing Blizzard's 44x32. Tune here.
    local ICON_TAB_SIZE = 24

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
            -- TOPLEFT/BOTTOMRIGHT fit set once, so the fit has to be re-applied
            -- after it. The square art is re-zeroed in the same pass: the tab
            -- pool hands the same button back on RemoveAllTabs/AddTab and Init
            -- runs SetSquareMode again, so a once-only SetAlpha(0) is not
            -- enough -- the selected tab kept showing its glow plate.
            local function ReapplySquare()
                for _, key in next, {"SquareBackground", "SquareBackgroundActive",
                                     "SquareBackgroundActiveGlow"} do
                    local region = Button[key]
                    if region then region:SetAlpha(0) end
                end

                Icon:ClearAllPoints()
                Icon:SetPoint("TOPLEFT", bg, 2, -2)
                Icon:SetPoint("BOTTOMRIGHT", bg, -2, 2)
            end
            ReapplySquare()
            if Button.SetTabSelected then
                _G.hooksecurefunc(Button, "SetTabSelected", ReapplySquare)
            end

            -- UpdateTabWidth gives an icon tab Icon:GetWidth() + 8, so 44 wide
            -- against a 32 tall button. Blizzard gets away with it because the
            -- 36x35 icon keeps its own size and sits centred inside; filling an
            -- Aurora backdrop with it instead stretched every icon sideways.
            -- Square the tab off -- which is the look wanted here anyway -- and
            -- take it down from Blizzard's 32: the icon fills an Aurora tab
            -- edge to edge, so the same box reads much heavier than it does
            -- with a 36x35 icon floating in it.
            if Button.UpdateTabWidth then
                _G.hooksecurefunc(Button, "UpdateTabWidth", function(self)
                    self:SetSize(ICON_TAB_SIZE, ICON_TAB_SIZE)
                end)
                Button:UpdateTabWidth()
            end
        end

        Button.Text:ClearAllPoints()
        Button.Text:SetAllPoints(bg)
        Button._auroraTabResize = true
    end
end

function private.FrameXML.TabSystemTemplates()

end
