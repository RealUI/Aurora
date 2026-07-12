local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin

--do --[[ FrameXML\CastingBarFrame.lua ]]
--end

do --[[ FrameXML\CastingBarFrame.xml ]]
    -- TAINT-SAFE: The original Skin.CastingBarFrameTemplate called
    -- Skin.FrameTypeStatusBar → Base.SetBackdrop → Base.CreateBackdrop
    -- which writes BackdropMixin methods directly onto the StatusBar
    -- frame table.  OverlayPlayerCastingBarFrame lives in the secure
    -- action bar hierarchy; tainting it propagates "secret number"
    -- errors to ActionButton.lua:609 (pressAndHoldAction comparison)
    -- and CastingBarFrame.lua:212 (forbidden table index).
    --
    -- The safe approach: only use widget API calls (SetStatusBarTexture,
    -- SetStatusBarColor, Hide, SetAlpha) that don't write addon-owned
    -- state onto the frame.
    local function TaintSafeSkinStatusBar(StatusBar)
        -- Replace the status bar texture with a flat color
        StatusBar:SetStatusBarTexture(private.textures.plain)
        local tex = StatusBar:GetStatusBarTexture()
        if tex then
            tex:SetDrawLayer("BORDER")
        end
        -- Hide Blizzard border/background textures
        if StatusBar.Background then StatusBar.Background:Hide() end
        if StatusBar.Border then StatusBar.Border:SetAlpha(0) end
        if StatusBar.BorderShield then StatusBar.BorderShield:SetAlpha(0) end
    end

    function Skin.CastingBarFrameTemplate(StatusBar)
        TaintSafeSkinStatusBar(StatusBar)

        StatusBar:GetRegions():Hide()
        StatusBar.Border:Hide()
        StatusBar.Text:ClearAllPoints()
        StatusBar.Text:SetPoint("CENTER")
        StatusBar.Spark:SetAlpha(0)

        StatusBar.Flash:SetAllPoints(StatusBar)
        StatusBar.Flash:SetColorTexture(1, 1, 1) -- static: not a theme color
    end
    function Skin.SmallCastingBarFrameTemplate(StatusBar)
        TaintSafeSkinStatusBar(StatusBar)

        StatusBar:GetRegions():Hide()
        StatusBar.Border:Hide()
        StatusBar.Text:ClearAllPoints()
        StatusBar.Text:SetPoint("CENTER")
        StatusBar.Spark:SetAlpha(0)

        StatusBar.Flash:SetAllPoints(StatusBar)
        StatusBar.Flash:SetColorTexture(1, 1, 1) -- static: not a theme color
    end
end

function private.FrameXML.CastingBarFrame()
    Skin.CastingBarFrameTemplate(_G.PlayerCastingBarFrame)
    Skin.CastingBarFrameTemplate(_G.OverlayPlayerCastingBarFrame)
end
