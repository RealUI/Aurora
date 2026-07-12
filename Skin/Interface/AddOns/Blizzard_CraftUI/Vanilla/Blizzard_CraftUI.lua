local _, private = ...
if private.shouldSkip() then return end

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Util = Aurora.Util

--[[ Classic Era CraftFrame (enchanting, beast training).
    Evidence: wow-ui-source-era/Interface/AddOns/Blizzard_CraftUI/Vanilla/
    Blizzard_CraftUI.xml (root L60) — structural twin of the era
    TradeSkillFrame (ClassTrainer-style list, QuestItemTemplate reagents).
]]

function private.AddOns.Blizzard_CraftUI()
    local CraftFrame = _G.CraftFrame

    Util.HideFrameTextures(CraftFrame)
    _G.CraftFramePortrait:SetAlpha(0)

    Skin.FrameTypeFrame(CraftFrame)
    CraftFrame:SetBackdropOption("offsets", {
        left = 10,
        right = 30,
        top = 0,
        bottom = 75,
    })

    Skin.UIPanelCloseButton(_G.CraftFrameCloseButton)

    Skin.FrameTypeStatusBar(_G.CraftRankFrame)
    if _G.CraftRankFrameBackground then
        _G.CraftRankFrameBackground:Hide()
    end
    if _G.CraftRankFrameBorder then
        _G.CraftRankFrameBorder:SetAlpha(0)
    end

    for _, suffix in _G.ipairs({"ExpandTabLeft", "ExpandTabMiddle", "ExpandTabRight"}) do
        local texture = _G["Craft"..suffix]
        if texture then
            texture:SetTexture("")
        end
    end

    if _G.CraftHighlight then
        _G.CraftHighlight:SetBlendMode("BLEND")
        Util.SetHighlightColor(_G.CraftHighlight, 0.2)
    end

    Skin.UIPanelScrollFrameTemplate(_G.CraftListScrollFrame)
    Skin.UIPanelScrollFrameTemplate(_G.CraftDetailScrollFrame)

    for i = 1, 8 do
        local reagent = _G["CraftReagent"..i]
        if reagent then
            Skin.LargeItemButtonTemplate(reagent)
        end
    end

    Skin.UIPanelButtonTemplate(_G.CraftCreateButton)
    Skin.UIPanelButtonTemplate(_G.CraftCancelButton)
end
