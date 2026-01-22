fx_version 'cerulean'
game 'gta5'

author 'mri_garage'
description 'Garage system for MRI Qbox/QBX with NUI + in-game configurable garages'
version '1.0.1'

lua54 'yes'

ui_page 'web/index.html'

shared_scripts {
  '@ox_lib/init.lua',
  'shared/utils.lua',
  'shared/electric.lua',
  'shared/config.lua',
}

client_scripts {
  'client/nui.lua',
  'client/zones.lua',
  'client/builder.lua',
  'client/main.lua',
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server/core.lua',
  'server/garages.lua',
  'server/vehicles.lua',
  'server/main.lua',
  'server/keys.lua',
}

files {
  'web/index.html',
  'web/style.css',
  'web/app.js',
}
