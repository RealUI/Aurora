local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin

--[[ Anniversary (TBC) casting bars — the RETAIL frame set
    (PlayerCastingBarFrame + OverlayPlayerCastingBarFrame) lives inside
    Blizzard_UIPanels_Game on 2.5.6 (Classic\CastingBarFrame.xml; same
    parentKeys as retail: Border/BorderShield/Text/Icon/Spark/Flash). Era
    keeps its own Blizzard_CastingBar addon skin — this TOC path is not
    listed on era, so this file never loads there.

    TAINT-SAFE approach identical to the Mainline and era skins: widget API
    only, no FrameTypeStatusBar/backdrop table writes
    (OverlayPlayerCastingBarFrame sits in the secure action bar hierarchy).
]]

do --[[ Classic\CastingBarFrame.xml ]]
    local function TaintSafeSkinStatusBar(StatusBar)
        StatusBar:SetStatusBarTexture(private.textures.plain)
        local tex = StatusBar:GetStatusBarTexture()
        if tex then
            tex:SetDrawLayer("BORDER")
        end

        local background = StatusBar:GetRegions()
        if background and background:IsObjectType("Texture") then
            background:SetColorTexture(0, 0, 0, 0.6)
        end

        if StatusBar.Border then StatusBar.Border:SetAlpha(0) end
        if StatusBar.BorderShield then StatusBar.BorderShield:SetAlpha(0) end
        if StatusBar.Spark then StatusBar.Spark:SetAlpha(0) end

        if StatusBar.Flash then
            StatusBar.Flash:SetAllPoints(StatusBar)
            StatusBar.Flash:SetColorTexture(1, 1, 1) -- static: not a theme color
        end

        if StatusBar.Text then
            StatusBar.Text:ClearAllPoints()
            StatusBar.Text:SetPoint("CENTER")
        end
    end

    function Skin.CastingBarFrameTemplate(StatusBar)
        TaintSafeSkinStatusBar(StatusBar)
    end
    function Skin.SmallCastingBarFrameTemplate(StatusBar)
        TaintSafeSkinStatusBar(StatusBar)
    end
end

function private.FrameXML.CastingBarFrame()
    if _G.PlayerCastingBarFrame then
        Skin.CastingBarFrameTemplate(_G.PlayerCastingBarFrame)
    end
    if _G.OverlayPlayerCastingBarFrame then
        Skin.CastingBarFrameTemplate(_G.OverlayPlayerCastingBarFrame)
    end
end
