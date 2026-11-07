local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals select

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color = Aurora.Color


--do --[[ AddOns\Blizzard_TrainerUI.lua ]]
--end

do --[[ AddOns\Blizzard_TrainerUI.xml ]]
    function Skin.ClassTrainerSkillButtonTemplate(Button)
        Skin.UIServiceButtonTemplate(Button)
    end
    -- Camelot only: category headers in the trainer list, drawn with the
    -- Professions recipe-header atlases.
    function Skin.TrainerUICategoryTemplate(Button)
        Button.LeftPiece:SetAlpha(0)
        Button.RightPiece:SetAlpha(0)
        Button.CenterPiece:SetAlpha(0)
        Base.SetBackdrop(Button, Color.button)
        Button:SetBackdropOption("offsets", {
            left = 1,
            right = 1,
            top = 1,
            bottom = 3,
        })
    end
end

function private.AddOns.Blizzard_TrainerUI()
    local ClassTrainerFrame = _G.ClassTrainerFrame
    Skin.ButtonFrameTemplate(ClassTrainerFrame)

    _G.ClassTrainerFrameMoneyBg:Hide()
    ClassTrainerFrame.BG:Hide()

    Skin.FrameTypeStatusBar(_G.ClassTrainerStatusBar)
    _G.ClassTrainerStatusBarLeft:Hide()
    _G.ClassTrainerStatusBarRight:Hide()
    _G.ClassTrainerStatusBarMiddle:Hide()
    _G.ClassTrainerStatusBarBackground:Hide()
    _G.ClassTrainerStatusBar:SetPoint("TOPLEFT", 8, -35)
    _G.ClassTrainerStatusBar:SetSize(192, 18)

    Skin.DropdownButton(ClassTrainerFrame.FilterDropdown)
    local ClassTrainerTrainButton = _G.ClassTrainerTrainButton
    Skin.MagicButtonTemplate(ClassTrainerTrainButton)

    -- WoW Forever's trainer XML attaches the cost display as parentKey "money"
    -- instead of naming it ClassTrainerFrameMoneyFrame; retail still names it.
    local moneyFrame = _G.ClassTrainerFrameMoneyFrame or ClassTrainerFrame.money
    if moneyFrame then
        local moneyBG = _G.CreateFrame("Frame", nil, ClassTrainerFrame)
        moneyBG:SetSize(142, 18)
        moneyBG:SetPoint("BOTTOMLEFT", 8, 5)
        Base.SetBackdrop(moneyBG, Color.frame)
        moneyBG:SetBackdropBorderColor(Color.yellow)
        Skin.SmallMoneyFrameTemplate(moneyFrame)
        moneyFrame:SetPoint("RIGHT", moneyBG, 11, 0)
    end

    Skin.ClassTrainerSkillButtonTemplate(ClassTrainerFrame.skillStepButton)
    Skin.WowScrollBoxList(ClassTrainerFrame.ScrollBox)

    -- The list rows come from the ScrollBox factory (ClassTrainerFrame_OnLoad),
    -- so only the skill-step button above ever got the skin; every row kept
    -- Blizzard's TrainerTextures plate, which reads as a dark backdrop over
    -- the list on Forever, where trainers are in daily use. Skin each row
    -- once, after Blizzard's initializer has run (same OnInitializedFrame
    -- path as the community list). Rows are told apart by shape: skill rows
    -- carry the money frame, Camelot's category headers the recipe pieces.
    local skinnedRows = _G.setmetatable({}, {__mode = "k"})
    local function SkinRow(Button)
        if skinnedRows[Button] then return end
        if Button.money and Button.icon then
            Skin.ClassTrainerSkillButtonTemplate(Button)
        elseif Button.LeftPiece and Button.CenterPiece then
            Skin.TrainerUICategoryTemplate(Button)
        else
            return
        end
        skinnedRows[Button] = true
    end
    local ScrollBox = ClassTrainerFrame.ScrollBox
    if _G.ScrollUtil and _G.ScrollUtil.AddInitializedFrameCallback then
        -- Event path: (owner, frame, elementData); ForEachFrame: (frame, ...).
        _G.ScrollUtil.AddInitializedFrameCallback(ScrollBox, function(_, Button)
            SkinRow(Button)
        end, ScrollBox)
        ScrollBox:ForEachFrame(SkinRow)
    end
    Skin.MinimalScrollBar(ClassTrainerFrame.ScrollBar)
    Skin.InsetFrameTemplate(ClassTrainerFrame.bottomInset)
end
