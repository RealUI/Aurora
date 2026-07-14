local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

--[[ TBC (anniversary) quest log (384x512 book panel — same structure as
    era plus a wrapped QuestLogCount frame, DailyQuestCountButton and
    honor/title reward rows).
    Evidence: wow-ui-source-anniversary/Interface/AddOns/Blizzard_UIPanels_Game/
    TBC/QuestLogFrame.xml — book icon + 4 sheets + a Common-Input quest
    counter box on the root; expand tab; 6 static title rows (runtime
    plus/minus icons — left stock); Faux list + detail scrolls; 10
    QuestLogRewardItemTemplate buttons (= LargeItemButtonTemplate);
    MoneyFrameTemplate coin rows (sheet slices — left stock). The
    QuestWatchFrame tracker is out of scope (RealUI ships its own).
]]

function private.FrameXML.QuestLogFrame()
    local QuestLogFrame = _G.QuestLogFrame

    Util.HideFrameTextures(QuestLogFrame, true)
    Skin.FrameTypeFrame(QuestLogFrame)
    QuestLogFrame:SetBackdropOption("offsets", {
        left = 10,
        right = 30,
        top = 0,
        bottom = 75,
    })

    Util.HideFrameTextures(_G.QuestLogExpandButtonFrame)
    Util.HideFrameTextures(_G.EmptyQuestLogFrame, true)

    -- TBC wraps the quest counter's Common-Input border art in a frame
    if _G.QuestLogCount then
        Util.HideFrameTextures(_G.QuestLogCount)
    end

    -- Selected-quest highlight
    if _G.QuestLogSkillHighlight then
        _G.QuestLogSkillHighlight:SetColorTexture(Color.highlight.r, Color.highlight.g, Color.highlight.b, 0.2)
    end

    Skin.FauxScrollFrameTemplate(_G.QuestLogListScrollFrame)
    Util.HideFrameTextures(_G.QuestLogListScrollFrame)
    Skin.UIPanelScrollFrameTemplate(_G.QuestLogDetailScrollFrame)
    Util.HideFrameTextures(_G.QuestLogDetailScrollFrame)

    for i = 1, 10 do
        local item = _G["QuestLogItem"..i]
        if item then
            Skin.LargeItemButtonTemplate(item)
        end
    end

    Skin.UIPanelCloseButton(_G.QuestLogFrameCloseButton)
    for _, name in ipairs({"QuestLogFrameAbandonButton", "QuestFrameExitButton", "QuestFramePushQuestButton"}) do
        local button = _G[name]
        if button then
            Skin.UIPanelButtonTemplate(button)
        end
    end
end
