local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals select type

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin

--do --[[ FrameXML\ModelPreviewFrame.lua ]]
--end

--do --[[ FrameXML\ModelPreviewFrame.xml ]]
--end

function private.SharedXML.ModelPreviewFrame()
    local ModelPreviewFrame = _G.ModelPreviewFrame

    --BlizzWTF: The close button added in this frame interferes with the one created in the template.
    -- The template's own close button used to be the 4th child, but that index
    -- is not portable: WoW Forever's ButtonFrameTemplate gains gamepad focus
    -- children (FrameGlow, LeftJumpHint, RightJumpHint, FocusJumpHint), which
    -- shifts everything after them. Find it by shape instead of by position.
    local closeButton = ModelPreviewFrame.CloseButton

    local function IsCloseButton(frame)
        return frame and frame ~= closeButton and frame.GetObjectType
            and frame:GetObjectType() == "Button" and type(frame.Disable) == "function"
    end

    -- Keep the historical index as the first guess so retail behaviour is
    -- unchanged, and only search when it does not hold.
    local templateCloseButton = select(4, ModelPreviewFrame:GetChildren())
    if not IsCloseButton(templateCloseButton) then
        templateCloseButton = nil
        for i = 1, select("#", ModelPreviewFrame:GetChildren()) do
            local child = select(i, ModelPreviewFrame:GetChildren())
            if IsCloseButton(child) then
                templateCloseButton = child
                break
            end
        end
    end

    if templateCloseButton then
        ModelPreviewFrame.CloseButton = templateCloseButton
    end
    Skin.ButtonFrameTemplate(ModelPreviewFrame)
    Skin.MagicButtonTemplate(closeButton)
    closeButton:SetPoint("BOTTOMRIGHT", -5, 5)

    ModelPreviewFrame.Display.YesMountsTex:Hide()
    ModelPreviewFrame.Display.ShadowOverlay:Hide()

    local ModelScene = ModelPreviewFrame.Display.ModelScene
    Skin.ModelSceneControlFrameTemplateLeftButtonTemplate(ModelScene.ControlFrame.rotateLeftButton)
    Skin.ModelSceneControlFrameTemplateRightButtonTemplate(ModelScene.ControlFrame.rotateRightButton)
    Skin.NavButtonPrevious(ModelScene.CarouselLeftButton)
    Skin.NavButtonNext(ModelScene.CarouselRightButton)
end
