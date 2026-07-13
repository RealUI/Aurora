local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Util = Aurora.Util

--[[ Classic-family petition/charter view (era/TBC/Mists).
    Evidence: Classic/PetitionFrame.xml — parchment charter panel with
    Cancel/Sign/Request/Rename buttons.
]]

function private.FrameXML.PetitionFrame()
    local PetitionFrame = _G.PetitionFrame

    Util.HideFrameTextures(PetitionFrame, true)
    Skin.FrameTypeFrame(PetitionFrame)
    PetitionFrame:SetBackdropOption("offsets", {
        left = 10,
        right = 30,
        top = 0,
        bottom = 75,
    })

    Util.HideFrameTextures(_G.PetitionNpcNameFrame)

    for _, name in ipairs({"PetitionFrameCancelButton", "PetitionFrameSignButton", "PetitionFrameRequestButton", "PetitionFrameRenameButton"}) do
        local button = _G[name]
        if button then
            Skin.UIPanelButtonTemplate(button)
        end
    end
end
