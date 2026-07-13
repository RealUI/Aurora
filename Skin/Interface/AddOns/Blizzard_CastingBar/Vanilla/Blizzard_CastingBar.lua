local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin

--[[ Era casting bar (Blizzard_CastingBar addon; the player bar is the
    global CastingBarFrame here, not PlayerCastingBarFrame).
    Evidence: wow-ui-source-era/Interface/AddOns/Blizzard_CastingBar/
    Vanilla/CastingBarFrame.xml — same parentKeys as retail (Border,
    BorderShield, Text, Icon, Spark, Flash + an unnamed black background).

    TAINT-SAFE approach copied from the Mainline skin: only widget API
    calls; no Skin.FrameTypeStatusBar/Base.SetBackdrop (those write
    BackdropMixin methods onto the frame table, and Blizzard's
    CastingBarFrame code runs in contexts that must stay clean).

    The Small template is also skinned here so unit spell bars inheriting
    SmallCastingBarFrameTemplate (target/focus, Wave 3 UnitFrame work)
    auto-skin once their frames are passed in.
]]

do --[[ Blizzard_CastingBar\Vanilla\CastingBarFrame.xml ]]
    local function TaintSafeSkinStatusBar(StatusBar)
        -- Replace the status bar texture with a flat color
        StatusBar:SetStatusBarTexture(private.textures.plain)
        local tex = StatusBar:GetStatusBarTexture()
        if tex then
            tex:SetDrawLayer("BORDER")
        end

        -- Unnamed black half-alpha background is the first region
        local background = StatusBar:GetRegions()
        if background and background:IsObjectType("Texture") then
            background:SetColorTexture(0, 0, 0, 0.6)
        end

        StatusBar.Border:SetAlpha(0)
        StatusBar.BorderShield:SetAlpha(0)
        StatusBar.Spark:SetAlpha(0)

        StatusBar.Flash:SetAllPoints(StatusBar)
        StatusBar.Flash:SetColorTexture(1, 1, 1) -- static: not a theme color

        StatusBar.Text:ClearAllPoints()
        StatusBar.Text:SetPoint("CENTER")
    end

    function Skin.CastingBarFrameTemplate(StatusBar)
        TaintSafeSkinStatusBar(StatusBar)
    end
    function Skin.SmallCastingBarFrameTemplate(StatusBar)
        TaintSafeSkinStatusBar(StatusBar)
    end
end

function private.AddOns.Blizzard_CastingBar()
    Skin.CastingBarFrameTemplate(_G.CastingBarFrame)
end
