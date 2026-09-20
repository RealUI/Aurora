local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin

--do --[[ SharedXML\ModelSceneTemplates.lua ]]
--end

do --[[ SharedXML\ModelSceneTemplates.xml ]]
    function Skin.ModifyModelSceneControlFrameBaseButtonTemplate(Button)
            Skin.FrameTypeButton(Button)
        Button:SetBackdropOption("offsets", {
            left = 5,
            right = 5,
            top = 5,
            bottom = 5,
        })
    end
    -- The zoom/rotate/reset bar above a model scene. Camelot shows it on the
    -- character panel, where retail does not, so it went unskinned there and
    -- sat as five common-button-square-gray buttons over the model. The Icon
    -- on each is the glyph (magnifier, arrows) and is left alone; only the
    -- button art is replaced.
    function Skin.ModelSceneControlFrameTemplate(Frame)
        if not Frame then return end

        for _, key in _G.next, {
            "zoomInButton", "zoomOutButton",
            "rotateLeftButton", "rotateRightButton",
            "resetButton",
        } do
            local Button = Frame[key]
            if Button then
                Skin.ModifyModelSceneControlFrameBaseButtonTemplate(Button)
            end
        end
    end
    function Skin.ModelSceneControlFrameTemplateLeftButtonTemplate(Button)
        Skin.ModifyModelSceneControlFrameBaseButtonTemplate(Button)

        local bg = Button:GetBackdropTexture("bg")
        local arrow = Button:CreateTexture(nil, "ARTWORK")
        arrow:SetPoint("TOPLEFT", bg, 8, -5)
        arrow:SetPoint("BOTTOMRIGHT", bg, -8, 4)
        Base.SetTexture(arrow, "arrowLeft")

        Button._auroraTextures = {arrow}
    end
    function Skin.ModelSceneControlFrameTemplateRightButtonTemplate(Button)
        Skin.ModifyModelSceneControlFrameBaseButtonTemplate(Button)

        local bg = Button:GetBackdropTexture("bg")
        local arrow = Button:CreateTexture(nil, "ARTWORK")
        arrow:SetPoint("TOPLEFT", bg, 8, -5)
        arrow:SetPoint("BOTTOMRIGHT", bg, -8, 4)
        Base.SetTexture(arrow, "arrowRight")

        Button._auroraTextures = {arrow}
    end
end

--function private.SharedXML.ModelSceneTemplates()
--end
