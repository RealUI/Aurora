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

    --[[ B261, AT-D20 (tasks.md 5.4.1), read from wow-ui-source (retail) and
        wow-ui-source-forever (the same template; Forever's lines are given
        where they differ). RaidGroup1Slot1..RaidGroup8Slot5 are plain buttons
        (RaidGroupSlotTemplate, Blizzard_RaidUI.xml:212-226; Forever
        :211-225), but an occupied slot is protected: RaidGroupFrame_Update
        anchors the secure RaidGroupButton to it (Blizzard_RaidUI.lua:469-470),
        and a frame that a protected frame is anchored to becomes protected
        itself, as does its RaidGroup frame. Blizzard re-anchors on every
        roster change, in combat too, and when a member is dragged (:594,
        :604; Forever :595, :605).
        Layer 1 put a backdrop (its methods and fields) and two HookScripts
        on every slot. Both are gone. What is left is the slot's own
        highlight texture: the engine shows it on hover, and Blizzard locks
        it on the drop target while a member is dragged (:532-541). Layer 1
        had cleared it, so the drop target showed nothing.
        Aurora sets its file and tint once, when Blizzard_RaidUI loads, which
        can be in combat (Blizzard_RaidFrame/Mainline/RaidFrame.lua:58-62;
        Forever :60-64). No call made here is a protected function (none
        carries IsProtectedFunction in Blizzard_APIDocumentationGenerated).
        Nothing is anchored to the slot, so its protection is not changed.
        Look: at rest the slot shows nothing of Aurora's, as before (Layer 1's
        fill and border were at alpha 0). Hover adds white at the Layer 2
        hover alpha (LAYER2_HOVER_ALPHA in Skin/skin.lua), as on the member
        rows. Layer 1's grey border on hover is dropped: it needed the two
        hooks. ]]
    local SLOT_HOVER_ALPHA = 0.08
    function Skin.RaidGroupSlotTemplate(Button)
        Button:SetHighlightTexture(private.textures.plain, "ADD")
        local highlight = Button:GetHighlightTexture()
        highlight:SetVertexColor(1, 1, 1)
        highlight:SetAlpha(SLOT_HOVER_ALPHA)
    end
    --[[ B261, AT-D21 (tasks.md 5.4.1), read from wow-ui-source (retail) and
        wow-ui-source-forever. RaidGroup1..8 (RaidGroupTemplate,
        Blizzard_RaidUI.xml:227-280; Forever :226-279) are protected in a
        raid: a group with an occupied slot holds a protected child (see the
        slots above). RaidGroupFrame_Update calls Show or Hide on every group
        on every roster change (Blizzard_RaidUI.lua:236, :243), in combat
        too, and keeps its own nextIndex on them (:250, :306, :477). It
        never walks a group's children or reads any other field; the drag
        code reads only GetParent(), GetID(), GetName() and nextIndex
        (:597-606; Forever :598-607).
        Layer 1 put Aurora's backdrop on the group frame itself: its methods
        and fields (_backdropInfo, the palette keys). The box is now drawn
        by a frame of Aurora's: a child of the group, so it shows and hides
        with it, at the group's own frame level, so the slots (one level up)
        and member rows (two up, :567-568) draw over it as they did over the
        group's own backdrop. It is a plain frame: no mouse, no name.
        Calls, and what each touches:
        - Frame:GetRegions():Hide(): the group's outline texture, a region
          (Region:Hide is not a protected function), as before.
        - CreateFrame("Frame", nil, Frame): a new frame; the group only gains
          an unprotected child, which leaves its protection as it was.
        - box:SetAllPoints(Frame), box:SetFrameLevel(...): calls on Aurora's
          frame, which is not protected; it is anchored to the group, never
          the group to it. Frame:GetFrameLevel() only reads.
        - Base.SetBackdrop(box, ...), box:SetBackdropBorderColor(...): on
          Aurora's frame; it carries the methods, fields and the palette
          registration.
        So nothing here is a protected call on a group, also when the skin
        runs late (Skin/init.lua:366-369) with a group already protected. ]]
    function Skin.RaidGroupTemplate(Frame)
        Frame:GetRegions():Hide()

        local box = _G.CreateFrame("Frame", nil, Frame)
        box:SetAllPoints(Frame)
        box:SetFrameLevel(Frame:GetFrameLevel())
        Base.SetBackdrop(box, Color.frame)
        box:SetBackdropBorderColor(Color.button)

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
