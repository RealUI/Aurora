local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals _G next type

--[[ Core ]]
local Aurora = private.Aurora
local Hook, Skin = Aurora.Hook, Aurora.Skin

-- B261 (task 5.3): portrait textures whose round mask SetPortraitToTexture
-- should be undone (a plain SetTexture again), registered by the skins that
-- crop them square. Was `_auroraResetPortrait` on the Blizzard texture. Weak
-- keys: a texture goes with its frame.
local resetPortraits = _G.setmetatable({}, {__mode = "k"})

--[[ Skin.SetPortraitReset(_texture_)
Registers `texture` so that Blizzard's SetPortraitToTexture on it is followed
by a plain SetTexture with the same path, keeping Aurora's square crop.
--]]
function Skin.SetPortraitReset(texture)
    resetPortraits[texture] = true
end

do --[[ FrameXML\UIParent.lua ]]
    function Hook.SetPortraitToTexture(texture, path)
        texture = _G[texture] or texture
        if not texture:IsForbidden() and resetPortraits[texture] then
            texture:SetTexture(path)
        end
    end
    function Hook.BuildIconArray(parent, baseName, template, rowSize, numRows, onButtonCreated)
        if Skin[template] then
            for i = 1, rowSize * numRows do
                Skin[template](_G[baseName..i])
            end
        end
    end
end

function private.FrameXML.UIParent()
    -- Code replaced with SetTexture functions.....
    if type(_G.SetPortraitToTexture) == "function" then
        _G.hooksecurefunc("SetPortraitToTexture", Hook.SetPortraitToTexture)
    end
    -- this one is still around :)
    if type(_G.BuildIconArray) == "function" then
        _G.hooksecurefunc("BuildIconArray", Hook.BuildIconArray)
    end
end
