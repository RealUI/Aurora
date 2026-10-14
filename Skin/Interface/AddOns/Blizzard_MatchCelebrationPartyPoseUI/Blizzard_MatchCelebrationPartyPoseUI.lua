local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin

--do --[[ AddOns\Blizzard_MatchCelebrationPartyPoseUI.lua ]]
--end

--do --[[ AddOns\Blizzard_MatchCelebrationPartyPoseUI.xml ]]
--end

function private.AddOns.Blizzard_MatchCelebrationPartyPoseUI()
    local MatchCelebrationPartyPoseFrame = _G.MatchCelebrationPartyPoseFrame

    -- No Skin.PartyPoseFrameTemplate here: it points Border.Center at the
    -- Background texture, and this frame hides Border.Center on every load
    -- (GetPartyPoseDataFromPartyPoseID), which would hide the background. The
    -- themed border, title and topper keep their texture-kit art.
    -- Score is a UI widget container and stays stock. Restyle only, no hooks:
    -- the Leave button's dismiss handler runs ConfirmOrLeaveLFGParty.
    Skin.PartyPoseModelFrameTemplate(MatchCelebrationPartyPoseFrame.ModelScene)

    local ButtonContainer = MatchCelebrationPartyPoseFrame.ButtonContainer
    Skin.UIPanelButtonNoTooltipResizeToFitTemplate(ButtonContainer.LeaveButton)
    Skin.UIPanelButtonNoTooltipResizeToFitTemplate(ButtonContainer.ExtraButton)
end
