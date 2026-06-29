local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

-- Guard: Blizzard_EngravingUI only exists in Season of Discovery builds
if not _G.C_AddOns or not _G.C_AddOns.DoesAddOnExist or not _G.C_AddOns.DoesAddOnExist("Blizzard_EngravingUI") then return end

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

function private.AddOns.Blizzard_EngravingUI()
    local EngravingFrame = _G.EngravingFrame
    if not EngravingFrame then return end

    -- Apply Aurora backdrop to the main engraving frame
    Base.SetBackdrop(EngravingFrame, Color.frame, Util.GetFrameAlpha())

    -- Hide border/background textures
    if EngravingFrame.BorderFrame then
        EngravingFrame.BorderFrame:Hide()
    end

    -- Skin rune socket slots
    if EngravingFrame.RuneSlots then
        for _, slot in _G.ipairs(EngravingFrame.RuneSlots) do
            if slot then
                if slot.Border then
                    slot.Border:Hide()
                end
                local icon = slot.Icon or slot.icon
                if icon then
                    Base.CropIcon(icon, slot)
                end
            end
        end
    end

    -- Skin rune selection list/scroll
    if EngravingFrame.ScrollFrame then
        Skin.UIPanelScrollFrameTemplate(EngravingFrame.ScrollFrame)
    end

    -- Skin close button
    if EngravingFrame.CloseButton then
        Skin.UIPanelCloseButton(EngravingFrame.CloseButton)
    elseif _G.EngravingFrameCloseButton then
        Skin.UIPanelCloseButton(_G.EngravingFrameCloseButton)
    end
end
