local _, private = ...
if private.shouldSkip() then return end
-- ERA-ONLY: anniversary (TBC) and Mists ship the retail-modern AddonList
-- (ScrollBox + SharedButtonSmall) — see the TBC/ sibling file
if not private.isVanilla then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Util = Aurora.Util

--[[ Classic-family addon list (era/TBC/Mists; retail resolves Mainline/).
    Evidence: wow-ui-source-*/Interface/AddOns/Blizzard_AddOnList/Classic/
    AddonList.xml — ButtonFrameTemplate root with STATIC AddonListEntry{i}
    rows (named $parentEnabled checkboxes) over a FauxScrollFrame, MagicButton
    footer buttons, a WowStyle1 dropdown, and the AddonDialog reload popup.
]]

function private.AddOns.Blizzard_AddOnList()
    local AddonList = _G.AddonList

    Skin.ButtonFrameTemplate(AddonList)
    Skin.DropdownButton(AddonList.Dropdown)
    Skin.UICheckButtonTemplate(_G.AddonListForceLoad)

    Skin.MagicButtonTemplate(AddonList.CancelButton)
    Skin.MagicButtonTemplate(AddonList.OkayButton)
    Skin.MagicButtonTemplate(AddonList.EnableAllButton)
    Skin.MagicButtonTemplate(AddonList.DisableAllButton)

    local i = 1
    while _G["AddonListEntry"..i] do
        local name = "AddonListEntry"..i
        Skin.UICheckButtonTemplate(_G[name.."Enabled"])
        Skin.UIPanelButtonTemplate(_G[name].LoadAddonButton)
        i = i + 1
    end

    local scrollFrame = _G.AddonListScrollFrame
    if scrollFrame then
        Skin.FauxScrollFrameTemplate(scrollFrame)
        Util.HideFrameTextures(scrollFrame)
    end

    -- Reload-UI confirmation dialog
    if _G.AddonDialogBackground then
        Skin.DialogBorderTemplate(_G.AddonDialogBackground)
        Skin.UIPanelButtonTemplate(_G.AddonDialogButton1)
        Skin.UIPanelButtonTemplate(_G.AddonDialogButton2)
    end
end
