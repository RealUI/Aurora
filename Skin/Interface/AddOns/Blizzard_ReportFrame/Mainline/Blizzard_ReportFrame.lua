local _, private = ...
if private.shouldSkip() then return end

local Aurora = private.Aurora
local Base, Hook, Skin = Aurora.Base, Aurora.Hook, Aurora.Skin

do --[[ AddOns\Blizzard_ReportFrame.lua ]]
    -- Skin minor category checkbuttons acquired from the pool.
    local function SkinMinorCategoryButton(button)
        if not button or button._auroraSkinned then return end
        button._auroraSkinned = true

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
    -- Report (submit) button
    if frame.ReportButton then
        Skin.FrameTypeButton(frame.ReportButton)
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
