-- Open a vehicle's hood to inspect it (GTA 6 style)

local HOOD = 4

local inspecting = false
local currentVeh = 0
local nearVeh = 0
local cam = nil

local function round1(v)
    return math.floor(v * 10 + 0.5) / 10
end

local function hasHood(veh)
    return GetIsDoorValid(veh, HOOD) and GetEntityBoneIndexByName(veh, 'bonnet') ~= -1
end

local function frontPoint(veh)
    local _, max = GetModelDimensions(GetEntityModel(veh))
    return GetOffsetFromEntityInWorldCoords(veh, 0.0, max.y, 0.0)
end

--- World point used to anchor the on-screen key prompt.
local function promptPoint(veh, opened)
    local pos = GetWorldPositionOfEntityBone(veh, GetEntityBoneIndexByName(veh, 'bonnet'))
    if opened then
        return pos + vector3(0.0, 0.0, 1.0)
    end
    local _, max = GetModelDimensions(GetEntityModel(veh))
    local localBone = GetOffsetFromEntityGivenWorldCoords(veh, pos.x, pos.y, pos.z)
    return GetOffsetFromEntityInWorldCoords(veh, 0.0, max.y - 0.6, localBone.z + 0.35)
end

------------------------------------------------------------------------
-- Vehicle data
------------------------------------------------------------------------

local function conditionLabel(body)
    if body >= 950 then return 'Excellent' end
    if body >= 800 then return 'Good' end
    if body >= 600 then return 'Average' end
    if body >= 350 then return 'Poor' end
    return 'Wrecked'
end

local function buildData(veh, record)
    local model = GetEntityModel(veh)
    local info = GetCatalog()[NormalizeHash(model)] or {}
    local modelName = (info.model or GetDisplayNameFromVehicleModel(model)):lower()

    -- Framework category decides the class profile; the game class is the fallback
    local class = Config.Categories[info.category or ''] or GetVehicleClass(veh)
    local classCfg = Config.Classes[class] or Config.Classes[1]
    local override = Config.Models[modelName] or {}

    local gameMake, gameName = ModelLabels(model)
    local make = info.brand or gameMake
    local name = info.name or gameName

    -- Performance stats (0 - 10), from the vehicle's live handling (includes upgrades)
    local kmh = GetVehicleEstimatedMaxSpeed(veh) * 3.6
    local mass = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fMass')
    local deform = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fDeformationDamageMult')
    local tractionLoss = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fTractionLossMult')

    local speed = round1(Clamp((kmh - 60.0) / 22.0, 0.5, 10.0))
    local accel = round1(Clamp(GetVehicleAcceleration(veh) * 20.0, 0.5, 10.0))
    local asphalt = round1(Clamp((GetVehicleMaxTraction(veh) - 1.2) * 4.0, 0.5, 10.0))
    local offroad = round1(Clamp((override.offroad or classCfg.offroad) + (1.0 - tractionLoss) * 1.5, 0.5, 10.0))
    local strength = round1(Clamp(mass / 600.0 + (0.8 - deform), 0.5, 10.0))

    -- Money: framework price -> game value -> class value
    local baseValue = info.price
    if not baseValue or baseValue <= 0 then baseValue = GetVehicleModelValue(model) end
    if not baseValue or baseValue <= 0 then baseValue = override.value or classCfg.value end

    local body = GetVehicleBodyHealth(veh)
    local sell = override.sell or math.floor(baseValue * Config.SellMultiplier * Clamp(body / 1000.0, 0.2, 1.0))
    local register = override.register or math.floor(baseValue * Config.RegisterMultiplier)

    return {
        make = make,
        model = name,
        locked = GetVehicleDoorLockStatus(veh) >= 2,
        -- 'none' | 'armed' (fitted, goes off for you) | 'owner' (fitted on your own car)
        security = (record.alarm or IsVehicleAlarmSet(veh)) and (record.mine and 'owner' or 'armed') or 'none',
        tracker = record.tracker and (record.mine and 'owner' or 'fitted') or 'none',
        registered = record.registered,
        sellValue = sell,
        registerCost = register,
        stats = {
            speed = speed,
            acceleration = accel,
            asphalt = asphalt,
            offroad = offroad,
            strength = strength,
        },
        rating = {
            road = math.floor((speed * 0.4 + accel * 0.3 + asphalt * 0.3) * 60 + 0.5),
            offroad = math.floor((offroad * 0.5 + strength * 0.3 + accel * 0.2) * 95 + 0.5),
        },
        info = {
            type = override.type or classCfg.type,
            era = Config.Eras[modelName] or (class == 5 and 'Classic' or Config.DefaultEra),
            seats = GetVehicleModelNumberOfSeats(model),
            storage = override.storage or classCfg.storage,
            condition = conditionLabel(body),
            specialist = override.specialist or classCfg.specialist,
        },
    }
end

------------------------------------------------------------------------
-- Camera
------------------------------------------------------------------------

local function startCamera(veh)
    local min, max = GetModelDimensions(GetEntityModel(veh))
    local from = GetOffsetFromEntityInWorldCoords(veh, min.x - 1.4, max.y + 2.0, max.z + 1.9)
    local to = GetOffsetFromEntityInWorldCoords(veh, 0.0, max.y - 1.2, 0.0)

    cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', from.x, from.y, from.z, 0.0, 0.0, 0.0, 50.0, false, 2)
    PointCamAtCoord(cam, to.x, to.y, to.z)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 700, true, false)
