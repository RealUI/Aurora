local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Util = Aurora.Util
-- local Color = Aurora.Color


do --[[ AddOns\AddonList.xml ]]
    function Skin.AddonListEntryTemplate(Button)
        Skin.UICheckButtonTemplate(Button.Enabled) -- BlizzWTF: Uses MinimalCheckboxArtTemplate, not UICheckButtonTemplate
        Skin.UIPanelButtonTemplate(Button.LoadAddonButton)
    end
end

function private.AddOns.Blizzard_AddOnList()
    local AddonList = _G.AddonList
    local bg = AddonList.Bg

    Skin.ButtonFrameTemplate(AddonList)
    Skin.UICheckButtonTemplate(AddonList.ForceLoad)
    Skin.SearchBoxTemplate(AddonList.SearchBox)

    local titleText = AddonList.TitleContainer
    titleText:ClearAllPoints()
    titleText:SetPoint("TOPLEFT", bg)
    titleText:SetPoint("BOTTOMRIGHT", bg, "TOPRIGHT", 0, -private.FRAME_TITLE_HEIGHT)

    Skin.SharedButtonSmallTemplate(AddonList.CancelButton)
    Skin.SharedButtonSmallTemplate(AddonList.OkayButton)
    Skin.SharedButtonSmallTemplate(AddonList.EnableAllButton)
    Skin.SharedButtonSmallTemplate(AddonList.DisableAllButton)
    Util.PositionRelative("BOTTOMRIGHT", AddonList, "BOTTOMRIGHT", -5, 5, 5, "Left", {
        AddonList.CancelButton,
        AddonList.OkayButton,
    })
    Util.PositionRelative("BOTTOMLEFT", AddonList, "BOTTOMLEFT", 5, 5, 5, "Right", {
        AddonList.EnableAllButton,
        AddonList.DisableAllButton,
    })
    Util.PositionRelative("TOPRIGHT", AddonList, "TOPRIGHT", -10, -30, 5, "Down", {
        AddonList.SearchBox,
        AddonList.ForceLoad,
    })
    Skin.DropdownButton(AddonList.Dropdown)
    AddonList.Dropdown:SetPoint("TOPLEFT", 10, -27)

    Skin.WowScrollBoxList(AddonList.ScrollBox)
    Skin.MinimalScrollBar(AddonList.ScrollBar)
    AddonList.ScrollBox:SetPoint("BOTTOMRIGHT", AddonList.CancelButton, "TOPRIGHT", -21, 5)
    AddonList.ScrollBox:SetPoint("TOPLEFT", AddonList.Performance, "BOTTOMLEFT", -2, 0)
    _G.hooksecurefunc(AddonList.ScrollBox, "Update", function(self)
        self:ForEachFrame(function(frame)
            if not frame.auroraSkinned then
                if frame.Enabled then
                    Skin.AddonListEntryTemplate(frame)
                end
                frame.auroraSkinned = true
            end
        end)
    end)
end
