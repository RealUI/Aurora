local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals next tinsert

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Util = Aurora.Util
do --[[ AddOns\Blizzard_QueueStatusFrame\Blizzard_QueueStatusFrame.lua ]]
    function Hook.QueueStatusEntry_SetFullDisplay(entry, _, _, _, isTank, isHealer, isDPS)
        local nextRoleIcon = 1
        if isDPS then
            local icon = entry["RoleIcon"..nextRoleIcon]
            Base.SetTexture(icon, "iconDAMAGER")
            icon._auroraBG:Show()
            nextRoleIcon = nextRoleIcon + 1
        end
        if isHealer then
            local icon = entry["RoleIcon"..nextRoleIcon]
            Base.SetTexture(icon, "iconHEALER")
            icon._auroraBG:Show()
            nextRoleIcon = nextRoleIcon + 1
        end
        if isTank then
            local icon = entry["RoleIcon"..nextRoleIcon]
            Base.SetTexture(icon, "iconTANK")
            icon._auroraBG:Show()
            nextRoleIcon = nextRoleIcon + 1
        end

        for i = nextRoleIcon, _G.LFD_NUM_ROLES do
            local icon = entry["RoleIcon"..i]
            if icon._auroraBG then
                icon._auroraBG:Hide()
            end
        end
        -- NOTE: do NOT call SetPoint on HealersFound or any entry sub-frame here.
        -- SetPoint on pool entry children taints their layout metrics permanently,
        -- causing entry.Status:GetHeight() to return a secret number and crashing
        -- Blizzard's arithmetic in QueueStatusEntry_SetMinimalDisplay:1119.
    end
end

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
        -- on sibling FontStrings to return secret numbers (see above).
        Skin.QueueStatusRoleCountTemplate(Frame.HealersFound)
        Skin.QueueStatusRoleCountTemplate(Frame.TanksFound)
        Skin.QueueStatusRoleCountTemplate(Frame.DamagersFound)
    end
end

function private.FrameXML.QueueStatusFrame()
     _G.hooksecurefunc("QueueStatusEntry_SetFullDisplay", Hook.QueueStatusEntry_SetFullDisplay)

    local QueueStatusFrame = _G.QueueStatusFrame
    -- NOTE: QueueStatusFrame already inherits TooltipBackdropTemplate in XML and has its OnLoad
    -- handler applied by Blizzard. Calling Skin.TooltipBackdropTemplate() on the protected frame
    -- marks it as addon-modified, which taints callback execution contexts created from that frame.
    -- This causes AcceptBattlefieldPort() protected calls to fail with ADDON_ACTION_FORBIDDEN.
    -- The queue entry children will still be skinned via WrapPoolAcquire below.
    Util.WrapPoolAcquire(QueueStatusFrame.statusEntriesPool, "QueueStatusEntryTemplate")
end
