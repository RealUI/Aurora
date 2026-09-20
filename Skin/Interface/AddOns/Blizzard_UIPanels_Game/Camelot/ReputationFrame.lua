local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin

-- Row templates and row-mixin hooks are shared with the Mainline skin and live
-- in Skin\shared\ReputationFrame.lua (D3.1). Two things differ here:
--
--  1. Anchoring. Camelot's CharacterFrame inherits PortraitFrameBaseTemplate,
--     not ButtonFrameTemplate, so it has no Inset -- the content anchor is
--     CharacterFrameLeftPaneHost (see T2.0.1).
--  2. The detail pane. Camelot's ReputationDetailFrame inherits
--     CharacterFrameSidePaneTemplate: it slides into the character frame's
--     right pane rather than floating, so it has no Border, CloseButton,
--     Title, Divider or ScrollingDescription. It adds a StandingBar.
--
-- The five row template names are identical, which is why the 1.00 jaccard in
-- docs/Aurora-Forever-Camelot-Divergence.md §8 said "near-verbatim" and was
-- wrong: the templates match, the frame around them does not.

function private.FrameXML.ReputationFrame()
    local ReputationFrame = _G.ReputationFrame
    ---------------------
    -- ReputationFrame --
    ---------------------
    if ReputationFrame.filterDropdown then
        Skin.DropdownButton(ReputationFrame.filterDropdown)
    end

    Skin.WowScrollBoxList(ReputationFrame.ScrollBox)
    Skin.MinimalScrollBar(ReputationFrame.ScrollBar)

    -- Not re-anchored. The Mainline skin pins the ScrollBox to
    -- CharacterFrame.Inset with offsets measured against the frame Aurora
    -- reshapes there; Camelot keeps Blizzard's own pane geometry, and a
    -- partial re-anchor onto LeftPaneHost only distorts it. Same rule as the
    -- Camelot PaperDollFrame skin.

    ---------------------------
    -- ReputationDetailFrame --
    ---------------------------
    local ReputationDetailFrame = ReputationFrame.ReputationDetailFrame
    if ReputationDetailFrame then
        -- StandingBar inherits Camelot's ReputationBarTemplate, which is a
        -- ColoredProgressBarTemplate -- a Frame with a masked Fill, not a
        -- StatusBar. SharedSkins.ReputationBar dispatches on the object type;
        -- calling Skin.FrameTypeStatusBar directly here threw
        -- "SetStatusBarTexture is not a function" and cost the whole skin.
        private.SharedSkins.ReputationBar(ReputationDetailFrame.StandingBar)

        if ReputationDetailFrame.MakeInactiveCheckbox then
            Skin.UICheckButtonTemplate(ReputationDetailFrame.MakeInactiveCheckbox)
        end
        if ReputationDetailFrame.AtWarCheckbox then
            Skin.UICheckButtonTemplate(ReputationDetailFrame.AtWarCheckbox)
        end
        if ReputationDetailFrame.WatchFactionCheckbox then
            Skin.UICheckButtonTemplate(ReputationDetailFrame.WatchFactionCheckbox)
        end
        if ReputationDetailFrame.ViewRenownButton then
            Skin.UIPanelButtonTemplate(ReputationDetailFrame.ViewRenownButton)
        end
    end

    private.SharedSkins.ReputationRows()
end
