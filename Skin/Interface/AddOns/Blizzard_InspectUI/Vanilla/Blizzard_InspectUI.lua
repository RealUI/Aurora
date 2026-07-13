local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs select

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Util = Aurora.Util

--[[ Era inspect frame (LoD, opens on inspecting a player).
    Evidence: wow-ui-source-era/Interface/AddOns/Blizzard_InspectUI/
    Vanilla/Blizzard_InspectUI.xml (plain root + CharacterFrameTab buttons)
    + Classic/InspectPaperDollFrame.xml (19 Inspect{slot}Slot item buttons,
    same layout as the character frame). Talent/honor tabs reuse art
    handled by their own shared code; first pass covers root + paperdoll.
]]

local slotNames = {
    "Head", "Neck", "Shoulder", "Back", "Chest", "Shirt", "Tabard",
    "Wrist", "Hands", "Waist", "Legs", "Feet", "Finger0", "Finger1",
    "Trinket0", "Trinket1", "MainHand", "SecondaryHand", "Ranged",
}

function private.AddOns.Blizzard_InspectUI()
    local InspectFrame = _G.InspectFrame
    if not InspectFrame then return end

    -- InspectFrame IS a ButtonFrameTemplate (unlike CharacterFrame) — full
    -- edge-to-edge backdrop, no art-band offsets. Sweep the extra root art
    -- (InspectFramePortrait circle) BEFORE the template skin.
    Util.HideFrameTextures(InspectFrame, true)
    Skin.ButtonFrameTemplate(InspectFrame)

    -- The portrait is re-set (and re-shown) when an inspect target loads
    local portrait = _G.InspectFramePortrait
    if portrait then
        portrait:SetAlpha(0)
        InspectFrame:HookScript("OnShow", function()
            portrait:SetAlpha(0)
        end)
    end

    local i = 1
    while _G["InspectFrameTab"..i] do
        Skin.CharacterFrameTabButtonTemplate(_G["InspectFrameTab"..i])
        i = i + 1
    end

    -- Honor tab: section border sheets are unnamed textures on the root
    if _G.InspectHonorFrame then
        Util.HideFrameTextures(_G.InspectHonorFrame)
        local bar = _G.InspectHonorFrameProgressBar
        if bar then
            Util.HideFrameTextures(bar)
            Skin.FrameTypeStatusBar(bar)
        end
    end

    -- Paperdoll tab
    if _G.InspectPaperDollFrame then
        Util.HideFrameTextures(_G.InspectPaperDollFrame, true)

        -- inner torn-edge border around the model
        if _G.InspectModelFrame then
            Util.HideFrameTextures(_G.InspectModelFrame)
        end

        for _, slot in ipairs(slotNames) do
            local name = "Inspect"..slot.."Slot"
            local button = _G[name]
            if button then
                -- The inspect slot templates carry ornate plate art as BOTH
                -- a named $parentFrame texture AND unnamed decor textures
                -- (Char-Slot-Bottom-* separators on the weapon row) — sweep
                -- every non-icon, non-state texture BEFORE the backdrop.
                local iconTexture = _G[name.."IconTexture"]
                local normal = button:GetNormalTexture()
                local pushed = button:GetPushedTexture()
                local highlight = button:GetHighlightTexture()
                for j = 1, select("#", button:GetRegions()) do
                    local region = select(j, button:GetRegions())
                    if region:IsObjectType("Texture") and region ~= iconTexture
                        and region ~= pushed and region ~= highlight then
                        region:SetAlpha(0)
                    end
                end

                Skin.FrameTypeItemButton(button)
                if normal then
                    normal:SetAlpha(0)
                end
            end
        end
    end
end
