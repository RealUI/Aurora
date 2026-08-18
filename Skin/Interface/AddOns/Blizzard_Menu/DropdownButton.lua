local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
-- local Skin =  Aurora.Skin
local Base = Aurora.Base
-- local Hook = Aurora.Hook
local Skin = Aurora.Skin
local Color = Aurora.Color

do --[[ Blizzard_Menu\DropdownButton.lua ]]
    do --[[ DropdownButton.lua ]]
        -- B09/B41: dropdowns lose their arrow affordance when Aurora hides the
        -- Blizzard art — WowStyle1DropdownTemplate's Arrow is re-atlased on
        -- every state change (so it is alpha-zeroed), and the filter-style
        -- dropdowns bake the arrow into the Background atlas that gets hidden.
        -- Attach Aurora's own arrow so every skinned dropdown keeps one.
        local function AddArrow(Frame)
            if Frame._auroraArrow then return end
            local arrow = Frame:CreateTexture(nil, "ARTWORK")
            arrow:SetTexture([[Interface\AddOns\Aurora\media\arrow-down-active]])
            arrow:SetSize(8, 8)
            arrow:SetPoint("RIGHT", -8, 0)
            Frame._auroraArrow = arrow
        end
        function Skin.DropdownButton(Frame, Width)
            -- local rightOfs = -105
            if not Frame then
                if private.isDev then
                    _G.print("Skin.DropdownButton - Frame is nil. This is likely a bug. You should not see this message.")
                end
                return
            end
            if private.IsSkinned(Frame) then
                return
            else
                private.SetSkinned(Frame, true)
            end
            -- if not Width then
            --     Width = 155
            -- end
            if Frame.Left then
                Frame.Left:SetAlpha(0)
            end
            if Frame.Middle then
                Frame.Middle:SetAlpha(0)
            end
            if Frame.Right then
                Frame.Right:SetAlpha(0)
            end
            if not Frame._auroraTextures then
                Frame._auroraTextures = {}
            end
            if Frame.Background then
                Frame.Background:Hide()
            end
            if Frame.TopEdge then
                Frame.TopEdge:Hide()
            end
            if Frame.TopLeftCorner then
                Frame.TopLeftCorner:Hide()
            end
            if Frame.TopRightCorner then
                Frame.TopRightCorner:Hide()
            end
            if Frame.BottomEdge then
                Frame.BottomEdge:Hide()
            end
            if Frame.BottomLeftCorner then
                Frame.BottomLeftCorner:Hide()
            end
            if Frame.BottomRightCorner then
                Frame.BottomRightCorner:Hide()
            end
            if Frame.LeftEdge then
                Frame.LeftEdge:Hide()
            end
            if Frame.RightEdge then
                Frame.RightEdge:Hide()
            end
            Frame._auroraWidth = nil
            if Width then
                Frame:SetWidth(Width)
                Frame._auroraWidth = Width
            end
            Base.SetBackdrop(Frame, Color.button)
            if Frame.Arrow then
                -- classic arrow-style dropdowns have an Arrow but no Background
                if Frame.Background then
                    Frame.Background:SetTexture(nil)
                end
                Frame:SetFrameLevel(Frame:GetFrameLevel() + 2)
                Frame.Arrow:SetAlpha(0)
            end
            if Frame.TabHighlight then Frame.TabHighlight:SetAlpha(0) end
            -- Texture child is an atlas-based arrow (e.g. ProfessionsRankBarDropdownMixin).
            -- Replace the atlas with Aurora's arrow BLP and hook OnButtonStateChanged
            -- so the atlas cannot be re-applied on every hover/click state change.
            if Frame.Texture then
                local function setArrow(btn)
                    btn.Texture:SetTexture([[Interface\AddOns\Aurora\media\arrow-down-active]])
                    btn.Texture:SetSize(8, 8)
                    btn.Texture:ClearAllPoints()
                    btn.Texture:SetPoint("CENTER")
                    btn.Texture:Show()
                end
                setArrow(Frame)
                if Frame.OnButtonStateChanged then
                    _G.hooksecurefunc(Frame, "OnButtonStateChanged", setArrow)
                end
            elseif Frame.Arrow or Frame.Background then
                -- Only replace an arrow we actually removed: the Arrow-carrying
                -- templates (alpha-zeroed above) and the filter-style templates
                -- whose arrow was baked into the Background atlas hidden above.
                --
                -- Deliberately NOT unconditional. UIDropDownMenuTemplate — what
                -- AceGUI's Dropdown widget uses, so every RealUI config
                -- dropdown — exposes its parts by global name
                -- (<name>Left/Middle/Right/Button) rather than parentKeys, so
                -- every check here misses and its own button arrow survives
                -- untouched. Adding one regardless gave those dropdowns two.
                AddArrow(Frame)
            end
        end
        function Skin.FilterButton(Frame, Width)
            -- local rightOfs = -105
            if not Frame then
                if private.isDev then
                    _G.print("Skin.FilterButton - Frame is nil. This is likely a bug. You should not see this message.")
                end
                return
            end
            if not Frame._auroraTextures then
                Frame._auroraTextures = {}
            end
            if Frame.Background then
                Frame.Background:Hide()
            end
            if Frame.TopEdge then
                Frame.TopEdge:Hide()
            end
            if Frame.TopLeftCorner then
                Frame.TopLeftCorner:Hide()
            end
            if Frame.TopRightCorner then
                Frame.TopRightCorner:Hide()
            end
            if Frame.BottomEdge then
                Frame.BottomEdge:Hide()
            end
            if Frame.BottomLeftCorner then
                Frame.BottomLeftCorner:Hide()
            end
            if Frame.BottomRightCorner then
                Frame.BottomRightCorner:Hide()
            end
            if Frame.LeftEdge then
                Frame.LeftEdge:Hide()
            end
            if Frame.RightEdge then
                Frame.RightEdge:Hide()
            end
            Frame._auroraWidth = nil
            Base.SetBackdrop(Frame, Color.button)
            if Frame.Arrow then
                if Frame.Background then
                    Frame.Background:SetTexture(nil)
                end
                Frame:SetFrameLevel(Frame:GetFrameLevel() + 2)
                Frame.Arrow:SetAlpha(0)
            end
            -- The filter templates carry their arrow inside the hidden
            -- Background atlas, so every skinned filter button needs
            -- Aurora's replacement arrow (B09/B41).
            AddArrow(Frame)
        end
    end
end

function private.AddOns.DropdownButton()

end
