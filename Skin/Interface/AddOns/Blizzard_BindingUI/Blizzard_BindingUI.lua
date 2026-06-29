local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

function private.AddOns.Blizzard_BindingUI()
    local KeyBindingFrame = _G.KeyBindingFrame
    if not KeyBindingFrame then return end

    ---------------------
    -- Main Frame      --
    ---------------------
    Base.SetBackdrop(KeyBindingFrame, Color.frame, Util.GetFrameAlpha())

    -- Hide Blizzard border/background textures
    local borderTextures = {
        "KeyBindingFrameTopLeft",
        "KeyBindingFrameTopRight",
        "KeyBindingFrameBottomLeft",
        "KeyBindingFrameBottomRight",
        "KeyBindingFrameTop",
        "KeyBindingFrameBottom",
        "KeyBindingFrameLeft",
        "KeyBindingFrameRight",
        "KeyBindingFrameTopBorder",
        "KeyBindingFrameTopRightCorner",
        "KeyBindingFrameRightBorder",
        "KeyBindingFrameBotRightCorner",
        "KeyBindingFrameBottomBorder",
        "KeyBindingFrameBotLeftCorner",
        "KeyBindingFrameLeftBorder",
        "KeyBindingFrameTopLeftCorner",
    }
    for _, texName in _G.ipairs(borderTextures) do
        local tex = _G[texName]
        if tex then
            tex:Hide()
        end
    end

    -- Hide header texture
    if _G.KeyBindingFrameHeader then
        _G.KeyBindingFrameHeader:Hide()
    end

    ---------------------
    -- Close Button    --
    ---------------------
    if _G.KeyBindingFrameCloseButton then
        Skin.UIPanelCloseButton(_G.KeyBindingFrameCloseButton)
    end

    ---------------------
    -- Scroll Frame    --
    ---------------------
    local scrollFrame = _G.KeyBindingFrameScrollFrame
    if scrollFrame then
        if Skin.FauxScrollFrameTemplate then
            Skin.FauxScrollFrameTemplate(scrollFrame)
        elseif scrollFrame.ScrollBar then
            Skin.MinimalScrollBar(scrollFrame.ScrollBar)
        elseif Skin.UIPanelScrollFrameTemplate then
            Skin.UIPanelScrollFrameTemplate(scrollFrame)
        end

        -- Hide scroll frame background textures
        local scrollBgTextures = {
            "KeyBindingFrameScrollFrameTop",
            "KeyBindingFrameScrollFrameBottom",
            "KeyBindingFrameScrollFrameMiddle",
        }
        for _, texName in _G.ipairs(scrollBgTextures) do
            local tex = _G[texName]
            if tex then
                tex:Hide()
            end
        end
    end

    ---------------------
    -- Action Buttons  --
    ---------------------
    if _G.KeyBindingFrameOkayButton then
        Skin.UIPanelButtonTemplate(_G.KeyBindingFrameOkayButton)
    end
    if _G.KeyBindingFrameCancelButton then
        Skin.UIPanelButtonTemplate(_G.KeyBindingFrameCancelButton)
    end
    if _G.KeyBindingFrameDefaultButton then
        Skin.UIPanelButtonTemplate(_G.KeyBindingFrameDefaultButton)
    end
    if _G.KeyBindingFrameUnbindButton then
        Skin.UIPanelButtonTemplate(_G.KeyBindingFrameUnbindButton)
    end

    ---------------------
    -- Category Dropdown --
    ---------------------
    if _G.KeyBindingFrameCategoryDropDown then
        if Skin.DropdownButton then
            Skin.DropdownButton(_G.KeyBindingFrameCategoryDropDown)
        end
    end

    -- Character-specific checkbox
    if _G.KeyBindingFrameCharacterButton then
        Skin.UICheckButtonTemplate(_G.KeyBindingFrameCharacterButton)
    end

    ---------------------
    -- Key Binding Buttons --
    ---------------------
    -- TBC KeyBindingFrame has individual binding rows (KeyBindingFrameBinding1-N)
    -- Each row has key1 and key2 button slots
    local NUM_KEY_BINDINGS_DISPLAYED = _G.KEY_BINDINGS_DISPLAYED or 21
    for i = 1, NUM_KEY_BINDINGS_DISPLAYED do
        local bindingButton = _G["KeyBindingFrameBinding" .. i]
        if bindingButton then
            -- Skin the row highlight
            local highlight = bindingButton:GetHighlightTexture()
            if highlight then
                Util.SetHighlightColor(highlight, 0.5)
            end
        end

        -- Key1 button
        local key1Button = _G["KeyBindingFrameBinding" .. i .. "Key1Button"]
        if key1Button then
            Skin.FrameTypeButton(key1Button)
        end

        -- Key2 button
        local key2Button = _G["KeyBindingFrameBinding" .. i .. "Key2Button"]
        if key2Button then
            Skin.FrameTypeButton(key2Button)
        end
    end

end
