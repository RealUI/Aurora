local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals _G

--[[ Core ]]
local Aurora = private.Aurora
local Hook, Skin = Aurora.Hook, Aurora.Skin

--[[ Classic-family GameMenuFrame (era 1.15.9 convergence / TBC / Mists):
    the retail pooled-button menu (Shared\GameMenuFrame.lua —
    GameMenuFrameMixin:InitButtons + buttonPool) on the classic
    MainMenuFrameTemplate shell (Blizzard_SharedXML\Classic\Frame\
    MainMenuFrameTemplates.xml: parentKey Border = DialogBorderNoCenter +
    BACKDROP_DIALOG_32_32, parentKey Header = ClassicDialogHeaderTemplate).
    Port of the Mainline skin. Buttons are MainMenuFrameButtonTemplate
    (= classic UIPanelButtonTemplate). No Skin.FrameTypeFrame on the root —
    the Border carries the dialog chrome (double-border otherwise).
]]

function Hook.GameMenuInitButtons(menu)
    if not menu.buttonPool then return end
    for button in menu.buttonPool:EnumerateActive() do
        if not button._auroraSkinned then
            Skin.UIPanelButtonTemplate(button)
            button._auroraSkinned = true
        end
    end
end

function private.AddOns.Blizzard_GameMenu()
    local GameMenuFrame = _G.GameMenuFrame

    if GameMenuFrame.Border then
        Skin.DialogBorderTemplate(GameMenuFrame.Border)
    end
    if GameMenuFrame.Header and GameMenuFrame.Header.BG then
        GameMenuFrame.Header.BG:SetTexture("")
    end

    -- InitButtons runs at OnLoad (before this skin) and again per menu
    -- open — hook for future opens, sweep the pool for existing buttons.
    _G.hooksecurefunc(GameMenuFrame, "InitButtons", Hook.GameMenuInitButtons)
    Hook.GameMenuInitButtons(GameMenuFrame)
end
