local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals select

--[[ Core ]]
local Aurora = private.Aurora
local Base, Skin = Aurora.Base, Aurora.Skin
local Color = Aurora.Color

--[[ Classic-family LootFrame (era/TBC/Mists).
    Evidence: wow-ui-source-*/Interface/AddOns/Blizzard_UIPanels_Game/
    Classic/LootFrame.xml (root L70: ButtonFrameTemplate; LootButtonTemplate
    = ItemButtonTemplate + $parentNameFrame plate + $parentText, hit rect
    extends 107px right of the icon). Group/bonus roll frames in the same
    file are left stock for now.
]]

local function SkinLootButton(Button)
    local name = Button:GetName()
    _G[name.."NameFrame"]:Hide()

    Skin.FrameTypeItemButton(Button)

    -- Name plate area matches the extended hit rect (right -107)
    local bg = _G.CreateFrame("Frame", nil, Button)
    bg:SetFrameLevel(Button:GetFrameLevel())
    bg:SetPoint("TOPLEFT", Button.icon, "TOPRIGHT", 2, 1)
    bg:SetPoint("BOTTOMRIGHT", Button, 107, 0)
    Base.SetBackdrop(bg, Color.frame)

    local text = _G[name.."Text"]
    text:SetParent(bg)
    text:SetDrawLayer("OVERLAY")
end

function private.FrameXML.LootFrame()
    local LootFrame = _G.LootFrame

    Skin.ButtonFrameTemplate(LootFrame)
    -- LootFrame_OnShow re-sets this texture on every open (skull/fishing
    -- icon); alpha survives SetTexture, a one-time SetTexture("") does not.
    _G.LootFramePortraitOverlay:SetAlpha(0)

    -- The "Items" label is the frame's real header: center it in the title
    -- bar and hide the creature-name title texts (clipped/truncated noise
    -- on this 170px frame).
    local bg = LootFrame:GetBackdropTexture("bg")
    for i = 1, select("#", LootFrame:GetRegions()) do
        local region = select(i, LootFrame:GetRegions())
        if region:IsObjectType("FontString") and region:GetText() == _G.ITEMS then
            region:ClearAllPoints()
            region:SetPoint("TOPLEFT", bg)
            region:SetPoint("BOTTOMRIGHT", bg, "TOPRIGHT", 0, -private.FRAME_TITLE_HEIGHT)
            region:SetJustifyH("CENTER")
            break
        end
    end
    if LootFrame.TitleText then
        LootFrame.TitleText:Hide()
    end
    if LootFrame.TitleContainer and LootFrame.TitleContainer.TitleText then
        LootFrame.TitleContainer.TitleText:Hide()
    end

    for i = 1, 4 do
        SkinLootButton(_G["LootButton"..i])
    end

    Skin.NavButtonPrevious(_G.LootFrameUpButton)
    Skin.NavButtonNext(_G.LootFrameDownButton)
end
