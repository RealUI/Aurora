local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin

--[[ Classic-family GameMenuFrame (era/TBC/Mists).
    Evidence: wow-ui-source-*/Interface/AddOns/Blizzard_GameMenu/Classic/GameMenuFrame.xml
    Plain BackdropTemplate dialog (BACKDROP_DIALOG_32_32) with a
    UI-DialogBox-Header texture and GameMenuButtonTemplate buttons
    (= UIPanelButtonTemplate, Blizzard_UIPanelTemplates/Classic).
]]

local menuButtons = {
    "GameMenuButtonHelp",
    "GameMenuButtonStore",
    "GameMenuButtonOptions",
    "GameMenuButtonUIOptions",
    "GameMenuButtonKeybindings",
    "GameMenuButtonMacros",
    "GameMenuButtonAddons",
    "GameMenuButtonRatings",
    "GameMenuButtonLogout",
    "GameMenuButtonQuit",
    "GameMenuButtonContinue",
}

function private.AddOns.Blizzard_GameMenu()
    local GameMenuFrame = _G.GameMenuFrame

    if _G.GameMenuFrameHeader then
        _G.GameMenuFrameHeader:SetTexture("")
    end
    Skin.FrameTypeFrame(GameMenuFrame)

    for _, name in ipairs(menuButtons) do
        local button = _G[name]
        if button then
            Skin.UIPanelButtonTemplate(button)
        end
    end
end
