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
