local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin

do --[[ FrameXML\MoneyInputFrame.xml ]]
    function Skin.MoneyInputFrameTemplate(Frame)
        if not Frame then return end

        local name = Frame:GetName()
        if not name then return end

        -- TBC uses "FrameNameGold", "FrameNameSilver", "FrameNameCopper" edit box naming
        local goldEditBox = _G[name .. "Gold"]
        if goldEditBox then
            Skin.FrameTypeEditBox(goldEditBox)

            -- Hide border textures
            local goldLeft = _G[name .. "GoldLeft"]
            if goldLeft then goldLeft:Hide() end
            local goldRight = _G[name .. "GoldRight"]
            if goldRight then goldRight:Hide() end
            local goldMiddle = _G[name .. "GoldMiddle"]
            if goldMiddle then goldMiddle:Hide() end
        end

        local silverEditBox = _G[name .. "Silver"]
        if silverEditBox then
            Skin.FrameTypeEditBox(silverEditBox)

            -- Hide border textures
            local silverLeft = _G[name .. "SilverLeft"]
            if silverLeft then silverLeft:Hide() end
            local silverRight = _G[name .. "SilverRight"]
            if silverRight then silverRight:Hide() end
            local silverMiddle = _G[name .. "SilverMiddle"]
            if silverMiddle then silverMiddle:Hide() end
        end

        local copperEditBox = _G[name .. "Copper"]
        if copperEditBox then
            Skin.FrameTypeEditBox(copperEditBox)

            -- Hide border textures
            local copperLeft = _G[name .. "CopperLeft"]
            if copperLeft then copperLeft:Hide() end
            local copperRight = _G[name .. "CopperRight"]
            if copperRight then copperRight:Hide() end
            local copperMiddle = _G[name .. "CopperMiddle"]
            if copperMiddle then copperMiddle:Hide() end
        end
    end
end

function private.FrameXML.MoneyInputFrame()
end
