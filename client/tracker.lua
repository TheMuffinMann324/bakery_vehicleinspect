-- GPS tracker: list your tracked vehicles, set a waypoint or ping them on the map.
-- These NUI callbacks serve both the /tracker screen and the phone apps.

local lastList = {}
local pingBlips = {} -- [plate] = blip

local function trackerList()
    local list = TriggerCallback('trackers') or {}
    local me = GetEntityCoords(PlayerPedId())

    for _, v in ipairs(list) do
        local make, name = ModelLabels(v.hash)
        v.brand = v.brand or make
        v.name = v.name or name
        v.hash = nil
        if v.coords then
            local c = vector3(v.coords.x, v.coords.y, v.coords.z)
            v.street = StreetName(c)
            v.distance = math.floor(#(me - c))
            v.status = (v.speed or 0) > 2.0 and 'Moving' or 'Parked'
        else
            v.status = 'Stored'
        end
    end

    lastList = list
    return list
end

local function find(plate)
    for _, v in ipairs(lastList) do
        if v.plate == plate then return v end
    end
end

RegisterNUICallback('getTrackers', function(_, cb)
    cb(trackerList())
end)

RegisterNUICallback('trackerWaypoint', function(data, cb)
    local v = find(data.plate)
    if v and v.coords then
        SetNewWaypoint(v.coords.x, v.coords.y)
        Notify(('Waypoint set to %s.'):format(v.plate), 'success')
    end
    cb(true)
end)

RegisterNUICallback('trackerPing', function(data, cb)
    local v = find(data.plate)
    if v and v.coords then
        if pingBlips[v.plate] and DoesBlipExist(pingBlips[v.plate]) then RemoveBlip(pingBlips[v.plate]) end
        pingBlips[v.plate] = AddTimedBlip(v.coords, 'Tracker: ' .. v.plate, 3, Config.Tracker.blipSeconds)
    end
    cb(true)
end)

------------------------------------------------------------------------
-- Standalone tracker screen (no phone needed)
------------------------------------------------------------------------

if Config.Tracker.command then
    RegisterCommand(Config.Tracker.command, function()
        SetNuiFocus(true, true)
        SendNUIMessage({ action = 'tracker' })
    end, false)
end

RegisterNUICallback('closeTracker', function(_, cb)
    SetNuiFocus(false, false)
    cb(true)
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, blip in pairs(pingBlips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
end)
