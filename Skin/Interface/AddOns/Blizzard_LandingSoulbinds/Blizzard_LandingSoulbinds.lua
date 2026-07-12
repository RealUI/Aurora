local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals select unpack

--[[ Core ]]
local Aurora = private.Aurora
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Util = Aurora.Util

do --[[ AddOns\Blizzard_LandingSoulbinds.lua ]]


    do --[[ Blizzard_LandingSoulbindButton ]]
        Hook.LandingPageSoulbindButtonMixin = {}

        local soulbind = {}
        local soulbinds = {
            Kyrian = {
                path = [[Interface/Soulbinds/SoulbindsShotsKyrian]],
                Kleia = {
                    size = {603, 558},
                    point = {140, 180},
                    coords = {0.000488281, 0.294922, 0.000976562, 0.545898}
                },
                Mikanikos = {
                    size = {578, 558},
                    point = {150, 190},
                    coords = {0.295898, 0.578125, 0.000976562, 0.545898}
                },
                Pelagos = {
                    size = {578, 558},
                    point = {165, 185},
                    coords = {0.579102, 0.861328, 0.000976562, 0.545898}
                }
            },
            Venthyr = {
                path = [[Interface/Soulbinds/SoulbindsShotsVenthyr]],
                Draven = {
                    size = {603, 558},
                    point = {175, 170},
                    coords = {0.606445, 0.900879, 0.000976562, 0.545898}
                },
                Nadjia = {
                    size = {629, 558},
                    point = {115, 165},
                    coords = {0.000488281, 0.307617, 0.000976562, 0.545898}
                },
                Theotar = {
                    size = {608, 558},
                    point = {120, 170},
                    coords = {0.308594, 0.605469, 0.000976562, 0.545898}
                }
            },
            NightFae = {
                path = [[Interface/Soulbinds/SoulbindsShotsFey]],
                Dreamweaver = {
                    size = {603, 558},
                    point = {190, 210},
                    coords = {0.000488281, 0.294922, 0.000976562, 0.545898}
                },
                Niya = {
                    size = {578, 558},
                    point = {165, 185},
                    coords = {0.591309, 0.873535, 0.000976562, 0.545898}
                },
                Korayn = {
                    size = {603, 558},
                    point = {225, 175},
                    coords = {0.295898, 0.590332, 0.000976562, 0.545898}
                }
            },
            Necrolord = {
                path = [[Interface/Soulbinds/SoulbindsShotsNecrolords]],
                Emeni = {
                    size = {629, 558},
                    point = {200, 225},
                    coords = {0.000488281, 0.307617, 0.000976562, 0.545898}
                },
                Marileth = {
                    size = {572, 558},
                    point = {185, 185},
                    coords = {0.588867, 0.868164, 0.000976562, 0.545898}
                },
                Heirmir = {
                    size = {572, 558},
                    point = {130, 175},
                    coords = {0.308594, 0.587891, 0.000976562, 0.545898}
                }
            },
        }

        function Hook.LandingPageSoulbindButtonMixin:SetSoulbind(soulbindData)
            if soulbind.id ~= soulbindData.ID then
                local covenantData = _G.C_Covenants.GetCovenantData(soulbindData.covenantID)

                soulbind.id = soulbindData.ID
                soulbind.path = soulbinds[covenantData.textureKit].path
                soulbind.size = soulbinds[covenantData.textureKit][soulbindData.textureKit].size
                soulbind.coords = soulbinds[covenantData.textureKit][soulbindData.textureKit].coords
                soulbind.point = soulbinds[covenantData.textureKit][soulbindData.textureKit].point
            end

            self.Portrait:ClearAllPoints()
            self.Portrait:SetPoint("TOPRIGHT", unpack(soulbind.point))
            self.Portrait:SetTexture(soulbind.path)
            self.Portrait:SetSize(unpack(soulbind.size))
            self.Portrait:SetTexCoord(unpack(soulbind.coords))
            self.Portrait:SetScale(0.65)
        end
    end
    do --[[ Blizzard_LandingRenownButton ]]
        local atlas = "covenantsanctum-renownlevel-border-%s"

        Hook.LandingPageRenownButtonMixin = {}
        function Hook.LandingPageRenownButtonMixin:UpdateButtonTextures()
            if self._orb then
                local covenantData = _G.C_Covenants.GetCovenantData(_G.C_Covenants.GetActiveCovenantID())
                self._orb:SetAtlas(atlas:format(covenantData.textureKit), true)
                self:SetButtonColor(private.COVENANT_COLORS[covenantData.textureKit])
            end
        end
    end
    do --[[ Blizzard_LandingSoulbindPanel ]]
        function Hook.LandingSoulbind_Create(parent)
            local SoulbindPanel = select(parent:GetNumChildren(), parent:GetChildren())
            Skin.LandingPageSoulbindPanelTemplate(SoulbindPanel)
        end
    end
