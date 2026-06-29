local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin

--do --[[ FrameXML\GuildInviteFrame.lua ]]
--end

--do --[[ FrameXML\GuildInviteFrame.xml ]]
--end

function private.FrameXML.GuildInviteFrame()
    if not _G.GuildInviteFrame then return end

    Skin.TranslucentFrameTemplate(_G.GuildInviteFrame)

    if _G.GuildInviteFrameBackground then
        _G.GuildInviteFrameBackground:Hide()
    end

    if _G.GuildInviteFrameInviterName then
        _G.GuildInviteFrameInviterName:SetPoint("TOP", 0, -20)
    end
    if _G.GuildInviteFrameTabardBorder then
        _G.GuildInviteFrameTabardBorder:SetPoint("TOPLEFT", "$parentTabardBackground", 0, 0)
        _G.GuildInviteFrameTabardBorder:SetSize(62, 62)
    end

    if _G.GuildInviteFrameTabardRing then
        _G.GuildInviteFrameTabardRing:Hide()
    end

    if _G.GuildInviteFrameJoinButton then
        Skin.UIPanelButtonTemplate(_G.GuildInviteFrameJoinButton)
    end
    if _G.GuildInviteFrameDeclineButton then
        Skin.UIPanelButtonTemplate(_G.GuildInviteFrameDeclineButton)
    end
end
