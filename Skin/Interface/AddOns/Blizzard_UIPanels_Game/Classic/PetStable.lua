local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Base, Skin = Aurora.Base, Aurora.Skin
local Util = Aurora.Util

--[[ Classic-family pet stable (era/TBC/Mists).
    Evidence: Classic/PetStable.xml — sheet panel with the pet model, one
    current + stabled pet slots (PetStableSlotTemplate CheckButtons), buy
    button and money chips (coin sheets left stock).
]]

local function SkinPetSlot(name)
    local button = _G[name]
    if not button then return end

    local icon = _G[name.."Icon"] or _G[name.."IconTexture"] or button.Icon
    if icon then
        Base.CropIcon(icon)
    end
    local ring = _G[name.."NormalTexture"]
    if ring then
        ring:SetAlpha(0)
    end
end

function private.FrameXML.PetStable()
    local PetStableFrame = _G.PetStableFrame

    Util.HideFrameTextures(PetStableFrame, true)
    Skin.FrameTypeFrame(PetStableFrame)
    PetStableFrame:SetBackdropOption("offsets", {
        left = 10,
        right = 30,
        top = 0,
        bottom = 75,
    })

    SkinPetSlot("PetStableCurrentPet")
    local i = 1
    while _G["PetStableStabledPet"..i] do
        SkinPetSlot("PetStableStabledPet"..i)
        i = i + 1
    end

    Skin.UIPanelButtonTemplate(_G.PetStablePurchaseButton)
    Skin.UIPanelCloseButton(_G.PetStableFrameCloseButton)
end
