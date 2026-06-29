local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals select type

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

function private.FrameXML.UIParent()
    -- Skin TutorialFrame if present
    local TutorialFrame = _G.TutorialFrame
    if TutorialFrame then
        Base.SetBackdrop(TutorialFrame, Color.frame, Util.GetFrameAlpha())

        -- Hide border textures
        for i = 1, TutorialFrame:GetNumRegions() do
            local region = _G.select(i, TutorialFrame:GetRegions())
            if region and region.GetObjectType and region:GetObjectType() == "Texture" then
                local texture = region:GetTexture()
                if texture and type(texture) == "string" and (texture:find("UI%-Tutorial") or texture:find("UI%-DialogBox")) then
                    region:Hide()
                end
            end
        end

        -- Skin close button
        local closeButton = _G.TutorialFrameCloseButton or TutorialFrame.CloseButton
        if closeButton then
            Skin.UIPanelCloseButton(closeButton)
        end

        -- Skin next/prev buttons
        if _G.TutorialFrameNextButton then
            Skin.UIPanelButtonTemplate(_G.TutorialFrameNextButton)
        end
        if _G.TutorialFramePrevButton then
            Skin.UIPanelButtonTemplate(_G.TutorialFramePrevButton)
        end
        if _G.TutorialFrameOkayButton then
            Skin.UIPanelButtonTemplate(_G.TutorialFrameOkayButton)
        end
    end

    -- Skin QuestWatchFrame (objective tracker in TBC) — minimal, just hide borders
    local QuestWatchFrame = _G.QuestWatchFrame
    if QuestWatchFrame then
        for i = 1, QuestWatchFrame:GetNumRegions() do
            local region = _G.select(i, QuestWatchFrame:GetRegions())
            if region and region.GetObjectType and region:GetObjectType() == "Texture" then
                local drawLayer = region:GetDrawLayer()
                if drawLayer == "BORDER" or drawLayer == "BACKGROUND" then
                    region:Hide()
                end
            end
        end
    end
end
