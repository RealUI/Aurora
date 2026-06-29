local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

function private.AddOns.Blizzard_TradeSkillUI()
    local TradeSkillFrame = _G.TradeSkillFrame
    if not TradeSkillFrame then return end

    ---------------------
    -- Main Frame      --
    ---------------------
    Base.SetBackdrop(TradeSkillFrame, Color.frame, Util.GetFrameAlpha())

    -- Hide Blizzard portrait/border textures
    if _G.TradeSkillFramePortrait then
        _G.TradeSkillFramePortrait:SetAlpha(0)
    end
    local borderTextures = {
        "TradeSkillFrameTopLeft",
        "TradeSkillFrameTopRight",
        "TradeSkillFrameBottomLeft",
        "TradeSkillFrameBottomRight",
        "TradeSkillFrameTop",
        "TradeSkillFrameBottom",
        "TradeSkillFrameLeft",
        "TradeSkillFrameRight",
        "TradeSkillFrameTopBorder",
        "TradeSkillFrameTopRightCorner",
        "TradeSkillFrameRightBorder",
        "TradeSkillFrameBotRightCorner",
        "TradeSkillFrameBottomBorder",
        "TradeSkillFrameBotLeftCorner",
        "TradeSkillFrameLeftBorder",
        "TradeSkillFrameTopLeftCorner",
        "TradeSkillFrameInsetBg",
    }
    for _, texName in _G.ipairs(borderTextures) do
        local tex = _G[texName]
        if tex then
            tex:Hide()
        end
    end

    -- Hide horizontal bar texture
    if _G.TradeSkillHorizontalBarLeft then
        _G.TradeSkillHorizontalBarLeft:Hide()
    end

    ---------------------
    -- Close Button    --
    ---------------------
    if _G.TradeSkillFrameCloseButton then
        Skin.UIPanelCloseButton(_G.TradeSkillFrameCloseButton)
    end

    ---------------------
    -- Recipe List     --
    ---------------------
    -- Skin the scroll frame for the recipe list
    local listScrollFrame = _G.TradeSkillListScrollFrame
    if listScrollFrame then
        if Skin.FauxScrollFrameTemplate then
            Skin.FauxScrollFrameTemplate(listScrollFrame)
        elseif listScrollFrame.ScrollBar then
            Skin.MinimalScrollBar(listScrollFrame.ScrollBar)
        elseif Skin.UIPanelScrollFrameTemplate then
            Skin.UIPanelScrollFrameTemplate(listScrollFrame)
        end
    end

    -- Skin recipe list buttons (expand/collapse headers)
    local NUM_TRADE_SKILL_ITEMS = _G.TRADE_SKILLS_DISPLAYED or 8
    for i = 1, NUM_TRADE_SKILL_ITEMS do
        local skillButton = _G["TradeSkillSkill" .. i]
        if skillButton then
            local highlight = skillButton:GetHighlightTexture()
            if highlight then
                Util.SetHighlightColor(highlight, 0.5)
            end
        end
    end

    ---------------------
    -- Detail Panel    --
    ---------------------
    -- Skin the detail scroll frame
    local detailScrollFrame = _G.TradeSkillDetailScrollFrame
    if detailScrollFrame then
        if Skin.FauxScrollFrameTemplate then
            Skin.FauxScrollFrameTemplate(detailScrollFrame)
        elseif detailScrollFrame.ScrollBar then
            Skin.MinimalScrollBar(detailScrollFrame.ScrollBar)
        elseif Skin.UIPanelScrollFrameTemplate then
            Skin.UIPanelScrollFrameTemplate(detailScrollFrame)
        end
    end

    -- Hide detail frame background textures
    local detailBgTextures = {
        "TradeSkillDetailScrollFrameTop",
        "TradeSkillDetailScrollFrameBottom",
    }
    for _, texName in _G.ipairs(detailBgTextures) do
        local tex = _G[texName]
        if tex then
            tex:Hide()
        end
    end

    -- Skin the skill icon in the detail panel
    local skillIcon = _G.TradeSkillSkillIcon
    if skillIcon then
        local iconTexture = skillIcon:GetNormalTexture()
        if iconTexture then
            Base.CropIcon(iconTexture, skillIcon)
        end
    end

    ---------------------
    -- Reagents        --
    ---------------------
    for i = 1, 8 do
        local reagent = _G["TradeSkillReagent" .. i]
        if reagent then
            local reagentName = "TradeSkillReagent" .. i
            -- Skin the reagent icon
            local nameIcon = _G[reagentName .. "IconTexture"]
            local iconFrame = _G[reagentName .. "Icon"] or reagent
            if nameIcon then
                Base.CropIcon(nameIcon, iconFrame)
            end

            -- Hide the reagent name frame border
            local nameBorder = _G[reagentName .. "NameFrame"]
            if nameBorder then
                nameBorder:Hide()
            end
        end
    end

    ---------------------
    -- Create Buttons  --
    ---------------------
    if _G.TradeSkillCreateButton then
        Skin.UIPanelButtonTemplate(_G.TradeSkillCreateButton)
    end
    if _G.TradeSkillCreateAllButton then
        Skin.UIPanelButtonTemplate(_G.TradeSkillCreateAllButton)
    end
    if _G.TradeSkillCancelButton then
        Skin.UIPanelButtonTemplate(_G.TradeSkillCancelButton)
    end

    ---------------------
    -- Input Box       --
    ---------------------
    if _G.TradeSkillInputBox then
        Skin.InputBoxTemplate(_G.TradeSkillInputBox)
    end

    ---------------------
    -- Decrease/Increase Buttons --
    ---------------------
    if _G.TradeSkillDecrementButton then
        Skin.FrameTypeButton(_G.TradeSkillDecrementButton)
    end
    if _G.TradeSkillIncrementButton then
        Skin.FrameTypeButton(_G.TradeSkillIncrementButton)
    end

    ---------------------
    -- Filter Dropdowns --
    ---------------------
    if _G.TradeSkillInvSlotDropDown then
        if Skin.DropdownButton then
            Skin.DropdownButton(_G.TradeSkillInvSlotDropDown)
        end
    end
    if _G.TradeSkillSubClassDropDown then
        if Skin.DropdownButton then
            Skin.DropdownButton(_G.TradeSkillSubClassDropDown)
        end
    end

    ---------------------
    -- Expand/Collapse --
    ---------------------
    if _G.TradeSkillExpandButtonFrame then
        local collapseAll = _G.TradeSkillCollapseAllButton
        if collapseAll then
            Skin.FrameTypeButton(collapseAll)
        end
    end

    ---------------------
    -- Rank Frame      --
    ---------------------
    local rankFrame = _G.TradeSkillRankFrame
    if rankFrame then
        local rankBorder = _G.TradeSkillRankFrameBorder
        if rankBorder then
            rankBorder:Hide()
        end
        local rankBackground = _G.TradeSkillRankFrameBackground
        if rankBackground then
            rankBackground:Hide()
        end
    end
end
