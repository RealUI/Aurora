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
    -- RaidFrame.RoleCount is a modern (Classic Anniversary+) addition
    if _G.RaidFrame and _G.RaidFrame.RoleCount then
        Skin.RoleCountTemplate(_G.RaidFrame.RoleCount)
    end
    if _G.RaidFrameAllAssistCheckButton then
        Skin.UICheckButtonTemplate(_G.RaidFrameAllAssistCheckButton)
    end
    if _G.RaidFrameConvertToRaidButton then
        Skin.UIPanelButtonTemplate(_G.RaidFrameConvertToRaidButton)
    end
    if _G.RaidFrameRaidInfoButton then
        Skin.UIPanelButtonTemplate(_G.RaidFrameRaidInfoButton)
    end


    -------------------
    -- RaidInfoFrame --
    -------------------
    local RaidInfoFrame = _G.RaidInfoFrame
    if not RaidInfoFrame then return end

    RaidInfoFrame:SetPoint("TOPLEFT", _G.RaidFrame, "TOPRIGHT", 1, -28)
    if RaidInfoFrame.Border then
        Skin.DialogBorderDarkTemplate(RaidInfoFrame.Border)
    end
    if RaidInfoFrame.Header then
        Skin.DialogHeaderTemplate(RaidInfoFrame.Header)
    end

    if _G.RaidInfoDetailHeader then _G.RaidInfoDetailHeader:Hide() end
    if _G.RaidInfoDetailFooter then _G.RaidInfoDetailFooter:Hide() end

    if _G.RaidInfoInstanceLabel then
        Skin.RaidInfoHeaderTemplate(_G.RaidInfoInstanceLabel)
    end
    if _G.RaidInfoIDLabel then
        Skin.RaidInfoHeaderTemplate(_G.RaidInfoIDLabel)
    end

    if _G.RaidInfoCloseButton then
        Skin.UIPanelCloseButton(_G.RaidInfoCloseButton)
    end
    if RaidInfoFrame.ScrollBox then
        Skin.WowScrollBoxList(RaidInfoFrame.ScrollBox)
    end
    if RaidInfoFrame.ScrollBar then
        Skin.MinimalScrollBar(RaidInfoFrame.ScrollBar)
    end
    if _G.RaidInfoExtendButton then
        Skin.UIPanelButtonTemplate(_G.RaidInfoExtendButton)
    end
    if _G.RaidInfoCancelButton then
        Skin.UIPanelButtonTemplate(_G.RaidInfoCancelButton)
    end
end
