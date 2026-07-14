local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Util = Aurora.Util

--[[ TBC (anniversary) CraftFrame (enchanting, beast training) — era twin
    plus a "have materials" filter checkbox and ClassTrainer-style scroll
    track art. Evidence: wow-ui-source-anniversary/Interface/AddOns/
    Blizzard_CraftUI/TBC/Blizzard_CraftUI.xml.
]]

function private.AddOns.Blizzard_CraftUI()
    local CraftFrame = _G.CraftFrame

    Util.HideFrameTextures(CraftFrame)
    if _G.CraftFramePortrait then
        _G.CraftFramePortrait:SetAlpha(0)
    end

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
        local normal = _G.CraftRankFrameBorderNormal
        if normal then
            normal:SetAlpha(0)
        else
            _G.CraftRankFrameBorder:SetAlpha(0)
        end
    end

    if _G.CraftFrameAvailableFilterCheckButton then
        Skin.UICheckButtonTemplate(_G.CraftFrameAvailableFilterCheckButton)
    end

    for _, suffix in ipairs({"ExpandTabLeft", "ExpandTabMiddle", "ExpandTabRight"}) do
        local texture = _G["Craft"..suffix]
        if texture then
            texture:SetTexture("")
        end
    end
    if _G.CraftExpandButtonFrame then
        Util.HideFrameTextures(_G.CraftExpandButtonFrame)
    end

    if _G.CraftHighlight then
        _G.CraftHighlight:SetBlendMode("BLEND")
        Util.SetHighlightColor(_G.CraftHighlight, 0.2)
    end

    Skin.FauxScrollFrameTemplate(_G.CraftListScrollFrame)
    Util.HideFrameTextures(_G.CraftListScrollFrame)
    Skin.UIPanelScrollFrameTemplate(_G.CraftDetailScrollFrame)
    for _, name in ipairs({"CraftDetailScrollFrameTop", "CraftDetailScrollFrameBottom"}) do
        local texture = _G[name]
        if texture then
            texture:SetAlpha(0)
        end
    end

    local craftIcon = _G.CraftIcon
    if craftIcon then
        craftIcon:SetNormalTexture("")
        Aurora.Base.CropIcon(craftIcon:GetNormalTexture())
    end

    for i = 1, 8 do
        local reagent = _G["CraftReagent"..i]
        if reagent then
            Skin.LargeItemButtonTemplate(reagent)
        end
    end

    Skin.UIPanelButtonTemplate(_G.CraftCreateButton)
    Skin.UIPanelButtonTemplate(_G.CraftCancelButton)
end
