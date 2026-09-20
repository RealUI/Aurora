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
    local ICON_TAB_SIZE = 32

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
        -- Init() selects: the three-slice above for a text tab, and a square
        -- set for an icon tab. Only the text half was handled, which is why the
        -- spellbook's category tabs kept their gold plate -- they are icon tabs.
        --
        -- None of the square-mode work can be done once at skin time. The tab
        -- pool hands the same button back on RemoveAllTabs/AddTab and Init runs
        -- SetSquareMode + UpdateTabWidth + SetTabSelected again, and a button
        -- skinned while its Icon was still textureless would never have been
        -- treated as an icon tab at all -- private.IsSkinned locks it out for
        -- good. Measured on the spellbook, build 69913: of six pooled tabs,
        -- four were right, one was raw 44x32 and one was sized but unfitted.
        -- So branch on self.tabIcon inside the hooks, which Init re-runs.
        local Icon = Button.Icon

        local function ApplySquareMode(self)
            if not self.tabIcon or not Icon then return end

            for _, key in next, {"SquareBackground", "SquareBackgroundActive",
                                 "SquareBackgroundActiveGlow"} do
                local region = self[key]
                if region then region:SetAlpha(0) end
            end

            -- The icon is masked square by IconMask; Base.CropIcon drops masks
            -- before cropping, which is what is wanted here.
            Base.CropIcon(Icon)

            -- SetTabSelected re-adds a CENTER point to Icon on every select
            -- *and* deselect, so the fit has to be re-applied after it.
            Icon:ClearAllPoints()
            Icon:SetPoint("TOPLEFT", bg, 2, -2)
            Icon:SetPoint("BOTTOMRIGHT", bg, -2, 2)
        end

        if Button.SetTabSelected then
            _G.hooksecurefunc(Button, "SetTabSelected", ApplySquareMode)
        end

        -- UpdateTabWidth gives an icon tab Icon:GetWidth() + 8, so 44 wide
        -- against a 32 tall button. Blizzard gets away with it because the
        -- 36x35 icon keeps its own size and sits centred inside; filling an
        -- Aurora backdrop with it instead stretched every icon sideways.
        -- Square the tab off -- which is the look wanted here anyway -- at
        -- Blizzard's own 32 height, which sits right next to the 36px spell
        -- icons in the list below. A text tab keeps Blizzard's computed width.
        if Button.UpdateTabWidth then
            _G.hooksecurefunc(Button, "UpdateTabWidth", function(self)
                if self.tabIcon then
                    self:SetSize(ICON_TAB_SIZE, ICON_TAB_SIZE)
                end
            end)
        end

        -- Catch a tab that Init already ran on before the skin got here.
        if Button.tabIcon then
            if Button.UpdateTabWidth then Button:UpdateTabWidth() end
            ApplySquareMode(Button)
        end

        Button.Text:ClearAllPoints()
        Button.Text:SetAllPoints(bg)
        Button._auroraTabResize = true
    end
end

function private.FrameXML.TabSystemTemplates()

end
