-- Vehicle keys (client).
-- Players who have keys for a car never set off its security system,
-- so the owner can lend their car to friends.
--
-- Using a different keys script? Add it to `keyScripts` below.
-- Your lockpick / hotwire script can also set the alarm off directly:
--     exports.bakery_vehicleinspect:TriggerAlarm(vehicle)

local keyScripts = {
    -- resource name = function(vehicle) return true if the player has keys end
    ['qbx_vehiclekeys'] = function(vehicle)
        return exports.qbx_vehiclekeys:HasKeys(vehicle)
    end,
    ['qb-vehiclekeys'] = function(vehicle)
        return exports['qb-vehiclekeys']:HasKeys(GetVehicleNumberPlateText(vehicle))
    end,
}

function HasVehicleKeys(vehicle)
    for resource, hasKeys in pairs(keyScripts) do
        if GetResourceState(resource) == 'started' then
            local ok, result = pcall(hasKeys, vehicle)
            if ok and result then return true end
        end
    end
    return false
end
