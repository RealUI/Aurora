local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

--[[ Classic-family macro panel (era/TBC/Mists; retail resolves Mainline/).
    Era's Blizzard_MacroUI is a 12.x backport: ButtonFrameTemplate root with
    the modern ScrollBoxSelector macro grid (both selector skins are active
    in the Shared layer on classic). Blizzard's layout is kept — art only.
    The icon-picker popup (IconSelectorPopupFrameTemplate) skin is
    Mainline-only; guarded, left stock for iteration.
]]

do --[[ Blizzard_MacroUI.xml ]]
    function Skin.MacroButtonTemplate(Button)
        Skin.SelectorButtonTemplate(Button)
    end
end

function private.AddOns.Blizzard_MacroUI()
    local MacroFrame = _G.MacroFrame

    -- Root sweep BEFORE the template skin: named portrait icon, trainer
    -- bars, selected-macro slot art
    Util.HideFrameTextures(MacroFrame, true)
    Skin.ButtonFrameTemplate(MacroFrame)

    Skin.PanelTopTabButtonTemplate(_G.MacroFrameTab1)
    Skin.PanelTopTabButtonTemplate(_G.MacroFrameTab2)

    -- Macro grid
    Skin.ScrollBoxSelectorTemplate(MacroFrame.MacroSelector)
    Skin.FrameTypeFrame(MacroFrame.MacroSelector)
    do
        local selectorBG = MacroFrame.MacroSelector:GetBackdropTexture("bg")
        if selectorBG then
            selectorBG:SetAlpha(0.65)
        end

        -- pooled grid buttons skin on creation
        local macroSelector = MacroFrame.MacroSelector
        local initMacroButton = macroSelector.GetSetupCallback and macroSelector:GetSetupCallback()
        if initMacroButton then
            macroSelector:SetSetupCallback(function(button, selectionIndex, name, texture, body)
                initMacroButton(button, selectionIndex, name, texture, body)

                local hasBackdropBG = button.GetBackdropTexture and button:GetBackdropTexture("bg")
                if not hasBackdropBG then
                    Skin.MacroButtonTemplate(button)
                end

                button:SetBackdropColor(1, 1, 1, 0.9)
            end)
        end
    end

    Skin.MacroButtonTemplate(MacroFrame.SelectedMacroButton)

    -- Macro text area
    local scrollFrame = _G.MacroFrameScrollFrame
    if scrollFrame and scrollFrame.ScrollBar and scrollFrame.ScrollBar.ScrollUpButton then
        Skin.UIPanelScrollBarTemplate(scrollFrame.ScrollBar)
    end
    Skin.TooltipBackdropTemplate(_G.MacroFrameTextBackground)
    do
        local r, g, b = Color.frame:GetRGB()
        _G.MacroFrameTextBackground:SetBackdropColor(r, g, b, 0.78)
        _G.MacroFrameTextBackground:SetBackdropBorderColor(Color.grayLight:GetRGB())
    end

    _G.MacroFrameSelectedMacroName:SetTextColor(Color.yellow:GetRGB())
    _G.MacroFrameEnterMacroText:SetTextColor(Color.grayLight:GetRGB())
    _G.MacroFrameCharLimitText:SetTextColor(Color.grayLight:GetRGB())

    for _, name in ipairs({"MacroEditButton", "MacroCancelButton", "MacroSaveButton", "MacroDeleteButton", "MacroNewButton", "MacroExitButton"}) do
        local button = _G[name]
        if button then
            Skin.UIPanelButtonTemplate(button)
        end
    end

    -- Icon picker popup: skin only if the Mainline-only template skin is
    -- ever ported to the Classic layer
    if Skin.IconSelectorPopupFrameTemplate and _G.MacroPopupFrame then
        Skin.IconSelectorPopupFrameTemplate(_G.MacroPopupFrame)
    end
end
