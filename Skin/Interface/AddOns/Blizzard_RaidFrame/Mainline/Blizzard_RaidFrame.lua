local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin

--do --[[ FrameXML\RaidFrame.lua ]]
--end

do --[[ FrameXML\RaidFrame.xml ]]
    function Skin.RaidInfoHeaderTemplate(Frame)
        Frame:DisableDrawLayer("BACKGROUND")
    end
end

function private.FrameXML.RaidFrame()
    Skin.RoleCountTemplate(_G.RaidFrame.RoleCount)
    Skin.UICheckButtonTemplate(_G.RaidFrameAllAssistCheckButton)

    -- B261 Layer 2 (tier A, row A1). RaidFrame_Update shows, enables or
    -- disables and hides this button on every GROUP_ROSTER_UPDATE
    -- (Blizzard_RaidFrame/Mainline/RaidFrame.lua:104-112; Forever :106-114)
    -- and then moves the protected raid group buttons in the same execution
    -- (:121-123), so nothing of Aurora's may be on it or run on its state.
    -- Shape "panel": it is a plain UIPanelButtonTemplate declared in XML
    -- (RaidFrame.xml:205), not pooled and not a layout frame, and all
    -- Blizzard re-sets on it is the file of its Left/Middle/Right plates
    -- (Blizzard_SharedXML/SecureUIPanelTemplates.lua:44-79), which the
    -- template keeps at alpha 0. No art that carries a meaning.
    Skin.TaintSafeUIPanelButtonTemplate(_G.RaidFrameConvertToRaidButton, "panel")
    Skin.UIPanelButtonTemplate(_G.RaidFrameRaidInfoButton)


    -------------------
    -- RaidInfoFrame --
    -------------------
    local RaidInfoFrame = _G.RaidInfoFrame
    RaidInfoFrame:SetPoint("TOPLEFT", _G.RaidFrame, "TOPRIGHT", 1, -28)
    Skin.DialogBorderDarkTemplate(RaidInfoFrame.Border)
    Skin.DialogHeaderTemplate(RaidInfoFrame.Header)

    _G.RaidInfoDetailHeader:Hide()
    _G.RaidInfoDetailFooter:Hide()

    Skin.RaidInfoHeaderTemplate(_G.RaidInfoInstanceLabel)
    Skin.RaidInfoHeaderTemplate(_G.RaidInfoIDLabel)

    Skin.UIPanelCloseButton(_G.RaidInfoCloseButton)
    Skin.WowScrollBoxList(RaidInfoFrame.ScrollBox)
    Skin.MinimalScrollBar(RaidInfoFrame.ScrollBar)
    Skin.UIPanelButtonTemplate(_G.RaidInfoExtendButton)
    Skin.UIPanelButtonTemplate(_G.RaidInfoCancelButton)
end
