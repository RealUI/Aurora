local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals _G next

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color = Aurora.Color
local Util = Aurora.Util

do
    do
        Hook.GameMenuFrameMixin = {}
        function Hook.GameMenuFrameMixin:OnShow()
        end
        function Hook.GameMenuFrameMixin:OnHide()
        end
        function Hook.GameMenuFrameMixin:OnEvent()
        end
        function Hook.GameMenuUpdateButtonStyle(button)
            if button.Left then
                button.Left:Hide()
            end
            if button.Right then
                button.Right:Hide()
            end
            if button.Center then
                button.Center:SetTexture("")
                button.Center:Hide()
            end
            -- Hide any highlight textures from three-slice template
            local highlight = button:GetHighlightTexture()
            if highlight then
                highlight:SetTexture("")
                highlight:Hide()
                highlight:SetAlpha(0)
            end
        end
        function Hook.GameMenuSkinButton(button)
            Skin.UIPanelButtonTemplate(button)

            button._isMinimal = false
            button:SetButtonColor(Color.button, 0.65)
            Base.SetBackdrop(button, Color.button, 0.65)

            Hook.GameMenuUpdateButtonStyle(button)
            if button.UpdateButton and not button._auroraGameMenuHooked then
                _G.hooksecurefunc(button, "UpdateButton", Hook.GameMenuUpdateButtonStyle)
                button._auroraGameMenuHooked = true
            end

            -- Create a custom highlight overlay that shows on hover
            if not button._auroraHighlight then
                local highlight = button:CreateTexture(nil, "HIGHLIGHT")
                highlight:SetAllPoints(button:GetBackdropTexture("bg"))
                highlight:SetColorTexture(0, 0, 0, 0.3) -- static: not a theme color
                button._auroraHighlight = highlight
            end

            button._auroraSkinned = true
        end
        function Hook.GameMenuInitButtons(menu)
            if not menu.buttonPool then return end
            for button in menu.buttonPool:EnumerateActive() do
                if not button._auroraSkinned then
                    Hook.GameMenuSkinButton(button)
                end
            end
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
    _G.hooksecurefunc(GameMenuFrame,"InitButtons", Hook.GameMenuInitButtons)
    Util.Mixin(GameMenuFrame, Hook.GameMenuFrameMixin)
    Skin.GameMenuFrameTemplate(GameMenuFrame)
end
