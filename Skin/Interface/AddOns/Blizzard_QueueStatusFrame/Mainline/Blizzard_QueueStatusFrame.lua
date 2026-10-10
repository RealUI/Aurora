local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Util = Aurora.Util
--[[ AddOns\Blizzard_QueueStatusFrame\Blizzard_QueueStatusFrame.lua ]]
-- The entry role icons are left as Blizzard's atlases (taint audit
-- 2026-10-06, B170 follow-up). Aurora's QueueStatusEntry_SetFullDisplay
-- post-hook gave each RoleIcon the "icon<ROLE>" texture snapshot, which
-- creates border, background and mask textures on the entry and writes
-- _auroraBorder/_auroraBG/_auroraMask onto the icon, inside the queue
-- frame's update that goes on to measure and lay out the same entry.

do --[[ AddOns\Blizzard_QueueStatusFrame\Blizzard_QueueStatusFrame.xml ]]
    function Skin.QueueStatusRoleCountTemplate(Frame)
        local debugName = Frame:GetDebugName()
        if debugName:find("HealersFound") then
            Frame.RoleIcon:SetAtlas("UI-LFG-RoleIcon-Healer-Micro")
        elseif debugName:find("Tank") then
            Frame.RoleIcon:SetAtlas("UI-LFG-RoleIcon-Tank-Micro")
        elseif debugName:find("Damager") then
            Frame.RoleIcon:SetAtlas("UI-LFG-RoleIcon-DPS-Micro")
        end
    end
    function Skin.QueueStatusEntryTemplate(Frame)
        -- NOTE: do NOT call SetPoint or SetHeight on any entry sub-frame here.
        -- Pool entry frames are used in protected call chains; any layout modification
        -- from addon code permanently taints the frame's geometry, causing GetHeight()
        -- on sibling FontStrings to return secret numbers
        -- (QueueStatusEntry_SetMinimalDisplay). SetAtlas on the existing icons only.
        Skin.QueueStatusRoleCountTemplate(Frame.HealersFound)
        Skin.QueueStatusRoleCountTemplate(Frame.TanksFound)
        Skin.QueueStatusRoleCountTemplate(Frame.DamagersFound)
    end
end

function private.FrameXML.QueueStatusFrame()
    local QueueStatusFrame = _G.QueueStatusFrame
    -- NOTE: QueueStatusFrame already inherits TooltipBackdropTemplate in XML and has its OnLoad
    -- handler applied by Blizzard. Calling Skin.TooltipBackdropTemplate() on the protected frame
    -- marks it as addon-modified, which taints callback execution contexts created from that frame.
    -- This causes AcceptBattlefieldPort() protected calls to fail with ADDON_ACTION_FORBIDDEN.
    -- The queue entry children will still be skinned via WrapPoolAcquire below.
    Util.WrapPoolAcquire(QueueStatusFrame.statusEntriesPool, "QueueStatusEntryTemplate")
end
