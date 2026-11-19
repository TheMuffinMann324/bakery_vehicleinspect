-- bakery_vehicleinspect configuration
-- Integrations (framework, vehicle keys, phone, target, notify) live in bridge/.

Config = {}

-- Framework used for vehicle data, money, ownership and notifications:
-- 'auto', 'qbx', 'qb', 'esx' or 'none'
--   qbx -> qbx_core vehicles + player_vehicles     qb  -> QBCore.Shared.Vehicles + player_vehicles
--   esx -> `vehicles` (esx_vehicleshop) + owned_vehicles
Config.Framework = 'auto'

-- Default keys (players can rebind them in Settings > Key Bindings > FiveM)
Config.Keys = {
    inspect = 'E', -- open / close the hood
    cycle   = 'G', -- switch info page (replaces R3)
}

Config.Distance    = 1.6   -- how close to the front of the car you need to be
Config.UseCamera   = true  -- cinematic over-the-shoulder camera while inspecting
Config.WalkToHood  = true  -- walk the player to the front corner before opening
Config.AllowLocked = false -- allow opening the hood of locked vehicles

-- Shown values are a share of the vehicle's framework price
Config.SellMultiplier     = 0.015 -- scaled further by body condition
Config.RegisterMultiplier = 0.10  -- also what the clerk charges to register

------------------------------------------------------------------------
-- Registration clerk (NPC): target her with ox_target / qb-target to open the menu
------------------------------------------------------------------------
Config.Office = {
    enabled   = true,
    -- Where clerks stand: vector4(x, y, z, heading). Add as many as you like.
    -- Tip: stand where you want her, then use /coords (or your admin menu) to copy the position.
    locations = {
        vector4(-544.9, -204.2, 38.22, 210.0), -- Rockford Hills City Hall
    },
    model    = 'a_f_y_business_02',
    scenario = 'WORLD_HUMAN_CLIPBOARD',
    distance = 2.0,  -- target distance
    blip     = { sprite = 525, color = 3, scale = 0.8, label = 'Vehicle Registration' },
    prices   = {
        alarm   = 2500, -- security system
        tracker = 1500, -- GPS tracker
    },
}

------------------------------------------------------------------------
-- Security (alarm)
------------------------------------------------------------------------
-- Who sets it off: anyone who isn't the owner and has no keys (bridge/client/keys.lua),
-- by pulling a locked door, getting behind the wheel or opening the hood.
Config.Alarm = {
    duration    = 30,   -- seconds the alarm sounds
    cooldown    = 60,   -- seconds before the same car can alert its owner again
    blipSeconds = 60,   -- how long the owner sees a flashing blip on the car
}

------------------------------------------------------------------------
-- GPS tracker
------------------------------------------------------------------------
Config.Tracker = {
    command     = 'tracker', -- opens the tracker app without a phone
    blipSeconds = 30,        -- "Ping" shows the car on the map for this long
    -- Phone app: 'auto', 'lb-phone', 'gksphone', 'codem-phone' or 'none' (see bridge/client/phone.lua)
    -- NPWD: add "bakery_vehicleinspect" to "apps" in npwd/config.json and start this resource before npwd
    phone       = 'auto',
    appName     = 'Tracker',
}

------------------------------------------------------------------------
-- Vehicle details
------------------------------------------------------------------------

-- Per-class defaults (GetVehicleClass). `value` is only used when the framework has no price.
Config.Classes = {
    [0]  = { type = 'Compact',    specialist = 'Tuners',     storage = 3, offroad = 2.5, value = 12000 },
    [1]  = { type = 'Sedan',      specialist = 'Lowriders',  storage = 4, offroad = 3.0, value = 15000 },
    [2]  = { type = 'SUV',        specialist = 'Off-Road',   storage = 6, offroad = 6.0, value = 30000 },
    [3]  = { type = 'Coupe',      specialist = 'Tuners',     storage = 3, offroad = 2.5, value = 25000 },
    [4]  = { type = 'Muscle',     specialist = 'Muscle',     storage = 4, offroad = 3.0, value = 25000 },
    [5]  = { type = 'Classic',    specialist = 'Classics',   storage = 3, offroad = 2.5, value = 60000 },
    [6]  = { type = 'Sports',     specialist = 'Exotics',    storage = 2, offroad = 2.0, value = 90000 },
    [7]  = { type = 'Super',      specialist = 'Exotics',    storage = 1, offroad = 1.5, value = 250000 },
    [8]  = { type = 'Motorcycle', specialist = 'Bikers',     storage = 1, offroad = 4.5, value = 10000 },
    [9]  = { type = 'Off-Road',   specialist = 'Off-Road',   storage = 5, offroad = 8.0, value = 35000 },
    [10] = { type = 'Industrial', specialist = 'Commercial', storage = 8, offroad = 5.0, value = 50000 },
    [11] = { type = 'Utility',    specialist = 'Commercial', storage = 7, offroad = 5.0, value = 25000 },
    [12] = { type = 'Van',        specialist = 'Commercial', storage = 8, offroad = 4.0, value = 20000 },
    [17] = { type = 'Service',    specialist = 'Commercial', storage = 4, offroad = 3.0, value = 20000 },
    [18] = { type = 'Emergency',  specialist = 'Commercial', storage = 4, offroad = 4.0, value = 40000 },
    [20] = { type = 'Commercial', specialist = 'Commercial', storage = 8, offroad = 4.0, value = 60000 },
}

-- Framework vehicle category -> class above (QBX / QBCore / ESX category names).
-- When a car has a framework category it wins over the game's class.
Config.Categories = {
    compacts = 0, compact = 0,
    sedans = 1, sedan = 1,
    suvs = 2, suv = 2,
    coupes = 3, coupe = 3,
    muscle = 4,
    sportsclassics = 5, classics = 5,
    sports = 6,
    super = 7,
    motorcycles = 8, motorcycle = 8,
    offroad = 9,
    industrial = 10,
    utility = 11,
    vans = 12, van = 12,
    service = 17,
    emergency = 18,
    commercial = 20,
}

-- Era shown on the info page. Anything not listed uses Config.DefaultEra
-- (or 'Classic' for the Sports Classics class).
Config.DefaultEra = 'Modern'
Config.Eras = {
    emperor   = '1980s Classic',
    emperor2  = '1980s Classic',
    virgo     = '1970s Classic',
    buccaneer = '1970s Classic',
    voodoo    = '1960s Classic',
    tornado   = '1950s Classic',
    peyote    = '1960s Classic',
    manana    = '1970s Classic',
}

-- Optional per-model overrides: any field from the class table plus fixed sell / register
-- e.g. emperor = { specialist = 'Lowriders', sell = 860, register = 5650 },
Config.Models = {
    emperor = { specialist = 'Lowriders' },
}
