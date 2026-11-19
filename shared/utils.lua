-- Small helpers shared by client and server

--- Plates come back padded with spaces from the game; store them trimmed + upper case.
function NormalizePlate(plate)
    if not plate then return nil end
    return (tostring(plate):gsub('^%s+', ''):gsub('%s+$', ''):upper())
end

--- Model hashes can be signed or unsigned depending on the native; always use unsigned.
function NormalizeHash(hash)
    if type(hash) == 'string' then
        hash = tonumber(hash) or joaat(hash)
    end
    return math.tointeger(hash) & 0xFFFFFFFF
end

------------------------------------------------------------------------
-- Minimal client -> server callbacks (no ox_lib dependency)
------------------------------------------------------------------------

local EVENT = GetCurrentResourceName() .. ':cb'

if IsDuplicityVersion() then
    local handlers = {}

    function RegisterCallback(name, fn)
        handlers[name] = fn
    end

    RegisterNetEvent(EVENT, function(name, id, ...)
        local src = source
        local fn = handlers[name]
        if not fn then return end
        local ok, result = pcall(fn, src, ...)
        if not ok then
            print(('^1[%s] callback %s failed: %s^0'):format(GetCurrentResourceName(), name, result))
            result = nil
        end
        TriggerClientEvent(EVENT .. ':result', src, id, result)
    end)
else
    local pending, nextId = {}, 0

    RegisterNetEvent(EVENT .. ':result', function(id, result)
        local p = pending[id]
        if p then
            pending[id] = nil
            p:resolve(result)
        end
    end)

    --- Calls a server callback and waits for its result (nil after 10s).
    function TriggerCallback(name, ...)
        nextId = nextId + 1
        local id = nextId
        local p = promise.new()
        pending[id] = p
        TriggerServerEvent(EVENT, name, id, ...)
        SetTimeout(10000, function()
            if pending[id] then
                pending[id] = nil
                p:resolve(nil)
            end
        end)
        return Citizen.Await(p)
    end
end
