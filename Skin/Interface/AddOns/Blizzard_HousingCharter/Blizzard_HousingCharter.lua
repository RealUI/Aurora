local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals pairs

--[[ Core ]]
local Aurora = private.Aurora
local Base, Skin = Aurora.Base, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

do --[[ AddOns\Blizzard_HousingCharter\Blizzard_HousingCharter.xml ]]
    function Skin.HousingCharterSignatureTemplate(Frame)
        -- Signature entries are minimal (just a font string), no heavy skinning needed
    end
end

function private.AddOns.Blizzard_HousingCharter()
    ----
    -- HousingCharterFrame
    ----
    local HousingCharterFrame = _G.HousingCharterFrame

    Base.SetBackdrop(HousingCharterFrame, Color.frame)

    -- Hide decorative textures
    HousingCharterFrame.Border:SetAlpha(0)
    HousingCharterFrame.Background:SetAlpha(0)
    HousingCharterFrame.Header:SetAlpha(0)

    -- SignaturesFrame: hide background atlas
    local SignaturesFrame = HousingCharterFrame.SignaturesFrame
    for _, region in pairs({SignaturesFrame:GetRegions()}) do
        if region:IsObjectType("Texture") then
            region:SetAlpha(0)
        end
    end

    -- Buttons
    Skin.UIPanelButtonTemplate(HousingCharterFrame.RequestButton)
    Skin.UIPanelButtonTemplate(HousingCharterFrame.SettingsButton)
    Skin.UIPanelButtonTemplate(HousingCharterFrame.CloseButton)

    -- Wrap signature pool (created in OnLoad, which fires before ADDON_LOADED)
    Util.WrapPoolAcquire(HousingCharterFrame.signaturePool, function(frame)
        if private.IsSkinned(frame) then return end
        private.SetSkinned(frame, true)
    end)

    ----
    -- HousingCharterRequestSignatureDialog
    ----
    local Dialog = _G.HousingCharterRequestSignatureDialog

    Skin.FrameTypeFrame(Dialog)
    Skin.FrameTypeButton(Dialog.ConfirmButton)
    Skin.FrameTypeButton(Dialog.CancelButton)
end
