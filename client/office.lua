-- Registration clerk: target the NPC (ox_target / qb-target) to open an ox_lib menu
-- where you register owned vehicles and fit a security system or GPS tracker.

local cfg = Config.Office

local function money(n)
    local s = tostring(math.floor(n))
    while true do
        local k
        s, k = s:gsub('^(-?%d+)(%d%d%d)', '%1,%2')
        if k == 0 then break end
    end
    return '$' .. s
end

local upgrades = {
    { kind = 'register', field = 'registered', label = 'Register vehicle', done = 'Registered', icon = 'file-signature' },
    { kind = 'alarm',    field = 'alarm',      label = 'Security system',  done = 'Security system fitted', icon = 'shield-halved' },
    { kind = 'tracker',  field = 'tracker',    label = 'GPS tracker',      done = 'GPS tracker fitted', icon = 'location-crosshairs' },
}

local openVehicle -- forward declaration

--- Menu / target callbacks wait on the server and dialogs, so run them in their own thread
local function async(fn)
    return function(...)
        local args = { ... }
        CreateThread(function() fn(table.unpack(args)) end)
    end
end

local function vehicleLabel(v)
    local make, name = ModelLabels(v.hash)
    return ('%s %s'):format(v.brand or make, v.name or name)
end

--- Main menu: one entry per owned vehicle
local function registerOffice(data)
    data = data or {}
    local vehicles = data.vehicles or {}
    local options = {}

    if data.bank then
        options[#options + 1] = { title = 'Bank balance: ' .. money(data.bank), icon = 'building-columns', readOnly = true }
    end

    if #vehicles == 0 then
        options[#options + 1] = { title = "You don't own any vehicles", icon = 'circle-info', readOnly = true }
    end

    for _, v in ipairs(vehicles) do
        local done = {}
        if v.registered then done[#done + 1] = 'Registered' end
        if v.alarm then done[#done + 1] = 'Security' end
        if v.tracker then done[#done + 1] = 'GPS' end

        options[#options + 1] = {
            title = vehicleLabel(v),
            description = v.plate .. (#done > 0 and ('  •  ' .. table.concat(done, ', ')) or '  •  Unregistered'),
            icon = 'car',
            arrow = true,
            onSelect = async(function() openVehicle(v) end),
        }
    end

    lib.registerContext({ id = 'bakery_registration', title = cfg.blip.label, options = options })
end

local function openOffice()
    registerOffice(TriggerCallback('office'))
    lib.showContext('bakery_registration')
end

--- Vehicle menu: register / security / tracker
openVehicle = function(v)
    local options = {}
    for _, u in ipairs(upgrades) do
        local owned = v[u.field]
        local cost = v.costs[u.kind]
        options[#options + 1] = {
            title = owned and u.done or ('%s  —  %s'):format(u.label, money(cost)),
            icon = owned and 'check' or u.icon,
            iconColor = owned and '#4fd17a' or nil,
            disabled = owned,
            onSelect = async(function()
                local answer = lib.alertDialog({
                    header = u.label,
                    content = ('Pay %s from your bank for **%s** (%s)?'):format(money(cost), vehicleLabel(v), v.plate),
                    centered = true,
                    cancel = true,
                })
                if answer ~= 'confirm' then return openVehicle(v) end

                local result = TriggerCallback('purchase', v.plate, u.kind) or {}
                if result.office then registerOffice(result.office) end -- keep the back menu up to date
                for _, updated in ipairs(result.office and result.office.vehicles or {}) do
                    if updated.plate == v.plate then v = updated end
                end
                openVehicle(v)
            end),
        }
    end

    lib.registerContext({
        id = 'bakery_registration_vehicle',
        title = ('%s  •  %s'):format(vehicleLabel(v), v.plate),
        menu = 'bakery_registration',
        options = options,
    })
    lib.showContext('bakery_registration_vehicle')
end

------------------------------------------------------------------------
-- Clerks (one per entry in Config.Office.locations) + blips
------------------------------------------------------------------------

local clerks = {} -- [index] = ped
local blips = {}

local function spawnClerk(coords)
    local model = joaat(cfg.model)
    if not pcall(lib.requestModel, model, 5000) then return end

    local ped = CreatePed(4, model, coords.x, coords.y, coords.z - 1.0, coords.w, false, true)
    SetModelAsNoLongerNeeded(model)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    if cfg.scenario then TaskStartScenarioInPlace(ped, cfg.scenario, 0, true) end

    AddEntityTarget(ped, {
        label = cfg.blip.label,
        icon = 'file-signature',
        distance = cfg.distance,
        onSelect = async(openOffice),
    })
    return ped
end

local function addBlip(coords)
    local b = cfg.blip
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, b.sprite)
    SetBlipColour(blip, b.color)
    SetBlipScale(blip, b.scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(b.label)
    EndTextCommandSetBlipName(blip)
    return blip
end

CreateThread(function()
    if not cfg.enabled then return end

    if cfg.blip then
        for i, coords in ipairs(cfg.locations) do blips[i] = addBlip(coords) end
    end

    -- clerks only exist while a player is nearby
    while true do
        local me = GetEntityCoords(PlayerPedId())
        for i, coords in ipairs(cfg.locations) do
            local near = #(me - coords.xyz) < 80.0
            if near and not (clerks[i] and DoesEntityExist(clerks[i])) then
                clerks[i] = spawnClerk(coords)
            elseif not near and clerks[i] then
                DeleteEntity(clerks[i])
                clerks[i] = nil
            end
        end
        Wait(1000)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, ped in pairs(clerks) do DeleteEntity(ped) end
    for _, blip in pairs(blips) do RemoveBlip(blip) end
end)
