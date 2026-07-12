local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals select

--[[ Core ]]
local Aurora = private.Aurora
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color = Aurora.Color
local Util = Aurora.Util

do --[[ AddOns\Blizzard_MacroUI.lua ]]
    function Hook.MacroFrame_OnShow(self)
        --_G.MacroPopupButton1:SetPoint("TOPLEFT", 25, -30)
        --_G.MacroPopupButton1:SetPoint("TOPLEFT", _G.MacroPopupScrollFrame, 0, -1)
    end
end

do --[[ AddOns\Blizzard_MacroUI.xml ]]
    function Skin.MacroButtonTemplate(Button)
        Skin.SelectorButtonTemplate(Button)
    end
end

function private.AddOns.Blizzard_MacroUI()
    ----====####################====----
    --        Blizzard_MacroUI        --
    ----====####################====----
    local MacroFrame = _G.MacroFrame
    --MacroFrame:HookScript("OnShow", Hook.MacroFrame_OnShow)

    Skin.ButtonFrameTemplate(MacroFrame)
    local bg = MacroFrame.NineSlice:GetBackdropTexture("bg")

    -- BlizzWTF: These should use the widgets included in the template
    local portrait, title = select(3, MacroFrame:GetRegions())
    portrait:Hide()
    title:SetAllPoints(MacroFrame.TitleContainer)

    _G.MacroHorizontalBarLeft:Hide()
    select(6, MacroFrame:GetRegions()):Hide() -- BarRight

    _G.MacroFrameSelectedMacroBackground:SetAlpha(0)
    _G.MacroFrameSelectedMacroName:SetPoint("TOPLEFT", _G.MacroFrameSelectedMacroButton, "TOPRIGHT", 9, 5)
    _G.MacroFrameEnterMacroText:ClearAllPoints()
    _G.MacroFrameEnterMacroText:SetPoint("BOTTOMLEFT", _G.MacroFrameTextBackground, "TOPLEFT", 7, 0)
    _G.MacroFrameCharLimitText:ClearAllPoints()
    _G.MacroFrameCharLimitText:SetPoint("TOP", _G.MacroFrameScrollFrame, "BOTTOM", 0, -3)

    Skin.MacroButtonTemplate(MacroFrame.SelectedMacroButton)
    MacroFrame.SelectedMacroButton:SetPoint("TOPLEFT", MacroFrame.MacroSelector, "BOTTOMLEFT", 7, -15)

    Skin.ScrollBoxSelectorTemplate(MacroFrame.MacroSelector)
    Skin.FrameTypeFrame(MacroFrame.MacroSelector)
    MacroFrame.MacroSelector:SetPoint("TOPLEFT", 10, -(private.FRAME_TITLE_HEIGHT + 29))
    do
        local selectorBG = MacroFrame.MacroSelector:GetBackdropTexture("bg")
        if selectorBG then
            selectorBG:SetAlpha(0.65)
        end
    end

    do
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
    --MacroFrame.MacroSelector:SetSize(298, 140)

    Skin.UIPanelButtonTemplate(_G.MacroEditButton)
    _G.MacroEditButton:ClearAllPoints()
    _G.MacroEditButton:SetPoint("BOTTOMLEFT", _G.MacroFrameSelectedMacroButton, "BOTTOMRIGHT", 5, -5)

    Skin.ScrollFrameTemplate(_G.MacroFrameScrollFrame)
    _G.MacroFrameScrollFrame:SetPoint("TOPLEFT", MacroFrame.MacroSelector, "BOTTOMLEFT", 0, -80)
    _G.MacroFrameScrollFrame:SetPoint("BOTTOMRIGHT", -28, 42)
    _G.MacroFrameTextButton:SetAllPoints(_G.MacroFrameScrollFrame)

    Skin.UIPanelButtonTemplate(_G.MacroCancelButton)
    _G.MacroCancelButton:SetPoint("BOTTOMRIGHT", _G.MacroFrameScrollFrame, "TOPRIGHT", 23, 10)
    Skin.UIPanelButtonTemplate(_G.MacroSaveButton)

    Skin.TooltipBackdropTemplate(_G.MacroFrameTextBackground)
    _G.MacroFrameTextBackground:SetPoint("TOPLEFT", _G.MacroFrameScrollFrame, -2, 2)
    _G.MacroFrameTextBackground:SetPoint("BOTTOMRIGHT", _G.MacroFrameScrollFrame, 20, -2)
    do
        local r, g, b = Color.frame:GetRGB()
        _G.MacroFrameTextBackground:SetBackdropColor(r, g, b, 0.78)
        _G.MacroFrameTextBackground:SetBackdropBorderColor(Color.grayLight:GetRGB())
    end

    _G.MacroFrameSelectedMacroName:SetTextColor(Color.yellow:GetRGB())
    _G.MacroFrameEnterMacroText:SetTextColor(Color.grayLight:GetRGB())
    _G.MacroFrameCharLimitText:SetTextColor(Color.grayLight:GetRGB())

    Skin.PanelTopTabButtonTemplate(_G.MacroFrameTab1)
    _G.MacroFrameTab1:SetPoint("TOPLEFT", 20, -20)
    Skin.PanelTopTabButtonTemplate(_G.MacroFrameTab2)
    _G.MacroFrameTab2:ClearAllPoints()
    _G.MacroFrameTab2:SetPoint("BOTTOMLEFT", _G.MacroFrameTab1, "BOTTOMRIGHT", 10, 0)

    Skin.UIPanelButtonTemplate(_G.MacroDeleteButton)
    _G.MacroDeleteButton:SetPoint("BOTTOMLEFT", bg, 5, 5)

    Skin.UIPanelButtonTemplate(_G.MacroNewButton)
    Skin.UIPanelButtonTemplate(_G.MacroExitButton)
    Util.PositionRelative("BOTTOMRIGHT", bg, "BOTTOMRIGHT", -5, 5, 5, "Left", {
        _G.MacroExitButton,
        _G.MacroNewButton,
    })

    ----====####################====----
    --   Blizzard_MacroIconSelector   --
    ----====####################====----
    local MacroPopupFrame = _G.MacroPopupFrame
    Skin.IconSelectorPopupFrameTemplate(MacroPopupFrame)
end
