local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Util = Aurora.Util

--[[ Classic-family skills tab (CharacterFrame tab 4 on era).
    Evidence: wow-ui-source-*/Interface/AddOns/Blizzard_UIPanels_Game/
    Classic/SkillFrame.xml — SkillStatusBarTemplate rows carry a child
    $parentBorder BUTTON (click target) whose NormalTexture is the ornate
    bar border; its fill/background layers are already flat colors. Header
    rows (SkillLabelTemplate) use runtime plus/minus icons — left stock.
]]

local function SkinSkillBar(name)
    local bar = _G[name]
    if not bar then return end

    bar:SetStatusBarTexture(private.textures.plain)

    local border = _G[name.."Border"]
    if border then
        local normal = _G[name.."BorderNormal"]
        if normal then
            normal:SetAlpha(0)
        end
        local highlight = _G[name.."BorderHighlight"]
        if highlight then
            highlight:SetTexture([[Interface\Buttons\White8x8]])
            highlight:SetVertexColor(1, 1, 1) -- static: ADD blend hover
            highlight:SetAlpha(0.2)
        end
    end
end

function private.FrameXML.SkillFrame()
    Util.HideFrameTextures(_G.SkillFrame)
    Util.HideFrameTextures(_G.SkillFrameExpandButtonFrame)

    for i = 1, 12 do
        SkinSkillBar("SkillRankFrame"..i)
    end
    SkinSkillBar("SkillDetailStatusBar")

    Skin.FauxScrollFrameTemplate(_G.SkillListScrollFrame)
    Util.HideFrameTextures(_G.SkillListScrollFrame)
    Skin.UIPanelScrollFrameTemplate(_G.SkillDetailScrollFrame)
    Util.HideFrameTextures(_G.SkillDetailScrollFrame)

    Skin.UIPanelButtonTemplate(_G.SkillFrameCancelButton)
end
