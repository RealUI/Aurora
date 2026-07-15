local _, private = ...
if private.shouldSkip() then return end

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

--[[ Classic-family CharacterFrameTabButtonTemplate (era/TBC/Mists).
    Evidence: wow-ui-source-*/Interface/AddOns/Blizzard_FrameXML/Classic/CharacterFrameTemplates.xml
    Old-style bottom tab: six $parent-named textures (no parentKeys) plus a
    named highlight texture. PanelTemplates_TabResize runs from the tab's own
    OnShow/OnEvent scripts — never resize the tab from the skin; the
    _auroraTabResize flag lets Aurora's PanelTemplates_TabResize hook adjust.
    Visual treatment matches Skin.PanelTabButtonTemplate: flat button backdrop.
]]

function Skin.CharacterFrameTabButtonTemplate(Button)
    local name = Button:GetName()

    Skin.FrameTypeButton(Button)
    Button:SetButtonColor(Color.button, Util.GetFrameAlpha(), false)
    -- Adjacent tabs overlap by 16px (XML anchors x="-16" — the old angled art
    -- blended together); inset each backdrop past the overlap so the flat
    -- boxes read as separate buttons. Side width 17 => visible text padding
    -- of 2*17 - 20 = 14px. Needs the owner frame to raise maxTabWidth above
    -- the default 88 (see the CharacterFrame skin).
    Button._auroraSideWidth = 17
    Button:SetBackdropOption("offsets", {
        left = 10,
        right = 10,
        top = 4,
        bottom = 6,
    })

    -- guarded: live tab variants (e.g. AchievementFrameTab2 on Mists)
    -- carry only a subset of the named pieces (or no name at all) — one
    -- nil here would be module-fatal
    if name then
        for _, suffix in ipairs({
            "LeftDisabled", "MiddleDisabled", "RightDisabled",
            "Left", "Middle", "Right",
        }) do
            if _G[name..suffix] then
                _G[name..suffix]:SetAlpha(0)
            end
        end
    end
    for _, key in ipairs({"LeftDisabled", "MiddleDisabled", "RightDisabled", "Left", "Middle", "Right"}) do
        if Button[key] then
            Button[key]:SetAlpha(0)
        end
    end

    if name and _G[name.."HighlightTexture"] then
        _G[name.."HighlightTexture"]:SetTexture("")
    end

    -- Single-point anchor only: PanelTemplates_TabResize measures the text
    -- via SetWidth(0)+GetWidth() (auto width). A two-point anchor (e.g.
    -- SetAllPoints on the backdrop) makes GetWidth return the anchor-derived
    -- width, which feeds back into the tab width and grows it every resize.
    local text = (name and _G[name.."Text"]) or (Button.GetFontString and Button:GetFontString())
    if text then
        text:ClearAllPoints()
        text:SetPoint("CENTER", Button)
    end

    Button._auroraTabResize = true
end
