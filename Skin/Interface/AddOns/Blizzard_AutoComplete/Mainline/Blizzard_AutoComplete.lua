local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Util = Aurora.Util

--do --[[ SharedXML\AutoComplete.lua ]]
--end

do --[[ SharedXML\AutoComplete.xml ]]
    function Skin.AutoCompleteButtonTemplate(Button)
        local highlight = Button:GetHighlightTexture()
        highlight:ClearAllPoints()
        highlight:SetPoint("LEFT", _G.AutoCompleteBox, 1, 0)
        highlight:SetPoint("RIGHT", _G.AutoCompleteBox, -1, 0)
        highlight:SetPoint("TOP", 0, 0)
        highlight:SetPoint("BOTTOM", 0, 0)
        Util.SetHighlightColor(highlight, .2)
    end
end

function private.SharedXML.AutoComplete()
    local AutoCompleteBox = _G.AutoCompleteBox
    Skin.FrameTypeFrame(AutoCompleteBox)

    Skin.AutoCompleteButtonTemplate(_G.AutoCompleteButton1)
    Skin.AutoCompleteButtonTemplate(_G.AutoCompleteButton2)
    Skin.AutoCompleteButtonTemplate(_G.AutoCompleteButton3)
    Skin.AutoCompleteButtonTemplate(_G.AutoCompleteButton4)
    Skin.AutoCompleteButtonTemplate(_G.AutoCompleteButton5)
end
