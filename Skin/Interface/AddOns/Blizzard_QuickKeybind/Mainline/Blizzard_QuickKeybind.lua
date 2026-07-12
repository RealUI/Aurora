local _, private = ...
if private.shouldSkip() then return end

local Aurora = private.Aurora
local Base, _, Skin = Aurora.Base, Aurora.Hook, Aurora.Skin
local Color = Aurora.Color

function private.AddOns.Blizzard_QuickKeybind()
    local frame = _G.QuickKeybindFrame
    if not frame then return end

    ------------------------------------
    -- Main frame backdrop
    -- QuickKeybindFrame is a Button inheriting QuickKeybindFrameTemplate
    -- with a BG child (DialogBorderTemplate) and Header (DialogHeaderTemplate)
    ------------------------------------
    Base.SetBackdrop(frame, Color.frame)

    ------------------------------------
    -- Strip BG DialogBorderTemplate NineSlice textures
    ------------------------------------
    if frame.BG then
        Skin.DialogBorderTemplate(frame.BG)
    end

    ------------------------------------
    -- Strip Header DialogHeaderTemplate textures
    ------------------------------------
    if frame.Header then
        Skin.DialogHeaderTemplate(frame.Header)
    end

    ------------------------------------
    -- Buttons (UIPanelButtonTemplate)
    ------------------------------------
    if frame.DefaultsButton then
        Skin.FrameTypeButton(frame.DefaultsButton)
    end
    if frame.CancelButton then
        Skin.FrameTypeButton(frame.CancelButton)
    end
    if frame.OkayButton then
        Skin.FrameTypeButton(frame.OkayButton)
    end

    ------------------------------------
    -- CheckButton (UICheckButtonTemplate)
    ------------------------------------
    if frame.UseCharacterBindingsButton then
        Skin.FrameTypeCheckButton(frame.UseCharacterBindingsButton)
    end

    ------------------------------------
    -- SAFETY: Do NOT modify QuickKeybindTooltip
    -- Do NOT skin or reparent the tooltip frame
    -- Do NOT modify tooltip hierarchy, parenting, or anchoring
    ------------------------------------
end
