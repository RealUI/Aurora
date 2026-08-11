local _, private = ...
if private.shouldSkip() then return end

---@diagnostic disable: undefined-global

--[[ Lua Globals ]]
-- luacheck: globals _G ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Base, Skin = Aurora.Base, Aurora.Skin
local Color = Aurora.Color

do --[[ AddOns\Blizzard_HousingControls\Blizzard_HousingControlButton.xml ]]
    function Skin.BaseHousingControlButtonTemplate(Button)
        if Button._auroraSkinned then
            return
        end

        Button._auroraSkinned = true
        Button._auroraHousingActionButton = true

        Base.SetBackdrop(Button, Color.button, 0.2)
        Button:SetBackdropOption("offsets", {
            left = 0,
            right = 0,
            top = 0,
            bottom = 0,
        })

        if Button.HoverIcon then
            Button.HoverIcon:SetAlpha(0.35)
        end
    end
end

local function SkinControlFrame(Frame)
    if not Frame then
        return
    end

    Base.SetBackdrop(Frame, Color.frame)

    if Frame.Background then
        Frame.Background:SetAlpha(0)
    end
    if Frame.Divider then
        Frame.Divider:SetAlpha(0)
    end
    if Frame.OwnerNameText then
        Frame.OwnerNameText:SetTextColor(Color.highlight:GetRGB())
    end

    -- 12.1: VisitorControlFrame's buttons moved under a ButtonContainer;
    -- both layout mixins now expose GetButtons() — prefer it
    local buttons = (Frame.GetButtons and Frame:GetButtons()) or Frame.Buttons
    if buttons then
        for _, button in ipairs(buttons) do
            Skin.BaseHousingControlButtonTemplate(button)
            if button.UpdateState then
                button:UpdateState()
            end
        end
    end
end

function private.AddOns.Blizzard_HousingControls()
    local HousingControlsFrame = _G.HousingControlsFrame

    SkinControlFrame(HousingControlsFrame.OwnerControlFrame)
    SkinControlFrame(HousingControlsFrame.VisitorControlFrame)
end