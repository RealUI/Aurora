local _, private = ...

-- luacheck: globals _G

local Skin = private.Aurora.Skin

-- B53: no Init hook here. An earlier one re-ran LootHistoryElementMixin:Init
-- from an Item:ContinueOnItemLoad callback so uncached drops got their name and
-- icon. Init writes self.dropInfo, which SetTooltip reads on every hover, so the
-- re-run left each fresh LFR row tainted. Blizzard re-inits rows securely on
-- LOOT_HISTORY_UPDATE_DROP; a briefly blank row is the lesser cost.

do --[[ FrameXML\LootHistory.xml ]]
    function Skin.LootHistoryElementTemplate(self)
        -- Hide the Blizzard art background textures that obscure ItemName text
        -- against Aurora's dark frame backdrop.
        self.BackgroundArtFrame.NameFrame:Hide()
        self.BackgroundArtFrame.BorderFrame:Hide()
    end
end

function private.FrameXML.LootHistory()
    _G.hooksecurefunc(_G.LootHistoryElementMixin, "OnLoad", Skin.LootHistoryElementTemplate)
    local origLayout = _G.ResizeLayoutMixin.Layout
    _G.LootHistoryRollTooltipLineMixin.Layout = function(self)
        local ok = _G.pcall(origLayout, self)
        if not ok then
            self:SetSize(200, 14)
        end
        if self.MarkClean then
            self:MarkClean()
        end
    end
end
