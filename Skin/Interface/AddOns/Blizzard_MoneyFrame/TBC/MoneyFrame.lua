local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin

do --[[ FrameXML\MoneyFrame.xml ]]
    function Skin.SmallMoneyFrameTemplate(Frame)
        if not Frame then return end

        local name = Frame:GetName()
        if not name then return end

        -- Hide border textures (Left/Middle/Right) if present
        local left = _G[name .. "Left"]
        if left then left:Hide() end

        local middle = _G[name .. "Middle"]
        if middle then middle:Hide() end

        local right = _G[name .. "Right"]
        if right then right:Hide() end

        -- Style gold/silver/copper icon regions
        -- TBC uses "FrameNameGoldButton", "FrameNameSilverButton", "FrameNameCopperButton"
        local goldButton = _G[name .. "GoldButton"]
        if goldButton then
            local goldTexture = goldButton:GetNormalTexture()
            if goldTexture then
                Base.CropIcon(goldTexture)
            end
        end

        local silverButton = _G[name .. "SilverButton"]
        if silverButton then
            local silverTexture = silverButton:GetNormalTexture()
            if silverTexture then
                Base.CropIcon(silverTexture)
            end
        end

        local copperButton = _G[name .. "CopperButton"]
        if copperButton then
            local copperTexture = copperButton:GetNormalTexture()
            if copperTexture then
                Base.CropIcon(copperTexture)
            end
        end
    end
end

function private.FrameXML.MoneyFrame()
end
