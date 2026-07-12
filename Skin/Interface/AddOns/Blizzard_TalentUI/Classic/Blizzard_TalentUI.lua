local _, private = ...
if private.shouldSkip() then return end
-- Mists resolves this Classic/ file through the skin-dir fallback, but MoP
-- talents are a different frame entirely (Mists\Blizzard_TalentUI.xml) —
-- that port belongs to the aurora-mists-support spec.
if private.isMists then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Util = Aurora.Util

--[[ Classic-family TalentUI (era + TBC; structurally identical, only the
    frame's own texture atlases differ and those are simply hidden).
    Evidence: wow-ui-source-era/Interface/AddOns/Blizzard_TalentUI/Classic/
    Blizzard_TalentUI.xml (root L16, named UI-Character-General-* quadrants)
    and Blizzard_FrameXML/Classic/Blizzard_TalentUITemplates.xml
    (TalentButtonTemplate = ItemButtonTemplate + $parentSlot +
    $parentRankBorder; TalentTabTemplate inherits
    CharacterFrameTabButtonTemplate). The talent tree background art and
    branch/arrow connectors are deliberately kept.
]]

local frameArt = {
    "PlayerTalentFrameTopLeft", "PlayerTalentFrameTopRight",
    "PlayerTalentFrameBottomLeft", "PlayerTalentFrameBottomRight",
    "PlayerTalentFramePointsLeft", "PlayerTalentFramePointsMiddle",
    "PlayerTalentFramePointsRight",
}

local function SkinTalentButton(Button)
    local name = Button:GetName()

    Skin.FrameTypeItemButton(Button)

    local slot = _G[name.."Slot"]
    if slot then
        slot:SetAlpha(0)
    end
    local rankBorder = _G[name.."RankBorder"]
    if rankBorder then
        rankBorder:SetTexture("")
    end
end

function private.AddOns.Blizzard_TalentUI()
    local PlayerTalentFrame = _G.PlayerTalentFrame

    for _, textureName in ipairs(frameArt) do
        local texture = _G[textureName]
        if texture then
            texture:SetTexture("")
        end
    end
    _G.PlayerTalentFramePortrait:SetAlpha(0)

    Skin.FrameTypeFrame(PlayerTalentFrame)
    PlayerTalentFrame:SetBackdropOption("offsets", {
        left = 10,
        right = 30,
        top = 0,
        bottom = 75,
    })

    Skin.UIPanelCloseButton(_G.PlayerTalentFrameCloseButton)

    if _G.PlayerTalentFrameStatusFrame then
        Util.HideFrameTextures(_G.PlayerTalentFrameStatusFrame)
    end
    if _G.PlayerTalentFramePointsBar then
        Util.HideFrameTextures(_G.PlayerTalentFramePointsBar)
    end
    if _G.PlayerTalentFramePreviewBar then
        Util.HideFrameTextures(_G.PlayerTalentFramePreviewBar)
    end
    if _G.PlayerTalentFramePreviewBarFiller then
        Util.HideFrameTextures(_G.PlayerTalentFramePreviewBarFiller)
    end

    if _G.PlayerTalentFrameActivateButton then
        Skin.UIPanelButtonTemplate(_G.PlayerTalentFrameActivateButton)
    end
    if _G.PlayerTalentFrameLearnButton then
        Skin.UIPanelButtonTemplate(_G.PlayerTalentFrameLearnButton)
    end

    Skin.UIPanelScrollFrameTemplate(_G.PlayerTalentFrameScrollFrame)

    for i = 1, 40 do
        local talent = _G["PlayerTalentFrameTalent"..i]
        if talent then
            SkinTalentButton(talent)
        end
    end

    local i = 1
    while _G["PlayerTalentFrameTab"..i] do
        Skin.CharacterFrameTabButtonTemplate(_G["PlayerTalentFrameTab"..i])
        i = i + 1
    end
end
