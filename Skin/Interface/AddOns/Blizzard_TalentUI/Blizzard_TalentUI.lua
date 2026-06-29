local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

function private.AddOns.Blizzard_TalentUI()
    local PlayerTalentFrame = _G.PlayerTalentFrame
    if not PlayerTalentFrame then return end

    -- Apply Aurora backdrop to the main talent frame
    Base.SetBackdrop(PlayerTalentFrame, Color.frame, Util.GetFrameAlpha())

    -- Hide Blizzard border/portrait textures
    if _G.PlayerTalentFramePortrait then
        _G.PlayerTalentFramePortrait:SetAlpha(0)
    end
    local borderTextures = {
        "PlayerTalentFrameTopLeft",
        "PlayerTalentFrameTopRight",
        "PlayerTalentFrameBottomLeft",
        "PlayerTalentFrameBottomRight",
    }
    for _, texName in _G.ipairs(borderTextures) do
        local tex = _G[texName]
        if tex then
            tex:Hide()
        end
    end

    -- Hide scroll frame background/border textures
    local scrollBgTextures = {
        "PlayerTalentFrameScrollFrameBackgroundTop",
        "PlayerTalentFrameScrollFrameBackgroundBottom",
    }
    for _, texName in _G.ipairs(scrollBgTextures) do
        local tex = _G[texName]
        if tex then
            tex:Hide()
        end
    end

    -- Hide talent tree background textures
    local treeBgTextures = {
        "PlayerTalentFrameBackgroundTopLeft",
        "PlayerTalentFrameBackgroundTopRight",
        "PlayerTalentFrameBackgroundBottomLeft",
        "PlayerTalentFrameBackgroundBottomRight",
    }
    for _, texName in _G.ipairs(treeBgTextures) do
        local tex = _G[texName]
        if tex then
            tex:SetAlpha(0)
        end
    end

    -- Skin close button
    if _G.PlayerTalentFrameCloseButton then
        Skin.UIPanelCloseButton(_G.PlayerTalentFrameCloseButton)
    end

    -- Skin cancel button
    if _G.PlayerTalentFrameCancelButton then
        Skin.UIPanelButtonTemplate(_G.PlayerTalentFrameCancelButton)
    end

    -- Skin activate button
    if _G.PlayerTalentFrameActivateButton then
        Skin.UIPanelButtonTemplate(_G.PlayerTalentFrameActivateButton)
    end

    -- Skin learn/reset buttons in the preview bar
    if _G.PlayerTalentFrameLearnButton then
        Skin.UIPanelButtonTemplate(_G.PlayerTalentFrameLearnButton)
    end
    if _G.PlayerTalentFrameResetButton then
        Skin.UIPanelButtonTemplate(_G.PlayerTalentFrameResetButton)
    end

    -- Skin talent tab buttons (spec tree tabs at bottom: Tab1-Tab4)
    for i = 1, 4 do
        local tab = _G["PlayerTalentFrameTab" .. i]
        if tab then
            Skin.PanelTabButtonTemplate(tab)
        end
    end

    -- Skin spec tabs on the right side (PlayerSpecTab1, PlayerSpecTab2, PlayerSpecTab3)
    for i = 1, 3 do
        local specTab = _G["PlayerSpecTab" .. i]
        if specTab then
            -- Hide the background texture
            local bg = _G["PlayerSpecTab" .. i .. "Background"]
            if bg then
                bg:Hide()
            end
            -- Crop the icon
            local icon = specTab:GetNormalTexture()
            if icon then
                Base.CropIcon(icon, specTab)
            end
            -- Hide the checked/highlight textures' default art
            local checked = specTab:GetCheckedTexture()
            if checked then
                checked:SetColorTexture(Color.highlight.r, Color.highlight.g, Color.highlight.b, 0.25)
            end
        end
    end

    -- Skin talent point buttons (up to 40 talent buttons per tree)
    for i = 1, 40 do
        local talent = _G["PlayerTalentFrameTalent" .. i]
        if talent then
            -- Hide the slot background texture
            local slot = _G["PlayerTalentFrameTalent" .. i .. "Slot"]
            if slot then
                slot:Hide()
            end
            -- Crop the icon texture
            local icon = _G["PlayerTalentFrameTalent" .. i .. "IconTexture"]
            if icon then
                Base.CropIcon(icon, talent)
            end
            -- Hide the default border (the ItemButton border)
            if talent.IconBorder then
                talent.IconBorder:SetAlpha(0)
            end
        end
    end

    -- Skin talent points counter area
    -- Hide the points bar border textures
    local pointsBar = _G.PlayerTalentFramePointsBar
    if pointsBar then
        local barTextures = {
            "PlayerTalentFramePointsBarBackground",
            "PlayerTalentFramePointsBarBorderLeft",
            "PlayerTalentFramePointsBarBorderRight",
            "PlayerTalentFramePointsBarBorderMiddle",
        }
        for _, texName in _G.ipairs(barTextures) do
            local tex = _G[texName]
            if tex then
                tex:Hide()
            end
        end
    end

    -- Hide status frame border textures
    local statusTextures = {
        "PlayerTalentFramePointsLeft",
        "PlayerTalentFramePointsMiddle",
        "PlayerTalentFramePointsRight",
    }
    for _, texName in _G.ipairs(statusTextures) do
        local tex = _G[texName]
        if tex then
            tex:Hide()
        end
    end

    -- Skin scroll frame
    local scrollFrame = _G.PlayerTalentFrameScrollFrame
    if scrollFrame then
        Skin.UIPanelScrollFrameTemplate(scrollFrame)
    end
end
