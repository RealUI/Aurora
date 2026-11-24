local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs next

--[[ Core ]]
local Aurora = private.Aurora
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

-- B261 (task 5.3): option frames and buttons already styled. Was
-- `__auroraStyled` on the Blizzard frames. The option frames come from
-- optionPools, one pool per template, so a frame keeps its template when it
-- comes back; the confirm buttons come from each option's buttonFramePool
-- and the toggle buttons are kept. The skin is the frame's own, so the mark
-- stays right through release and reuse; weak keys let it go with the frame.
local styled = _G.setmetatable({}, {__mode = "k"})

do --[[ AddOns\Blizzard_PlayerChoice.lua ]]
    do -- Blizzard_PlayerChoice
        Hook.PlayerChoiceFrameMixin = {}
        function Hook.PlayerChoiceFrameMixin:SetupFrame()
            -- Store pre-hide dimensions to detect layout recalculation
            local preW, preH = self:GetWidth(), self:GetHeight()

            -- Blizzard re-textures the NineSlice via ApplyIdenticalCornersLayout /
            -- ApplyUniqueCornersLayout on each SetupFrame call, which applies atlas
            -- textures (SetAtlas) to the pieces.  SetTexture("") does NOT clear atlas
            -- mode, so the kit art would still render.  Hiding the whole NineSlice
            -- child frame avoids all of this; Aurora's own backdrop (applied directly
            -- to PlayerChoiceFrame by Skin.FrameTypeFrame) provides the background.
            self.NineSlice:Hide()
            -- Hide the new single-atlas overlay introduced for kits without useOldNineSlice
            if self.BorderOverlay then
                self.BorderOverlay:SetAlpha(0)
            end
            if self.BlackBackground then
                self.BlackBackground:SetAlpha(0)
            end
            -- 3-D border model scene (renders at BORDER draw layer over entire frame)
            if self.BorderLayerModelScene then
                self.BorderLayerModelScene:SetAlpha(0)
                self.BorderLayerModelScene:Hide()
            end
            -- Blizzard re-shows Background (a child Frame) and sets BackgroundTile each call;
            -- zero the tile texture and hide the whole frame so nothing bleeds through.
            if self.Background.BackgroundTile then
                self.Background.BackgroundTile:SetTexture("")
                self.Background.BackgroundTile:SetAlpha(0)
            end
            self.Background:Hide()
            if self.Header then
                self.Header.Texture:SetAlpha(0)
            end
            Skin.UIPanelCloseButton(self.CloseButton)
            if self.Title then
                if self.Title.Left then self.Title.Left:Hide() end
                if self.Title.Right then self.Title.Right:Hide() end
                if self.Title.Middle then self.Title.Middle:Hide() end
            end

            -- Restore dimensions if hiding NineSlice triggered a layout recalculation
            if self:GetWidth() ~= preW or self:GetHeight() ~= preH then
                self:SetSize(preW, preH)
            end

            -- Constrain frame to screen-safe dimensions
            local maxWidth = _G.GetScreenWidth() * 0.9
            local maxHeight = _G.GetScreenHeight() * 0.85
            if maxWidth > 0 and self:GetWidth() > maxWidth then self:SetWidth(maxWidth) end
            if maxHeight > 0 and self:GetHeight() > maxHeight then self:SetHeight(maxHeight) end

            -- Fix positioning for Worldsoul/TWW panels: Aurora's skinning changes the layout.
            -- Position lower on screen to prevent covering too much UI space.
            if self.uiTextureKit == "thewarwithin" or self.uiTextureKit == "midnight" then
                self:ClearAllPoints()
                self:SetPoint("CENTER", 0, -600)
            end
        end

        function Hook.PlayerChoiceFrameMixin:SetupOptions()
            -- Skin the toggle buttons in the frame-level OptionButtonsContainer
            if self.OptionButtonsContainer then
                for _, toggleFrame in next, {self.OptionButtonsContainer:GetChildren()} do
                    if toggleFrame.Button and not styled[toggleFrame.Button] then
                        Skin.UIPanelButtonTemplate(toggleFrame.Button)
                        styled[toggleFrame.Button] = true
                    end
                end
            end

            -- Skin each pooled option frame; frames are created lazily so we
            -- must do this here rather than at addon load time.
            -- Map template name → the Hook mixin that holds the Setup logic,
            -- so we can invoke it immediately (Setup already ran before this hook fires).
            local templateHooks = {
                PlayerChoiceNormalOptionTemplate = Hook.PlayerChoiceNormalOptionTemplateMixin,
                PlayerChoiceCovenantChoiceOptionTemplate = Hook.PlayerChoiceCovenantChoiceOptionTemplateMixin,
            }
            if self.optionPools and self.optionFrameTemplate then
                local hookMixin = templateHooks[self.optionFrameTemplate]
                for optionFrame in self.optionPools:EnumerateActiveByTemplate(self.optionFrameTemplate) do
                    if not styled[optionFrame] then
                        local skinFunc = Skin[self.optionFrameTemplate]
                        if skinFunc then
                            -- Hook future Setup calls on this frame
                            skinFunc(optionFrame)
                        end
                        -- Apply the visual changes for the current display pass;
                        -- Setup already ran before our SetupOptions hook fired.
                        if hookMixin and hookMixin.Setup then
                            hookMixin.Setup(optionFrame, optionFrame.optionInfo,
                                optionFrame.frameTextureKit, optionFrame.soloOption, optionFrame.showAsList)
                        end
                        styled[optionFrame] = true
                    end
                end
            end
        end
    end
    --do -- Blizzard_PlayerChoiceToggleButton
    --end
    do -- Blizzard_PlayerChoiceOptionBase
        Hook.PlayerChoiceBaseOptionTemplateMixin = {}
        function Hook.PlayerChoiceBaseOptionTemplateMixin:Setup(optionInfo, frameTextureKit, soloOption, showAsList)
            -- OptionText is a PlayerChoiceBaseOptionTextTemplateMixin frame with its own
            -- SetTextColor that dispatches correctly for HTML vs plain-text mode.
            -- Note: for PlayerChoiceNormalOptionTemplate, Blizzard re-sets the color AFTER
            -- this base Setup returns, so the Normal hook overrides it again there.
            if self.OptionText then
                self.OptionText:SetTextColor(Color.white:GetRGBA())
            end
        end
    end
    do -- Blizzard_PlayerChoiceNormalOptionTemplate
        Hook.PlayerChoiceNormalOptionTemplateMixin = {}
        function Hook.PlayerChoiceNormalOptionTemplateMixin:Setup(optionInfo, frameTextureKit, soloOption, showAsList)
            local kit = Util.GetTextureKit(frameTextureKit)
            self.Background:SetAlpha(0)
            self.ArtworkBorder:SetAlpha(0)

            self.Header.Ribbon:SetAlpha(0)
            self.Header.Contents.Text:SetTextColor(kit.title:GetRGBA())

            --self.SubHeader.BG:SetAlpha(0)
            self.SubHeader.Text:SetTextColor(kit.title:GetRGBA())

            -- Blizzard overwrites OptionText color in this same Setup call (after base runs);
            -- override it here, after Blizzard has set it, using the mixin's own SetTextColor
            -- which correctly handles the HTML vs plain-text switch.
            if self.OptionText then
                self.OptionText:SetTextColor(Color.white:GetRGBA())
            end

            -- Skin the choice confirm buttons created by the option button pool
            if self.OptionButtonsContainer and self.OptionButtonsContainer.buttonFramePool then
                for buttonFrame in self.OptionButtonsContainer.buttonFramePool:EnumerateActive() do
                    if buttonFrame.Button and not styled[buttonFrame.Button] then
                        Skin.UIPanelButtonTemplate(buttonFrame.Button)
                        styled[buttonFrame.Button] = true
                    end
                end
            end
        end
    end
    --do -- Blizzard_PlayerChoicePowerChoiceTemplate
    --end
    --do -- Blizzard_PlayerChoiceTorghastOptionTemplate
    --end
    do -- Blizzard_PlayerChoiceCovenantChoiceOptionTemplate
        Hook.PlayerChoiceCovenantChoiceOptionTemplateMixin = {}
        function Hook.PlayerChoiceCovenantChoiceOptionTemplateMixin:Setup(optionInfo, frameTextureKit, soloOption, showAsList)
            self.BackgroundShadowSmall:SetAlpha(0)
            self.BackgroundShadowLarge:SetAlpha(0)
        end
    end
    --do -- Blizzard_PlayerChoiceCypherOptionTemplate
    --end
    --do -- Blizzard_PlayerChoiceTimer
    --end
