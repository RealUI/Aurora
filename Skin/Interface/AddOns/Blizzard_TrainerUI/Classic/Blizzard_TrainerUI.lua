local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base, Skin = Aurora.Base, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

--[[ Classic-family class/profession trainer (era/TBC/Mists; retail ships a
    different flat Blizzard_TrainerUI — not skinned there, entry stays
    inactive). Evidence: wow-ui-source-era/Interface/AddOns/
    Blizzard_TrainerUI/Blizzard_TrainerUI.xml (classic 384x512 sheet panel;
    templates in Blizzard_FrameXML/Classic/ClassTrainerFrameTemplates.xml —
    detail scrollbar track art is named $parentTop/Bottom, the list
    scrollbar's is unnamed). Skill rows are text buttons with runtime
    plus/minus icons — left stock (first pass).
]]

function private.AddOns.Blizzard_TrainerUI()
    local ClassTrainerFrame = _G.ClassTrainerFrame

    -- Root sheets + portrait + horizontal divider bar; alpha mode because
    -- the portrait is re-set via SetPortraitTexture per trainer
    Util.HideFrameTextures(ClassTrainerFrame, true)
    Skin.FrameTypeFrame(ClassTrainerFrame)
    ClassTrainerFrame:SetBackdropOption("offsets", {
        left = 10,
        right = 30,
        top = 0,
        bottom = 75,
    })

    -- "All" collapse tab art
    Util.HideFrameTextures(_G.ClassTrainerExpandButtonFrame)

    -- Selected-row highlight
    if _G.ClassTrainerSkillHighlight then
        _G.ClassTrainerSkillHighlight:SetColorTexture(Color.highlight.r, Color.highlight.g, Color.highlight.b, 0.2)
    end

    if ClassTrainerFrame.FilterDropdown then
        Skin.DropdownButton(ClassTrainerFrame.FilterDropdown)
    end

    -- Skill list (FauxScrollFrame, unnamed track art on the scroll frame)
    Skin.FauxScrollFrameTemplate(_G.ClassTrainerListScrollFrame)
    Util.HideFrameTextures(_G.ClassTrainerListScrollFrame)

    -- Detail pane (named track art)
    Skin.UIPanelScrollFrameTemplate(_G.ClassTrainerDetailScrollFrame)
    for _, name in _G.ipairs({"ClassTrainerDetailScrollFrameTop", "ClassTrainerDetailScrollFrameBottom"}) do
        local texture = _G[name]
        if texture then
            texture:SetAlpha(0)
        end
    end

    -- Skill icon: set at runtime via SetNormalTexture — force-create and
    -- crop once (texcoords persist across SetNormalTexture)
    local skillIcon = _G.ClassTrainerSkillIcon
    if skillIcon then
        skillIcon:SetNormalTexture("")
        Base.CropIcon(skillIcon:GetNormalTexture())
    end

    Skin.UIPanelButtonTemplate(_G.ClassTrainerTrainButton)
    Skin.UIPanelButtonTemplate(_G.ClassTrainerCancelButton)
    Skin.UIPanelCloseButton(_G.ClassTrainerFrameCloseButton)
end
