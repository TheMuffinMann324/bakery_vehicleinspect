fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Bakery'
description 'GTA 6 style vehicle inspection, registration, security systems and GPS trackers'
version '1.2.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/utils.lua',
}

client_scripts {
    'bridge/client/*.lua', -- keys, notify, phone, target
    'client/utils.lua',
    'client/security.lua',
    'client/office.lua',
    'client/tracker.lua',
    'client/inspect.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/server/framework.lua',
    'server/vehicles.lua',
    'server/office.lua',
    'server/security.lua',
    'server/tracker.lua',
}

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/phone.html',
    'web/dist/**/*',
}

dependencies {
    'ox_lib',
    'oxmysql',
}
