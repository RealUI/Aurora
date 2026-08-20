local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Base = Aurora.Base

--do --[[ FrameXML\ScrollBar.lua ]]
--end

do --[[ FrameXML\ScrollBar.xml ]]
    function Skin.ScrollBarBaseTemplate(Frame)
    end
    function Skin.FrameTypeScrollBarButton(Button)
        Skin.FrameTypeButton(Button)
        local tex = Button:GetRegions()
        if Button.direction then
            -- Button:SetBackdropOption("offsets", {
            --     left = 2,
            --     right = 1,
            --     top = 0,
            --     bottom = 1,
            -- })

            -- local bg = Button:GetBackdropTexture("bg")
            tex:ClearAllPoints()
            -- tex:SetPoint("TOPLEFT", bg, 3, -5)
            -- tex:SetPoint("BOTTOMRIGHT", bg, -3, 5)
            Button._auroraTextures = {tex}

            local function setArrow()
                if Button.direction == _G.ScrollControllerMixin.Directions.Decrease then
                    Base.SetTexture(tex, "arrowUp")
                else
                    Base.SetTexture(tex, "arrowDown")
                end
            end
            -- B35: apply now, not just in the hook — OnShow only fires on a
            -- Hide→Show transition, so a stepper that is already visible when
            -- skinned (chat at login) kept Blizzard's atlas until the first
            -- scroll toggled it.
            setArrow()
            Button:HookScript("OnShow", setArrow)

            -- ...and re-assert after every state change:
            -- MinimalScrollBarStepperScriptsMixin:OnButtonStateChanged does
            -- Texture:SetAtlas(GetAtlas(), UseAtlasSize) on enable/disable/
            -- enter/leave/mouse-down, stamping Blizzard's atlas back over the
            -- arrow — including during login init, after the skin ran.
            if Button.OnButtonStateChanged then
                _G.hooksecurefunc(Button, "OnButtonStateChanged", setArrow)
            end
        else
            -- Button:SetBackdropOption("offsets", {
            --     left = 0,
            --     right = -1,
            --     top = 0,
            --     bottom = 1,
            -- })
            tex:Hide()
        end

        Button.Enter:SetAlpha(0)
        Button.Down:SetAlpha(0)
    end
end

function private.SharedXML.ScrollBar()
    ----====####################====----
    --              ScrollBar              --
    ----====####################====----

    -------------
    -- Section --
    -------------
end
