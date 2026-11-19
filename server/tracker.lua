-- GPS tracker: where are the player's tracked vehicles right now?

local function worldVehiclesByPlate()
    local out = {}
    for _, veh in ipairs(GetAllVehicles()) do
        local plate = NormalizePlate(GetVehicleNumberPlateText(veh))
        if plate then out[plate] = veh end
    end
    return out
end

RegisterCallback('trackers', function(src)
    local identifier = Bridge.identifier(src)
    if not identifier then return {} end

    local catalog = Vehicles.catalog()
    local world = nil -- only scanned if the player has a tracked car
    local list = {}

    for _, v in ipairs(Bridge.ownedVehicles(identifier)) do
        local r = Vehicles.get(v.plate)
        if r and r.tracker and r.owner == identifier then
            world = world or worldVehiclesByPlate()
            local info = catalog[v.hash]
            local entry = { plate = v.plate, hash = v.hash, name = info and info.name, brand = info and info.brand }

            local veh = world[v.plate]
            if veh and DoesEntityExist(veh) then
                local c = GetEntityCoords(veh)
                entry.coords = { x = c.x, y = c.y, z = c.z }
                entry.speed = GetEntitySpeed(veh)
            end
            list[#list + 1] = entry
        end
    end
    return list
end)
