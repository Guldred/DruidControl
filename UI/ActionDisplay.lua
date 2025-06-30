local initializeBuffPositions = function()
    if not DruidControlDB.buffPositions then
        DruidControlDB.buffPositions = {}
        for actionName, actionData in pairs(DC.actionDisplay.actions) do
            DruidControlDB.buffPositions[actionName] = { x = actionData.defaultPositions.x, y = actionData.defaultPositions.y }
        end
    end

    if DruidControlDB.actionDisplayLocked == nil then
        DruidControlDB.actionDisplayLocked = true
    end
    DC.actionDisplay.isLocked = DruidControlDB.acDisplayLocked
end

DC.actionDisplay = {
    frames = {},
    isLocked = true,
    updateInterval = 0.1,
    lastUpdate = 0,
    iconPlaceholder = "Interface\\Icons\\INV_Misc_QuestionMark",

    actions = {
        ["Swiftmend"] = {
            name = "Swiftmend",
            icon = "Interface\\Icons\\INV_Relics_IdolofRejuvenation",
            description = "Instantly heals a friendly target for a large amount.",
            defaultPositions = { x = 100, y = 0 },
            wasReallyUsed = false,
            iconScale = 1.0,
            iconScaleGrowing = false
        },
        ["Nature's Swiftness"] = {
            name = "Nature's Swiftness",
            icon = "Interface\\Icons\\Spell_Nature_RavenForm",
            description = "Next Nature spell you cast will be instant.",
            defaultPositions = { x = 100, y = -60 },
            wasReallyUsed = false,
            iconScale = 1.0,
            iconScaleGrowing = true
        }
    }
}

local createFrame = function(actionName)
    local actionData = DC.actionDisplay.actions[actionName]
    if not actionData then return nil end

    local frameName = "DruidControlAction_" .. string.gsub(actionName, " ", "")
    local frame = CreateFrame("Frame", frameName, UIParent)

    frame:SetWidth(64)
    frame:SetHeight(64)
    frame:SetFrameStrata("HIGH")

    frame.icon = frame:CreateTexture(actionData.icon, "ARTWORK")
    frame.icon:SetWidth(64)
    frame.icon:SetHeight(64)
    frame.icon:SetPoint("CENTER", frame, "CENTER", 0, 0)

    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints(frame)
    frame.bg:SetVertexColor(0, 0, 0, 0.8)

    frame.border = frame:CreateTexture(nil, "BORDER")
    frame.border:SetAllPoints(frame)
    frame.border:SetVertexColor(1, 1, 1, 0.8)

    frame.timerText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.timerText:SetPoint("CENTER", frame, "CENTER", 0, 0)
    frame.timerText:SetTextColor(1, 1, 1, 1)
    frame.timerText:SetText("")

    frame.nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.nameText:SetPoint("CENTER", frame, "CENTER", 0, -10)
    frame.nameText:SetTextColor(0.8, 0.8, 0.8, 1)
    frame.nameText:SetText(actionName)
    frame.nameText:Hide()

    frame.stackText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.stackText:SetPoint("BOTTOMLEFT", frame.icon, "BOTTOMLEFT", 2, 2)
    frame.stackText:SetTextColor(1, 1, 1, 1)
    frame.stackText:SetText("")

    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")

    frame:SetScript("OnDragStart", function()
        if not DC.actionDisplay.isLocked then
            this:StartMoving()
        end
    end)

    frame:SetScript("OnDragStop", function()
        if not DC.actionDisplay.isLocked then
            this:StopMovingOrSizing()

            local point, relativeTo, relativePoint, xOfs, yOfs = this:GetPoint()
            DruidControlDB.buffPositions[actionName] = { x = xOfs, y = yOfs }
        end
    end)

    frame:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetText(actionName)
        if not DC.actionDisplay.isLocked then
            GameTooltip:AddLine("Drag to move", 0.5, 0.5, 0.5)
        end
        GameTooltip:Show()
    end)

    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local pos = DruidControlDB.buffPositions[actionName] or DC.actionDisplay.actions[actionName].defaultPositions
    frame:SetPoint("CENTER", UIParent, "CENTER", pos.x, pos.y)

    frame:Hide()

    return frame
end

local initializeFrames = function()
    for actionName, _ in pairs(DC.actionDisplay.actions) do
        DC.printMessage("Initializing action display for: " .. (actionName or "nil"))
        if not DC.actionDisplay.frames[actionName] then
            DC.actionDisplay.frames[actionName] = createFrame(actionName)
        end
    end
end

