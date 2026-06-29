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
    if not MacroFrame then return end

    Skin.ButtonFrameTemplate(MacroFrame)
    local bg
    if MacroFrame.NineSlice and MacroFrame.NineSlice.GetBackdropTexture then
        bg = MacroFrame.NineSlice:GetBackdropTexture("bg")
    end

    -- BlizzWTF: These should use the widgets included in the template
    local portrait, title = select(3, MacroFrame:GetRegions())
    if portrait then portrait:Hide() end
    if title and MacroFrame.TitleContainer then
        title:SetAllPoints(MacroFrame.TitleContainer)
    end

    if _G.MacroHorizontalBarLeft then _G.MacroHorizontalBarLeft:Hide() end
    local barRight = select(6, MacroFrame:GetRegions())
    if barRight then barRight:Hide() end

    if _G.MacroFrameSelectedMacroBackground then
        _G.MacroFrameSelectedMacroBackground:SetAlpha(0)
    end
    if _G.MacroFrameSelectedMacroName and _G.MacroFrameSelectedMacroButton then
        _G.MacroFrameSelectedMacroName:SetPoint("TOPLEFT", _G.MacroFrameSelectedMacroButton, "TOPRIGHT", 9, 5)
    end
    if _G.MacroFrameEnterMacroText and _G.MacroFrameTextBackground then
        _G.MacroFrameEnterMacroText:ClearAllPoints()
        _G.MacroFrameEnterMacroText:SetPoint("BOTTOMLEFT", _G.MacroFrameTextBackground, "TOPLEFT", 7, 0)
    end
    if _G.MacroFrameCharLimitText and _G.MacroFrameScrollFrame then
        _G.MacroFrameCharLimitText:ClearAllPoints()
        _G.MacroFrameCharLimitText:SetPoint("TOP", _G.MacroFrameScrollFrame, "BOTTOM", 0, -3)
    end

    if MacroFrame.SelectedMacroButton then
        Skin.MacroButtonTemplate(MacroFrame.SelectedMacroButton)
        if MacroFrame.MacroSelector then
            MacroFrame.SelectedMacroButton:SetPoint("TOPLEFT", MacroFrame.MacroSelector, "BOTTOMLEFT", 7, -15)
        end
    end

    -- MacroSelector is the modern ScrollBoxSelector pattern
    if MacroFrame.MacroSelector then
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
    end

    if _G.MacroEditButton then
        Skin.UIPanelButtonTemplate(_G.MacroEditButton)
        _G.MacroEditButton:ClearAllPoints()
        if _G.MacroFrameSelectedMacroButton then
            _G.MacroEditButton:SetPoint("BOTTOMLEFT", _G.MacroFrameSelectedMacroButton, "BOTTOMRIGHT", 5, -5)
        end
    end

    if _G.MacroFrameScrollFrame then
        Skin.ScrollFrameTemplate(_G.MacroFrameScrollFrame)
        if MacroFrame.MacroSelector then
            _G.MacroFrameScrollFrame:SetPoint("TOPLEFT", MacroFrame.MacroSelector, "BOTTOMLEFT", 0, -80)
        end
        _G.MacroFrameScrollFrame:SetPoint("BOTTOMRIGHT", -28, 42)
        if _G.MacroFrameTextButton then
            _G.MacroFrameTextButton:SetAllPoints(_G.MacroFrameScrollFrame)
        end
    end

    if _G.MacroCancelButton then
        Skin.UIPanelButtonTemplate(_G.MacroCancelButton)
        if _G.MacroFrameScrollFrame then
            _G.MacroCancelButton:SetPoint("BOTTOMRIGHT", _G.MacroFrameScrollFrame, "TOPRIGHT", 23, 10)
        end
    end
    if _G.MacroSaveButton then
        Skin.UIPanelButtonTemplate(_G.MacroSaveButton)
    end

    if _G.MacroFrameTextBackground and _G.MacroFrameScrollFrame then
        Skin.TooltipBackdropTemplate(_G.MacroFrameTextBackground)
        _G.MacroFrameTextBackground:SetPoint("TOPLEFT", _G.MacroFrameScrollFrame, -2, 2)
        _G.MacroFrameTextBackground:SetPoint("BOTTOMRIGHT", _G.MacroFrameScrollFrame, 20, -2)
        do
            local r, g, b = Color.frame:GetRGB()
            _G.MacroFrameTextBackground:SetBackdropColor(r, g, b, 0.78)
            _G.MacroFrameTextBackground:SetBackdropBorderColor(Color.grayLight:GetRGB())
        end
    end

    if _G.MacroFrameSelectedMacroName then
        _G.MacroFrameSelectedMacroName:SetTextColor(Color.yellow:GetRGB())
    end
    if _G.MacroFrameEnterMacroText then
        _G.MacroFrameEnterMacroText:SetTextColor(Color.grayLight:GetRGB())
    end
    if _G.MacroFrameCharLimitText then
        _G.MacroFrameCharLimitText:SetTextColor(Color.grayLight:GetRGB())
    end

    if _G.MacroFrameTab1 then
        Skin.PanelTopTabButtonTemplate(_G.MacroFrameTab1)
        _G.MacroFrameTab1:SetPoint("TOPLEFT", 20, -20)
    end
    if _G.MacroFrameTab2 then
        Skin.PanelTopTabButtonTemplate(_G.MacroFrameTab2)
        _G.MacroFrameTab2:ClearAllPoints()
        if _G.MacroFrameTab1 then
            _G.MacroFrameTab2:SetPoint("BOTTOMLEFT", _G.MacroFrameTab1, "BOTTOMRIGHT", 10, 0)
        end
    end

    if _G.MacroDeleteButton and bg then
        Skin.UIPanelButtonTemplate(_G.MacroDeleteButton)
        _G.MacroDeleteButton:SetPoint("BOTTOMLEFT", bg, 5, 5)
    end

    if _G.MacroNewButton and _G.MacroExitButton and bg then
        Skin.UIPanelButtonTemplate(_G.MacroNewButton)
        Skin.UIPanelButtonTemplate(_G.MacroExitButton)
        Util.PositionRelative("BOTTOMRIGHT", bg, "BOTTOMRIGHT", -5, 5, 5, "Left", {
            _G.MacroExitButton,
            _G.MacroNewButton,
        })
    end

    ----====####################====----
    --   Blizzard_MacroIconSelector   --
    ----====####################====----
    local MacroPopupFrame = _G.MacroPopupFrame
    if MacroPopupFrame then
        Skin.IconSelectorPopupFrameTemplate(MacroPopupFrame)
    end
end
