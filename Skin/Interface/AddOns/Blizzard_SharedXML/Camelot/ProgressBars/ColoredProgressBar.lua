local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals next

--[[ Core ]]
local Aurora = private.Aurora
local Base, Skin = Aurora.Base, Aurora.Skin
local Color = Aurora.Color

do --[[ SharedXML\ProgressBars\ColoredProgressBar.xml ]]
    -- Camelot's bar widget, and the base of its ReputationBarTemplate.
    --
    -- It is a **Frame**, not a StatusBar: the fill is a plain texture
    -- (common-stat-bar-white) clipped by a MaskTexture and driven by
    -- ColoredProgressBarMixin. Skin.FrameTypeStatusBar cannot be used on it --
    -- it hooks SetStatusBarTexture/SetStatusBarColor, which do not exist here,
    -- and throws "SetStatusBarTexture is not a function".
    --
    -- Treatment matches what FrameTypeStatusBar gives a real status bar: hide
    -- Blizzard's bar background, give the frame Aurora's backdrop, and leave
    -- the masked Fill alone so the mixin keeps driving its width and colour.
    function Skin.ColoredProgressBarTemplate(Frame)
        if not Frame then return end

        -- The background is the unnamed common-stat-bar-BG texture; Fill and
        -- Mask carry parentKeys, so anything without one is chrome.
        --
        -- The status bar texture is spared as well: some templates inheriting
        -- this one are declared <StatusBar> rather than <Frame> (Camelot's
        -- SkillsBarTemplate), and on those the bar texture is a region that
        -- would otherwise be swept up with the chrome.
        local barTexture = Frame.GetStatusBarTexture and Frame:GetStatusBarTexture()

        for _, region in next, {Frame:GetRegions()} do
            if region:IsObjectType("Texture")
                and region ~= Frame.Fill
                and region ~= Frame.Mask
                and region ~= barTexture then
                region:Hide()
            end
        end

        Base.SetBackdrop(Frame, Color.button, Color.frame.a)
        Frame:SetBackdropOption("offsets", {
            left = -1,
            right = -2,
            top = -1,
            bottom = -1,
        })
    end
end