local updateDisplay = function(actionName, frame)
    if not DC or not DC.actionDisplay.isLocked then return end
    if DC.state.inCombat == false then
        frame:Hide()
        return
    end

    local action = DC.actionDisplay.actions[actionName]
    local start, duration, enabled = GetActionCooldown(action.actionBarSlot)
    local currentTime = GetTime()
    local cooldown = (start + duration) - currentTime

    if (cooldown > 1.5) then
        DC.actionDisplay.actions[actionName].wasReallyUsed = true
    end

    if (cooldown > 0 and action.wasReallyUsed) then
        frame:Hide()
    else

        frame:Show()
        frame.icon:SetTexture(DC.actionDisplay.actions[actionName].icon)
        DC.actionDisplay.actions[actionName].wasReallyUsed = false
    end
end

local animateFrame = function(actionName, frame)
    if DC.state.inCombat == false then
        return
    end
    local actionData = DC.actionDisplay.actions[actionName]
    if not actionData then return end

    local action = DC.actionDisplay.actions[actionName]

    if action.iconScaleGrowing then
        action.iconScale = math.min(action.iconScale + 0.006, 1.07)
    else
        action.iconScale = math.max(action.iconScale - 0.006, 0.93)
    end

    -- Ändere Richtung bei Erreichen der Grenzen
    if action.iconScale >= 1.07 then
        action.iconScaleGrowing = false
    elseif action.iconScale <= 0.93 then
        action.iconScaleGrowing = true
    end

    -- Basis-Größe ist 64, passe Größe basierend auf Skalierungsfaktor an
    local newSize = 64 * action.iconScale
    frame.icon:SetWidth(newSize)
    frame.icon:SetHeight(newSize)
end

local updateAllActionDisplays = function()
    for actionName, frame in pairs(DC.actionDisplay.frames) do
        updateDisplay(actionName, frame)
    end
end

local animateAllActionDisplays = function()
    for actionName, frame in pairs(DC.actionDisplay.frames) do
        animateFrame(actionName, frame)
    end
end

DC.lockFrames = function()
    DC.actionDisplay.isLocked = true
    DruidControlDB.actionDisplayLocked = DC.actionDisplay.isLocked
    for actionName, frame in pairs(DC.actionDisplay.frames) do
        frame.nameText:Hide()
    end
end

DC.unlockFrames = function()
    DC.actionDisplay.isLocked = false
    DruidControlDB.actionDisplayLocked = DC.actionDisplay.isLocked
    for actionName, frame in pairs(DC.actionDisplay.frames) do
        frame.nameText:Show()
        frame.icon:SetTexture(DC.actionDisplay.actions[actionName].icon)
        --frame.timerText:SetText("0")
        frame:Show()
    end
end

DC.actionDisplay_ToggleLock = function()
    DC.actionDisplay.isLocked = not DC.actionDisplay.isLocked
    DruidControlDB.actionDisplayLocked = DC.actionDisplay.isLocked

    if DC.actionDisplay.isLocked then
        DC.lockFrames()
    else
        DC.unlockFrames()
    end

    if DC.actionDisplay.isLocked then
        DEFAULT_CHAT_FRAME:AddMessage("DruidControl: Buff-Frame locked", 1.0, 1.0, 0.0)
    else
        DEFAULT_CHAT_FRAME:AddMessage("DruidControl: Buff-Frame unlocked - Drag to move", 1.0, 1.0, 0.0)
    end
end

DC.actionDisplay_ResetPositions = function()
    for actionName, actionData in pairs(DC.actionDisplay.actions) do
        local defaultPos = actionData.defaultPositions
        DruidControlDB.buffPositions[actionName] = { x = defaultPos.x, y = defaultPos.y }
        if DC.actionDisplay.frames[actionName] then
            DC.actionDisplay.frames[actionName]:ClearAllPoints()
            DC.actionDisplay.frames[actionName]:SetPoint("CENTER", UIParent, "CENTER", defaultPos.x, defaultPos.y)
        end
    end
    DEFAULT_CHAT_FRAME:AddMessage("DruidControl: Buff-Position reset", 1.0, 1.0, 0.0)
end

local setupActionBarPositions = function()
    actionbarSlots = DruidControlDB.ACTIONBAR_SPELL_SLOTS or { }
    for actionName, actionData in pairs(DC.actionDisplay.actions) do
        if actionbarSlots[actionName] then
            actionData.actionBarSlot = actionbarSlots[actionName]
        else
            DC.printMessage("DruidControl: Actions missing in DB! Please add Nature Switfness and Swiftmend to your bars and use '/dc scan' afterwards")
            return false
        end
    end
    return true
end

local initialize = function()
    if not setupActionBarPositions() then
        DC.printMessage("Init failed!.")
        return
    end
    initializeBuffPositions()
    initializeFrames()
end

DC.initBuffFrames = function()
    initialize()
    DC.lockFrames()
    DC.registerUpdateFunction(updateAllActionDisplays, 0.2)
    DC.registerUpdateFunction(animateAllActionDisplays,0.03)
end