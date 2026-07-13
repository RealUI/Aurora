local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Util = Aurora.Util

--[[ Classic-family guild registrar (era/TBC/Mists).
    Evidence: Classic/GuildRegistrarFrame.xml — QuestFrame-style NPC panel
    (parchment sheets, greeting rows via QuestTitleButtonTemplate, guild
    name edit box, purchase/cancel). Text colors flow through the fonts
    already recolored for the quest panels; verify in-game.
]]

function private.FrameXML.GuildRegistrarFrame()
    local GuildRegistrarFrame = _G.GuildRegistrarFrame

    Util.HideFrameTextures(GuildRegistrarFrame, true)
    Skin.FrameTypeFrame(GuildRegistrarFrame)
    GuildRegistrarFrame:SetBackdropOption("offsets", {
        left = 10,
        right = 30,
        top = 0,
        bottom = 75,
    })

    Util.HideFrameTextures(_G.GuildRegistrarNpcNameFrame)
    Util.HideFrameTextures(_G.GuildRegistrarGreetingFrame)
    Util.HideFrameTextures(_G.GuildRegistrarPurchaseFrame)

    local editBox = _G.GuildRegistrarFrameEditBox
    if editBox then
        Util.HideFrameTextures(editBox)
        Skin.FrameTypeEditBox(editBox)
    end

    for _, name in ipairs({"GuildRegistrarFrameGoodbyeButton", "GuildRegistrarFrameCancelButton", "GuildRegistrarFramePurchaseButton"}) do
        local button = _G[name]
        if button then
            Skin.UIPanelButtonTemplate(button)
        end
    end
end
