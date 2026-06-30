local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals next

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Color = Aurora.Color

-- TBC-safe action-button skin helper.
--
-- Aurora's Skin.ActionButtonTemplate (defined in Blizzard_ActionBarController)
-- dereferences Mainline-only member fields (AutoCastable, AutoCastShine, ...)
-- without nil guards. The TBC Classic Anniversary ActionButtonTemplate does not
-- have those fields, so calling that helper on these buttons would raise a nil
-- error. Per design Component 1 we use this local helper instead, which only
-- touches regions that exist in the TBC template and guards every reference.
local function SkinActionButton(button)
    if not button then return end

    local name = button.GetName and button:GetName()

    -- Crop the icon to hide the built-in border art
    local icon = button.icon or (name and _G[name.."Icon"])
    if icon then
        Base.CropIcon(icon)
    end

    -- Tuck the cooldown swipe inside the cropped icon
    local cooldown = button.cooldown or (name and _G[name.."Cooldown"])
    if cooldown then
        cooldown:ClearAllPoints()
        cooldown:SetPoint("TOPLEFT", icon or button, 2, -2)
        cooldown:SetPoint("BOTTOMRIGHT", icon or button, -2, 2)
    end

    -- Remove the Blizzard normal/quickslot art so the flat backdrop shows
    if button.ClearNormalTexture then
        button:ClearNormalTexture()
    else
        local normal = (button.GetNormalTexture and button:GetNormalTexture())
            or button.NormalTexture
            or (name and _G[name.."NormalTexture"])
        if normal then
            normal:SetTexture("")
        end
    end

    -- Hide the spell-proc border and floating background art
    local border = button.Border or (name and _G[name.."Border"])
    if border then
        border:Hide()
    end

    local floatingBG = name and _G[name.."FloatingBG"]
    if floatingBG then
        floatingBG:SetTexture("")
    end

    -- Textures are hidden above; apply the flat backdrop last (ordering rule)
    Base.SetBackdrop(button, Color.frame, 0.3)
    if button.SetBackdropOption then
        button:SetBackdropOption("offsets", {
            left = -1,
            right = -1,
            top = -1,
            bottom = -1,
        })
    end
end

function private.AddOns.Blizzard_ActionBar()
    -- Strip the race/class artwork tiles from the main bar
    local MainMenuBarArtFrame = _G.MainMenuBarArtFrame
    if MainMenuBarArtFrame then
        for _, region in next, {MainMenuBarArtFrame:GetRegions()} do
            if region and region.IsObjectType and region:IsObjectType("Texture") then
                region:Hide()
            end
        end
    end

    -- Hide the gryphon/end-cap art (nil-guarded per global)
    if _G.MainMenuBarLeftEndCap then
        _G.MainMenuBarLeftEndCap:Hide()
    end
    if _G.MainMenuBarRightEndCap then
        _G.MainMenuBarRightEndCap:Hide()
    end

    -- Main action bar buttons (1-12)
    for i = 1, 12 do
        SkinActionButton(_G["ActionButton"..i])
    end

    -- Stance/shapeshift bar buttons (1-10)
    for i = 1, 10 do
        SkinActionButton(_G["StanceButton"..i])
    end

    -- Secondary action bars (12 buttons each); skip any bar absent in this build
    local multiBars = {
        "MultiBarBottomLeft",
        "MultiBarBottomRight",
        "MultiBarRight",
        "MultiBarLeft",
    }
    for _, barName in next, multiBars do
        if _G[barName] then
            for i = 1, 12 do
                SkinActionButton(_G[barName.."Button"..i])
            end
        end
    end
end
