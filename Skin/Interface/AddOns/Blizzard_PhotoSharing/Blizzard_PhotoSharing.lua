local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals pairs

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin


-- Helper: hide Common-Input-Border textures on a parent frame that wraps an EditBox.
-- The TitleFrame and DescriptionFrame each have 9 named textures (TL, TR, T, BL, BR, B, L, R, M)
-- using the Common-Input-Border file set.
local function HideCommonInputBorder(parentFrame)
    if not parentFrame then return end
    local name = parentFrame:GetName()
    if not name then return end
    local suffixes = {"TopLeft", "TopRight", "Top", "BottomLeft", "BottomRight", "Bottom", "Left", "Right", "Middle"}
    for _, suffix in pairs(suffixes) do
        local tex = parentFrame[suffix] or _G[name .. suffix]
        if tex and tex.SetAlpha then
            tex:SetAlpha(0)
        end
    end
end


function private.AddOns.Blizzard_PhotoSharing()
    ----
    -- PhotoSharingFrame (SettingsFrameTemplate)
    ----
    local Frame = _G.PhotoSharingFrame

    Skin.FrameTypeFrame(Frame)

    -- Hide the rock texture background
    if Frame.TopInset then Frame.TopInset:SetAlpha(0) end

    -- PublishButton / CancelButton (UIPanelButtonTemplate)
    Skin.UIPanelButtonTemplate(Frame.PublishButton)
    Skin.UIPanelButtonTemplate(Frame.CancelButton)

    -- PhotoSharingTitleEditBox — nested inside TitleFrame
    local TitleFrame = Frame.TitleFrame
    if TitleFrame then
        HideCommonInputBorder(TitleFrame)
        if TitleFrame.PhotoSharingTitleEditBox then
            Skin.FrameTypeEditBox(TitleFrame.PhotoSharingTitleEditBox)
        end
    end

    -- PhotoSharingDescriptionEditBox — nested inside DescriptionFrame
    local DescriptionFrame = Frame.DescriptionFrame
    if DescriptionFrame then
        HideCommonInputBorder(DescriptionFrame)
        if DescriptionFrame.PhotoSharingDescriptionEditBox then
            Skin.FrameTypeEditBox(DescriptionFrame.PhotoSharingDescriptionEditBox)
        end
    end

    -- ScreenshotPreview: leave unskinned (rendering texture)

    ----
    -- PhotoSharingBrowserFrame (DefaultPanelTemplate — ButtonFrameTemplateNoPortrait layout)
    ----
    local Browser = _G.PhotoSharingBrowserFrame

    Skin.DefaultPanelTemplate(Browser)
    Skin.UIPanelCloseButton(Browser.CloseButton)

    -- Browser (SimpleBrowser web view): leave unskinned

    ----
    -- PhotoSharingBrowserPopup (DefaultPanelTemplate — ButtonFrameTemplateNoPortrait layout)
    ----
    local BrowserPopup = _G.PhotoSharingBrowserPopup

    Skin.DefaultPanelTemplate(BrowserPopup)
    Skin.UIPanelCloseButton(BrowserPopup.CloseButton)

    -- Browser (SimpleBrowser web view): leave unskinned
end
