local _, private = ...
if private.shouldSkip() then return end

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin

do --[[ AddOns\Blizzard_MapCanvas.xml ]]
    function Skin.MapCanvasFrameScrollContainerTemplate(ScrollFrame)
    end
    function Skin.MapCanvasFrameTemplate(Frame)
    end
end

function private.AddOns.Blizzard_MapCanvas()
    ----====####################====----
    --   MapCanvas_DataProviderBase   --
    ----====####################====----

    ----====#####################====----
    -- MapCanvas_PinFrameLevelsManager --
    ----====#####################====----

    ----====#####################====----
    --  Blizzard_MapCanvasDetailLayer  --
    ----====#####################====----

    ----====####################====----
    -- MapCanvas_ScrollContainerMixin --
    ----====####################====----
    -- NOTE: Previously this block replaced IsZoomingIn, IsZoomingOut,
    -- CalculateLerpScaling, and RefreshCanvasScale via direct table writes on
    -- MapCanvasScrollControllerMixin (to add nil guards that WoW 12 no longer
    -- needs).  Direct writes to a mixin table taint every frame that uses it.
    -- When Blizzard's secure pin-acquisition path (secureexecuterange →
    -- AcquirePin → OnAcquired → UpdateMousePropagation) runs, the taint from
    -- those writes bleeds in and blocks SetPropagateMouseClicks.
    -- The replacements have been removed; Blizzard's originals handle nil safely.

    ----====####################====----
    --       Blizzard_MapCanvas       --
    ----====####################====----
end
