local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin

--[[ TBC (anniversary) addon list: the 2.5.6 client ships the RETAIL-MODERN
    AddonList (ButtonFrameTemplate + ScrollBox/MinimalScrollBar + pooled
    MinimalCheckboxArt rows + SharedButtonSmall footer buttons — verified in
    wow-ui-source-anniversary). Adapted from the Mainline skin; the
    SharedButtonSmall skin chain is Mainline-only, so a local three-slice
    fallback is used. Era keeps the legacy Classic/ sibling.
]]

local function SkinFooterButton(Button)
    if not Button then return end
    if Skin.SharedButtonSmallTemplate then
        Skin.SharedButtonSmallTemplate(Button)
        return
    end
    for _, key in ipairs({"Left", "Center", "Right"}) do
        if Button[key] then
            Button[key]:SetAlpha(0)
        end
    end
    Skin.FrameTypeButton(Button)
end

do --[[ AddonList.xml ]]
    function Skin.AddonListEntryTemplate(Button)
        if Button.Enabled then
            Skin.UICheckButtonTemplate(Button.Enabled)
        end
        if Button.LoadAddonButton then
            Skin.UIPanelButtonTemplate(Button.LoadAddonButton)
        end
    end
end

function private.AddOns.Blizzard_AddOnList()
    local AddonList = _G.AddonList

    Skin.ButtonFrameTemplate(AddonList)
    if AddonList.ForceLoad then
        Skin.UICheckButtonTemplate(AddonList.ForceLoad)
    end
    if AddonList.SearchBox then
        Skin.SearchBoxTemplate(AddonList.SearchBox)
    end

    SkinFooterButton(AddonList.CancelButton)
    SkinFooterButton(AddonList.OkayButton)
    SkinFooterButton(AddonList.EnableAllButton)
    SkinFooterButton(AddonList.DisableAllButton)

    if AddonList.Dropdown then
        Skin.DropdownButton(AddonList.Dropdown)
    end

    if AddonList.ScrollBox then
        Skin.WowScrollBoxList(AddonList.ScrollBox)
        Skin.MinimalScrollBar(AddonList.ScrollBar)
        _G.hooksecurefunc(AddonList.ScrollBox, "Update", function(self)
            self:ForEachFrame(function(frame)
                if not frame._auroraSkinned then
                    Skin.AddonListEntryTemplate(frame)
                    frame._auroraSkinned = true
                end
            end)
        end)
    end
end
