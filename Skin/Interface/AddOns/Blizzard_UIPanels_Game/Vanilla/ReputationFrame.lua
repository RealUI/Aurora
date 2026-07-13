local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Util = Aurora.Util

--[[ Era reputation tab (CharacterFrame tab 3).
    Evidence: wow-ui-source-era/Interface/AddOns/Blizzard_UIPanels_Game/
    Vanilla/ReputationFrame.xml — 15 static ReputationBar{i} rows (sheet
    border art $parentReputationBarLeft/Right, ADD highlights), a
    FauxScrollFrame, and the ReputationDetailFrame side popup. The AtWar
    swords and LFG-bonus check overlays are informational — kept.
]]

function private.FrameXML.ReputationFrame()
    Util.HideFrameTextures(_G.ReputationFrame)

    for i = 1, 15 do
        local name = "ReputationBar"..i
        local bar = _G[name]
        if bar then
            _G[name.."ReputationBarLeft"]:SetAlpha(0)
            _G[name.."ReputationBarRight"]:SetAlpha(0)

            for _, hlName in ipairs({name.."Highlight1", name.."Highlight2"}) do
                local highlight = _G[hlName]
                if highlight then
                    highlight:SetTexture([[Interface\Buttons\White8x8]])
                    highlight:SetVertexColor(1, 1, 1) -- static: ADD blend hover
                    highlight:SetAlpha(0.2)
                end
            end

            Skin.FrameTypeStatusBar(bar)
        end
    end

    Skin.FauxScrollFrameTemplate(_G.ReputationListScrollFrame)

    local detail = _G.ReputationDetailFrame
    Skin.FrameTypeFrame(detail)
    Skin.UIPanelCloseButton(_G.ReputationDetailCloseButton)
    Skin.UICheckButtonTemplate(_G.ReputationDetailInactiveCheckbox)
    Skin.UICheckButtonTemplate(_G.ReputationDetailMainScreenCheckbox)
    -- ReputationDetailAtWarCheckbox: custom swords art — left stock
end
