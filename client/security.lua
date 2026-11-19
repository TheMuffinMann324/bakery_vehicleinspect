-- Security system (alarm), client side.
--
-- When someone who isn't the owner (and has no keys, see bridge/client/keys.lua)
--   * tries a locked door,
--   * gets behind the wheel, or
--   * pops the hood
-- of a car with a security system, the alarm sounds and the owner gets an alert.
--
-- Lightweight: the server shares the plates that have an alarm
-- (GlobalState.bakeryVehicleAlarms), so ordinary cars never cause a server call.

Security = {}

local reported = {} -- [plate] = GetGameTimer() of the last report

--- Reports a break-in on `vehicle` if it has a security system. Safe to call often.
function Security.check(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return end

    local plate = NormalizePlate(GetVehicleNumberPlateText(vehicle))
    local alarms = GlobalState.bakeryVehicleAlarms
    if not (alarms and alarms[plate]) then return end
    if HasVehicleKeys(vehicle) then return end

    local now = GetGameTimer()
    if reported[plate] and now - reported[plate] < 10000 then return end
    reported[plate] = now

    local c = GetEntityCoords(vehicle)
    TriggerServerEvent('bakery_vehicleinspect:breakIn', VehToNet(vehicle), plate, { x = c.x, y = c.y, z = c.z })
end

--- For lockpick / hotwire scripts: exports.bakery_vehicleinspect:TriggerAlarm(vehicle)
exports('TriggerAlarm', Security.check)

------------------------------------------------------------------------
-- Alarm + owner alert (sent by the server)
------------------------------------------------------------------------

RegisterNetEvent('bakery_vehicleinspect:soundAlarm', function(netId)
    local vehicle = NetToVeh(netId)
    if not DoesEntityExist(vehicle) then return end
    RequestControl(vehicle)
    SetVehicleAlarm(vehicle, true)
    SetVehicleAlarmTimeLeft(vehicle, Config.Alarm.duration * 1000)
    StartVehicleAlarm(vehicle)
end)

RegisterNetEvent('bakery_vehicleinspect:alarmAlert', function(plate, coords)
    local where = coords and StreetName(coords) or 'unknown location'
    Notify(('Security alert: the alarm on %s went off near %s.'):format(plate, where), 'error')
    PhoneNotify('Security alert', ('%s alarm triggered near %s'):format(plate, where))
    if coords then
        AddTimedBlip(coords, 'Alarm: ' .. plate, 1, Config.Alarm.blipSeconds)
    end
end)

------------------------------------------------------------------------
-- Detection
------------------------------------------------------------------------

-- Got into a car: the game tells us, no polling needed
AddEventHandler('gameEventTriggered', function(name, args)
    if name ~= 'CEventNetworkPlayerEnteredVehicle' or args[1] ~= PlayerId() then return end
    local vehicle = args[2]
    if GetPedInVehicleSeat(vehicle, -1) == PlayerPedId() then
        Security.check(vehicle)
    end
end)

-- Pulling on a locked door: one cheap native every half second
CreateThread(function()
    while true do
        local vehicle = GetVehiclePedIsTryingToEnter(PlayerPedId())
        if vehicle ~= 0 and GetVehicleDoorLockStatus(vehicle) >= 2 then
            Security.check(vehicle)
        end
        Wait(500)
    end
end)
