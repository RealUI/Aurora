local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

function private.AddOns.Blizzard_CraftUI()
    local CraftFrame = _G.CraftFrame
    if not CraftFrame then return end

    ---------------------
    -- Main Frame      --
    ---------------------
    Base.SetBackdrop(CraftFrame, Color.frame, Util.GetFrameAlpha())

    -- Hide Blizzard portrait/border textures
    if _G.CraftFramePortrait then
        _G.CraftFramePortrait:SetAlpha(0)
    end
    local borderTextures = {
        "CraftFrameTopLeft",
        "CraftFrameTopRight",
        "CraftFrameBottomLeft",
        "CraftFrameBottomRight",
        "CraftFrameTop",
        "CraftFrameBottom",
        "CraftFrameLeft",
        "CraftFrameRight",
        "CraftFrameTopBorder",
        "CraftFrameTopRightCorner",
        "CraftFrameRightBorder",
        "CraftFrameBotRightCorner",
        "CraftFrameBottomBorder",
        "CraftFrameBotLeftCorner",
        "CraftFrameLeftBorder",
        "CraftFrameTopLeftCorner",
        "CraftFrameInsetBg",
    }
    for _, texName in _G.ipairs(borderTextures) do
        local tex = _G[texName]
        if tex then
            tex:Hide()
        end
    end

    -- Hide horizontal bar texture
    if _G.CraftHorizontalBarLeft then
        _G.CraftHorizontalBarLeft:Hide()
    end

    ---------------------
    -- Close Button    --
    ---------------------
    if _G.CraftFrameCloseButton then
        Skin.UIPanelCloseButton(_G.CraftFrameCloseButton)
    end

    ---------------------
    -- Craft List      --
    ---------------------
    -- Skin the scroll frame for the craft list
    local listScrollFrame = _G.CraftListScrollFrame
    if listScrollFrame then
        if Skin.FauxScrollFrameTemplate then
            Skin.FauxScrollFrameTemplate(listScrollFrame)
        elseif listScrollFrame.ScrollBar then
            Skin.MinimalScrollBar(listScrollFrame.ScrollBar)
        elseif Skin.UIPanelScrollFrameTemplate then
            Skin.UIPanelScrollFrameTemplate(listScrollFrame)
        end
    end

    -- Skin craft list buttons (expand/collapse headers)
    local NUM_CRAFT_ITEMS = _G.CRAFTS_DISPLAYED or 8
    for i = 1, NUM_CRAFT_ITEMS do
        local craftButton = _G["Craft" .. i]
        if craftButton then
            local highlight = craftButton:GetHighlightTexture()
            if highlight then
                Util.SetHighlightColor(highlight, 0.5)
            end
        end
    end

    ---------------------
    -- Detail Panel    --
    ---------------------
    -- Skin the detail scroll frame
    local detailScrollFrame = _G.CraftDetailScrollFrame
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
        "CraftDetailScrollFrameTop",
        "CraftDetailScrollFrameBottom",
    }
    for _, texName in _G.ipairs(detailBgTextures) do
        local tex = _G[texName]
        if tex then
            tex:Hide()
        end
    end

    -- Skin the craft icon in the detail panel
    local craftIcon = _G.CraftIcon
    if craftIcon then
        local iconTexture = craftIcon:GetNormalTexture()
        if iconTexture then
            Base.CropIcon(iconTexture, craftIcon)
        end
    end

    ---------------------
    -- Reagents        --
    ---------------------
    for i = 1, 4 do
        local reagent = _G["CraftReagent" .. i]
        if reagent then
            local reagentName = "CraftReagent" .. i
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
    -- Create Button   --
    ---------------------
    if _G.CraftCreateButton then
        Skin.UIPanelButtonTemplate(_G.CraftCreateButton)
    end
    if _G.CraftCancelButton then
        Skin.UIPanelButtonTemplate(_G.CraftCancelButton)
    end

    ---------------------
    -- Expand/Collapse --
    ---------------------
    if _G.CraftExpandButtonFrame then
        local collapseAll = _G.CraftCollapseAllButton
        if collapseAll then
            Skin.FrameTypeButton(collapseAll)
        end
    end

    ---------------------
    -- Rank Frame      --
    ---------------------
    local rankFrame = _G.CraftRankFrame
    if rankFrame then
        local rankBorder = _G.CraftRankFrameBorder
        if rankBorder then
            rankBorder:Hide()
        end
        local rankBackground = _G.CraftRankFrameBackground
        if rankBackground then
            rankBackground:Hide()
        end
    end
end
