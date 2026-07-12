local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals _G

--[[ Core ]]
local Aurora = private.Aurora
local Color = Aurora.Color
local Skin = Aurora.Skin

--do --[[ FrameXML\VehicleLeaveButton.lua ]]
--end

do --[[ FrameXML\VehicleLeaveButton.xml ]]
    function Skin.VehicleLeaveButton(Button)
        if not Button then return end

        local normalTex = Button:GetNormalTexture()
        if normalTex then
            normalTex:SetVertexColor(Color.button:GetRGB())
        end

        local pushedTex = Button:GetPushedTexture()
        if pushedTex then
            pushedTex:SetVertexColor(0.7, 0.7, 0.7) -- static: not a theme color
        end

        local disabledTex = Button:GetDisabledTexture()
        if disabledTex then
            disabledTex:SetVertexColor(0.4, 0.4, 0.4, 0.75) -- static: not a theme color
        end

        -- Keep this protected button taint-safe by only restyling Blizzard's
        -- existing texture regions.
        local highlight = Button.Highlight or Button:GetHighlightTexture()
        if highlight then
            highlight:ClearAllPoints()
            highlight:SetAllPoints(Button)
            highlight:SetAlpha(0.2)
        end
    end
end

function private.FrameXML.VehicleLeaveButton()
    local button = _G.MainMenuBarVehicleLeaveButton

    -- Try both possible paths
    if not button then
        button = _G.MainActionBar and _G.MainActionBar.VehicleLeaveButton
    end

    if button then
        Skin.VehicleLeaveButton(button)
    end
end
