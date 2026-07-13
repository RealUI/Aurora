local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Util = Aurora.Util

--[[ Classic-family key bindings dialog (era/TBC/Mists; retail moved
    keybinds into Settings). Evidence: wow-ui-source-era/Interface/AddOns/
    Blizzard_BindingUI/Blizzard_BindingUI.xml — BACKDROP_DIALOG_32_32 root
    with flat separators, a rock-textured header, category list
    (OptionsFrameListTemplate), and per-row key buttons inheriting
    UIMenuButtonStretchTemplate (created dynamically from
    KeyBindingFrameBindingTemplate).
]]

function private.AddOns.Blizzard_BindingUI()
    local KeyBindingFrame = _G.KeyBindingFrame
    if not KeyBindingFrame then return end

    Skin.FrameTypeFrame(KeyBindingFrame)

    -- Header: rock fill + translucent border
    local header = KeyBindingFrame.header
    if header then
        Util.HideFrameTextures(header)
        if header.NineSlice then
            Util.HideFrameTextures(header.NineSlice)
        end
        if header.Bg then
            header.Bg:SetAlpha(0)
        end
    end

    if KeyBindingFrame.characterSpecificButton then
        Skin.UICheckButtonTemplate(KeyBindingFrame.characterSpecificButton)
    end
    for _, key in ipairs({"unbindButton", "okayButton", "cancelButton", "defaultsButton"}) do
        local button = KeyBindingFrame[key]
        if button then
            Skin.UIPanelButtonTemplate(button)
        end
    end

    -- Category list panel + its scroll frame
    local categoryList = KeyBindingFrame.categoryList
    if categoryList then
        Util.HideFrameTextures(categoryList)
        if categoryList.NineSlice then
            Util.HideFrameTextures(categoryList.NineSlice)
        end
    end

    local scrollFrame = _G.KeyBindingFrameScrollFrame
    if scrollFrame and scrollFrame.ScrollBar and scrollFrame.ScrollBar.ScrollUpButton then
        Skin.UIPanelScrollBarTemplate(scrollFrame.ScrollBar)
    end

    -- Binding rows are static children named KeyBindingFrameBinding{i} with
    -- Key1Button/Key2Button stretch buttons
    local i = 1
    while _G["KeyBindingFrameBinding"..i] do
        local rowName = "KeyBindingFrameBinding"..i
        for _, suffix in ipairs({"Key1Button", "Key2Button"}) do
            local button = _G[rowName..suffix]
            if button then
                Skin.UIMenuButtonStretchTemplate(button)
            end
        end
        i = i + 1
    end
end
