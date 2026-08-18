local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Base = Aurora.Base
local Color = Aurora.Color

do --[[ FrameXML\UIDropDownMenu.xml ]]
    do --[[ UIDropDownMenuTemplates.xml ]]
        function Skin.MainLineMenuTemplates1(Button)
        end
        function Skin.WowStyle1ArrowDropdownTemplate(Button)
            if not Button._auroraTextures then
                Button._auroraTextures = {}
            end
            if Button.Background then
                Button.Background:Hide()
            end
            if Button.TopEdge then
                Button.TopEdge:Hide()
            end
            if Button.TopLeftCorner then
                Button.TopLeftCorner:Hide()
            end
            if Button.TopRightCorner then
                Button.TopRightCorner:Hide()
            end
            if Button.BottomEdge then
                Button.BottomEdge:Hide()
            end
            if Button.BottomLeftCorner then
                Button.BottomLeftCorner:Hide()
            end
            if Button.BottomRightCorner then
                Button.BottomRightCorner:Hide()
            end
            if Button.LeftEdge then
                Button.LeftEdge:Hide()
            end
            if Button.RightEdge then
                Button.RightEdge:Hide()
            end
            Button._auroraWidth = nil
            Base.SetBackdrop(Button, Color.button)
            if Button.Arrow then
                if Button.Background then
                    Button.Background:SetTexture(nil)
                end
                Button:SetFrameLevel(Button:GetFrameLevel() + 2)
                Button.Arrow:SetAlpha(0)
            end
            -- B09: the Blizzard arrow is re-atlased on every state change (so
            -- it is alpha-zeroed above); attach Aurora's own arrow so this
            -- arrow-only dropdown keeps its affordance.
            if not Button._auroraArrow then
                local arrow = Button:CreateTexture(nil, "ARTWORK")
                arrow:SetTexture([[Interface\AddOns\Aurora\media\arrow-down-active]])
                arrow:SetSize(10, 10)
                arrow:SetPoint("CENTER")
                Button._auroraArrow = arrow
            end
        end
    end
end


function private.AddOns.MainLineMenuTemplates()

end
