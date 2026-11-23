local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Base, Skin = Aurora.Base, Aurora.Skin
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

--[[ B261 Layer 2 (tier A, row A9), read from wow-ui-source-anniversary.
    QuestLog_OnEvent runs QuestLog_Update on QUEST_LOG_UPDATE, UPDATE_FACTION
    and UNIT_QUEST_LOG_CHANGED whether the log is open or not
    (Blizzard_UIPanels_Game/TBC/QuestLogFrame.lua:60-62). QuestLog_Update
    disables or enables the abandon button (:116, :122), runs
    FauxScrollFrame_Update on the quest list (:131), which disables or enables
    the list's two scroll buttons (Blizzard_SharedXML/SecureScrollTemplates.lua:193-202),
    and disables or enables the share button (:310-314). The same handler then
    runs QuestWatch_Update (:62), which ends in UIParent_ManageFramePositions
    (:770) and re-anchors protected bars. So nothing of Aurora's may be on
    these four buttons or run on their state. The exit, close and detail
    scroll buttons are tier C and stay on the Layer 1 skin. ]]

-- The quest list's scroll bar: Skin.FauxScrollFrameTemplate would put the
-- Layer 1 skin on its two buttons (and a `direction` key on each), so the
-- bar is drawn here instead. Shape "panel" for both buttons: they are
-- UIPanelScrollUpButtonTemplate and UIPanelScrollDownButtonTemplate
-- (Blizzard_SharedXML/SecureUIPanelTemplates.xml:76-90), 18x16, declared in
-- XML, not pooled and not a layout frame, and their state textures are set
-- in XML only; Blizzard only enables and disables them: at load
-- (UIPanelScrollFrame_OnLoad, SecureScrollTemplates.lua:36-37) and in
-- FauxScrollFrame_Update (above). The list's own OnVerticalScroll
-- (TBC/QuestLogFrame.xml:693-695) replaces the template's, so scrolling goes through
-- FauxScrollFrame_OnVerticalScroll (SecureScrollTemplates.lua:227-234) back
-- into QuestLog_Update. The arrow is on the panel. The thumb is a texture of the slider, not a button:
-- restyled in place (rule 3), at the 16x24 the Layer 1 skin gives it; no
-- Blizzard line sets its texture again.
--
-- The detail scroll bar (QuestLogDetailScrollFrame, a UIPanelScrollFrameTemplate,
-- TBC/QuestLogFrame.xml:698) is drawn by the same helper: owner decision AT-D17 (2026-11-23),
-- the one exception to AT-D1's tier C rule, so the two bars look alike and
-- the detail bar's buttons carry no `direction` key and no OnShow hook.
-- QuestLog_Update shows that scroll frame (:123) in the same tier A execution,
-- and its own template scripts enable and disable the two buttons and show
-- or hide the thumb (ScrollFrame_OnScrollRangeChanged and
-- ScrollFrame_OnVerticalScroll, SecureScrollTemplates.lua:64-110, :134-141),
-- on QuestLog_UpdateQuestDetails' UpdateScrollChildRect (:502) or a scroll.
-- Same slider template, so the same shapes and the same thumb restyle.
local function TaintSafeFauxScrollBar(ScrollFrame)
    local ScrollBar = ScrollFrame.ScrollBar
    local steppers = {
        {ScrollBar.ScrollUpButton, "arrowUp"},
        {ScrollBar.ScrollDownButton, "arrowDown"},
    }
    for _, stepper in ipairs(steppers) do
        local panel = Skin.TaintSafeFrameTypeButton(stepper[1], "panel")
        local arrow = panel:CreateTexture(nil, "ARTWORK")
        arrow:SetSize(14, 6)
        arrow:SetPoint("CENTER")
        Base.SetTexture(arrow, stepper[2])
    end

    local thumb = ScrollBar.ThumbTexture
    thumb:SetTexture(private.textures.plain)
    thumb:SetVertexColor(Color.button:GetRGB())
    thumb:SetSize(16, 24)
end

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

    TaintSafeFauxScrollBar(_G.QuestLogListScrollFrame)
    Util.HideFrameTextures(_G.QuestLogListScrollFrame)
    TaintSafeFauxScrollBar(_G.QuestLogDetailScrollFrame)
    Util.HideFrameTextures(_G.QuestLogDetailScrollFrame)

    for i = 1, 10 do
        local item = _G["QuestLogItem"..i]
        if item then
            Skin.LargeItemButtonTemplate(item)
        end
    end

    Skin.UIPanelCloseButton(_G.QuestLogFrameCloseButton)
    Skin.UIPanelButtonTemplate(_G.QuestFrameExitButton)

    -- Shape "panel": plain UIPanelButtonTemplate buttons declared in XML
    -- (TBC/QuestLogFrame.xml:543, :591), not pooled and not layout frames;
    -- all Blizzard re-sets on them is the file of their Left/Middle/Right
    -- plates (Blizzard_SharedXML/SecureUIPanelTemplates.lua:174-209), which
    -- the template keeps at alpha 0. No art that carries a meaning.
    Skin.TaintSafeUIPanelButtonTemplate(_G.QuestLogFrameAbandonButton, "panel")
    Skin.TaintSafeUIPanelButtonTemplate(_G.QuestFramePushQuestButton, "panel")
end
