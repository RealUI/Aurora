local _, private = ...
if private.shouldSkip() then return end

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Util = Aurora.Util

--[[ Mists (5.5.4) Scenario finder — same MoP-shell/modern-guts hybrid as
    the LFD pane: ScenarioFinderFrame hosting Queue (=ScenarioQueueFrame)
    with the scenario painting Bg, a WowStyle1 dropdown, ScrollFrameTemplate
    random panel, WoWScrollBoxList specific list and a MagicButton.
    Evidence: wow-ui-source-classic/Interface/AddOns/Blizzard_GroupFinder/
    Shared/ScenarioFinder.xml; structural reference: original MoP-era
    Aurora FrameXML/ScenarioFinder.lua (repo history).
]]

function private.FrameXML.ScenarioFinder()
    local ScenarioFinderFrame = _G.ScenarioFinderFrame
    if not ScenarioFinderFrame then return end

    Util.HideFrameTextures(ScenarioFinderFrame, true)
    if ScenarioFinderFrame.Inset then
        Skin.InsetFrameTemplate(ScenarioFinderFrame.Inset)
    end

    local Queue = ScenarioFinderFrame.Queue or _G.ScenarioQueueFrame
    if not Queue then return end

    -- scenario painting behind the random panel
    if Queue.Bg then
        Queue.Bg:SetAlpha(0)
    end
    if Queue.Dropdown then
        Skin.DropdownButton(Queue.Dropdown)
    end
    if _G.ScenarioQueueFrameFindGroupButton then
        Skin.MagicButtonTemplate(_G.ScenarioQueueFrameFindGroupButton)
    end

    local Specific = Queue.Specific
    if Specific then
        if Specific.ScrollFrame and Skin.WowScrollBoxList then
            Skin.WowScrollBoxList(Specific.ScrollFrame)
        end
        if Specific.ScrollBar and Skin.MinimalScrollBar then
            Skin.MinimalScrollBar(Specific.ScrollBar)
        end
    end

    -- random panel scroll (kept last, least-certain structure)
    local Random = Queue.Random
    if Random and Random.ScrollFrame and Random.ScrollFrame.ScrollBar
        and Skin.MinimalScrollBar then
        Skin.MinimalScrollBar(Random.ScrollFrame.ScrollBar)
    end
end