end

do --[[ AddOns\Blizzard_PlayerChoice.xml ]]
    --do -- Blizzard_PlayerChoiceToggleButton
    --end
    do -- Blizzard_PlayerChoiceOptionBase
        function Skin.PlayerChoiceBaseOptionButtonTemplate(Button)
            Skin.UIPanelButtonTemplate(Button)
        end
        function Skin.PlayerChoiceBaseSmallerOptionButtonTemplate(Button)
            Skin.PlayerChoiceBaseOptionButtonTemplate(Button)
        end
        function Skin.PlayerChoiceBaseOptionTemplate(Frame)
            Util.Mixin(Frame, Hook.PlayerChoiceBaseOptionTemplateMixin)
        end
    end
    do -- Blizzard_PlayerChoiceNormalOptionTemplate
        function Skin.PlayerChoiceNormalOptionTemplate(Frame)
            Skin.PlayerChoiceBaseOptionTemplate(Frame)
            Util.Mixin(Frame, Hook.PlayerChoiceNormalOptionTemplateMixin)
        end
    end
    --do -- Blizzard_PlayerChoicePowerChoiceTemplate
    --end
    --do -- Blizzard_PlayerChoiceTorghastOptionTemplate
    --end
    do -- Blizzard_PlayerChoiceCovenantChoiceOptionTemplate
        function Skin.PlayerChoiceCovenantChoiceOptionTemplate(Frame)
            Skin.PlayerChoiceBaseOptionTemplate(Frame)
            Util.Mixin(Frame, Hook.PlayerChoiceCovenantChoiceOptionTemplateMixin)
        end
    end
    --do -- Blizzard_PlayerChoiceCypherOptionTemplate
    --end
    --do -- Blizzard_PlayerChoiceTimer
    --end
