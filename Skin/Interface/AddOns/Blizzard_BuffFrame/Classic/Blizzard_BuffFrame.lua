local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base

--[[ Classic-family buff frame (era/TBC/Mists; retail resolves Mainline/).
    Evidence: wow-ui-source-*/Interface/AddOns/Blizzard_BuffFrame/Classic/
    BuffFrame.xml — the LEGACY aura system: AuraButton_Update() lazily
    creates BuffButton{i}/DebuffButton{i} globals; the icon is the named
    $parentIcon texture (no parentKey). The debuff $parentBorder overlay is
    KEPT — Blizzard vertex-colors it by dispel type. The purple
    TempEnchant border is decorative and stripped.
]]

local function SkinAuraButton(button, name)
    if not button or button._auroraSkinned then return end

    local icon = _G[name.."Icon"]
    if icon then
        Base.CropIcon(icon)
    end

    button._auroraSkinned = true
end

function private.AddOns.Blizzard_BuffFrame()
    -- Buff/debuff buttons are created lazily inside AuraButton_Update
    _G.hooksecurefunc("AuraButton_Update", function(buttonName, index)
        local name = buttonName..index
        local button = _G[name]
        if button then
            SkinAuraButton(button, name)
        end
    end)

    -- XML-defined weapon temp enchant buttons
    for i = 1, 3 do
        local name = "TempEnchant"..i
        local button = _G[name]
        if button then
            SkinAuraButton(button, name)
            local border = _G[name.."Border"]
            if border then
                border:SetTexture("")
            end
        end
    end
end
