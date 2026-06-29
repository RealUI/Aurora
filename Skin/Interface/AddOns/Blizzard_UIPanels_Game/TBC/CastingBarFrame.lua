local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Color = Aurora.Color

do --[[ Classic\CastingBarFrame.xml ]]
    -- TBC CastingBarFrame uses CastingBarFrameTemplate which has
    -- .Border (UI-CastingBar-Border) and .Flash (UI-CastingBar-Flash)
    -- as parentKey textures. Skin by hiding border art and styling
    -- the StatusBar minimally with a flat texture.
    local function SkinClassicCastingBar(castBar)
        if not castBar then return end

        -- Replace the status bar texture with a flat color
        castBar:SetStatusBarTexture(private.textures.plain)
        local tex = castBar:GetStatusBarTexture()
        if tex then
            tex:SetDrawLayer("BORDER")
        end

        -- Hide the ornate border art
        if castBar.Border then
            castBar.Border:Hide()
        end

        -- Hide the flash texture (it uses ADD blend for spell finish glow)
        if castBar.Flash then
            castBar.Flash:SetAllPoints(castBar)
            castBar.Flash:SetColorTexture(1, 1, 1)
        end

        -- Hide the spark glow
        if castBar.Spark then
            castBar.Spark:SetAlpha(0)
        end

        -- Hide background texture if present
        if castBar.Background then
            castBar.Background:Hide()
        end

        -- Center the text
        if castBar.Text then
            castBar.Text:ClearAllPoints()
            castBar.Text:SetPoint("CENTER")
        end

        -- Apply a minimal backdrop
        Base.SetBackdrop(castBar, Color.frame)
    end

    function private.FrameXML.CastingBarFrame()
        -- Player cast bar (CastingBarFrameTemplate instance)
        SkinClassicCastingBar(_G.PlayerCastingBarFrame)

        -- Pet cast bar if it exists
        SkinClassicCastingBar(_G.PetCastingBarFrame)
    end
end