end

do --[[ AddOns\Blizzard_LandingSoulbinds.xml ]]
    do --[[ Blizzard_LandingSoulbindButton ]]
        function Skin.LandingPageSoulbindButtonTemplate(Button)
            Skin.FrameTypeButton(Button)
            Button:SetBackdropOption("offsets", {
                left = 7,
                right = 7,
                top = 8,
                bottom = 6,
            })

            Button.Press:SetAlpha(0)
            Button.Highlight:SetAlpha(0)

            local clipFrame = _G.CreateFrame("Frame", nil, Button)
            clipFrame:SetClipsChildren(true)
            clipFrame:SetPoint("TOPLEFT", 8, -9)
            clipFrame:SetPoint("BOTTOMRIGHT", -8, 7)

            Button.Portrait:SetParent(clipFrame)
            Button.Portrait:SetDesaturated(true)
            Button.Portrait:SetAlpha(0.6)
        end
    end
    do --[[ Blizzard_LandingRenownButton ]]
        function Skin.LandingPageRenownButtonTemplate(Button)
            Skin.FrameTypeButton(Button)
            Button:SetBackdropOption("offsets", {
                left = 7,
                right = 7,
                top = 8,
                bottom = 6,
            })

            Button.PushedImage:SetAlpha(0)
            Button:GetHighlightTexture():SetAlpha(0)

            local clipFrame = _G.CreateFrame("Frame", nil, Button)
            clipFrame:SetClipsChildren(true)
            clipFrame:SetPoint("TOPLEFT", 8, -9)
            clipFrame:SetPoint("BOTTOMRIGHT", -8, 7)

            Button.Label:SetParent(clipFrame)
            Button.Renown:SetParent(clipFrame)

            local orb = clipFrame:CreateTexture(nil, "ARTWORK")
            orb:SetPoint("RIGHT", 131, 0)
            orb:SetAlpha(0.5)
            orb:SetScale(0.89)
            Button._orb = orb
        end
    end
    do --[[ Blizzard_LandingSoulbindPanel ]]
        function Skin.LandingPageSoulbindPanelTemplate(Frame)
            local divider = Frame:GetRegions()
            divider:SetColorTexture(1, 1, 1, 0.2) -- static: not a theme color
            divider:SetSize(261, 1)
            divider:SetPoint("TOPLEFT", 50, 0)
            Skin.LandingPageRenownButtonTemplate(Frame.RenownButton)
            Hook.LandingPageRenownButtonMixin.UpdateButtonTextures(Frame.RenownButton)
            Skin.LandingPageSoulbindButtonTemplate(Frame.SoulbindButton)
        end
    end
end

function private.AddOns.Blizzard_LandingSoulbinds()
    ----====####################====----
    -- Blizzard_LandingSoulbindButton --
    ----====####################====----
    Util.Mixin(_G.LandingPageSoulbindButtonMixin, Hook.LandingPageSoulbindButtonMixin)

    ----====####################====----
    -- Blizzard_LandingRenownButton --
    ----====####################====----
    Util.Mixin(_G.LandingPageRenownButtonMixin, Hook.LandingPageRenownButtonMixin)

    ----====#####################====----
    --  Blizzard_LandingSoulbindPanel  --
    ----====#####################====----
    _G.hooksecurefunc(_G.LandingSoulbind, "Create", Hook.LandingSoulbind_Create)
end
