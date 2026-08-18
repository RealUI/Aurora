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

        -- Reward buttons come from the ScrollBox's element factory, NOT from
        -- rewardsFrame.rewardPool: Blizzard creates that pool in OnLoad and
        -- only ever calls ReleaseAll() on it, so wrapping its Acquire skinned
        -- nothing and the buttons kept Blizzard's rounded UI-QuestItemNameFrame
        -- plate and uncropped icon. Skin them as the ScrollBox acquires them.
        local scrollBox = rewardsFrame.ScrollBox
        if scrollBox then
            -- Skin.LargeItemButtonTemplate's "right = 108" offset yields a
            -- square icon only at the template's own 147px width. This list is
            -- a vertical ScrollBox view, which anchors elements TOPLEFT *and*
            -- TOPRIGHT to the scroll target (ScrollBoxViewUtil.SetPoint,
            -- elementStretchDisabled off), so the button is stretched to the
            -- ScrollBox width and the icon comes out rectangular. Re-derive the
            -- offset from the live size to keep the icon square, and redo it
            -- whenever the row is re-stretched.
            local function SquareIcon(frame)
                local w, h = frame:GetWidth(), frame:GetHeight()
                if not w or not h or w <= 0 or h <= 2 then return end

                local side = h - 2
                if w <= side then return end

                frame:SetBackdropOption("offsets", {
                    left = 0,
                    right = w - side,
                    top = 0,
                    bottom = 2,
                })
            end

            local function SkinReward(frame)
                if not frame then return end
                if not private.IsSkinned(frame) then
                    Skin.LargeItemButtonTemplate(frame)
                    private.SetSkinned(frame, true)
                    frame:HookScript("OnSizeChanged", SquareIcon)
                end
                SquareIcon(frame)
            end

            _G.ScrollUtil.AddAcquiredFrameCallback(scrollBox, function(o, frame)
                SkinReward(frame)
            end, rewardsFrame)

            scrollBox:ForEachFrame(SkinReward)
        end
    end
end
