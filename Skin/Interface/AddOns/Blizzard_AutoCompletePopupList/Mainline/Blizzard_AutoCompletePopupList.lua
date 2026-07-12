local _, private = ...
if private.shouldSkip() then return end

local Aurora = private.Aurora
local Base, Hook = Aurora.Base, Aurora.Hook
local Color = Aurora.Color

do --[[ AddOns\Blizzard_AutoCompletePopupList.lua ]]
    -- Skin an AutoCompletePopupListResultTemplate entry
    local function SkinResultEntry(frame)
        if not frame or frame._auroraSkinned then return end

        -- Crop the ability/item icon
        if frame.Icon then
            Base.CropIcon(frame.Icon)
        end

        -- Hide the decorative icon border atlas
        if frame.IconFrame then
            frame.IconFrame:SetAlpha(0)
        end

        frame._auroraSkinned = true
    end

    -- Callback for ScrollUtil.AddAcquiredFrameCallback
    function Hook.AutoCompletePopupListScrollBoxCallback(o, frame)
        SkinResultEntry(frame)
    end
end

function private.AddOns.Blizzard_AutoCompletePopupList()
    ------------------------------------
    -- Find all AutoCompletePopupList instances
    -- The template is virtual; instances are created by parent addons.
    -- We hook the mixin's OnLoad to catch any instance.
    ------------------------------------
    _G.hooksecurefunc(_G.AutoCompletePopupListMixin, "OnLoad", function(self)
        if self._auroraSkinned then return end

        ------------------------------------
        -- Apply Aurora backdrop
        ------------------------------------
        Base.SetBackdrop(self, Color.frame)

        ------------------------------------
        -- Strip border textures and background
        ------------------------------------
        local texturesToHide = { "Background", "BorderAnchor", "BotRightCorner", "BottomBorder", "LeftBorder", "RightBorder" }
        for _, key in ipairs(texturesToHide) do
            if self[key] then
                self[key]:SetAlpha(0)
            end
        end

        ------------------------------------
        -- ScrollBox: skin dynamically acquired result entries
        ------------------------------------
        local scrollBox = self.ScrollBox
        if scrollBox then
            _G.ScrollUtil.AddAcquiredFrameCallback(scrollBox, Hook.AutoCompletePopupListScrollBoxCallback, self)

            -- Skin any already-existing frames
            scrollBox:ForEachFrame(function(child)
                if not child._auroraSkinned then
                    if child.Icon then
                        Base.CropIcon(child.Icon)
                    end
                    if child.IconFrame then
                        child.IconFrame:SetAlpha(0)
                    end
                    child._auroraSkinned = true
                end
            end)
        end

        self._auroraSkinned = true
    end)
end
