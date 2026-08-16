local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base, Hook, Skin = Aurora.Base, Aurora.Hook, Aurora.Skin
local Util = Aurora.Util

do --[[ AddOns\Blizzard_MatchmakingQueueDisplay.lua ]]
    Hook.QueueTypeSettingsFrameMixin = {}
    function Hook.QueueTypeSettingsFrameMixin:UpdateButtons()
        -- Post-hook: skin any queue type buttons that become visible
        local container = self.QueueContainer
        if not container then return end

        local buttons = { container.Training, container.Solo, container.Duo, container.Trio }
        for _, btn in next, buttons do
            if btn and not private.IsSkinned(btn) then
                Skin.FrameTypeButton(btn)
                private.SetSkinned(btn, true)
            end
        end

        if self.GameReadyButton and not private.IsSkinned(self.GameReadyButton) then
            Skin.FrameTypeButton(self.GameReadyButton)
            private.SetSkinned(self.GameReadyButton, true)
        end
    end
end

--[[ AddOns\Blizzard_MatchmakingQueueDisplay.xml ]]
-- Queue type selection buttons and ready/leave buttons are skinned
-- dynamically via the UpdateButtons hook and the registration function.

function private.AddOns.Blizzard_MatchmakingQueueDisplay()
    ------------------------------------------------
    -- Hook mixin prototypes via Util.Mixin
    ------------------------------------------------
    Util.Mixin(_G.QueueTypeSettingsFrameMixin, Hook.QueueTypeSettingsFrameMixin)

    ------------------------------------------------
    -- Skin the QueueTypeSettingsFrame if it exists
    ------------------------------------------------
    local settingsFrame = _G.QueueTypeSettingsFrame
    if settingsFrame then
        Skin.FrameTypeFrame(settingsFrame)
        Base.StripBlizzardTextures(settingsFrame)

        -- Skin the QueueContainer
        local container = settingsFrame.QueueContainer
        if container then
            Base.StripBlizzardTextures(container)

            -- Skin queue type selection buttons
            local buttons = { container.Training, container.Solo, container.Duo, container.Trio }
            for _, btn in next, buttons do
                if btn and not private.IsSkinned(btn) then
                    Skin.FrameTypeButton(btn)
                    private.SetSkinned(btn, true)
                end
            end
        end

        -- Skin the GameReadyButton
        if settingsFrame.GameReadyButton and not private.IsSkinned(settingsFrame.GameReadyButton) then
            Skin.FrameTypeButton(settingsFrame.GameReadyButton)
            private.SetSkinned(settingsFrame.GameReadyButton, true)
        end
    end

    ------------------------------------------------
    -- Skin the MatchmakingQueueFrame if it exists
    ------------------------------------------------
    local queueFrame = _G.MatchmakingQueueFrame
    if queueFrame then
        Skin.FrameTypeFrame(queueFrame)
        Base.StripBlizzardTextures(queueFrame)

        -- Skin the LeaveQueueButton if present
        if queueFrame.LeaveQueueButton and not private.IsSkinned(queueFrame.LeaveQueueButton) then
            Skin.FrameTypeButton(queueFrame.LeaveQueueButton)
            private.SetSkinned(queueFrame.LeaveQueueButton, true)
        end
    end
end
