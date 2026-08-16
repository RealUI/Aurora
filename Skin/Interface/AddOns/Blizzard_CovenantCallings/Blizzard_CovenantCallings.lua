local _, private = ...
if private.shouldSkip() then return end

local Aurora = private.Aurora
local Base, Hook, Skin = Aurora.Base, Aurora.Hook, Aurora.Skin
local Util = Aurora.Util

do
    Hook.GarrisonLandingPageMixin = {}
    function Hook.GarrisonLandingPageMixin:SetupCovenantCallings()
        local callingsFrame = self.CovenantCallings
        if not callingsFrame then
            return
        end

        Skin.CovenantCallingsTemplate(callingsFrame)
        Util.WrapPoolAcquire(callingsFrame.pool, Skin.CovenantCallingQuestTemplate)
    end

    function Skin.CovenantCallingQuestTemplate(Frame)
        if private.IsSkinned(Frame) then
            return
        end

        private.SetSkinned(Frame, true)
        Frame._auroraIconBorder = Base.CropIcon(Frame.Icon, Frame)
    end

    function Skin.CovenantCallingsTemplate(Frame)
        if private.IsSkinned(Frame) then
            return
        end

        private.SetSkinned(Frame, true)

        if Frame.Background then
            Frame.Background:SetAlpha(0)
        end
        if Frame.Decor then
            Frame.Decor:SetAlpha(0)
        end
    end
end

function private.AddOns.Blizzard_CovenantCallings()
    _G.hooksecurefunc(_G.GarrisonLandingPageMixin, "SetupCovenantCallings", Hook.GarrisonLandingPageMixin.SetupCovenantCallings)

    if _G.GarrisonLandingPage and _G.GarrisonLandingPage.CovenantCallings then
        Hook.GarrisonLandingPageMixin.SetupCovenantCallings(_G.GarrisonLandingPage)
    end
end
