local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Hook, Skin = Aurora.Hook, Aurora.Skin

do --[[ SharedXML\HybridScrollFrame.lua ]]
    function Hook.HybridScrollFrame_CreateButtons(self, buttonTemplate, initialOffsetX, initialOffsetY, initialPoint, initialRelative, offsetX, offsetY, point, relativePoint)
        --print("Hook.HybridScrollFrame_CreateButtons", buttonTemplate)
        if Skin[buttonTemplate] then
            local numButtons = #self.buttons
            local numSkinned = self._auroraNumSkinned or 0

            for i = numSkinned + 1, numButtons do
                Skin[buttonTemplate](self.buttons[i])
            end
            self._auroraNumSkinned = numButtons
        end
    end
end

do --[[ SharedXML\HybridScrollFrame.xml ]]
    Skin.HybridScrollBarButton = Skin.ScrollBarThumb

    function Skin.HybridScrollBarTemplate(Slider)
        Slider.ThumbTexture = Slider.thumbTexture
        Skin.UIPanelScrollBarTemplate(Slider)
    end
    function Skin.HybridScrollBarTrimTemplate(Slider)
        local parent = Slider:GetParent()
        Slider:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, -17)
        Slider:SetPoint("BOTTOMLEFT", parent, "BOTTOMRIGHT", 0, 17)

        Slider.trackBG:SetAlpha(0)

        Slider.Top:Hide()
        Slider.Bottom:Hide()
        Slider.Middle:Hide()

        -- Use the unified scrollbar skin which handles buttons and thumb
        Skin.FrameTypeScrollBar(Slider)
        Slider.UpButton:SetPoint("BOTTOM", Slider, "TOP")
        Slider.DownButton:SetPoint("TOP", Slider, "BOTTOM")
        Skin.ScrollBarThumb(Slider.thumbTexture)
    end
    function Skin.MinimalHybridScrollBarTemplate(Slider)
        Slider:GetParent().scrollUp.direction = _G.ScrollControllerMixin.Directions.Decrease
        Slider:GetParent().scrollDown.direction = _G.ScrollControllerMixin.Directions.Increase
        Skin.FrameTypeScrollBar(Slider)
    end
    -- HybridScrollFrameTemplate -- Has no visible parts
    function Skin.BasicHybridScrollFrameTemplate(ScrollFrame)
        Skin.HybridScrollBarTemplate(ScrollFrame.ScrollBar)
    end
    function Skin.MinimalHybridScrollFrameTemplate(ScrollFrame)
        Skin.MinimalHybridScrollBarTemplate(ScrollFrame.scrollBar)
    end
end

function private.SharedXML.HybridScrollFrame()
    _G.hooksecurefunc("HybridScrollFrame_CreateButtons", Hook.HybridScrollFrame_CreateButtons)
end
