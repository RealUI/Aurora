local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals next

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

do --[[ SharedXML\NineSlice.lua ]]
    local nineSliceSetup = {
        "TopLeftCorner",
        "TopRightCorner",
        "BottomLeftCorner",
        "BottomRightCorner",
        "TopEdge",
        "BottomEdge",
        "LeftEdge",
        "RightEdge",
        "Center",
    }

    local function BasicFrame(Frame, kit)
        Skin.FrameTypeFrame(Frame)
        Base.SetBackdropColor(Frame, kit.backdrop, Util.GetFrameAlpha())
    end

    local function InsetFrame(Frame, kit)
        Base.SetBackdrop(Frame, kit.backdrop, Color.frame.a)
    end

    local function HideFrame(Frame, kit)
        Base.SetBackdrop(Frame, kit.backdrop, 0)
        Frame:SetBackdropBorderColor(kit.backdrop, 0)
    end

    local layouts = {
        SimplePanelTemplate = BasicFrame,
        PortraitFrameTemplate = BasicFrame,
        PortraitFrameTemplateMinimizable = BasicFrame,
        ButtonFrameTemplateNoPortrait = BasicFrame,
        ButtonFrameTemplateNoPortraitMinimizable = BasicFrame,
        InsetFrameTemplate = HideFrame,
        BFAMissionHorde = BasicFrame,
        BFAMissionAlliance = BasicFrame,
        --CovenantMissionFrame = BasicFrame,
        GenericMetal = BasicFrame,
        Dialog = function(Frame, kit)
            if Frame.debug then
                _G.print("Layout Dialog", Frame.debug, kit)
            end

            BasicFrame(Frame, kit)
            Frame:SetBackdropOption("offsets", {
                left = 5,
                right = 5,
                top = 5,
                bottom = 5,
            })
        end,
        WoodenNeutralFrameTemplate = BasicFrame,
        Runeforge = BasicFrame,
        AdventuresMissionComplete = InsetFrame,
        CharacterCreateDropdown = BasicFrame,
        --ChatBubble = BasicFrame,
        SelectionFrameTemplate = BasicFrame,
        UniqueCornersLayout = BasicFrame,
        --GMChatRequest = BasicFrame,
        TooltipDefaultLayout = BasicFrame,
        TooltipAzeriteLayout = BasicFrame,
        TooltipCorruptedLayout = BasicFrame,
        TooltipMawLayout = BasicFrame,
        --TooltipGluesLayout = BasicFrame,
        --TooltipMixedLayout = BasicFrame,
        HeldBagLayout = BasicFrame,
        --IdenticalCornersLayoutNoCenter = BasicFrame,
        IdenticalCornersLayout = BasicFrame,
        --ThreeSliceVerticalLayout = BasicFrame,
        --ThreeSliceHorizontalLayout = BasicFrame,

        -- Blizzard_OrderHallTalents
        BFAOrderTalentHorde = BasicFrame,
        BFAOrderTalentAlliance = BasicFrame,

        -- Blizzard_PartyPoseUI
        PartyPoseFrameTemplate = BasicFrame,
        PartyPoseKit = BasicFrame,
    }

    local function GetNameforLayout(container, userLayout)
        if container.debug then
            _G.print("GetNameforLayout", container.debug, userLayout, container.GetFrameLayoutType)
        end

        if type(userLayout) == "string" then
            return userLayout
        end

        if type(userLayout) == "table" then
            for layoutName, layout in next, _G.NineSliceLayouts do
                if layout == userLayout then
                    return layoutName
                end
            end
        end

        local layoutType = userLayout
        if container.GetFrameLayoutType then
            local ok, resolvedLayoutType = _G.pcall(container.GetFrameLayoutType, container)
            if ok then
                layoutType = resolvedLayoutType
            end
        elseif container.backdropInfo then
            if container.backdropInfo.bgFile:find("DialogBox") then
                return "Dialog"
            else
                return "SimplePanelTemplate"
            end
        end

        if container.debug then
            _G.print("find name", container.debug, layoutType)
        end

        if layoutType then
            return layoutType
        end

        for layoutName, layout in next, _G.NineSliceLayouts do
            if layout == userLayout then
                return layoutName
            end
        end
    end

    Hook.NineSliceUtil = {}
    function Hook.NineSliceUtil.ApplyLayout(container, userLayout, textureKit)
        if not container._auroraNineSlice then return end
        if textureKit == "AuroraSkin" or container._applyLayout then return end

        container._applyLayout = true
        local userLayoutName = GetNameforLayout(container, userLayout)

        if container.debug then
            _G.print("ApplyLayout", container.debug, userLayout, userLayoutName, textureKit)
            if not userLayoutName and not textureKit then
                _G.error("Found usage")
            end
        end

        if layouts[userLayoutName] then
            if container.debug then
                private.debug("Apply layout with textureKit", userLayoutName)
            end
            layouts[userLayoutName](container, Util.GetTextureKit(textureKit))
        else
            if userLayoutName then
                private.debug("Missing skin for nineslice layout", userLayoutName)
            elseif private.isDev then
                _G.print("Missing name for nineslice layout:", container:GetDebugName())
            end

            if not container.SetBackdropOption then return end
            container:SetBackdrop(private.backdrop)
            for i = 1, #nineSliceSetup do
                local piece = Util.GetNineSlicePiece(container, nineSliceSetup[i])
                if piece then
                    piece:SetTexture("")
                end
            end
        end
        container._applyLayout = false
    end
end

function private.SharedXML.NineSlice()
    Util.Mixin(_G.NineSliceUtil, Hook.NineSliceUtil)
end
