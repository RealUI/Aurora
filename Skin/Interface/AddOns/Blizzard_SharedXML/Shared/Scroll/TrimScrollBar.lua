local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin

--do --[[ SharedXML\TrimScrollBar.lua ]]
--end

do --[[ SharedXML\TrimScrollBar.xml ]]
    function Skin.WowTrimScrollBarStepperScripts(Frame)
        Skin.FrameTypeButton(Frame)
        Frame.Texture:Hide()
        Frame.Overlay:SetAlpha(0)

        local bg = Frame:GetBackdropTexture("bg")
        local arrow = Frame:CreateTexture(nil, "ARTWORK")
        arrow:SetPoint("TOPLEFT", bg, 3, -5)
        arrow:SetPoint("BOTTOMRIGHT", bg, -3, 5)
        if Frame.direction < 0 then
            Base.SetTexture(arrow, "arrowUp")
        else
            Base.SetTexture(arrow, "arrowDown")
        end
        Frame._auroraTextures = {arrow}
    end
    function Skin.WowTrimScrollBarThumbScripts(Frame)
        Skin.FrameTypeButton(Frame)
        Frame.Begin:Hide()
        Frame.End:Hide()
        Frame.Middle:Hide()
    end

    function Skin.WowTrimScrollBar(EventFrame)
        if EventFrame.Backplate then -- retail layout
            Skin.VerticalScrollBarTemplate(EventFrame)

            local tex = EventFrame.Backplate
            tex:SetPoint("TOPLEFT", 4, -20)
            tex:SetPoint("BOTTOMRIGHT", -3, 21)

            EventFrame.Background:Hide()
            EventFrame.Track:SetAllPoints(tex)
            Skin.WowTrimScrollBarThumbScripts(EventFrame.Track.Thumb)

            Skin.WowTrimScrollBarStepperScripts(EventFrame.Back)
            EventFrame.Back:SetPoint("TOPLEFT", 4, -2)
            Skin.WowTrimScrollBarStepperScripts(EventFrame.Forward)
            EventFrame.Forward:SetPoint("BOTTOMLEFT", 4, 2)
        else
            -- classic (Mists 5.5.4) hybrid: Track/Thumb/Background
            -- parentKeys but NO Backplate; ornate track art + gold
            -- steppers — everything guarded, live drifts from the dump
            if EventFrame.Background and EventFrame.Background.Hide then
                EventFrame.Background:Hide()
            end
            local thumb = EventFrame.Track and EventFrame.Track.Thumb
            if thumb then
                if thumb.Begin then thumb.Begin:Hide() end
                if thumb.End then thumb.End:Hide() end
                if thumb.Middle then thumb.Middle:Hide() end
                Skin.FrameTypeButton(thumb)
            end
            for _, key in ipairs({"Back", "Forward"}) do
                local stepper = EventFrame[key]
                if stepper and stepper.Texture and stepper.Overlay then
                    if stepper.direction == nil then
                        stepper.direction = (key == "Back") and -1 or 1
                    end
                    Skin.WowTrimScrollBarStepperScripts(stepper)
                end
            end
        end
    end
end

--function private.SharedXML.TrimScrollBar()
--end
