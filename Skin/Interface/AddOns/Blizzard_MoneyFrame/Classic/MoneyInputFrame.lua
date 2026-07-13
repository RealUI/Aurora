local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin

--[[ Classic-family money input (era/TBC/Mists; retail resolves Mainline/).
    Evidence: wow-ui-source-*/Interface/AddOns/Blizzard_MoneyFrame/Classic/
    MoneyInputFrame.xml — parentKeys gold/silver/copper, Common-Input border
    pieces as named $parentLeft/Right/Middle, coin icon at parentKey texture
    (UI-MoneyIcons sheet slice — left alone). Blizzard's own layout/anchors
    are kept; only art is swapped.
]]

do --[[ Classic\MoneyInputFrame.xml ]]
    local money = {"gold", "silver", "copper"}
    function Skin.MoneyInputFrameTemplate(Frame)
        for i = 1, #money do
            local EditBox = Frame[money[i]]
            if EditBox then
                -- strip the border art BEFORE the backdrop is created
                local name = EditBox:GetName()
                for _, piece in ipairs({"Left", "Right", "Middle"}) do
                    local texture = _G[name..piece]
                    if texture then
                        texture:Hide()
                    end
                end
                Skin.FrameTypeEditBox(EditBox)
                -- widen the backdrop and clear the right side for the coin
                EditBox:SetBackdropOption("offsets", {
                    left = -5,
                    right = 15,
                    top = 0,
                    bottom = 0,
                })

                local bg = EditBox:GetBackdropTexture("bg")
                if bg and EditBox.texture then
                    EditBox.texture:ClearAllPoints()
                    EditBox.texture:SetPoint("LEFT", bg, "RIGHT", 2, 0)
                end

                if i > 1 then
                    EditBox:SetPoint("LEFT", Frame[money[i - 1]], "RIGHT", 6, 0)
                    EditBox:SetSize(35, 20)
                else
                    EditBox:SetSize(70, 20)
                end
            end
        end
    end
end
