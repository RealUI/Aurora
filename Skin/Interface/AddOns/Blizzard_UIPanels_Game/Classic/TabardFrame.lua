local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Util = Aurora.Util

--[[ Classic-family tabard designer (era/TBC/Mists).
    Evidence: Classic/TabardFrame.xml — classic sheet panel around the
    TabardModel, 5 customization rows (left/right arrow buttons kept —
    small round art), cost chip, money inset, Accept/Cancel.
]]

function private.FrameXML.TabardFrame()
    local TabardFrame = _G.TabardFrame

    Util.HideFrameTextures(TabardFrame, true)
    Skin.FrameTypeFrame(TabardFrame)
    TabardFrame:SetBackdropOption("offsets", {
        left = 10,
        right = 30,
        top = 0,
        bottom = 75,
    })

    Skin.TooltipBackdropTemplate(_G.TabardFrameCostFrame)
    Skin.InsetFrameTemplate(_G.TabardFrameMoneyInset)
    Util.HideFrameTextures(_G.TabardFrameMoneyBg)

    Skin.UIPanelButtonTemplate(_G.TabardFrameAcceptButton)
    Skin.UIPanelButtonTemplate(_G.TabardFrameCancelButton)

    local i = 1
    while _G["TabardFrameCustomization"..i] do
        Util.HideFrameTextures(_G["TabardFrameCustomization"..i])
        i = i + 1
    end
end
