local _, private = ...
if private.shouldSkip() then return end

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Util = Aurora.Util

--[[ Classic Era TradeSkillFrame (professions).
    Evidence: wow-ui-source-era/Interface/AddOns/Blizzard_TradeSkillUI/
    Vanilla/Blizzard_TradeSkillUI.xml (root L42: plain 384x512 sheet,
    ClassTrainer-style list). TBC uses its own TBC\ file (tbc-v2 spec).
    Reagents inherit QuestItemTemplate (= LargeItemButtonTemplate).
    Skill rows are text buttons colored by difficulty — kept as-is.
]]

function private.AddOns.Blizzard_TradeSkillUI()
    local TradeSkillFrame = _G.TradeSkillFrame

    Util.HideFrameTextures(TradeSkillFrame)
    _G.TradeSkillFramePortrait:SetAlpha(0)

    Skin.FrameTypeFrame(TradeSkillFrame)
    TradeSkillFrame:SetBackdropOption("offsets", {
        left = 10,
        right = 30,
        top = 0,
        bottom = 75,
    })

    Skin.UIPanelCloseButton(_G.TradeSkillFrameCloseButton)

    -- Skill rank status bar
    Skin.FrameTypeStatusBar(_G.TradeSkillRankFrame)
    if _G.TradeSkillRankFrameBackground then
        _G.TradeSkillRankFrameBackground:Hide()
    end
    if _G.TradeSkillRankFrameBorder then
        _G.TradeSkillRankFrameBorder:SetAlpha(0)
    end

    -- "Expand all" tab art
    for _, suffix in _G.ipairs({"ExpandTabLeft", "ExpandTabMiddle", "ExpandTabRight"}) do
        local texture = _G["TradeSkill"..suffix]
        if texture then
            texture:SetTexture("")
        end
    end

    if _G.TradeSkillHighlight then
        _G.TradeSkillHighlight:SetBlendMode("BLEND")
        Util.SetHighlightColor(_G.TradeSkillHighlight, 0.2)
    end

    -- Filter dropdowns are modern WowStyle1DropdownTemplate buttons
    Skin.DropdownButton(_G.TradeSkillInvSlotDropdown)
    Skin.DropdownButton(_G.TradeSkillSubClassDropdown)

    Skin.UIPanelScrollFrameTemplate(_G.TradeSkillListScrollFrame)
    Skin.UIPanelScrollFrameTemplate(_G.TradeSkillDetailScrollFrame)

    for i = 1, 8 do
        local reagent = _G["TradeSkillReagent"..i]
        if reagent then
            Skin.LargeItemButtonTemplate(reagent)
        end
    end

    Skin.UIPanelButtonTemplate(_G.TradeSkillCreateButton)
    Skin.UIPanelButtonTemplate(_G.TradeSkillCreateAllButton)
    Skin.UIPanelButtonTemplate(_G.TradeSkillCancelButton)

    Skin.NavButtonPrevious(_G.TradeSkillDecrementButton)
    Skin.NavButtonNext(_G.TradeSkillIncrementButton)
    Skin.FrameTypeEditBox(_G.TradeSkillInputBox)
end
