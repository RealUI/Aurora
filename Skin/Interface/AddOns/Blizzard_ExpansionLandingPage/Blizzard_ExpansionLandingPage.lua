local _, private = ...
if private.shouldSkip() then return end

local Aurora = private.Aurora
local Base, Skin = Aurora.Base, Aurora.Skin

local function StripRunesOfPowerDecorations(frame)
    if frame.Background then frame.Background:SetAlpha(0) end
    if frame.BorderOverlay then frame.BorderOverlay:SetAlpha(0) end
    if frame.NineSlice then Base.StripBlizzardTextures(frame.NineSlice) end
    if frame.Inset then Base.StripBlizzardTextures(frame.Inset) end
end

function private.AddOns.Blizzard_ExpansionLandingPage()
    if not _G.ExpansionLandingPage then return end

    _G.ExpansionLandingPage:HookScript("OnShow", function(self)
        local overlay = self.Overlay and self.Overlay.MidnightLandingOverlay
        if not overlay or overlay._auroraSkinned then return end
        overlay._auroraSkinned = true

        if overlay.CloseButton then
            Skin.UIPanelCloseButton(overlay.CloseButton)
        end

        local runesFrame = overlay.RunesOfPowerFrame
        if runesFrame then
            StripRunesOfPowerDecorations(runesFrame)
            -- ApplyLayout is called on each OnShow and re-adds atlas decorations.
            -- Hook it to re-strip every time.
            if runesFrame.ApplyLayout then
                hooksecurefunc(runesFrame, "ApplyLayout", function(self)
                    StripRunesOfPowerDecorations(self)
                end)
            end
        end
    end)
end
