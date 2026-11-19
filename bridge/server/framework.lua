-- Framework bridge (server): QBX, QBCore and ESX.
-- Everything framework-specific lives here: who a player is, their bank money,
-- notifications, the vehicle catalog (prices/names) and which vehicles they own.
-- To support another framework, add a branch to each function below.

Bridge = {}

local function started(res)
    return GetResourceState(res) == 'started'
end

local function detect()
    if Config.Framework ~= 'auto' then return Config.Framework end
    if started('qbx_core') then return 'qbx' end
    if started('qb-core') then return 'qb' end
    if started('es_extended') then return 'esx' end
    return 'none'
end

local QBCore, ESX
local cached

--- Detected framework (re-checked until one is found, in case it starts after us)
local function fw()
    if cached then return cached end
    local name = detect()
    if name == 'qb' then QBCore = exports['qb-core']:GetCoreObject() end
    if name == 'esx' then ESX = exports.es_extended:getSharedObject() end
    if name ~= 'none' then cached = name end
    return name
end
Bridge.framework = fw

------------------------------------------------------------------------
-- Players
------------------------------------------------------------------------

--- Character identifier (citizenid / ESX identifier) for a player source.
function Bridge.identifier(src)
    if fw() == 'qbx' then
        local p = exports.qbx_core:GetPlayer(src)
        return p and p.PlayerData.citizenid
    elseif fw() == 'qb' then
        local p = QBCore.Functions.GetPlayer(src)
        return p and p.PlayerData.citizenid
    elseif fw() == 'esx' then
        local p = ESX.GetPlayerFromId(src)
        return p and p.identifier
    end
    return GetPlayerIdentifierByType(src, 'license')
end

--- Online player source for a character identifier, or nil.
function Bridge.sourceOf(identifier)
    if fw() == 'qbx' then
        local p = exports.qbx_core:GetPlayerByCitizenId(identifier)
        return p and p.PlayerData.source
    elseif fw() == 'qb' then
        local p = QBCore.Functions.GetPlayerByCitizenId(identifier)
        return p and p.PlayerData.source
    elseif fw() == 'esx' then
        local p = ESX.GetPlayerFromIdentifier(identifier)
        return p and p.source
    end
    for _, id in ipairs(GetPlayers()) do
        if GetPlayerIdentifierByType(id, 'license') == identifier then return tonumber(id) end
    end
end

------------------------------------------------------------------------
-- Money (bank)
------------------------------------------------------------------------

function Bridge.getBank(src)
    if fw() == 'qbx' then
        return exports.qbx_core:GetMoney(src, 'bank') or 0
    elseif fw() == 'qb' then
        local p = QBCore.Functions.GetPlayer(src)
        return p and p.PlayerData.money.bank or 0
    elseif fw() == 'esx' then
        local p = ESX.GetPlayerFromId(src)
        return p and p.getAccount('bank').money or 0
    end
    return math.huge -- standalone: everything is free
end

function Bridge.removeBank(src, amount, reason)
    if amount <= 0 then return true end
    if Bridge.getBank(src) < amount then return false end

    if fw() == 'qbx' then
        return exports.qbx_core:RemoveMoney(src, 'bank', amount, reason)
    elseif fw() == 'qb' then
        return QBCore.Functions.GetPlayer(src).Functions.RemoveMoney('bank', amount, reason)
    elseif fw() == 'esx' then
        ESX.GetPlayerFromId(src).removeAccountMoney('bank', amount, reason)
        return true
    end
    return true
end

------------------------------------------------------------------------
-- Notifications
------------------------------------------------------------------------

function Bridge.notify(src, text, kind)
    kind = kind or 'inform'
    if fw() == 'qbx' then
        exports.qbx_core:Notify(src, text, kind)
    elseif fw() == 'qb' then
        TriggerClientEvent('QBCore:Notify', src, text, kind == 'inform' and 'primary' or kind)
    elseif fw() == 'esx' then
        TriggerClientEvent('esx:showNotification', src, text)
    else
        TriggerClientEvent('chat:addMessage', src, { args = { 'Vehicle', text } })
    end
end

------------------------------------------------------------------------
-- Vehicles
------------------------------------------------------------------------

--- { [modelHash] = { price, name, brand, category, model } }
function Bridge.vehicleCatalog()
    local out = {}
    local function add(model, v)
        model = v.model or model
        out[NormalizeHash(model)] = {
            model = model,
            price = tonumber(v.price),
            name = v.name,
            brand = v.brand,
            category = v.category and tostring(v.category):lower(),
        }
    end

    if fw() == 'qbx' then
        for model, v in pairs(exports.qbx_core:GetVehiclesByName()) do add(model, v) end
    elseif fw() == 'qb' then
        for model, v in pairs(QBCore.Shared.Vehicles) do add(model, v) end
    elseif fw() == 'esx' then
        for _, row in ipairs(MySQL.query.await('SELECT model, name, price, category FROM vehicles') or {}) do
            add(row.model, row)
        end
    end
    return out
end

--- Vehicles a character owns: { { plate, hash } }
function Bridge.ownedVehicles(identifier)
    local out = {}
    if fw() == 'qbx' or fw() == 'qb' then
        local rows = MySQL.query.await('SELECT plate, vehicle, hash FROM player_vehicles WHERE citizenid = ?', { identifier })
        for _, row in ipairs(rows or {}) do
            out[#out + 1] = { plate = NormalizePlate(row.plate), hash = NormalizeHash(row.vehicle or row.hash) }
        end
    elseif fw() == 'esx' then
        local rows = MySQL.query.await('SELECT plate, vehicle FROM owned_vehicles WHERE owner = ?', { identifier })
        for _, row in ipairs(rows or {}) do
            local props = json.decode(row.vehicle or '{}') or {}
            if props.model then
                out[#out + 1] = { plate = NormalizePlate(row.plate), hash = NormalizeHash(props.model) }
            end
        end
    end
    return out
end
