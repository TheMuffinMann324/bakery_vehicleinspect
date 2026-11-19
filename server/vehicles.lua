-- Vehicle data shared by every feature:
--   * the framework catalog (prices, names, categories)
--   * security records per plate: registered / alarm / tracker (table `bakery_vehicle_security`)

Vehicles = {}

local catalog = nil  -- { [modelHash] = { price, name, brand, category, model } }
local records = {}   -- { [plate] = { owner, registered, alarm, tracker } }

------------------------------------------------------------------------
-- Catalog
------------------------------------------------------------------------

function Vehicles.catalog()
    if catalog then return catalog end
    local ok, result = pcall(Bridge.vehicleCatalog)
    if not ok then
        print(('^3[%s] could not read vehicles from %s: %s^0'):format(GetCurrentResourceName(), Bridge.framework(), result))
        return {}
    end
    if next(result) then catalog = result end -- only cache once the framework answered
    return result
end

--- Framework price of a model (falls back to 20,000 for unknown models)
function Vehicles.price(hash)
    local info = Vehicles.catalog()[hash]
    return info and info.price or 20000
end

RegisterCallback('catalog', function()
    return Vehicles.catalog()
end)

------------------------------------------------------------------------
-- Security records
------------------------------------------------------------------------

--- Plates with an alarm fitted, shared with every client so they only
--- contact the server for cars that actually have one.
local function publishAlarms()
    local plates = {}
    for plate, r in pairs(records) do
        if r.alarm then plates[plate] = true end
    end
    GlobalState.bakeryVehicleAlarms = plates
end

CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `bakery_vehicle_security` (
            `plate` VARCHAR(16) NOT NULL,
            `owner` VARCHAR(64) NOT NULL,
            `registered` TINYINT(1) NOT NULL DEFAULT 0,
            `alarm` TINYINT(1) NOT NULL DEFAULT 0,
            `tracker` TINYINT(1) NOT NULL DEFAULT 0,
            PRIMARY KEY (`plate`)
        )
    ]])

    for _, row in ipairs(MySQL.query.await('SELECT * FROM bakery_vehicle_security') or {}) do
        records[row.plate] = {
            owner = row.owner,
            registered = row.registered == 1 or row.registered == true,
            alarm = row.alarm == 1 or row.alarm == true,
            tracker = row.tracker == 1 or row.tracker == true,
        }
    end
    publishAlarms()
end)

--- Record for a plate, or nil
function Vehicles.get(plate)
    return records[NormalizePlate(plate)]
end

--- Sets one field ('registered' | 'alarm' | 'tracker') for a plate and saves it.
--- A different owner than the stored one starts a fresh record (the car changed hands).
function Vehicles.set(plate, owner, field, value)
    plate = NormalizePlate(plate)
    local r = records[plate]
    if not r or r.owner ~= owner then
        r = { owner = owner, registered = false, alarm = false, tracker = false }
        records[plate] = r
    end
    r[field] = value and true or false

    MySQL.query.await([[
        INSERT INTO bakery_vehicle_security (plate, owner, registered, alarm, tracker) VALUES (?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE owner = VALUES(owner), registered = VALUES(registered),
            alarm = VALUES(alarm), tracker = VALUES(tracker)
    ]], { plate, r.owner, r.registered and 1 or 0, r.alarm and 1 or 0, r.tracker and 1 or 0 })

    if field == 'alarm' then publishAlarms() end
end

--- What the inspect panel shows for a plate
RegisterCallback('record', function(src, plate)
    local r = Vehicles.get(plate)
    if not r then return { registered = false, alarm = false, tracker = false, mine = false } end
    return {
        registered = r.registered,
        alarm = r.alarm,
        tracker = r.tracker,
        mine = r.owner == Bridge.identifier(src),
    }
end)

------------------------------------------------------------------------
-- Exports for other resources (garages, vehicle keys, police MDT, ...)
------------------------------------------------------------------------

--- exports.bakery_vehicleinspect:GetVehicleSecurity(plate)
--- -> { owner, registered, alarm, tracker } or nil
exports('GetVehicleSecurity', function(plate)
    local r = Vehicles.get(plate)
    return r and { owner = r.owner, registered = r.registered, alarm = r.alarm, tracker = r.tracker }
end)

--- exports.bakery_vehicleinspect:SetVehicleSecurity(plate, owner, field, value)
--- field: 'registered' | 'alarm' | 'tracker'   owner: citizenid / ESX identifier
exports('SetVehicleSecurity', function(plate, owner, field, value)
    if field ~= 'registered' and field ~= 'alarm' and field ~= 'tracker' then return false end
    Vehicles.set(plate, owner, field, value)
    return true
end)
