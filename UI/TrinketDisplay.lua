DC.trinketDisplay = {
    frames = {},
    isLocked = true,
    updateInterval = 0.1,
    lastUpdate = 0,
    iconPlaceholder = "Interface\\Icons\\INV_Misc_QuestionMark",

    trinkets = {
        ["TopTrinket"] = {
            name = "Top Trinket",
            icon = "Interface\\Icons\\INV_Misc_Gem_Pearl_05",
            slotID = 13, -- Top Trinket Slot
            defaultPositions = { x = 150, y = 0 },
            wasReallyUsed = false,
            iconScale = 1.0,
            iconScaleGrowing = false
        },
        ["BottomTrinket"] = {
            name = "Bottom Trinket",
            icon = "Interface\\Icons\\INV_Misc_Gem_Pearl_05",
            slotID = 14, -- Bottom Trinket Slot
            defaultPositions = { x = 150, y = -60 },
            wasReallyUsed = false,
            iconScale = 1.0,
            iconScaleGrowing = true
        }
    }
}

-- Initialisierung der Trinket-Positionen in der DB
local initializeTrinketPositions = function()
    if not DruidControlDB.trinketPositions then
        DruidControlDB.trinketPositions = {}
        for trinketName, trinketData in pairs(DC.trinketDisplay.trinkets) do
            DruidControlDB.trinketPositions[trinketName] = { x = trinketData.defaultPositions.x, y = trinketData.defaultPositions.y }
        end
    end

    -- Gemeinsame Lock-Einstellung mit actionDisplay
    DC.trinketDisplay.isLocked = DC.actionDisplay.isLocked
end

-- Frame für ein Trinket erstellen
local createTrinketFrame = function(trinketName)
    local trinketData = DC.trinketDisplay.trinkets[trinketName]
    if not trinketData then return nil end

    local frameName = "DruidControlTrinket_" .. string.gsub(trinketName, " ", "")
    local frame = CreateFrame("Frame", frameName, UIParent)

    -- Frame Einstellungen (ähnlich wie bei Action-Frames)
    frame:SetWidth(64)
    frame:SetHeight(64)
    frame:SetFrameStrata("HIGH")

    frame.icon = frame:CreateTexture(nil, "ARTWORK")
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
    frame.nameText:SetPoint("BOTTOM", frame, "BOTTOM", 0, -12)
    frame.nameText:SetTextColor(0.8, 0.8, 0.8, 1)
    frame.nameText:SetText(trinketName)
    frame.nameText:Hide()

    -- Drag-and-Drop Funktionalität
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")

    frame:SetScript("OnDragStart", function()
        if not DC.trinketDisplay.isLocked then
            this:StartMoving()
        end
    end)

    frame:SetScript("OnDragStop", function()
        if not DC.trinketDisplay.isLocked then
            this:StopMovingOrSizing()

            local point, relativeTo, relativePoint, xOfs, yOfs = this:GetPoint()
            DruidControlDB.trinketPositions[trinketName] = { x = xOfs, y = yOfs }
        end
    end)

    -- Tooltip
    frame:SetScript("OnEnter", function()
        local trinketLink = GetInventoryItemLink("player", trinketData.slotID)
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")

        if trinketLink then
            GameTooltip:SetInventoryItem("player", trinketData.slotID)
        else
            GameTooltip:SetText(trinketData.name)
        end

        if not DC.trinketDisplay.isLocked then
            GameTooltip:AddLine("Drag to move", 0.5, 0.5, 0.5)
        end
        GameTooltip:Show()
    end)

    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Position setzen
    local pos = DruidControlDB.trinketPositions[trinketName] or trinketData.defaultPositions
    frame:SetPoint("CENTER", UIParent, "CENTER", pos.x, pos.y)

    frame:Hide()

    return frame
end

-- Initialisierung aller Trinket-Frames
local initializeTrinketFrames = function()
    for trinketName, _ in pairs(DC.trinketDisplay.trinkets) do
        if not DC.trinketDisplay.frames[trinketName] then
            DC.trinketDisplay.frames[trinketName] = createTrinketFrame(trinketName)
        end
    end
end

