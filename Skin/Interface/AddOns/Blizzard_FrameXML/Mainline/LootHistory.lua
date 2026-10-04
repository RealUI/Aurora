local _, private = ...

-- luacheck: globals _G next

local Aurora = private.Aurora
local Base, Skin = Aurora.Base, Aurora.Skin
local Color = Aurora.Color

-- B53: no Init hook here. An earlier one re-ran LootHistoryElementMixin:Init
-- from an Item:ContinueOnItemLoad callback so uncached drops got their name and
-- icon. Init writes self.dropInfo, which SetTooltip reads on every hover, so the
-- re-run left each fresh LFR row tainted. Blizzard re-inits rows securely on
-- LOOT_HISTORY_UPDATE_DROP; a briefly blank row is the lesser cost.
--
-- Nor a Layout override on LootHistoryRollTooltipLineMixin. Writing into that
-- Blizzard mixin tainted every roll-line frame built from it: the mixin copy
-- reads the tainted Layout and writes the keys after it (Init included) tainted,
-- so every loot tooltip ran tainted from its first line. The override only
-- existed to swallow the secret-arithmetic that taint caused.

do --[[ FrameXML\LootHistory.xml ]]
    function Skin.LootHistoryElementTemplate(self)
        -- Hide the Blizzard art background textures that obscure ItemName text
        -- against Aurora's dark frame backdrop.
        self.BackgroundArtFrame.NameFrame:Hide()
        self.BackgroundArtFrame.BorderFrame:Hide()

        -- A card behind each row in place of the hidden art, so rows read as
        -- separate entries. It lives on a child frame of our own and nothing is
        -- stored on the row: SetTooltip reads the row's fields on every hover,
        -- and a tainted one taints the tooltip (B53; same cure as B72).
        local card = _G.CreateFrame("Frame", nil, self)
        card:SetPoint("TOPLEFT", 2, -2)
        card:SetPoint("BOTTOMRIGHT", -2, 2)
        card:SetFrameLevel(self.BackgroundArtFrame:GetFrameLevel())
        Base.SetBackdrop(card, Color.button, 0.3)
    end
end

function private.FrameXML.LootHistory()
    _G.hooksecurefunc(_G.LootHistoryElementMixin, "OnLoad", Skin.LootHistoryElementTemplate)

    -- B157: the window chrome was never skinned (Blizzard title bar and red
    -- close button). Panel art and the close button only: these write to the
    -- NineSlice, Bg and button children, never to the window, the rows or the
    -- roll tooltip path that B53 cleaned up.
    local LootHistoryFrame = _G.GroupLootHistoryFrame
    if LootHistoryFrame then
        Skin.DefaultPanelFlatTemplate(LootHistoryFrame)
        if LootHistoryFrame.ClosePanelButton then
            Skin.UIPanelCloseButton(LootHistoryFrame.ClosePanelButton)
        end

        -- The resize tab under the bottom edge: one unnamed OVERLAY texture
        -- (lootroll-resizehandle). Its scripts only StartSizing the window,
        -- which is not protected, so a plain Aurora button look is safe.
        local ResizeButton = LootHistoryFrame.ResizeButton
        if ResizeButton then
            for _, region in next, {ResizeButton:GetRegions()} do
                if region:IsObjectType("Texture") then
                    region:SetAlpha(0)
                end
            end
            Skin.FrameTypeButton(ResizeButton)
        end
    end
end
