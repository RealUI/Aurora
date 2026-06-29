local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals select

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

do --[[ FrameXML\GroupLootFrame.xml ]]
    function Skin.GroupLootFrameTemplate(Frame)
        if not Frame then return end

        local frameName = Frame:GetName()
        if not frameName then return end

        -- Strip Blizzard border/decoration textures
        local slotTexture = _G[frameName.."SlotTexture"]
        if slotTexture then
            slotTexture:SetTexture("")
        end

        local nameFrame = _G[frameName.."NameFrame"]
        if nameFrame then
            nameFrame:SetTexture("")
        end

        local decoration = _G[frameName.."Decoration"]
        if decoration then
            decoration:Hide()
        end

        local corner = _G[frameName.."Corner"]
        if corner then
            corner:Hide()
        end

        -- Apply Aurora backdrop
        Base.SetBackdrop(Frame, Color.frame, Util.GetFrameAlpha())

        -- Skin the icon button
        local iconFrame = Frame.IconFrame
        if iconFrame then
            if iconFrame.Icon then
                Base.CropIcon(iconFrame.Icon, iconFrame)
            end
            if iconFrame.SetNormalTexture then
                iconFrame:SetNormalTexture("")
            end
            if iconFrame.SetHighlightTexture then
                iconFrame:SetHighlightTexture("")
            end
        end

        -- Skin roll buttons
        local needButton = Frame.NeedButton
        if needButton then
            if Skin.FrameTypeButton then
                Skin.FrameTypeButton(needButton)
            end
        end

        local greedButton = Frame.GreedButton
        if greedButton then
            if Skin.FrameTypeButton then
                Skin.FrameTypeButton(greedButton)
            end
        end

        -- Skin pass button (inherits UIPanelCloseButton)
        local passButton = Frame.PassButton
        if passButton then
            if Skin.UIPanelCloseButton then
                Skin.UIPanelCloseButton(passButton)
            end
        end

        -- Skin disenchant button (may exist in some TBC builds)
        local disenchantButton = Frame.DisenchantButton
        if disenchantButton then
            if Skin.FrameTypeButton then
                Skin.FrameTypeButton(disenchantButton)
            end
        end

        -- Skin the timer status bar
        local timer = Frame.Timer
        if timer then
            if Skin.FrameTypeStatusBar then
                Skin.FrameTypeStatusBar(timer)
            else
                -- Fallback: strip border texture and apply minimal backdrop
                for i = 1, timer:GetNumRegions() do
                    local region = select(i, timer:GetRegions())
                    if region and region.GetObjectType and region:GetObjectType() == "Texture" then
                        local drawLayer = region:GetDrawLayer()
                        if drawLayer == "ARTWORK" then
                            region:SetTexture("")
                        end
                    end
                end
                Base.SetBackdrop(timer, Color.button)
            end
        end
    end
end

function private.FrameXML.GroupLootFrame()
    ---------------------
    -- GroupLootFrames --
    ---------------------
    local NUM_GROUP_LOOT_FRAMES = _G.NUM_GROUP_LOOT_FRAMES or 4

    for i = 1, NUM_GROUP_LOOT_FRAMES do
        local frame = _G["GroupLootFrame"..i]
        if frame then
            Skin.GroupLootFrameTemplate(frame)
        end
    end
end
