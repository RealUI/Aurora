local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color = Aurora.Color

do --[[ AddOns\Blizzard_ProfessionsBook ]]
    function Skin.ProfessionButtonTemplate(CheckButton)
        Base.CropIcon(CheckButton.IconTexture, CheckButton)

        local nameFrame = _G[CheckButton:GetName().."NameFrame"]
        nameFrame:Hide()

        Base.CropIcon(CheckButton:GetPushedTexture())
        Base.CropIcon(CheckButton:GetHighlightTexture())
        Base.CropIcon(CheckButton:GetCheckedTexture())
    end
    function Skin.ProfessionStatusBarTemplate(StatusBar)
        local name = StatusBar:GetName()
        Skin.FrameTypeStatusBar(StatusBar)
        StatusBar:SetStatusBarColor(Color.green:GetRGB())

        StatusBar:SetSize(115, 12)
        StatusBar.rankText:SetPoint("CENTER")

        _G[name.."Left"]:Hide()
        StatusBar.capRight:SetAlpha(0)

        _G[name.."BGLeft"]:Hide()
        _G[name.."BGMiddle"]:Hide()
        _G[name.."BGRight"]:Hide()
    end
    function Skin.PrimaryProfessionTemplate(Frame)
        local name = Frame:GetName()

        Frame.professionName:SetPoint("TOPLEFT", Frame.icon, "TOPRIGHT", 12, 0)
        Frame.missingHeader:SetTextColor(Color.white:GetRGB())
        Frame.missingText:SetTextColor(Color.grayLight:GetRGB())
        _G[name.."IconBorder"]:Hide()

        Frame.icon:ClearAllPoints()
        Frame.icon:SetPoint("TOPLEFT", 6, -6)
        Frame.icon:SetSize(81, 81)
        Base.CropIcon(Frame.icon, Frame)

        Skin.ProfessionButtonTemplate(Frame.SpellButton2)
        Frame.SpellButton2:SetPoint("TOPRIGHT", -109, 0)
        Skin.ProfessionButtonTemplate(Frame.SpellButton1)
        Frame.SpellButton1:SetPoint("TOPLEFT", Frame.SpellButton2, "BOTTOMLEFT", 0, -3)
        Skin.ProfessionStatusBarTemplate(Frame.statusBar)
        Frame.statusBar:ClearAllPoints()
        Frame.statusBar:SetPoint("BOTTOMLEFT", Frame.icon, "BOTTOMRIGHT", 9, 5)

        Frame.UnlearnButton:ClearAllPoints()
        Frame.UnlearnButton:SetPoint("BOTTOMRIGHT", Frame.icon)
    end
    function Skin.SecondaryProfessionTemplate(Button)
        Skin.ProfessionButtonTemplate(Button.SpellButton1)
        Skin.ProfessionButtonTemplate(Button.SpellButton2)
        Skin.ProfessionStatusBarTemplate(Button.statusBar)
        Button.statusBar:SetPoint("BOTTOMLEFT", -10, 5)

        Button.rank:SetPoint("BOTTOMLEFT", Button.statusBar, "TOPLEFT", 3, 4)
        Button.missingHeader:SetTextColor(Color.white:GetRGB())
        Button.missingText:SetTextColor(Color.grayLight:GetRGB())
    end
end

function private.AddOns.Blizzard_ProfessionsBook()
    local ProfessionsBookFrame = _G.ProfessionsBookFrame
    -- WoW Forever has no standalone professions book: its TOC marks
    -- Blizzard_ProfessionsBook.xml [ExcludeLoadGameType camelot] and loads a
    -- Camelot\ template set instead, so the frame this whole skin is written
    -- against is never created. Nothing below can run.
    if not ProfessionsBookFrame then return end

    Skin.NineSlicePanelTemplate(ProfessionsBookFrame.NineSlice)
    ProfessionsBookFrame.NineSlice:SetFrameLevel(1)

    -- Give the outer frame a dark-grey background (not pure black)
    if ProfessionsBookFrame.NineSlice.Bg then
        ProfessionsBookFrame.NineSlice.Bg:SetColorTexture(Color.panelBg:GetRGB())
        ProfessionsBookFrame.NineSlice.Bg:SetAllPoints(ProfessionsBookFrame.NineSlice)
        ProfessionsBookFrame.NineSlice.Bg:Show()
    end

    -- Hide portrait but keep the frame background
    if ProfessionsBookFrame.PortraitContainer then
        ProfessionsBookFrame.PortraitContainer:Hide()
    end

    Skin.UIPanelCloseButton(ProfessionsBookFrame.CloseButton)
    _G.ProfessionsBookFrameTutorialButton:Hide()

    -- Hide the left/right parchment page backgrounds. WoW Forever's Camelot
    -- ProfessionsBook templates have no parchment pages to hide.
    for i = 1, 2 do
        local page = _G["ProfessionsBookPage" .. i]
        if page then
            page:Hide()
        end
    end

    -- Dark background for the content area
    local ProfessionsContentFrame = _G.ProfessionsContentFrame
    if ProfessionsContentFrame and not ProfessionsContentFrame._auroraBackground then
        local bg = ProfessionsContentFrame:CreateTexture(nil, "BACKGROUND", nil, -8)
        bg:SetColorTexture(Color.panelBg:GetRGB())
        bg:SetAllPoints(ProfessionsContentFrame)
        ProfessionsContentFrame._auroraBackground = bg
    end

    local ProfessionsBookFrameInset = _G.ProfessionsBookFrameInset
    Skin.NineSlicePanelTemplate(ProfessionsBookFrameInset.NineSlice)
    Skin.PrimaryProfessionTemplate(_G.PrimaryProfession1)
    Skin.PrimaryProfessionTemplate(_G.PrimaryProfession2)
    Skin.SecondaryProfessionTemplate(_G.SecondaryProfession1)
    Skin.SecondaryProfessionTemplate(_G.SecondaryProfession2)
    Skin.SecondaryProfessionTemplate(_G.SecondaryProfession3)
end
