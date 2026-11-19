-- Client helpers shared by the inspect, office, security and tracker files

function Clamp(v, lo, hi)
    return math.max(lo, math.min(hi, v))
end

--- Label of the key a player bound to a command (falls back to the default).
function KeyLabel(command, fallback)
    local btn = GetControlInstructionalButton(0, GetHashKey(command) | 0x80000000, true)
    if btn and btn:sub(1, 2) == 't_' then
        return btn:sub(3)
    end
    return fallback
end

function RequestControl(entity)
    if NetworkHasControlOfEntity(entity) then return true end
    NetworkRequestControlOfEntity(entity)
    local timeout = GetGameTimer() + 500
    while not NetworkHasControlOfEntity(entity) and GetGameTimer() < timeout do
        Wait(0)
    end
    return NetworkHasControlOfEntity(entity)
end

--- Game label for a model, e.g. "Albany", "Emperor"
function ModelLabels(hash)
    local make = GetLabelText(GetMakeNameFromVehicleModel(hash))
    if make == 'NULL' then make = GetMakeNameFromVehicleModel(hash) end
    local name = GetLabelText(GetDisplayNameFromVehicleModel(hash))
    if name == 'NULL' then name = GetDisplayNameFromVehicleModel(hash) end
    return make, name
end

function StreetName(coords)
    local street, cross = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local name = GetStreetNameFromHashKey(street)
    if cross ~= 0 then name = name .. ' / ' .. GetStreetNameFromHashKey(cross) end
    return name
end

------------------------------------------------------------------------
-- Framework vehicle catalog (prices, names, categories)
------------------------------------------------------------------------

local catalog = nil

--- { [hash] = { price, name, brand, category, model } }, fetched once from the server
function GetCatalog()
    if catalog and next(catalog) then return catalog end
    catalog = TriggerCallback('catalog') or {}
    return catalog
end

------------------------------------------------------------------------
-- World key prompt ("E  OPEN HOOD")
------------------------------------------------------------------------

local last = { visible = false, x = 0, y = 0, label = '' }

--- Shows the key prompt at a world position (only sends NUI updates when it moves).
function ShowPrompt(coords, label)
    local onScreen, x, y = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)
    if not onScreen then return HidePrompt() end

    if last.visible and label == last.label
        and math.abs(x - last.x) < 0.001 and math.abs(y - last.y) < 0.001 then
        return
    end

    last = { visible = true, x = x, y = y, label = label }
    SendNUIMessage({
        action = 'prompt',
        visible = true,
        x = x,
        y = y,
        label = label,
        key = KeyLabel('vehinspect', Config.Keys.inspect),
    })
end

function HidePrompt()
    if not last.visible then return end
    last = { visible = false, x = 0, y = 0, label = '' }
    SendNUIMessage({ action = 'prompt', visible = false })
end

------------------------------------------------------------------------
-- Map blips
------------------------------------------------------------------------

--- Flashing map blip that removes itself after `seconds`
function AddTimedBlip(coords, label, color, seconds)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 225)
    SetBlipColour(blip, color)
    SetBlipFlashes(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(label)
    EndTextCommandSetBlipName(blip)
    SetTimeout(seconds * 1000, function()
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end)
    return blip
end
