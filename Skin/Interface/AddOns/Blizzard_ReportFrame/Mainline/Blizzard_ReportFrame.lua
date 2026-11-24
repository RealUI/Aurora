local _, private = ...
if private.shouldSkip() then return end

local Aurora = private.Aurora
local Base, Hook, Skin = Aurora.Base, Aurora.Hook, Aurora.Skin

do --[[ AddOns\Blizzard_ReportFrame.lua ]]
    -- Skin minor category checkbuttons acquired from the pool.
    local function SkinMinorCategoryButton(button)
        if not button or private.IsSkinned(button) then return end
        private.SetSkinned(button, true)

        Skin.FrameTypeCheckButton(button)

        -- Hide the Blizzard atlas textures used as normal/highlight/checked
        if button.GetNormalTexture then
            local tex = button:GetNormalTexture()
            if tex then tex:SetAlpha(0) end
        end
        if button.GetHighlightTexture then
            local tex = button:GetHighlightTexture()
            if tex then tex:SetAlpha(0) end
        end
        if button.GetCheckedTexture then
            local tex = button:GetCheckedTexture()
            if tex then tex:SetAlpha(0) end
        end
    end

    Hook.SharedReportFrameMixinAnchorMinorCategory = {}
    function Hook.SharedReportFrameMixinAnchorMinorCategory:AnchorMinorCategory(index, minorCategory)
        -- Skin the most recently acquired minor category button from the pool.
        local pool = self.MinorCategoryButtonPool
        if pool then
            for button in pool:EnumerateActive() do
                SkinMinorCategoryButton(button)
            end
        end
    end
end

function private.AddOns.Blizzard_ReportFrame()
    local frame = _G.ReportFrame
    if not frame then return end

    ------------------------------------
    -- Main frame backdrop
    ------------------------------------
    Skin.FrameTypeFrame(frame)

    ------------------------------------
    -- Strip decorative textures
    ------------------------------------
    -- The Border child frame has NineSlice Dialog textures applied via
    -- NineSliceUtil.ApplyLayoutByName in OnLoad — strip all its regions.
    if frame.Border then
        Base.StripBlizzardTextures(frame.Border)
    end

    -- Background inset textures
    if frame.TopInset then frame.TopInset:SetAlpha(0) end
    if frame.BottomInset then frame.BottomInset:SetAlpha(0) end
    if frame.TopInsetEdge then frame.TopInsetEdge:SetAlpha(0) end
    if frame.BottomInsetEdge then frame.BottomInsetEdge:SetAlpha(0) end

    -- Watermark (shown on thank-you state)
    if frame.Watermark then frame.Watermark:SetAlpha(0) end

    ------------------------------------
    -- Buttons
    ------------------------------------
    -- Report (submit) button. B261 Layer 2 (A-candidate, tasks.md 3.2.5), read
    -- from wow-ui-source (retail) and wow-ui-source-forever. Every category,
    -- flag or screenshot change runs UpdateButtonState into ManageButton,
    -- which is SetEnabled on the button (Blizzard_ReportFrameShared/
    -- ReportFrameShared.lua:347-351, Blizzard_ReportFrame/ReportFrame.lua:33-35;
    -- Forever :356-360 and :33-35); its click runs SendReport into
    -- C_ReportSystem.SendReport (ReportFrameShared.lua:342-343, :218-233;
    -- Forever :351-352, :227-242), which has restrictions
    -- (ReportSystemDocumentation.lua:126-129). Shape "panel": a
    -- UIPanelButtonTemplate in XML (ReportFrameShared.xml:114, both trees),
    -- not pooled, not a layout frame; Blizzard re-sets only the plates
    -- (Blizzard_SharedXML/SecureUIPanelTemplates.lua:44-79).
    -- The panel sits at the report frame's level, and that frame keeps an
    -- unnamed black texture at alpha 0.9 on BACKGROUND, sublevel 0, over the
    -- whole frame (ReportFrameShared.xml:47-55, both trees; the skin hides the
    -- two inset textures at sublevels 1 and 2 by alpha, not this one). A
    -- panel's fill is at -6 and would draw under it, so the panel's backdrop
    -- goes to 3, its edge to 4, above all three (the Fable review of step 15,
    -- finding 7).
    if frame.ReportButton then
        local panel = Skin.TaintSafeUIPanelButtonTemplate(frame.ReportButton, "panel")
        panel:SetBackdropLayer("BACKGROUND", 3)
    end

    -- Close button
    if frame.CloseButton then
        Skin.UIPanelCloseButton(frame.CloseButton)
        -- Hide the extra border texture on the close button
        if frame.CloseButton.Border then
            frame.CloseButton.Border:SetAlpha(0)
        end
    end

    -- Screenshot take button
    local ssFrame = frame.ScreenshotReportingFrame
    if ssFrame and ssFrame.TakeScreenshotButton then
        Skin.FrameTypeButton(ssFrame.TakeScreenshotButton)
    end

    ------------------------------------
    -- Hook pool for dynamic minor category checkbuttons
    ------------------------------------
    _G.hooksecurefunc(frame, "AnchorMinorCategory", Hook.SharedReportFrameMixinAnchorMinorCategory.AnchorMinorCategory)
end