end

local function stopCamera()
    if not cam then return end
    RenderScriptCams(false, true, 700, true, false)
    DestroyCam(cam, false)
    cam = nil
end

------------------------------------------------------------------------
-- Open / close
------------------------------------------------------------------------

local function closeInspect()
    if not inspecting then return end
    inspecting = false

    if DoesEntityExist(currentVeh) then
        RequestControl(currentVeh)
        SetVehicleDoorShut(currentVeh, HOOD, false)
    end

    stopCamera()
    ClearPedTasks(PlayerPedId())
    SendNUIMessage({ action = 'close' })
    HidePrompt()
    currentVeh = 0
end

local function openInspect(veh)
    local ped = PlayerPedId()
    inspecting = true
    currentVeh = veh
    HidePrompt()

    local min, max = GetModelDimensions(GetEntityModel(veh))
    local hood = GetOffsetFromEntityInWorldCoords(veh, 0.0, max.y - 0.8, 0.0)

    if Config.WalkToHood then
        local stand = GetOffsetFromEntityInWorldCoords(veh, min.x * 0.55, max.y + 0.55, 0.0)
        local heading = GetHeadingFromVector_2d(hood.x - stand.x, hood.y - stand.y)
        TaskGoStraightToCoord(ped, stand.x, stand.y, stand.z, 1.0, 3000, heading, 0.15)

        local timeout = GetGameTimer() + 3000
        while #(GetEntityCoords(ped).xy - stand.xy) > 0.35 and GetGameTimer() < timeout do
            Wait(50)
        end
    end

    TaskTurnPedToFaceCoord(ped, hood.x, hood.y, hood.z, 800)
    Wait(500)

    if not inspecting or not DoesEntityExist(veh) then
        return closeInspect()
    end

    RequestControl(veh)
    SetVehicleDoorOpen(veh, HOOD, false, false)
    Security.check(veh) -- popping the hood of someone else's alarmed car sets it off

    if Config.UseCamera then startCamera(veh) end

    local record = TriggerCallback('record', GetVehicleNumberPlateText(veh)) or {}

    SendNUIMessage({
        action = 'open',
        data = buildData(veh, record),
        keys = {
            close = KeyLabel('vehinspect', Config.Keys.inspect),
            cycle = KeyLabel('vehinspect_next', Config.Keys.cycle),
        },
    })

    while inspecting do
        DisableControlAction(0, 30, true)  -- move left/right
        DisableControlAction(0, 31, true)  -- move up/down
        DisableControlAction(0, 21, true)  -- sprint
        DisableControlAction(0, 22, true)  -- jump
        DisableControlAction(0, 23, true)  -- enter vehicle
        DisableControlAction(0, 24, true)  -- attack
        DisableControlAction(0, 25, true)  -- aim
        DisableControlAction(0, 44, true)  -- cover

        ped = PlayerPedId()
        if not DoesEntityExist(veh) or IsEntityDead(ped) or IsPedInAnyVehicle(ped, true)
            or GetEntitySpeed(veh) > 1.0 or #(GetEntityCoords(ped) - GetEntityCoords(veh)) > 6.0 then
            closeInspect()
            break
        end

        ShowPrompt(promptPoint(veh, true), 'Close')
        Wait(0)
    end
end

------------------------------------------------------------------------
-- Keys
------------------------------------------------------------------------

RegisterCommand('vehinspect', function()
    if inspecting then
        return closeInspect()
    end
    if nearVeh ~= 0 then
        CreateThread(function() openInspect(nearVeh) end)
    end
end, false)

RegisterCommand('vehinspect_next', function()
    if inspecting then
        SendNUIMessage({ action = 'cycle' })
    end
end, false)

RegisterKeyMapping('vehinspect', 'Vehicle: open / close hood', 'keyboard', Config.Keys.inspect)
RegisterKeyMapping('vehinspect_next', 'Vehicle: next info page', 'keyboard', Config.Keys.cycle)

------------------------------------------------------------------------
-- Proximity (hood prompt)
------------------------------------------------------------------------

CreateThread(function()
    while true do
        local sleep = 300
        local ped = PlayerPedId()

        if inspecting or IsPedInAnyVehicle(ped, true) or IsEntityDead(ped) or IsNuiFocused() then
            nearVeh = 0
        else
            local pos = GetEntityCoords(ped)
            local best, bestDist = 0, Config.Distance

            for _, veh in ipairs(GetGamePool('CVehicle')) do
                if #(pos - GetEntityCoords(veh)) < 8.0 and hasHood(veh) then
                    local dist = #(pos - frontPoint(veh))
                    if dist < bestDist and GetEntitySpeed(veh) < 1.0
                        and (Config.AllowLocked or GetVehicleDoorLockStatus(veh) < 2) then
                        best, bestDist = veh, dist
                    end
                end
            end

            nearVeh = best
        end

        if nearVeh ~= 0 then
            -- follow the target on screen every frame while in range
            local untilTime = GetGameTimer() + sleep
            while GetGameTimer() < untilTime and not inspecting and not IsNuiFocused() do
                if DoesEntityExist(nearVeh) then
                    ShowPrompt(promptPoint(nearVeh, false), 'Open Hood')
                else
                    break
                end
                Wait(0)
            end
            if IsNuiFocused() then HidePrompt() end
        else
            if not inspecting then HidePrompt() end
            Wait(sleep)
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        closeInspect()
    end
end)
