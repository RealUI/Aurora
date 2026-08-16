local _, private = ...
if private.shouldSkip() then return end

local Aurora = private.Aurora
local Base, Hook, Skin = Aurora.Base, Aurora.Hook, Aurora.Skin
local Color = Aurora.Color

do --[[ AddOns\Blizzard_ClickBindingUI.lua ]]
    -- Skin a ClickBindingLineTemplate entry (binding row with icon, name, binding text)
    local function SkinBindingLine(frame)
        if not frame or private.IsSkinned(frame) then return end

        -- Crop the spell/macro icon
        if frame.Icon then
            Base.CropIcon(frame.Icon)
        end

        -- Hide the decorative background atlas
        if frame.Background then
            frame.Background:SetAlpha(0)
        end

        -- Hide the "new" outline atlas
        if frame.NewOutline then
            frame.NewOutline:SetAlpha(0)
        end

        private.SetSkinned(frame, true)
    end

    -- Callback for ScrollUtil.AddAcquiredFrameCallback
    function Hook.ClickBindingScrollBoxCallback(o, frame)
        SkinBindingLine(frame)
    end
end

function private.AddOns.Blizzard_ClickBindingUI()
    local frame = _G.ClickBindingFrame
    if not frame then return end

    ------------------------------------
    -- Main frame (PortraitFrameTemplate)
    ------------------------------------
    Skin.FrameTypeFrame(frame)

    ------------------------------------
    -- Strip decorative textures
    ------------------------------------
    Base.StripBlizzardTextures(frame)

    ------------------------------------
    -- ScrollBoxBackground backdrop
    ------------------------------------
    if frame.ScrollBoxBackground then
        Base.SetBackdrop(frame.ScrollBoxBackground, Color.frame)
    end

    ------------------------------------
    -- Action buttons
    ------------------------------------
    if frame.SaveButton then
        Skin.FrameTypeButton(frame.SaveButton)
    end
    if frame.AddBindingButton then
        Skin.FrameTypeButton(frame.AddBindingButton)
    end
    if frame.ResetButton then
        Skin.FrameTypeButton(frame.ResetButton)
    end

    ------------------------------------
    -- Mouseover cast checkbox
    ------------------------------------
    if frame.EnableMouseoverCastCheckbox then
        Skin.FrameTypeCheckButton(frame.EnableMouseoverCastCheckbox)
    end

    ------------------------------------
    -- Close button
    ------------------------------------
    if frame.CloseButton then
        Skin.UIPanelCloseButton(frame.CloseButton)
    end

    ------------------------------------
    -- ScrollBox: skin dynamically acquired binding entries
    ------------------------------------
    local scrollBox = frame.ScrollBox
    if scrollBox then
        _G.ScrollUtil.AddAcquiredFrameCallback(scrollBox, Hook.ClickBindingScrollBoxCallback, frame)

        -- Skin any already-existing frames
        scrollBox:ForEachFrame(function(child)
            if child.Icon then
                if not private.IsSkinned(child) then
                    if child.Icon then
                        Base.CropIcon(child.Icon)
                    end
                    if child.Background then
                        child.Background:SetAlpha(0)
                    end
                    if child.NewOutline then
                        child.NewOutline:SetAlpha(0)
                    end
                    private.SetSkinned(child, true)
                end
            end
        end)
    end
end