-- Trinket-Icons aktualisieren
local updateTrinketDisplay = function(trinketName, frame)
    if not DC or not frame or DC.state.inCombat == false then
        frame:Hide()
        return
    end

    local trinketData = DC.trinketDisplay.trinkets[trinketName]
    local trinketLink = GetInventoryItemLink("player", trinketData.slotID)

    -- Aktualisiere Icon basierend auf dem ausgerüsteten Trinket
    if trinketLink then
        -- Icon des ausgerüsteten Trinkets holen
        local _, _, itemCode = string.find(trinketLink, "item:(%d+):")
        if itemCode then
            _, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(itemCode)
            if itemTexture then
                trinketData.icon = itemTexture
            end
        end
    end

    local start, duration, enabled = GetInventoryItemCooldown("player", trinketData.slotID)
    local onCooldown = (start > 0 and duration > 0)

    if onCooldown then
        local timeLeft = (start + duration) - GetTime()
        if timeLeft > 0 then
            --[[if timeLeft < 10 then
                frame.timerText:SetText(string.format("%.1f", timeLeft))
            else
                frame.timerText:SetText(string.format("%d", math.floor(timeLeft)))
            end]]
            frame:Hide()
        end
    else
        --frame.timerText:SetText("")
        -- Nur anzeigen, wenn Trinket benutzt werden kann
        -- Update Textur zur textur des Trinkets
        frame.icon:SetTexture(GetInventoryItemTexture("player", trinketData.slotID) or trinketData.icon)

        if enabled == 1 and trinketLink then
            frame:Show()
        else
            frame:Hide()
        end
    end

    --frame.icon:SetTexture(trinketData.icon)
end

-- Animationslogik für Trinkets
local animateTrinketFrame = function(trinketName, frame)
    if DC.state.inCombat == false then
        return
    end

    local trinketData = DC.trinketDisplay.trinkets[trinketName]
    if not trinketData then return end

    -- Gleiches Pulsieren wie bei Actions
    if trinketData.iconScaleGrowing then
        trinketData.iconScale = math.min(trinketData.iconScale + 0.006, 1.07)
    else
        trinketData.iconScale = math.max(trinketData.iconScale - 0.006, 0.93)
    end

    if trinketData.iconScale >= 1.07 then
        trinketData.iconScaleGrowing = false
    elseif trinketData.iconScale <= 0.93 then
        trinketData.iconScaleGrowing = true
    end

    local newSize = 64 * trinketData.iconScale
    frame.icon:SetWidth(newSize)
    frame.icon:SetHeight(newSize)
end

local updateAllTrinketDisplays = function()
    for trinketName, frame in pairs(DC.trinketDisplay.frames) do
        updateTrinketDisplay(trinketName, frame)
    end
end

local animateAllTrinketDisplays = function()
    for trinketName, frame in pairs(DC.trinketDisplay.frames) do
        animateTrinketFrame(trinketName, frame)
    end
end

local originalLockFrames = DC.lockFrames
DC.lockFrames = function()
    originalLockFrames()
    DC.trinketDisplay.isLocked = true
    for trinketName, frame in pairs(DC.trinketDisplay.frames) do
        frame.nameText:Hide()
    end
end

local originalUnlockFrames = DC.unlockFrames
DC.unlockFrames = function()
    originalUnlockFrames()
    DC.trinketDisplay.isLocked = false
    for trinketName, frame in pairs(DC.trinketDisplay.frames) do
        frame.nameText:Show()
        frame.icon:SetTexture(DC.trinketDisplay.trinkets[trinketName].icon)
        frame:Show()
    end
end

DC.trinketDisplay_ResetPositions = function()
    for trinketName, trinketData in pairs(DC.trinketDisplay.trinkets) do
        local defaultPos = trinketData.defaultPositions
        DruidControlDB.trinketPositions[trinketName] = { x = defaultPos.x, y = defaultPos.y }
        if DC.trinketDisplay.frames[trinketName] then
            DC.trinketDisplay.frames[trinketName]:ClearAllPoints()
            DC.trinketDisplay.frames[trinketName]:SetPoint("CENTER", UIParent, "CENTER", defaultPos.x, defaultPos.y)
        end
    end
    DEFAULT_CHAT_FRAME:AddMessage("DruidControl: Trinket-Position zurückgesetzt", 1.0, 1.0, 0.0)
end

DC.initTrinketFrames = function()
    initializeTrinketPositions()
    initializeTrinketFrames()

    DC.registerUpdateFunction(updateAllTrinketDisplays, 0.2)
    DC.registerUpdateFunction(animateAllTrinketDisplays, 0.03)
end

local originalInitBuffFrames = DC.initBuffFrames
DC.initBuffFrames = function()
    originalInitBuffFrames()
    DC.initTrinketFrames()
end