-- Registration clerk: list the player's own vehicles and sell registration,
-- a security system (alarm) or a GPS tracker for them.

local upgrades = {
    register = { field = 'registered', label = 'Registration' },
    alarm    = { field = 'alarm',      label = 'Security system' },
    tracker  = { field = 'tracker',    label = 'GPS tracker' },
}

local function costs(hash)
    return {
        register = math.floor(Vehicles.price(hash) * Config.RegisterMultiplier),
        alarm = Config.Office.prices.alarm,
        tracker = Config.Office.prices.tracker,
    }
end

--- Everything the menu needs: bank balance + the player's vehicles with their upgrades
local function officeData(src)
    local identifier = Bridge.identifier(src)
    if not identifier then return { vehicles = {} } end

    local catalog = Vehicles.catalog()
    local list = {}
    for _, v in ipairs(Bridge.ownedVehicles(identifier)) do
        local r = Vehicles.get(v.plate)
        local mine = r and r.owner == identifier
        local info = catalog[v.hash]
        list[#list + 1] = {
            plate = v.plate,
            hash = v.hash,
            name = info and info.name,
            brand = info and info.brand,
            registered = mine and r.registered or false,
            alarm = mine and r.alarm or false,
            tracker = mine and r.tracker or false,
            costs = costs(v.hash),
        }
    end

    local bank = Bridge.getBank(src)
    return { bank = bank ~= math.huge and bank or nil, vehicles = list }
end

RegisterCallback('office', officeData)

RegisterCallback('purchase', function(src, plate, kind)
    local upgrade = upgrades[kind]
    if not upgrade then return { ok = false } end
    plate = NormalizePlate(plate)

    -- only vehicles this character owns
    local identifier = Bridge.identifier(src)
    local owned
    for _, v in ipairs(Bridge.ownedVehicles(identifier)) do
        if v.plate == plate then owned = v break end
    end
    if not owned then
        Bridge.notify(src, 'You do not own that vehicle.', 'error')
        return { ok = false, office = officeData(src) }
    end

    local r = Vehicles.get(plate)
    if r and r.owner == identifier and r[upgrade.field] then
        return { ok = false, office = officeData(src) } -- already has it
    end

    local cost = costs(owned.hash)[kind]
    if not Bridge.removeBank(src, cost, ('vehicle-%s-%s'):format(kind, plate)) then
        Bridge.notify(src, ('Not enough money in the bank ($%s needed).'):format(cost), 'error')
        return { ok = false, office = officeData(src) }
    end

    Vehicles.set(plate, identifier, upgrade.field, true)
    Bridge.notify(src, ('%s added to %s for $%s.'):format(upgrade.label, plate, cost), 'success')
    return { ok = true, office = officeData(src) }
end)
