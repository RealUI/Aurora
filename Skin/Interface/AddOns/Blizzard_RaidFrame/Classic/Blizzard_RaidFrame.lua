local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin

--[[ Classic-family RaidFrame (era/TBC/Mists share this Classic file).
    Evidence: wow-ui-source-*/Interface/AddOns/Blizzard_UIPanels_Game/
    Classic/RaidFrame.xml — RaidFrame itself is chrome-less (claimed as a
    FriendsFrame tab via ClaimRaidFrame); RaidParentFrame is a standalone
    ButtonFrameTemplate shell with two CharacterFrameTab buttons;
    RaidInfoFrame is a BackdropTemplate popup (BACKDROP_DARK_DIALOG_32_32)
    with a modern ScrollBox + WowClassicScrollBar list.
]]

function private.FrameXML.RaidFrame()
    -- Raid tab content (parented dynamically into FriendsFrame)
    Skin.UICheckButtonTemplate(_G.RaidFrameAllAssistCheckButton)
    Skin.UIPanelButtonTemplate(_G.RaidFrameConvertToRaidButton)
    Skin.UIPanelButtonTemplate(_G.RaidFrameRaidInfoButton)

    -- Raid Information popup
    local RaidInfoFrame = _G.RaidInfoFrame
    _G.RaidInfoDetailHeader:SetTexture("")
    _G.RaidInfoDetailCorner:SetTexture("")
    Skin.FrameTypeFrame(RaidInfoFrame)
    Skin.UIPanelCloseButton(_G.RaidInfoCloseButton)
    Skin.WowClassicScrollBar(RaidInfoFrame.ScrollBar)

    -- Standalone raid panel shell (Raid / Looking for Raid tabs)
    if _G.RaidParentFrame then
        Skin.ButtonFrameTemplate(_G.RaidParentFrame)
        Skin.CharacterFrameTabButtonTemplate(_G.RaidParentFrameTab1)
        Skin.CharacterFrameTabButtonTemplate(_G.RaidParentFrameTab2)
    end
end
