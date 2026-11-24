local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals min

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color = Aurora.Color

do --[[ AddOns\Blizzard_RaidUI.lua ]]
    function Hook.RaidGroupFrame_Update()
        if not _G.IsInRaid() then return end

        local button, subframes
        for i = 1, _G.MAX_RAID_MEMBERS do
            button = _G["RaidGroupButton"..i]
            if button:IsShown() then
                subframes = button.subframes
                local _, _, _, _, className, classToken, _, online, dead = _G.GetRaidRosterInfo(i)
                if (online and not dead) and className then
                    local color = _G.CUSTOM_CLASS_COLORS[classToken]
                    subframes.name:SetTextColor(color.r, color.g, color.b)
                    subframes.level:SetTextColor(color.r, color.g, color.b)
                    subframes.class:SetTextColor(color.r, color.g, color.b)
                end
            end
        end
    end
end

do --[[ AddOns\Blizzard_RaidUI.xml ]]
    --[[ B261 Layer 2 (A-candidate, tasks.md 3.2.5), read from wow-ui-source
        (retail) and wow-ui-source-forever. RaidGroupButton1..40 are
        protected themselves: SecureUnitButtonTemplate
        (Blizzard_RaidUI/Mainline/Blizzard_RaidUI.xml:76; Forever :75, the
        same template). RaidGroupFrame_Update hides, moves and shows them on
        every roster change (Blizzard_RaidUI.lua:469-484, the same lines on
        Forever), in combat too. Blizzard never enables or disables them and
        never re-sets their state textures (only the class filter buttons
        are enabled and disabled, :108, :110); the only art is the template's
        NormalTexture and HighlightTexture (Blizzard_RaidUI.xml:205-210;
        Forever :204-209).
        Shape "flat": the engine's own state textures and nothing else. Not
        "panel": that makes a frame of Aurora's a child of the protected
        button and anchors the button's pressed, disabled and highlight
        textures to that frame's border pieces, so a region of a protected
        frame would hang from an unprotected one. What the engine does with
        that in combat cannot be read from source; "flat" creates no frame
        and anchors nothing, and the button's own regions are all it uses.
        This skin itself can run in combat: Blizzard loads Blizzard_RaidUI
        from GROUP_ROSTER_UPDATE (Blizzard_RaidFrame/Mainline/RaidFrame.lua:61-62;
        Forever :63-64),
        so the first roster change of a session runs it. Flat then makes
        only texture calls on the protected buttons, the kind Layer 1 made
        there too; the panel would add ClearAllPoints and SetPoint on their
        state textures in that moment.
        The name, level and class font strings are ARTWORK regions, as they
        were over Blizzard's NormalTexture. The Layer 1 class-colour border
        on hover goes with the backdrop. ]]
    function Skin.RaidGroupButtonTemplate(Button)
        Skin.TaintSafeFrameTypeButton(Button, "flat")
    end
    function Skin.RaidGroupSlotTemplate(Button)
        Button:ClearHighlightTexture()
        Base.SetBackdrop(Button, Color.button, 0)
        Button:SetBackdropBorderColor(Color.button, 0)

        Button:HookScript("OnEnter", function(dialog)
            dialog:SetBackdropBorderColor(Color.button, 1)
        end)
        Button:HookScript("OnLeave", function(dialog)
            dialog:SetBackdropBorderColor(Color.button, 0)
        end)
    end
    function Skin.RaidGroupTemplate(Frame)
        Frame:GetRegions():Hide()

        Base.SetBackdrop(Frame, Color.frame)
        Frame:SetBackdropBorderColor(Color.button)

        local name = Frame:GetName()
        _G[name.."Label"]:SetPoint("TOP", 0, 12)
        Skin.RaidGroupSlotTemplate(_G[name.."Slot1"])
        Skin.RaidGroupSlotTemplate(_G[name.."Slot2"])
        Skin.RaidGroupSlotTemplate(_G[name.."Slot3"])
        Skin.RaidGroupSlotTemplate(_G[name.."Slot4"])
        Skin.RaidGroupSlotTemplate(_G[name.."Slot5"])
    end
end

function private.AddOns.Blizzard_RaidUI()
    _G.hooksecurefunc("RaidGroupFrame_Update", Hook.RaidGroupFrame_Update)

    _G.RaidGroup1:SetPoint("TOPLEFT", 5, -58)
    _G.RaidGroup2:SetPoint("LEFT", _G.RaidGroup1, "RIGHT", 4, 0)
    for groupID = 1, _G.NUM_RAID_GROUPS do
        Skin.RaidGroupTemplate(_G["RaidGroup"..groupID])
    end

    for memberID = 1, _G.MAX_RAID_MEMBERS do
        Skin.RaidGroupButtonTemplate(_G["RaidGroupButton"..memberID])
    end
end
