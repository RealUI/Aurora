local _, private = ...
if private.shouldSkip() then return end

local Aurora = private.Aurora
local Base, _, Skin = Aurora.Base, Aurora.Hook, Aurora.Skin

function private.AddOns.Blizzard_PlunderstormPrematchUI()
    local frame = _G.PrematchHeaderFrame
    if not frame then return end

    ------------------------------------
    -- PrematchHeaderFrame
    ------------------------------------
    if not private.IsSkinned(frame) then
        private.SetSkinned(frame, true)
        Skin.FrameTypeFrame(frame)
    end

    ------------------------------------
    -- Strip plunderstorm-top-menu-frame atlas background
    ------------------------------------
    Base.StripBlizzardTextures(frame)

    ------------------------------------
    -- QueueFrame (PortraitFrameTemplate)
    ------------------------------------
    if frame.QueueFrame then
        if not private.IsSkinned(frame.QueueFrame) then
            private.SetSkinned(frame.QueueFrame, true)
            Skin.FrameTypeFrame(frame.QueueFrame)
        end

        -- StartQueueButton (SharedButtonSmallTemplate)
        if frame.QueueFrame.StartQueueButton then
            Skin.FrameTypeButton(frame.QueueFrame.StartQueueButton)
        end
    end

    ------------------------------------
    -- Header buttons
    ------------------------------------
    if frame.PlunderstoreButton then
        Skin.FrameTypeButton(frame.PlunderstoreButton)
    end
    if frame.CustomizeButton then
        Skin.FrameTypeButton(frame.CustomizeButton)
    end
    if frame.QueueSelect then
        Skin.FrameTypeButton(frame.QueueSelect)
    end
    if frame.DropMapButton then
        Skin.FrameTypeButton(frame.DropMapButton)
    end
end
