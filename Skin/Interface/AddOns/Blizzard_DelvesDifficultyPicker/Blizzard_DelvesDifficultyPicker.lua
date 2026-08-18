local _, private = ...
if private.shouldSkip() then return end

local Aurora = private.Aurora
local Hook = Aurora.Hook
local Skin = Aurora.Skin
local Util = Aurora.Util

function private.AddOns.Blizzard_DelvesDifficultyPicker()
    local DelvesDifficultyPickerFrame = _G.DelvesDifficultyPickerFrame

    -- The Map Properties icons live in an addon-local widget container, not one
    -- of the global containers Blizzard_UIWidgets mixes the hook into, so their
    -- widgets never reached Skin.UIWidgetTemplateSpellDisplay and kept
    -- Blizzard's circular Border/CircleMask. Mixing the hook in here routes them
    -- through the same skin path. Widgets are created when the frame registers
    -- its widget set (on show), which is after this runs.
    Util.Mixin(DelvesDifficultyPickerFrame.DelveModifiersWidgetContainer, Hook.UIWidgetContainerMixin)

    Skin.InsetFrameTemplate(DelvesDifficultyPickerFrame)
    Skin.DialogBorderTemplate(DelvesDifficultyPickerFrame.Border)
    Skin.UIPanelCloseButton(DelvesDifficultyPickerFrame.CloseButton)
    Skin.DropdownButton(DelvesDifficultyPickerFrame.Dropdown)
    Skin.UIPanelButtonTemplate(DelvesDifficultyPickerFrame.EnterDelveButton)

    local rewardsFrame = DelvesDifficultyPickerFrame.DelveRewardsContainerFrame
    if rewardsFrame then
        if rewardsFrame.ScrollBox then
            Skin.WowScrollBoxList(rewardsFrame.ScrollBox)
        end
        if rewardsFrame.ScrollBar then
            Skin.MinimalScrollBar(rewardsFrame.ScrollBar)
        end

        Util.WrapPoolAcquire(rewardsFrame.rewardPool, Skin.LargeItemButtonTemplate)
    end
end
