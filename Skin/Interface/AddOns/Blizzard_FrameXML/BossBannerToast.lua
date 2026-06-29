local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

-- [[ Core ]]
local Aurora = private.Aurora
local Hook = Aurora.Hook

do --[[ FrameXML\BossBannerToast.lua ]]
    function Hook.BossBanner_ConfigureLootFrame(lootFrame, data)
        lootFrame.PlayerName:SetTextColor(_G.CUSTOM_CLASS_COLORS[data.className]:GetRGB())
    end
end

--do --[[ FrameXML\BossBannerToast.xml ]]
--end

function private.FrameXML.BossBannerToast()
    -- BossBanner_ConfigureLootFrame is Mainline-only (boss kill banners)
    if _G.BossBanner_ConfigureLootFrame then
        _G.hooksecurefunc("BossBanner_ConfigureLootFrame", Hook.BossBanner_ConfigureLootFrame)
    end
end
