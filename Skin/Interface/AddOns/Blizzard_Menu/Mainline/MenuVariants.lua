local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Color = Aurora.Color

-- Minimum background opacity for popup menus, regardless of Frame Opacity.
local MENU_MIN_ALPHA = 0.9

do --[[ FrameXML\UIDropDownMenu.xml ]]
    do --[[ UIDropDownMenuTemplates.xml ]]
        function Skin.MenuVariants1(Button)
        end
    end
end


-- B41: menu checkboxes/radios (e.g. the Calendar "Filters" popup) use gold
-- Blizzard atlases that clash with the Aurora look. The selection textures are
-- created fresh every time a menu is generated, so restyle them from a
-- hooksecurefunc post-hook on MenuVariants — widget-API calls only
-- (SetDesaturated/SetVertexColor), no writes to the pooled menu frames.
local function SkinSelectionTextures(_, frame)
    local box = frame.leftTexture1
    if box then
        box:SetDesaturated(true)
    end
    local tick = frame.leftTexture2
    if tick then
        tick:SetDesaturated(true)
        tick:SetVertexColor(Color.highlight:GetRGB())
    end
end

-- Registered under the real addon name: the previous key ("MenuVariants")
-- never matched a loadable addon, so this hook never fired.
function private.AddOns.Blizzard_Menu()
    -- Hook MenuStyle1Mixin:Generate to replace the atlas background with Aurora's color.
    -- This affects all context menus and dropdown popups that use the default menu style.
    --
    -- TAINT NOTE: Do NOT call Base.SetBackdrop(self, ...) here. Base.SetBackdrop writes
    -- backdrop metadata directly to the frame's Lua table, marking it as addon-modified
    -- (tainted). Menu item OnClick handlers dispatch through this container frame, so a
    -- tainted MenuStyle1 frame propagates into the click context. When "View Houses" is
    -- clicked and Blizzard_HouseList loads for the first time, scroll entry Init runs in
    -- the tainted context and SetScript("OnClick", GenerateClosure(...)) installs a
    -- tainted click handler on VisitHouseButton. The next "Visit House" click then
    -- triggers ADDON_ACTION_FORBIDDEN for C_Housing.VisitHouse.
    --
    -- Safe alternative: recolor the Blizzard-created background texture via the widget
    -- API (SetColorTexture). This does not write to the frame's Lua table and is safe.
    _G.hooksecurefunc(_G.MenuStyle1Mixin, "Generate", function(self)
        -- Color.frame carries the user's Frame Opacity setting (0.2 by
        -- default). That reads fine on a large panel, but a dropdown is a
        -- transient popup drawn over arbitrary world and UI content — at 0.2
        -- the entries are unreadable, which is what Blizzard's opaque
        -- common-dropdown-bg atlas was providing. Floor the alpha so menus
        -- stay legible while still following the frame colour.
        local alpha = _G.math.max(Color.frame.a or 1, MENU_MIN_ALPHA)

        for _, region in ipairs({ self:GetRegions() }) do
            if region:IsObjectType("Texture") and region:GetAtlas() == "common-dropdown-bg" then
                -- Replace the atlas with a solid Aurora frame color.
                -- SetColorTexture on a Blizzard-created texture is widget-API only —
                -- no Lua table write to the parent frame, no taint.
                region:SetColorTexture(Color.frame.r, Color.frame.g, Color.frame.b, alpha)
            end
        end
    end)

    if _G.MenuVariants then
        if _G.MenuVariants.CreateCheckbox then
            _G.hooksecurefunc(_G.MenuVariants, "CreateCheckbox", SkinSelectionTextures)
        end
        if _G.MenuVariants.CreateRadio then
            _G.hooksecurefunc(_G.MenuVariants, "CreateRadio", SkinSelectionTextures)
        end
    end
end

