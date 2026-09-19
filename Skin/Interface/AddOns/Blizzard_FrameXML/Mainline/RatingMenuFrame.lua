local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin

--do --[[ FrameXML\RatingMenuFrame.lua ]]
--end

--do --[[ FrameXML\RatingMenuFrame.xml ]]
--end

function private.FrameXML.RatingMenuFrame()
    local RatingMenuFrame = _G.RatingMenuFrame
    if private.isRetail then
        Skin.DialogBorderTemplate(RatingMenuFrame.Border)
        Skin.DialogHeaderTemplate(RatingMenuFrame.Header)
        Skin.UIPanelButtonTemplate(_G.RatingMenuButtonOkay)
    else
        Skin.DialogBorderTemplate(RatingMenuFrame)

        _G.RatingMenuFrameHeader:Hide()
        _G.RatingMenuFrameText:ClearAllPoints()
        _G.RatingMenuFrameText:SetPoint("TOPLEFT")
        _G.RatingMenuFrameText:SetPoint("BOTTOMRIGHT", _G.RatingMenuFrame, "TOPRIGHT", 0, -private.FRAME_TITLE_HEIGHT)

        -- Was Skin.OptionsButtonTemplate, which is defined nowhere in Aurora and
        -- names a Blizzard template that exists in no source tree, retail or
        -- classic -- a fossil from an older client. This whole branch is already
        -- unreachable (the file lives under Mainline\, so only the Mainline and
        -- Forever manifests carry it, and private.isRetail is true on both), but
        -- it is pointed at the button skin the retail branch uses rather than
        -- left calling a nil, so it would behave if the file were ever added to
        -- a classic manifest.
        Skin.UIPanelButtonTemplate(_G.RatingMenuButtonOkay)
    end
end
