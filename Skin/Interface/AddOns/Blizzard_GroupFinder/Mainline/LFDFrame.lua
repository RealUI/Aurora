local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Util = Aurora.Util

do --[[ FrameXML\LFDFrame.lua ]]
    function Hook.LFDQueueFrameRandomCooldownFrame_Update()
        for i = 1, _G.GetNumSubgroupMembers() do
            local nameLabel = _G["LFDQueueFrameCooldownFrameName"..i]

            -- Class token and name can be secret in combat (WoW 12): secret keys
            -- throw on table index, secret strings throw in SetFormattedText.
            -- When withheld, leave Blizzard's own label untouched.
            local _, classFilename = _G.UnitClass("party"..i)
            if _G.issecretvalue(classFilename) then classFilename = nil end
            local name = _G.GetUnitName("party"..i, true)
            if name and not _G.issecretvalue(name) then
                local classColor = classFilename and _G.CUSTOM_CLASS_COLORS[classFilename] or _G.NORMAL_FONT_COLOR
                nameLabel:SetFormattedText("|cff%.2x%.2x%.2x%s|r", classColor.r * 255, classColor.g * 255, classColor.b * 255, name)
            end
        end
    end
end

do --[[ FrameXML\LFDFrame.xml ]]
    function Skin.LFDRoleButtonTemplate(Button)
        Skin.LFGRoleButtonWithBackgroundAndRewardTemplate(Button)
    end
    function Skin.LFDRoleCheckPopupButtonTemplate(Button)
        Skin.LFGRoleButtonTemplate(Button)
    end
    function Skin.LFDFrameDungeonChoiceTemplate(Button)
        Skin.LFGSpecificChoiceTemplate(Button)
    end
end

function private.FrameXML.LFDFrame()
    _G.hooksecurefunc("LFDQueueFrameRandomCooldownFrame_Update", Hook.LFDQueueFrameRandomCooldownFrame_Update)

    -----------------------
    -- LFDRoleCheckPopup --
    -----------------------
    local LFDRoleCheckPopup = _G.LFDRoleCheckPopup
    Skin.DialogBorderTemplate(LFDRoleCheckPopup.Border)

    _G.LFDRoleCheckPopupRoleButtonTank:SetPoint("LEFT", 33, 0)
    Skin.LFDRoleCheckPopupButtonTemplate(_G.LFDRoleCheckPopupRoleButtonTank)
    Skin.LFDRoleCheckPopupButtonTemplate(_G.LFDRoleCheckPopupRoleButtonHealer)
    Skin.LFDRoleCheckPopupButtonTemplate(_G.LFDRoleCheckPopupRoleButtonDPS)

    Skin.UIPanelButtonTemplate(_G.LFDRoleCheckPopupAcceptButton)
    Skin.UIPanelButtonTemplate(_G.LFDRoleCheckPopupDeclineButton)
    Util.PositionRelative("BOTTOMLEFT", LFDRoleCheckPopup, "BOTTOMLEFT", 36, 15, 5, "Right", {
        _G.LFDRoleCheckPopupAcceptButton,
        _G.LFDRoleCheckPopupDeclineButton,
    })

    --------------------
    -- LFDParentFrame --
    --------------------
    local LFDParentFrame = _G.LFDParentFrame
    _G.LFDParentFrameRoleBackground:Hide()
    LFDParentFrame.TopTileStreaks:Hide()

    Skin.InsetFrameTemplate(LFDParentFrame.Inset)

    -- LFDQueueFrame --
    local LFDQueueFrame = _G.LFDQueueFrame
    _G.LFDQueueFrameBackground:Hide()

    Skin.LFDRoleButtonTemplate(_G.LFDQueueFrameRoleButtonTank)
    Skin.LFDRoleButtonTemplate(_G.LFDQueueFrameRoleButtonHealer)
    Skin.LFDRoleButtonTemplate(_G.LFDQueueFrameRoleButtonDPS)
    Skin.LFGRoleButtonTemplate(_G.LFDQueueFrameRoleButtonLeader)
    Skin.DropdownButton(_G.LFDQueueFrameTypeDropdown)
    _G.LFDQueueFrameTypeDropdown:ClearAllPoints()
    _G.LFDQueueFrameTypeDropdown:SetPoint("BOTTOMLEFT", LFDQueueFrame, "BOTTOMLEFT", 131, 287)
    _G.LFDQueueFrameTypeDropdown:SetPoint("BOTTOMRIGHT", LFDQueueFrame, "BOTTOMRIGHT", -30, 287)
    Skin.ScrollFrameTemplate(_G.LFDQueueFrameRandomScrollFrame)
    Skin.LFGRewardFrameTemplate(_G.LFDQueueFrameRandomScrollFrameChildFrame)

    Skin.WowScrollBoxList(LFDQueueFrame.Specific.ScrollBox)
    Skin.MinimalScrollBar(LFDQueueFrame.Specific.ScrollBar)

    Skin.MagicButtonTemplate(_G.LFDQueueFrameFindGroupButton)
    Skin.LFGBackfillCoverTemplate(LFDQueueFrame.PartyBackfill)
    Skin.LFGCooldownCoverTemplate(LFDQueueFrame.CooldownFrame)
end
