DC = {
    UpdateFunctions = {},

    OnUpdate = function()
        for _, func in ipairs(DC.UpdateFunctions) do
            if (GetTime() - func.lastUpdate >= func.interval) then
                func.f()
                func.lastUpdate = GetTime()
            end
        end
    end,

    forceUpdate = function()
        for _, func in ipairs(DC.UpdateFunctions) do
            func.f()
            func.lastUpdate = GetTime()
        end
    end,

    registerUpdateFunction = function(func, interval)
        if type(func) == "function" then
            table.insert(DC.UpdateFunctions, {
                f = func,
                lastUpdate = 0,
                interval = interval or 0.1,
            })
        else
            error("DruidControl: registerUpdateFunction expects a function and an interval (optional)")
        end
    end,

    unregisterUpdateFunction = function(func)
        for i, updateFunc in ipairs(DC.UpdateFunctions) do
            if updateFunc.f == func then
                table.remove(DC.UpdateFunctions, i)
                return
            end
        end
        error("DruidControl: unregisterUpdateFunction could not find the specified function")
    end,

    printMessage = function(text)
        DEFAULT_CHAT_FRAME:AddMessage(text, 1.0, 1.0, 0.0)
    end,

    state = {
        inCombat = false
    }
}

DruidControlDB = {
    buffDisplayLocked = false,
    buffDisplay = {
        frames = {},
        iconPlaceholder = "Interface\\Icons\\INV_Misc_QuestionMark",
    },
}

SLASH_DRUIDCONTROL1 = "/druidcontrol"
SLASH_DRUIDCONTROL2 = "/dc"

SlashCmdList["DRUIDCONTROL"] = function(msg)
    local args = {}
    for word in string.gfind(msg, "%S+") do
        table.insert(args, string.lower(word))
    end

    local command = args[1] or ""

    if command == "lock" then
        DC.lockFrames()
    elseif command == "unlock" then
        DC.unlockFrames()
    elseif command == "reset" then
        DC.actionDisplay_ResetPositions()
    else
        DC.printMessage("DruidControl Commands:")
        DC.printMessage("  /dc lock - lock frames")
        DC.printMessage("  /dc unlock - unlock frames")
    end
end
