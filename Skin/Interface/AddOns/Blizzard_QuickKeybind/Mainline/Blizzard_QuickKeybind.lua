local _, private = ...
if private.shouldSkip() then return end

local Aurora = private.Aurora
local Base, _, Skin = Aurora.Base, Aurora.Hook, Aurora.Skin
local Color = Aurora.Color

function private.AddOns.Blizzard_QuickKeybind()
    local frame = _G.QuickKeybindFrame
    if not frame then return end

    --[[ B261 (A-candidate, tasks.md 3.2.5; task 5.4 for the check button),
        read from wow-ui-source (retail) and wow-ui-source-forever, the same
        lines on both. QuickKeybindFrameTemplate is protected="true"
        (Blizzard_QuickKeybind/QuickKeybind.xml:20), so nothing of Aurora's
        goes on the frame itself: no backdrop. The dialog look comes from its
        BG child (DialogBorderTemplate, :47), skinned below as before.
        The four controls are children of the protected frame, not protected
        themselves, so a panel of Aurora's under each is allowed: it is a
        child of an unprotected button and anchored to it, and IsProtected()
        on it is false. Blizzard sets their text and OnClick once
        (QuickKeybind.lua:107-125) and the check button's checked state
        (:139, :144); it never enables, disables or re-skins them. ]]

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
    -- Buttons (UIPanelButtonTemplate, QuickKeybind.xml:58-75): panel shape
    ------------------------------------
    if frame.DefaultsButton then
        Skin.TaintSafeUIPanelButtonTemplate(frame.DefaultsButton, "panel")
    end
    if frame.CancelButton then
        Skin.TaintSafeUIPanelButtonTemplate(frame.CancelButton, "panel")
    end
    if frame.OkayButton then
        Skin.TaintSafeUIPanelButtonTemplate(frame.OkayButton, "panel")
    end

    ------------------------------------
    -- CheckButton (UICheckButtonTemplate, QuickKeybind.xml:53-57): the
    -- Layer 1 check box (Skin.UICheckButtonTemplate's box 6 inside the
    -- button, fill at 0.3) drawn as a panel. The checked texture is the
    -- button's own region, restyled in place as Skin.UICheckButtonTemplate
    -- does it; the engine shows and hides it on SetChecked.
    ------------------------------------
    local checkButton = frame.UseCharacterBindingsButton
    if checkButton then
        local panel = Skin.TaintSafeFrameTypeButton(checkButton, "panel")
        panel:SetBackdropOption("offsets", {
            left = 6,
            right = 6,
            top = 6,
            bottom = 6,
        })
        Base.SetBackdropColor(panel, Color.button, 0.3)

        local bg = panel:GetBackdropTexture("bg")
        local check = checkButton:GetCheckedTexture()
        check:ClearAllPoints()
        check:SetPoint("TOPLEFT", bg, -6, 6)
        check:SetPoint("BOTTOMRIGHT", bg, 6, -6)
        check:SetDesaturated(true)
        check:SetVertexColor(Color.highlight:GetRGB())
    end

    ------------------------------------
    -- SAFETY: Do NOT modify QuickKeybindTooltip
    -- Do NOT skin or reparent the tooltip frame
    -- Do NOT modify tooltip hierarchy, parenting, or anchoring
    ------------------------------------
end
