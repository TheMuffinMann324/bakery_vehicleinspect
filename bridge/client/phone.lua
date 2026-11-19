-- Phone integration (client): adds the GPS Tracker app to your phone.
--
-- Every phone loads the same page, web/dist/phone.html, which talks to this resource
-- directly. To support another phone, add an entry to `phones` that registers
-- `PAGE` as a custom app using that phone's own export.
--
-- NPWD works differently: add "bakery_vehicleinspect" to "apps" in npwd/config.json
-- (NPWD loads web/dist/remoteEntry.js itself, nothing to do here).

local RES = GetCurrentResourceName()
local APP_ID = 'bakery-tracker'
local PAGE = ('https://cfx-nui-%s/web/dist/phone.html'):format(RES)
local ICON = ('https://cfx-nui-%s/web/dist/tracker-icon.svg'):format(RES)
local DESCRIPTION = 'Locate your vehicles fitted with a GPS tracker'

local phones = {
    ['lb-phone'] = {
        register = function()
            return exports['lb-phone']:AddCustomApp({
                identifier = APP_ID,
                name = Config.Tracker.appName,
                description = DESCRIPTION,
                developer = 'Bakery',
                defaultApp = true,
                ui = RES .. '/web/dist/phone.html',
                icon = ICON,
                fixBlur = true,
            })
        end,
        remove = function() exports['lb-phone']:RemoveCustomApp(APP_ID) end,
        notify = function(title, text)
            exports['lb-phone']:SendNotification({ app = APP_ID, title = title, content = text })
        end,
    },

    ['gksphone'] = {
        register = function()
            exports['gksphone']:AddCustomApp({
                name = APP_ID,
                appurl = PAGE,
                icons = ICON,
                description = DESCRIPTION,
                show = true,
                labelLangs = { en = Config.Tracker.appName },
            })
            return true
        end,
    },

    ['codem-phone'] = {
        register = function()
            return exports['codem-phone']:AddCustomApp({
                identifier = APP_ID,
                name = Config.Tracker.appName,
                ui = PAGE,
                icon = ICON,
                description = DESCRIPTION,
                defaultApp = true,
                fixBlur = true,
            })
        end,
    },
}

--- Name of the phone in use, or nil
local function activePhone()
    local choice = Config.Tracker.phone
    if choice == 'none' then return nil end
    if choice ~= 'auto' then
        return phones[choice] and GetResourceState(choice) == 'started' and choice or nil
    end
    for name in pairs(phones) do
        if GetResourceState(name) == 'started' then return name end
    end
end

local function register()
    local name = activePhone()
    if not name then return end
    Wait(500) -- let the phone finish starting
    local ok, added, err = pcall(phones[name].register)
    if not ok or added == false then
        print(('^3[%s] could not add the tracker app to %s: %s^0'):format(RES, name, tostring(err or added)))
    end
end

--- Push notification on the phone (when the phone supports it)
function PhoneNotify(title, text)
    local phone = phones[activePhone() or '']
    if phone and phone.notify then pcall(phone.notify, title, text) end
end

CreateThread(register)

AddEventHandler('onClientResourceStart', function(res)
    if phones[res] then CreateThread(register) end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= RES then return end
    local phone = phones[activePhone() or '']
    if phone and phone.remove then pcall(phone.remove) end
end)
