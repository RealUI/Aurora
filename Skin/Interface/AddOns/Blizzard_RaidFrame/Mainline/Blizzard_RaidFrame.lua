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
    Skin.UIPanelButtonTemplate(_G.RaidFrameConvertToRaidButton)
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
