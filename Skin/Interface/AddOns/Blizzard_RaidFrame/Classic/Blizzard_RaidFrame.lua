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

    -- B261 Layer 2 (tier A, row A2). RaidFrameMixin:Update shows, enables or
    -- disables and hides this button on every GROUP_ROSTER_UPDATE
    -- (Blizzard_RaidFrame/Classic/RaidFrame.lua:234-243, the same lines in
    -- the Vanilla, TBC and Mists trees) and then moves the protected raid
    -- group buttons in the same execution (:248-250), so nothing of Aurora's
    -- may be on it or run on its state.
    -- Shape "panel": it is a plain UIPanelButtonTemplate declared in XML
    -- (Classic/RaidFrame.xml:185 on Vanilla and TBC, Wrath/RaidFrame.xml:199
    -- on Mists), not pooled and not a layout frame, and all Blizzard re-sets
    -- on it is the file of its Left/Middle/Right plates
    -- (Blizzard_SharedXML/SecureUIPanelTemplates.lua:174-209), which the
    -- template keeps at alpha 0. No art that carries a meaning.
    Skin.TaintSafeUIPanelButtonTemplate(_G.RaidFrameConvertToRaidButton, "panel")
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
