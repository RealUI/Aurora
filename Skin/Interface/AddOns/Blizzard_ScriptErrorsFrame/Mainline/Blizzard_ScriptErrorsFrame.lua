local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base, Skin = Aurora.Base, Aurora.Skin
local Color = Aurora.Color

--[[ AddOns\Blizzard_ScriptErrorsFrame.lua ]]
-- ScriptErrorsFrameMixin is a dialog based on UIPanelDialogTemplate.
-- No dynamic element creation — all children are static XML frames.

--[[ AddOns\Blizzard_ScriptErrorsFrame.xml ]]
-- ScriptErrorsFrame inherits UIPanelDialogTemplate with:
--   ScrollFrame (ScrollFrameTemplate + MinimalScrollBar), Text EditBox,
--   PreviousError/NextError nav buttons, Reload/Close action buttons,
--   Title, IndexLabel, DragArea.

function private.AddOns.Blizzard_ScriptErrorsFrame()
    local frame = _G.ScriptErrorsFrame
    if not frame then return end

    ------------------------------------------------
    -- Main dialog frame
    ------------------------------------------------
    Skin.FrameTypeFrame(frame)
    Base.StripBlizzardTextures(frame)

    ------------------------------------------------
    -- Close button (X) from UIPanelDialogTemplate
    ------------------------------------------------
    local closeButton = frame.CloseButton or _G.ScriptErrorsFrameCloseButton
    if closeButton then
        Skin.UIPanelCloseButton(closeButton)
    end

    ------------------------------------------------
    -- Navigation buttons (PreviousError / NextError)
    ------------------------------------------------
    Skin.FrameTypeButton(frame.PreviousError)
    Skin.FrameTypeButton(frame.NextError)

    ------------------------------------------------
    -- Action buttons (Reload UI / Close)
    ------------------------------------------------
    if frame.Reload then
        Skin.UIPanelButtonTemplate(frame.Reload)
    end
    if frame.Close then
        Skin.UIPanelButtonTemplate(frame.Close)
    end

    ------------------------------------------------
    -- Scroll frame and scroll bar
    ------------------------------------------------
    local scrollFrame = frame.ScrollFrame
    if scrollFrame then
        Base.SetBackdrop(scrollFrame, Color.frame)

        -- Skin the scroll bar if present
        local scrollBar = scrollFrame.ScrollBar
        if scrollBar then
            Skin.FrameTypeScrollBar(scrollBar)
        end
    end
end
