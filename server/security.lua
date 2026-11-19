-- Security system (alarm).
-- A client reports a break-in on a car whose plate is in GlobalState.bakeryVehicleAlarms;
-- the server double-checks, sets the alarm off and alerts the owner.

local cooldown = {} -- [plate] = os.time() of the last alert

RegisterNetEvent('bakery_vehicleinspect:breakIn', function(netId, plate, coords)
    local src = source
    local r = Vehicles.get(plate)
    if not r or not r.alarm then return end
    if r.owner == Bridge.identifier(src) then return end -- owners never set off their own alarm

    plate = NormalizePlate(plate)
    local now = os.time()
    if cooldown[plate] and now - cooldown[plate] < Config.Alarm.cooldown then return end
    cooldown[plate] = now

    TriggerClientEvent('bakery_vehicleinspect:soundAlarm', src, netId)

    local owner = Bridge.sourceOf(r.owner)
    if owner then
        TriggerClientEvent('bakery_vehicleinspect:alarmAlert', owner, plate, coords)
    end
end)
