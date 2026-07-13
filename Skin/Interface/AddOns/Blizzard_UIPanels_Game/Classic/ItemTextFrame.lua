local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin

--[[ Classic-family readable items (books/plaques/letters).
    Evidence: Classic/ItemTextFrame.xml. DELIBERATELY minimal: the page
    material (parchment/stone/bronze) is re-set per item and the page text
    is colored for it — stripping the material would leave dark-on-dark
    text (the QuestFrame lesson). Only the scrollbar and page-turn buttons
    are skinned.
]]

function private.FrameXML.ItemTextFrame()
    Skin.UIPanelScrollFrameTemplate(_G.ItemTextScrollFrame)

    if _G.ItemTextPrevPageButton then
        Skin.NavButtonPrevious(_G.ItemTextPrevPageButton)
    end
    if _G.ItemTextNextPageButton then
        Skin.NavButtonNext(_G.ItemTextNextPageButton)
    end
end
