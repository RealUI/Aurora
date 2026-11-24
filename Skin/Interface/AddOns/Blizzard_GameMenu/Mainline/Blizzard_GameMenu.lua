local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals _G

--[[ Core ]]
local Aurora = private.Aurora
local Hook, Skin = Aurora.Hook, Aurora.Skin

--[[ B261 Layer 2 (A-candidate, tasks.md 3.2.5), read from wow-ui-source
    (retail) and wow-ui-source-forever. The game menu's buttons come from a
    frame pool (MainMenuFrameMixin:OnLoad, Blizzard_SharedXML/Shared/Frame/
    MainMenuFrameTemplates.lua:14). Every InitButtons (on show and on its
    events, Blizzard_GameMenu/Shared/GameMenuFrame.lua:68, :88) releases
    them all and acquires them again for the current entries (:19, :26),
    with SetEnabled on each (:44). Logout, Quit and
    ShowUIPanel(EditModeManagerFrame) run from those same buttons' clicks
    (GameMenuFrame.lua:215, :216, :185). Forever: the same code at
    GameMenuFrame.lua:72, :101, :265, :266, :235; the pool file differs only
    in AddCloseButton.
    Shape "flat": the buttons are pooled, children of a VerticalLayoutFrame
    that measures them (MainMenuFrameTemplates.xml, MainMenuFrameTemplate).
    The Layer 2 record is kept by Aurora, keyed by the button, and the
    state textures are the button's own, so both stay with the button
    through release (Pool_HideAndClearAnchors and layoutIndex = nil,
    MainMenuFrameTemplates.lua:4-7) and come back with it on the next
    Acquire for any entry; Acquire touches neither.
    The buttons are BigRedThreeSliceButtonTemplate
    (Blizzard_SharedXML/Mainline/Frame/MainMenuFrameTemplates.xml): Left,
    Center and Right are re-stamped with SetAtlas on every show, enable,
    disable, press and release (ThreeSliceButtonMixin:UpdateButton,
    Blizzard_SharedXML/Shared/Button/ThreeSliceButtonTemplate.lua, and the
    template's scripts, ThreeSliceButtonTemplate.xml:4-58). SetAtlas does
    not touch alpha, so alpha 0 holds; no hook on UpdateButton.
    Each pooled button is skinned once, the first time it is active after
    an InitButtons, with widget calls only; nothing is written on the
    button and no Aurora code runs in a click. ]]
local function SkinMenuButton(button)
    if button.Left then button.Left:SetAlpha(0) end
    if button.Center then button.Center:SetAlpha(0) end
    if button.Right then button.Right:SetAlpha(0) end
    Skin.TaintSafeFrameTypeButton(button, "flat")
    private.SetSkinned(button, true)
end

-- Also called by RealUI after it adds its own entry
-- (RealUI/RealUI/GameMenu.lua), so the name stays.
function Hook.GameMenuInitButtons(menu)
    if not menu.buttonPool then return end
    for button in menu.buttonPool:EnumerateActive() do
        if not private.IsSkinned(button) then
            SkinMenuButton(button)
        end
    end
end

do
    do
        function Skin.GameMenuFrameTemplate(Frame)
            if not Frame then
                return
            end
            Skin.DialogBorderTemplate(Frame.Border)
            Skin.DialogHeaderTemplate(Frame.Header)
        end
    end
end

function private.FrameXML.GameMenuFrame()
    local GameMenuFrame = _G.GameMenuFrame
    -- Hook InitButtons for every open. On retail and Forever OnLoad only
    -- resets the pool (MainMenuFrameTemplates.lua:9-16), so the call below
    -- usually finds nothing active; it covers a menu already built before
    -- this skin ran.
    _G.hooksecurefunc(GameMenuFrame, "InitButtons", Hook.GameMenuInitButtons)
    Hook.GameMenuInitButtons(GameMenuFrame)
    Skin.GameMenuFrameTemplate(GameMenuFrame)
end
