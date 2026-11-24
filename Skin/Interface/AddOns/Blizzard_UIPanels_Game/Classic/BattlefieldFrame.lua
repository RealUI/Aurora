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

    for _, name in ipairs({"BattlefieldFrameCancelButton", "BattlefieldFrameJoinButton"}) do
        local button = _G[name]
        if button then
            Skin.UIPanelButtonTemplate(button)
        end
    end
    --[[ B261 Layer 2 (A-candidate, tasks.md 3.2.5), read from
        wow-ui-source-era (Vanilla) and wow-ui-source-anniversary (TBC), the
        same lines on both. BattlefieldFrame_Update enables or disables the
        group join button (Blizzard_UIPanels_Game/Classic/BattlefieldFrame.lua:156-165)
        on UPDATE_BATTLEFIELD_STATUS and PARTY_LEADER_CHANGED, which the frame
        has registered whether it is shown or not (:14-17, :37-43); its click
        runs C_PvP.JoinBattlefield (:176-178). Shape "panel": a
        UIPanelButtonTemplate in XML (BattlefieldFrame.xml:337), not pooled,
        not a layout frame; Blizzard re-sets only the plates
        (SecureUIPanelTemplates.lua:174-209). The join and cancel buttons
        are never enabled or disabled and keep the Layer 1 skin. ]]
    Skin.TaintSafeUIPanelButtonTemplate(_G.BattlefieldFrameGroupJoinButton, "panel")
    Skin.UIPanelCloseButton(_G.BattlefieldFrameCloseButton)
end
