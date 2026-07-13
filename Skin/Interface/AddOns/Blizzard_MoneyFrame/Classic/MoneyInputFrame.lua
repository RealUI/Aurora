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
    function Skin.MoneyInputFrameTemplate(Frame)
        for _, key in ipairs({"gold", "silver", "copper"}) do
            local EditBox = Frame[key]
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
            end
        end
    end
end
