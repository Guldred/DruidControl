local DruidControlFrame = CreateFrame("Frame")
DruidControlFrame:RegisterEvent("ADDON_LOADED")
DruidControlFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
DruidControlFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
DruidControlFrame:RegisterEvent("PLAYER_ENTER_COMBAT")
DruidControlFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")

DruidControlFrame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "DruidControl" then
        DC.initBuffFrames()
        DC.printMessage("DruidControl loaded.")
    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_ENTER_COMBAT" then
        DC.state.inCombat = true
    elseif event == "PLAYER_REGEN_ENABLED" then
        DC.state.inCombat = false
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then

    end

    DruidControlFrame:SetScript("OnUpdate", function()
        DC.OnUpdate()
    end)
end)