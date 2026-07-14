local _, private = ...
if private.shouldSkip() then return end

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Util = Aurora.Util

--[[ Mists (5.5.4) Dungeon Finder pane — MoP shell with retail-modern
    guts: LFDParentFrame (role background art + TopTileStreaks + inset)
    hosting LFDQueueFrame with a WowStyle1 type dropdown, the questpaper
    random-dungeon panel (ScrollFrameTemplate), a WowScrollBoxList
    specific-dungeon list and a MagicButton. Role buttons stay stock —
    their skin chain is Mainline-only (same call as Shared\RaidFinder).
    Evidence: wow-ui-source-classic/Interface/AddOns/Blizzard_GroupFinder/
    Classic/LFDFrame.xml; structural reference: original MoP-era Aurora
    FrameXML/LFDFrame.lua (repo history).
]]

function private.FrameXML.LFDFrame()
    -- role check popup
    local RoleCheckPopup = _G.LFDRoleCheckPopup
    if RoleCheckPopup then
        if RoleCheckPopup.Border then
            Skin.DialogBorderTemplate(RoleCheckPopup.Border)
        end
        if _G.LFDRoleCheckPopupAcceptButton then
            Skin.UIPanelButtonTemplate(_G.LFDRoleCheckPopupAcceptButton)
        end
        if _G.LFDRoleCheckPopupDeclineButton then
            Skin.UIPanelButtonTemplate(_G.LFDRoleCheckPopupDeclineButton)
        end
    end

    local LFDParentFrame = _G.LFDParentFrame
    if not LFDParentFrame then return end

    -- blue role background + top tile streaks
    Util.HideFrameTextures(LFDParentFrame, true)
    if LFDParentFrame.Inset then
        Skin.InsetFrameTemplate(LFDParentFrame.Inset)
    end

    local LFDQueueFrame = _G.LFDQueueFrame
    if not LFDQueueFrame then return end

    -- questpaper panel behind the random-dungeon description
    if _G.LFDQueueFrameBackground then
        _G.LFDQueueFrameBackground:SetAlpha(0)
    end

    if LFDQueueFrame.TypeDropdown then
        Skin.DropdownButton(LFDQueueFrame.TypeDropdown)
    end

    if _G.LFDQueueFrameFindGroupButton then
        Skin.MagicButtonTemplate(_G.LFDQueueFrameFindGroupButton)
    end

    -- specific-dungeon list (retail-modern scroll pair)
    local Specific = LFDQueueFrame.Specific
    if Specific then
        if Specific.ScrollBox and Skin.WowScrollBoxList then
            Skin.WowScrollBoxList(Specific.ScrollBox)
        end
        if Specific.ScrollBar and Skin.MinimalScrollBar then
            Skin.MinimalScrollBar(Specific.ScrollBar)
        end
    end

    -- random-dungeon reward panel scroll (kept last: structure least
    -- certain; a failure here must not cost the rest of the pane)
    local RandomScroll = _G.LFDQueueFrameRandomScrollFrame
    if RandomScroll and RandomScroll.ScrollBar and Skin.MinimalScrollBar then
        Skin.MinimalScrollBar(RandomScroll.ScrollBar)
    end
end
