local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Util = Aurora.Util

--[[ TBC (anniversary) TradeSkillFrame — same 384x512 skeleton as era but
    the era filter dropdowns are replaced by a search box + "have materials"
    checkbox, and the scrolls carry ClassTrainer-style track art.
    Evidence: wow-ui-source-anniversary/Interface/AddOns/
    Blizzard_TradeSkillUI/TBC/Blizzard_TradeSkillUI.xml.
]]

function private.AddOns.Blizzard_TradeSkillUI()
    local TradeSkillFrame = _G.TradeSkillFrame

    Util.HideFrameTextures(TradeSkillFrame)
    if _G.TradeSkillFramePortrait then
        _G.TradeSkillFramePortrait:SetAlpha(0)
    end

    Skin.FrameTypeFrame(TradeSkillFrame)
    TradeSkillFrame:SetBackdropOption("offsets", {
        left = 10,
        right = 30,
        top = 0,
        bottom = 75,
    })

    Skin.UIPanelCloseButton(_G.TradeSkillFrameCloseButton)

    -- Skill rank status bar (border is a Button child here, like SkillFrame)
    Skin.FrameTypeStatusBar(_G.TradeSkillRankFrame)
    if _G.TradeSkillRankFrameBackground then
        _G.TradeSkillRankFrameBackground:Hide()
    end
    if _G.TradeSkillRankFrameBorder then
        local normal = _G.TradeSkillRankFrameBorderNormal
        if normal then
            normal:SetAlpha(0)
        else
            _G.TradeSkillRankFrameBorder:SetAlpha(0)
        end
    end

    -- Search box + "have materials" filter (replace era's dropdowns)
    local searchBox = _G.TradeSearchInputBox
    if searchBox then
        Util.HideFrameTextures(searchBox)
        Skin.FrameTypeEditBox(searchBox)
    end
    if _G.TradeSkillFrameAvailableFilterCheckButton then
        Skin.UICheckButtonTemplate(_G.TradeSkillFrameAvailableFilterCheckButton)
    end

    -- "Expand all" tab art
    for _, suffix in ipairs({"ExpandTabLeft", "ExpandTabMiddle", "ExpandTabRight"}) do
        local texture = _G["TradeSkill"..suffix]
        if texture then
            texture:SetTexture("")
        end
    end
    if _G.TradeSkillExpandButtonFrame then
        Util.HideFrameTextures(_G.TradeSkillExpandButtonFrame)
    end

    if _G.TradeSkillHighlight then
        _G.TradeSkillHighlight:SetBlendMode("BLEND")
        Util.SetHighlightColor(_G.TradeSkillHighlight, 0.2)
    end

    -- ClassTrainer-style scrolls: list track art is unnamed, detail's is named
    Skin.FauxScrollFrameTemplate(_G.TradeSkillListScrollFrame)
    Util.HideFrameTextures(_G.TradeSkillListScrollFrame)
    Skin.UIPanelScrollFrameTemplate(_G.TradeSkillDetailScrollFrame)
    for _, name in ipairs({"TradeSkillDetailScrollFrameTop", "TradeSkillDetailScrollFrameBottom"}) do
        local texture = _G[name]
        if texture then
            texture:SetAlpha(0)
        end
    end

    -- Recipe icon set at runtime
    local skillIcon = _G.TradeSkillSkillIcon
    if skillIcon then
        skillIcon:SetNormalTexture("")
        Aurora.Base.CropIcon(skillIcon:GetNormalTexture())
    end

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
