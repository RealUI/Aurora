local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Color, Skin = Aurora.Color, Aurora.Skin

local function SkinTalkingHeadFrame(Frame)
    if not Frame then return end

    local textBackground = Frame.BackgroundFrame and Frame.BackgroundFrame.TextBackground
    if textBackground then
        textBackground:SetAtlas(nil)
        textBackground:SetTexture("Interface\\Buttons\\WHITE8x8")
        local r, g, b = Color.panelBg:GetRGB()
        textBackground:SetVertexColor(r, g, b)
        textBackground:SetAlpha(0.92)

        -- Register for palette refresh on mode switch
        Color.RegisterPaletteTexture(textBackground, "panelBg", 0.92)
    end

    local portrait = Frame.PortraitFrame and Frame.PortraitFrame.Portrait
    if portrait then
        portrait:SetAlpha(0)
    end

    local model = Frame.MainFrame and Frame.MainFrame.Model
    if model and model.PortraitBg then
        model.PortraitBg:SetAlpha(0)
    end

    local sheen = Frame.MainFrame and Frame.MainFrame.Sheen
    if sheen then
        sheen:SetAlpha(0)
    end

    local textSheen = Frame.MainFrame and Frame.MainFrame.TextSheen
    if textSheen then
        textSheen:SetAlpha(0)
    end

    local overlay = Frame.MainFrame and Frame.MainFrame.Overlay
    if overlay then
        if overlay.Glow_TopBar then
            overlay.Glow_TopBar:SetAlpha(0)
        end
        if overlay.Glow_LeftBar then
            overlay.Glow_LeftBar:SetAlpha(0)
        end
        if overlay.Glow_RightBar then
            overlay.Glow_RightBar:SetAlpha(0)
        end
    end

    local closeButton = Frame.MainFrame and Frame.MainFrame.CloseButton
    if closeButton then
        Skin.TaintSafeUIPanelCloseButton(closeButton)
    end
end

function private.FrameXML.TalkingHeadUI()
    local talkingHeadFrame = _G.TalkingHeadFrame
    if not talkingHeadFrame then return end

    SkinTalkingHeadFrame(talkingHeadFrame)

    if talkingHeadFrame.PlayCurrent then
        _G.hooksecurefunc(talkingHeadFrame, "PlayCurrent", SkinTalkingHeadFrame)
    end
end
