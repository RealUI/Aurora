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
end

function private.AddOns.Blizzard_TrainerUI()
    local ClassTrainerFrame = _G.ClassTrainerFrame
    if not ClassTrainerFrame then return end

    Skin.ButtonFrameTemplate(ClassTrainerFrame)

    if _G.ClassTrainerFrameMoneyBg then
        _G.ClassTrainerFrameMoneyBg:Hide()
    end
    if ClassTrainerFrame.BG then
        ClassTrainerFrame.BG:Hide()
    end

    if _G.ClassTrainerStatusBar then
        Skin.FrameTypeStatusBar(_G.ClassTrainerStatusBar)
        if _G.ClassTrainerStatusBarLeft then _G.ClassTrainerStatusBarLeft:Hide() end
        if _G.ClassTrainerStatusBarRight then _G.ClassTrainerStatusBarRight:Hide() end
        if _G.ClassTrainerStatusBarMiddle then _G.ClassTrainerStatusBarMiddle:Hide() end
        if _G.ClassTrainerStatusBarBackground then _G.ClassTrainerStatusBarBackground:Hide() end
        _G.ClassTrainerStatusBar:SetPoint("TOPLEFT", 8, -35)
        _G.ClassTrainerStatusBar:SetSize(192, 18)
    end

    -- FilterDropdown is the modern dropdown (Classic Anniversary+)
    if ClassTrainerFrame.FilterDropdown then
        Skin.DropdownButton(ClassTrainerFrame.FilterDropdown)
    end

    local ClassTrainerTrainButton = _G.ClassTrainerTrainButton
    if ClassTrainerTrainButton then
        Skin.MagicButtonTemplate(ClassTrainerTrainButton)
    end

    local moneyBG = _G.CreateFrame("Frame", nil, ClassTrainerFrame)
    moneyBG:SetSize(142, 18)
    moneyBG:SetPoint("BOTTOMLEFT", 8, 5)
    Base.SetBackdrop(moneyBG, Color.frame)
    moneyBG:SetBackdropBorderColor(Color.yellow)
    if _G.ClassTrainerFrameMoneyFrame then
        Skin.SmallMoneyFrameTemplate(_G.ClassTrainerFrameMoneyFrame)
        _G.ClassTrainerFrameMoneyFrame:SetPoint("RIGHT", moneyBG, 11, 0)
    end

    -- skillStepButton, ScrollBox, ScrollBar are the modern pattern
    if ClassTrainerFrame.skillStepButton then
        Skin.ClassTrainerSkillButtonTemplate(ClassTrainerFrame.skillStepButton)
    end
    if ClassTrainerFrame.ScrollBox then
        Skin.WowScrollBoxList(ClassTrainerFrame.ScrollBox)
    end
    if ClassTrainerFrame.ScrollBar then
        Skin.MinimalScrollBar(ClassTrainerFrame.ScrollBar)
    end
    if ClassTrainerFrame.bottomInset then
        Skin.InsetFrameTemplate(ClassTrainerFrame.bottomInset)
    end
end
