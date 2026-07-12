local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Color = Aurora.Color

do --[[ FrameXML\UIDropDownMenu.xml ]]
    do --[[ UIDropDownMenuTemplates.xml ]]
        function Skin.MenuVariants1(Button)
        end
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
        for _, region in ipairs({ self:GetRegions() }) do
            if region:IsObjectType("Texture") and region:GetAtlas() == "common-dropdown-bg" then
                -- Replace the atlas with a solid Aurora frame color.
                -- SetColorTexture on a Blizzard-created texture is widget-API only —
                -- no Lua table write to the parent frame, no taint.
                region:SetColorTexture(Color.frame.r, Color.frame.g, Color.frame.b, Color.frame.a)
            end
        end
    end)
end

