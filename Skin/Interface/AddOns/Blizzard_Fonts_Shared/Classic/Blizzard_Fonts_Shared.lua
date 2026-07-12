local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Color = Aurora.Color

--[[ Classic-family font styles (era/TBC/Mists).
    Evidence: wow-ui-source-*/Interface/AddOns/Blizzard_Fonts_Shared/
    Shared/FontStyles.xml + Shared/GameFontStyles.xml (QuestTitleFont,
    QuestFont, QuestFontLeft, QuestFontNormalSmall, MailTextFontNormal,
    InvoiceTextFont*, GameFontBlackMedium — same object names as retail).
    Classic quest/mail text is dark-on-parchment; with the parchment art
    hidden it must be recolored to be readable (classic clients lack an
    effective questTextContrast path). Font FACE replacement (the retail
    Base.SetFont pass) is deliberately not ported yet.
]]

function private.FrameXML.Fonts()
    local white = Color.white

    local darkFonts = {
        "GameFontBlackMedium",
        "QuestTitleFont",
        "QuestFont",
        -- (QuestFontLeft is a virtual font template, not a global object;
        -- its users are recolored at their call sites instead)
        "QuestFontNormalSmall",
        "MailTextFontNormal",
        "InvoiceTextFontNormal",
        "InvoiceTextFontSmall",
    }
    for _, name in ipairs(darkFonts) do
        local fontObject = _G[name]
        if fontObject then
            fontObject:SetTextColor(white:GetRGB())
        end
    end
end
