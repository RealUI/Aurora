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

--[[ B261 Layer 2 (A-candidate, tasks.md 3.2.5), read from
    wow-ui-source-classic (Mists), wow-ui-source-anniversary (TBC) and
    wow-ui-source-era (Vanilla). The same pool as retail
    (Blizzard_SharedXML/Shared/Frame/MainMenuFrameTemplates.lua: pool at
    :14, release and Acquire at :19, :25, SetEnabled at :36 on the classic
    trees), the same Logout and Quit on the same buttons
    (Blizzard_GameMenu/Shared/GameMenuFrame.lua:158-159 in the Mists tree). The buttons are
    MainMenuFrameButtonTemplate, a UIPanelButtonTemplate
    (Blizzard_SharedXML/Classic/Frame/MainMenuFrameTemplates.xml:11-16, all
    three trees), whose plates Blizzard re-sets on every press, show,
    enable and disable (SecureUIPanelTemplates.lua:174-209):
    Skin.TaintSafeUIPanelButtonTemplate hides them by alpha. Shape "flat":
    pooled buttons in a VerticalLayoutFrame. The Layer 2 record and the
    state textures stay with a button through release and the next
    Acquire. Skinned once, the first time each is active. ]]
function Hook.GameMenuInitButtons(menu)
    if not menu.buttonPool then return end
    for button in menu.buttonPool:EnumerateActive() do
        if not private.IsSkinned(button) then
            Skin.TaintSafeUIPanelButtonTemplate(button, "flat")
            private.SetSkinned(button, true)
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
