local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin

-- B261 (task 5.3): how many of a hybrid scroll frame's buttons are skinned,
-- keyed by the scroll frame. Was `_auroraNumSkinned` on the Blizzard frame.
-- HybridScrollFrame_CreateButtons only ever adds buttons and keeps them (no
-- pool), so the count only grows; weak keys.
local numSkinned = _G.setmetatable({}, {__mode = "k"})

do --[[ SharedXML\HybridScrollFrame.lua ]]
    function Hook.HybridScrollFrame_CreateButtons(self, buttonTemplate, initialOffsetX, initialOffsetY, initialPoint, initialRelative, offsetX, offsetY, point, relativePoint)
        --print("Hook.HybridScrollFrame_CreateButtons", buttonTemplate)
        if Skin[buttonTemplate] then
            local numButtons = #self.buttons
            for i = (numSkinned[self] or 0) + 1, numButtons do
                Skin[buttonTemplate](self.buttons[i])
            end
            numSkinned[self] = numButtons
        end
    end
end

do --[[ SharedXML\HybridScrollFrame.xml ]]
    Skin.HybridScrollBarButton = Skin.ScrollBarThumb

    -- Classic hybrid scroll buttons keep Blizzard's wheel-delta .direction
    -- (up = 1, down = -1, read by HybridScrollFrameScrollButton_OnClick),
    -- which is sign-opposite to ScrollControllerMixin.Directions — so the
    -- retail path (which overwrites .direction for FrameTypeScrollBar's
    -- arrow art) would invert click-scrolling. Skin without touching it.
    local function ClassicHybridScrollButton(Button, isUp)
        if not Button then return end
        Skin.FrameTypeButton(Button)
        for _, key in ipairs({"Normal", "Pushed", "Disabled", "Highlight"}) do
            if Button[key] then
                Button[key]:SetAlpha(0)
            end
        end

        local arrow = Button:CreateTexture(nil, "ARTWORK")
        arrow:SetSize(14, 6)
        if isUp then
            arrow:SetPoint("BOTTOMLEFT", Button, 2, 4)
            Base.SetTexture(arrow, "arrowUp")
        else
            arrow:SetPoint("TOPLEFT", Button, 2, -4)
            Base.SetTexture(arrow, "arrowDown")
        end
    end
    local function ClassicHybridScrollBar(Slider, UpButton, DownButton)
        for _, key in ipairs({"trackBG", "ScrollBarTop", "ScrollBarMiddle", "ScrollBarBottom"}) do
            if Slider[key] then
                Slider[key]:SetAlpha(0)
            end
        end
        ClassicHybridScrollButton(UpButton, true)
        ClassicHybridScrollButton(DownButton, false)
        Skin.ScrollBarThumb(Slider.thumbTexture)
    end

    function Skin.HybridScrollBarTemplate(Slider)
        if private.isRetail then
            Slider.ThumbTexture = Slider.thumbTexture
            Skin.UIPanelScrollBarTemplate(Slider)
            return
        end
        ClassicHybridScrollBar(Slider, Slider.ScrollUpButton, Slider.ScrollDownButton)
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
        if private.isRetail then
            Slider:GetParent().scrollUp.direction = _G.ScrollControllerMixin.Directions.Decrease
            Slider:GetParent().scrollDown.direction = _G.ScrollControllerMixin.Directions.Increase
            Skin.FrameTypeScrollBar(Slider)
            return
        end
        -- Minimal variant: buttons are name-only children ($parentScrollUpButton)
        local name = Slider:GetName()
        local scrollFrame = Slider:GetParent()
        local up = (name and _G[name.."ScrollUpButton"]) or scrollFrame.scrollUp
        local down = (name and _G[name.."ScrollDownButton"]) or scrollFrame.scrollDown
        ClassicHybridScrollBar(Slider, up, down)
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
