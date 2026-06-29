local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

-- Guard: Blizzard_ReforgingUI only exists in Cataclysm-era Classic builds
if not _G.C_AddOns or not _G.C_AddOns.DoesAddOnExist or not _G.C_AddOns.DoesAddOnExist("Blizzard_ReforgingUI") then return end

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

function private.AddOns.Blizzard_ReforgingUI()
    local ReforgingFrame = _G.ReforgingFrame
    if not ReforgingFrame then return end

    -- Apply Aurora backdrop to the main reforging frame
    Base.SetBackdrop(ReforgingFrame, Color.frame, Util.GetFrameAlpha())

    -- Hide portrait texture
    if _G.ReforgingFramePortrait then
        _G.ReforgingFramePortrait:SetAlpha(0)
    end

    -- Hide border textures
    local borderTextures = {
        "ReforgingFrameTopLeft",
        "ReforgingFrameTopRight",
        "ReforgingFrameBottomLeft",
        "ReforgingFrameBottomRight",
    }
    for _, texName in _G.ipairs(borderTextures) do
        local tex = _G[texName]
        if tex then
            tex:Hide()
        end
    end

    -- Skin stat selection dropdowns (source and destination stats)
    if ReforgingFrame.SourceStat then
        if ReforgingFrame.SourceStat.Dropdown then
            Skin.DropdownButton(ReforgingFrame.SourceStat.Dropdown)
        end
    end
    if ReforgingFrame.DestinationStat then
        if ReforgingFrame.DestinationStat.Dropdown then
            Skin.DropdownButton(ReforgingFrame.DestinationStat.Dropdown)
        end
    end

    -- Legacy dropdown globals (older Classic builds)
    if _G.ReforgingFrameSourceStatDropDown then
        Skin.UIDropDownMenuTemplate(_G.ReforgingFrameSourceStatDropDown)
    end
    if _G.ReforgingFrameDestStatDropDown then
        Skin.UIDropDownMenuTemplate(_G.ReforgingFrameDestStatDropDown)
    end

    -- Skin reforge button
    if ReforgingFrame.ReforgeButton then
        Skin.UIPanelButtonTemplate(ReforgingFrame.ReforgeButton)
    elseif _G.ReforgingFrameReforgeButton then
        Skin.UIPanelButtonTemplate(_G.ReforgingFrameReforgeButton)
    end

    -- Skin close button
    if _G.ReforgingFrameCloseButton then
        Skin.UIPanelCloseButton(_G.ReforgingFrameCloseButton)
    elseif ReforgingFrame.CloseButton then
        Skin.UIPanelCloseButton(ReforgingFrame.CloseButton)
    end
end
