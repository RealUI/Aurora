local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

do --[[ FrameXML\WarCampaignTemplates.xml ]]
    -- CampaignTooltipTemplate: skinned through the taint-safe tooltip path in
    -- QuestMapFrame.lua (Skin.SharedTooltipTemplate, solid background). The old
    -- FrameTypeFrame skin here was never called and is removed.
    -- CampaignHeaderDisplayTemplate, CampaignHeaderTemplate: no frame-time
    -- skin. The quest log's campaign headers are pooled and restyled in place
    -- from Hook.QuestLogQuests_Update, the campaign overview's header from its
    -- SetCampaign hook, both through Skin.CampaignHeaderInPlace (QuestMapFrame.lua).
    -- The old clip frame, colour layer and emblem overlay (_clipFrame,
    -- _auroraBG, _auroraOverlay) are gone: they were created on Acquire, inside
    -- the quest log build (B170 follow-up, 2026-10-06).
    -- B38: the collapse button keeps its stock plus/minus icon.
    -- CampaignHeaderMinimalTemplate: restyled in place from
    -- Hook.QuestLogQuests_Update (QuestMapFrame.lua).
end

function private.FrameXML.WarCampaignTemplates()
end
