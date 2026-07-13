local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Util = Aurora.Util

--[[ Classic-family battleground queue panel (era/TBC/Mists).
    Evidence: Classic/BattlefieldFrame.xml — sheet panel, 12 text zone
    rows over a FauxScrollFrame, Join/Group Join/Cancel.
]]

function private.FrameXML.BattlefieldFrame()
    local BattlefieldFrame = _G.BattlefieldFrame

    Util.HideFrameTextures(BattlefieldFrame, true)
    Skin.FrameTypeFrame(BattlefieldFrame)
    BattlefieldFrame:SetBackdropOption("offsets", {
        left = 10,
        right = 30,
        top = 0,
        bottom = 75,
    })

    Skin.FauxScrollFrameTemplate(_G.BattlefieldListScrollFrame)
    Util.HideFrameTextures(_G.BattlefieldListScrollFrame)

    for _, name in ipairs({"BattlefieldFrameCancelButton", "BattlefieldFrameJoinButton", "BattlefieldFrameGroupJoinButton"}) do
        local button = _G[name]
        if button then
            Skin.UIPanelButtonTemplate(button)
        end
    end
    Skin.UIPanelCloseButton(_G.BattlefieldFrameCloseButton)
end
