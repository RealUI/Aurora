local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals hooksecurefunc

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Color, Util = Aurora.Color, Aurora.Util

-- Helper: skin an individual alert frame when it's added to the container.
-- Alert toast frames have a Background texture and possibly icon buttons.
local function SkinAlertFrame(frame)
    if not frame then return end
    if frame._auroraSkinned then return end
    frame._auroraSkinned = true

    -- Apply a flat backdrop to the alert toast frame itself
    Base.SetBackdrop(frame, Color.frame, Util.GetFrameAlpha())

    -- Hide background art textures (LFG dungeon toast, achievement alert bg, etc.)
    if frame.Background then
        frame.Background:SetAlpha(0)
    end
    if frame.BGAtlas then
        frame.BGAtlas:SetAlpha(0)
    end
    if frame.PvPBackground then
        frame.PvPBackground:SetAlpha(0)
    end
    if frame.RatedPvPBackground then
        frame.RatedPvPBackground:SetAlpha(0)
    end

    -- Hide dungeon/raid art textures (DungeonCompletionAlertFrame)
    if frame.raidArt then
        frame.raidArt:SetAlpha(0)
    end
    for i = 1, 4 do
        local artKey = "dungeonArt" .. i
        if frame[artKey] then
            frame[artKey]:SetAlpha(0)
        end
    end

    -- Hide glow and shine overlays (these are animated cosmetics)
    if frame.glow then
        frame.glow:SetAlpha(0)
    end
    if frame.shine then
        frame.shine:SetAlpha(0)
    end
    if frame.glowFrame and frame.glowFrame.glow then
        frame.glowFrame.glow:SetAlpha(0)
    end

    -- Skin the icon if present (achievement icon, loot icon, etc.)
    local icon = frame.Icon
    if icon then
        local iconTexture = icon.Texture or icon
        if iconTexture and iconTexture.GetObjectType and iconTexture:GetObjectType() == "Texture" then
            Base.CropIcon(iconTexture, icon)
        end
        -- Hide the ornamental icon border overlay
        if icon.Overlay then
            icon.Overlay:SetAlpha(0)
        end
    end

    -- Skin the icon border (loot alert quality border)
    if frame.IconBorder then
        frame.IconBorder:SetAlpha(0)
    end
    if frame.IconOverlay then
        frame.IconOverlay:SetAlpha(0)
    end

    -- Skin reward frames if present (dungeon completion rewards)
    if frame.RewardFrames then
        for _, rewardFrame in _G.ipairs(frame.RewardFrames) do
            if rewardFrame.texture then
                Base.CropIcon(rewardFrame.texture, rewardFrame)
            end
        end
    end
end

function private.FrameXML.AlertFrames()
    local AlertFrame = _G.AlertFrame
    if not AlertFrame then return end

    -- Hook AddAlertFrame on the AlertContainerMixin to skin each alert as it's shown
    if AlertFrame.AddAlertFrame then
        _G.hooksecurefunc(AlertFrame, "AddAlertFrame", function(_, frame)
            SkinAlertFrame(frame)
        end)
    end
end
