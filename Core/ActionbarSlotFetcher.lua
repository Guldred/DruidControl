
DC.findSpellSlots = function()
    local foundSlots = {}
    local spellIds = {
        ["Nature's Swiftness"] = 17116,
        ["Swiftmend"] = 18562
    }

    for slot = 1, 120 do
        if HasAction(slot) then
            local text, type, id = GetActionText(slot)
            text = text or ""
            type = type or ""
            id = id or 0
            for spellKey, targetId in pairs(spellIds) do
                if id == targetId and not foundSlots[spellKey] then
                    foundSlots[spellKey] = slot
                    DC.printMessage("DruidControl: Found " .. spellKey .. " in slot " .. slot)
                end
            end
        end
    end

    return foundSlots
end