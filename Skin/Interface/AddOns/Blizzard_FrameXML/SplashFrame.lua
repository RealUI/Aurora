local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin

--do --[[ FrameXML\SplashFrame.lua ]]
--end

do --[[ FrameXML\SplashFrame.xml ]]
    Skin.SplashFeatureFrameTemplate = private.nop
end

function private.FrameXML.SplashFrame()
    local SplashFrame = _G.SplashFrame
    if not SplashFrame then return end

    if SplashFrame.BottomCloseButton then
        Skin.UIPanelButtonTemplate(SplashFrame.BottomCloseButton)
    end

    if SplashFrame.TopCloseButton then
        Skin.UIPanelCloseButton(SplashFrame.TopCloseButton)
    end
    if SplashFrame.Feature1 then
        Skin.SplashFeatureFrameTemplate(SplashFrame.Feature1)
    end
    if SplashFrame.Feature2 then
        Skin.SplashFeatureFrameTemplate(SplashFrame.Feature2)
    end
end
