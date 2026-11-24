local _, private = ...
if private.shouldSkip() then
    return
end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin

function private.FrameXML.ReadyCheck()
    local ReadyCheckListenerFrame = _G.ReadyCheckListenerFrame
    Skin.NineSlicePanelTemplate(ReadyCheckListenerFrame.NineSlice)
    ReadyCheckListenerFrame.NineSlice:SetFrameLevel(1)
    _G.ReadyCheckFrameText:SetPoint("TOP", ReadyCheckListenerFrame.NineSlice, "TOP", 0, -30)
    _G.select(2, ReadyCheckListenerFrame.NineSlice:GetRegions()):Hide()
    --[[ B261 Layer 2 (A-candidate, tasks.md 3.2.5), read from wow-ui-source
        (retail) and wow-ui-source-forever. READY_CHECK shows the frame
        (Blizzard_FrameXML/Mainline/ReadyCheck.lua:55, :64-65, :23-26;
        Forever :36, :45-46, :23-26), in combat too; the clicks run
        C_PartyInfo.ConfirmReadyCheck (ReadyCheck.xml:87, :100, both trees).
        Blizzard sets only their text (:59-60; Forever :40-41) and never
        enables, disables or re-skins them. Shape "panel":
        UIPanelButtonTemplate buttons in XML (ReadyCheck.xml:79, :92), not
        pooled, not layout frames; Blizzard re-sets only the plates
        (Blizzard_SharedXML/SecureUIPanelTemplates.lua:44-79). The
        re-anchoring is skin-time widget API and stays.
        The panels sit at ReadyCheckListenerFrame's level, and that frame has
        a texture of its own, Bg, the dark dialog tile at BACKGROUND -5 over
        the whole frame (ReadyCheck.xml:26-32, both trees), which this skin
        leaves in place. A panel's fill is at -6 and would draw under it, so
        each panel's backdrop goes to -4, its edge to -3, above the tile (the
        Fable review of step 15, finding 6). ]]
    local yesPanel = Skin.TaintSafeUIPanelButtonTemplate(_G.ReadyCheckFrameYesButton, "panel")
    yesPanel:SetBackdropLayer("BACKGROUND", -4)
    _G.ReadyCheckFrameYesButton:SetPoint("TOPRIGHT", -184, -55)
    local noPanel = Skin.TaintSafeUIPanelButtonTemplate(_G.ReadyCheckFrameNoButton, "panel")
    noPanel:SetBackdropLayer("BACKGROUND", -4)
    _G.ReadyCheckFrameNoButton:SetPoint("TOPLEFT", 184, -55)
end