end

function private.AddOns.Blizzard_PlayerChoice()
    ----====#####################====----
    --      Blizzard_PlayerChoice      --
    ----====#####################====----
    local PlayerChoiceFrame = _G.PlayerChoiceFrame
    Util.Mixin(PlayerChoiceFrame, Hook.PlayerChoiceFrameMixin)
    Skin.FrameTypeFrame(PlayerChoiceFrame)
    Skin.NineSlicePanelTemplate(PlayerChoiceFrame.NineSlice)
    PlayerChoiceFrame.NineSlice:SetFrameLevel(1)
    Skin.UIPanelCloseButton(PlayerChoiceFrame.CloseButton)

    -- Solid Aurora background sitting below all Blizzard layers (Background tile,
    -- BorderOverlay, etc.) — mirrors the treatment on PlayerSpellsFrame sub-frames.
    if not PlayerChoiceFrame._auroraBackground then
        local bg = PlayerChoiceFrame:CreateTexture(nil, "BACKGROUND", nil, -8)
        bg:SetColorTexture(Color.panelBg:GetRGB())
        bg:SetAllPoints(PlayerChoiceFrame)
        PlayerChoiceFrame._auroraBackground = bg
    end

    -- 3-D border model scene covers the entire frame at BORDER draw layer
    if PlayerChoiceFrame.BorderLayerModelScene then
        PlayerChoiceFrame.BorderLayerModelScene:SetAlpha(0)
        PlayerChoiceFrame.BorderLayerModelScene:Hide()
    end

    -- Background is a child Frame (not a texture) so it always renders above parent
    -- textures regardless of sub-level. Blizzard calls Show() on it inside SetupFrame,
    -- so hook OnShow to permanently suppress it.
    if PlayerChoiceFrame.Background.BackgroundTile then
        PlayerChoiceFrame.Background.BackgroundTile:SetTexture("")
        PlayerChoiceFrame.Background.BackgroundTile:SetAlpha(0)
    end
    PlayerChoiceFrame.Background:Hide()
    PlayerChoiceFrame.Background:HookScript("OnShow", function(self) self:Hide() end)

    ----====############%%%########====----
    -- Blizzard_PlayerChoiceToggleButton --
    ----====############%%%########====----


    ----====#####################====----
    -- Blizzard_PlayerChoiceOptionBase --
    ----====#####################====----
    Util.Mixin(_G.PlayerChoiceBaseOptionTemplateMixin, Hook.PlayerChoiceBaseOptionTemplateMixin)


    ----====####################%%%########====----
    -- Blizzard_PlayerChoiceNormalOptionTemplate --
    ----====####################%%%########====----


    ----====####################%%########====----
    -- Blizzard_PlayerChoicePowerChoiceTemplate --
    ----====####################%%########====----


    ----====#################################====----
    -- Blizzard_PlayerChoiceTorghastOptionTemplate --
    ----====#################################====----


    ----====############################%%%########====----
    -- Blizzard_PlayerChoiceCovenantChoiceOptionTemplate --
    ----====############################%%%########====----


    ----====####################%%%########====----
    -- Blizzard_PlayerChoiceCypherOptionTemplate --
    ----====####################%%%########====----


    ----====####################====----
    --   Blizzard_PlayerChoiceTimer   --
    ----====####################====----
end
