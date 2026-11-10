local _, private = ...
if private.shouldSkip() then return end
-- B224: Forever shows this same TaxiFrame for its classic taxi maps
-- (uiMapSystem Taxi), but isRetail is also true there; only retail skips
if private.isRetail and not private.isForever then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Util = Aurora.Util

--[[ Mists (5.5.4) flight master — the Shared\ TaxiFrame is a MODERN
    BasicFrameTemplateWithInset (no TaxiMerchant/TaxiCloseButton globals the
    old skin expected; verified against wow-ui-source-classic). Era/TBC use
    the Classic\ file instead — same registration key, never co-loaded.
    Forever (Camelot) loads the identical Shared\TaxiFrame.xml on the
    Mainline BasicFrameTemplateWithInset (B224).
]]

function private.FrameXML.TaxiFrame()
    local TaxiFrame = _G.TaxiFrame

    Util.HideFrameTextures(TaxiFrame, true)
    if TaxiFrame.NineSlice then
        Util.HideFrameTextures(TaxiFrame.NineSlice)
    end
    -- the flight map is rendered INTO InsetBg (SetTaxiMap(self.InsetBg)) —
    -- it must survive the sweep
    if TaxiFrame.InsetBg then
        TaxiFrame.InsetBg:SetAlpha(1)
    end
    if TaxiFrame.TopTileStreaks then
        TaxiFrame.TopTileStreaks:SetTexture("")
    end
    Skin.FrameTypeFrame(TaxiFrame)

    if TaxiFrame.Inset then
        Skin.InsetFrameTemplate(TaxiFrame.Inset)
    end

    local close = TaxiFrame.CloseButton or _G.TaxiCloseButton
    if close then
        Skin.UIPanelCloseButton(close)
    end
end
