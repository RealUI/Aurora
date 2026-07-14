local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs select

--[[ Core ]]
local Aurora = private.Aurora
local Base, Skin = Aurora.Base, Aurora.Skin
local Color = Aurora.Color

--[[ Mists (5.5.4) challenge modes pane — third PVEFrame tab. Written
    blind from evidence (needs a level-90 character to fully exercise),
    so everything is guarded and non-fatal. The challenge artwork
    painting (details.bg) is kept as content. Evidence:
    wow-ui-source-classic/Interface/AddOns/Blizzard_ChallengesUI/Mists/
    Blizzard_ChallengesUI.xml.
]]

function private.AddOns.Blizzard_ChallengesUI()
    local ChallengesFrame = _G.ChallengesFrame
    if not ChallengesFrame then return end

    if _G.ChallengesFrameInset then
        Skin.InsetFrameTemplate(_G.ChallengesFrameInset)
    end

    local details = ChallengesFrame.details
    if details then
        -- strip the decorative besttime plate + divider strips, keep the
        -- challenge painting
        for i = 1, _G.select("#", details:GetRegions()) do
            local region = _G.select(i, details:GetRegions())
            if region:GetObjectType() == "Texture" and region ~= details.bg then
                region:SetAlpha(0)
            end
        end

        for i = 1, 5 do
            local row = details["RewardRow"..i]
            if row then
                if row.Bg then
                    row.Bg:SetAlpha(0)
                end
                for _, key in ipairs({"Reward1", "Reward2"}) do
                    local reward = row[key]
                    if reward and reward.Icon then
                        Base.CropIcon(reward.Icon, reward)
                    end
                end
            end
        end
    end

    -- dungeon list rows: flatten the selection if rows exist by name
    local index = 1
    local row = _G["ChallengesFrameDungeonButton"..index]
    while row do
        if row.selectedTex then
            local r, g, b = Color.highlight:GetRGB()
            row.selectedTex:SetColorTexture(r, g, b, 0.2)
        end
        index = index + 1
        row = _G["ChallengesFrameDungeonButton"..index]
    end
end
