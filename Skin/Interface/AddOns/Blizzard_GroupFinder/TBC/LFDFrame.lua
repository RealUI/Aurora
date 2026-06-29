local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

function private.FrameXML.LFDFrame()
    --------------------
    -- LFDParentFrame --
    --------------------
    local LFDParentFrame = _G.LFDParentFrame
    if not LFDParentFrame then return end

    Base.SetBackdrop(LFDParentFrame, Color.frame, Util.GetFrameAlpha())

    -- Hide background and decoration textures
    if _G.LFDParentFrameRoleBackground then
        _G.LFDParentFrameRoleBackground:Hide()
    end
    if LFDParentFrame.TopTileStreaks then
        LFDParentFrame.TopTileStreaks:Hide()
    end

    --------------------
    -- LFDQueueFrame  --
    --------------------
    local LFDQueueFrame = _G.LFDQueueFrame
    if not LFDQueueFrame then return end

    if _G.LFDQueueFrameBackground then
        _G.LFDQueueFrameBackground:Hide()
    end

    -- Skin dungeon type dropdown
    local typeDropdown = _G.LFDQueueFrameTypeDropdown
    if typeDropdown then
        Skin.DropdownButton(typeDropdown)
    end

    -- Skin role check buttons
    local roleButtonTank = _G.LFDQueueFrameRoleButtonTank
    if roleButtonTank then
        if roleButtonTank.checkButton then
            Skin.UICheckButtonTemplate(roleButtonTank.checkButton)
        end
    end

    local roleButtonHealer = _G.LFDQueueFrameRoleButtonHealer
    if roleButtonHealer then
        if roleButtonHealer.checkButton then
            Skin.UICheckButtonTemplate(roleButtonHealer.checkButton)
        end
    end

    local roleButtonDPS = _G.LFDQueueFrameRoleButtonDPS
    if roleButtonDPS then
        if roleButtonDPS.checkButton then
            Skin.UICheckButtonTemplate(roleButtonDPS.checkButton)
        end
    end

    local roleButtonLeader = _G.LFDQueueFrameRoleButtonLeader
    if roleButtonLeader then
        if roleButtonLeader.checkButton then
            Skin.UICheckButtonTemplate(roleButtonLeader.checkButton)
        end
    end

    -- Skin specific dungeon check buttons
    for i = 1, 15 do
        local button = _G["LFDQueueFrameSpecificListButton" .. i]
        if button then
            if button.enableButton then
                Skin.UICheckButtonTemplate(button.enableButton)
            end
            if button.expandOrCollapseButton then
                Skin.ExpandOrCollapse(button.expandOrCollapseButton)
            end
        end
    end

    -- Skin reward display
    local randomScrollFrame = _G.LFDQueueFrameRandomScrollFrame
    if randomScrollFrame then
        local childFrame = _G.LFDQueueFrameRandomScrollFrameChildFrame
        if childFrame then
            -- Skin reward items in the random dungeon reward section
            for i = 1, 10 do
                local item = _G["LFDQueueFrameRandomScrollFrameChildFrameItem" .. i]
                if item then
                    if item.Icon or item.icon then
                        local icon = item.Icon or item.icon
                        Base.CropIcon(icon, item)
                    end
                    if item.IconBorder then
                        item.IconBorder:SetAlpha(0)
                    end
                end
            end
            -- Skin money reward if present
            if childFrame.MoneyReward then
                local icon = childFrame.MoneyReward.Icon or childFrame.MoneyReward.icon
                if icon then
                    Base.CropIcon(icon, childFrame.MoneyReward)
                end
            end
        end
    end

    -- Skin Find Group / Queue button
    local findGroupButton = _G.LFDQueueFrameFindGroupButton
    if findGroupButton then
        Skin.UIPanelButtonTemplate(findGroupButton)
    end
end
