local GaragesCache = {}
local zones = {}
local blips = {}

local function clearAll()
  for _,z in ipairs(zones) do
    if z and z.remove then z:remove() end
  end
  zones = {}

  for _,b in ipairs(blips) do
    if b and DoesBlipExist(b) then RemoveBlip(b) end
  end
  blips = {}
end

function CreateGarageZones()
  clearAll()

  for id,g in pairs(GaragesCache) do
    local c = g.coords
    if c and c.x then
      local center = vec3(c.x + 0.0, c.y + 0.0, c.z + 0.0)

      local zone = lib.zones.sphere({
        coords = center,
        radius = Config.UI.openDist or 2.0,
        debug = Config.Debug,
        inside = function()
          lib.showTextUI(('[%s] Abrir Garagem'):format(Config.UI.openKey or 'E'))
          if IsControlJustReleased(0, 38) then -- E
            exports.mri_garage:OpenGarageUI(id)
          end
        end,
        onExit = function()
          lib.hideTextUI()
        end
      })

      zones[#zones+1] = zone

      if g.blip and (g.settings and g.settings.showInMap ~= false) then
        local b = AddBlipForCoord(center.x, center.y, center.z)
        SetBlipSprite(b, g.blip.sprite or 357)
        SetBlipColour(b, g.blip.color or 2)
        SetBlipScale(b, g.blip.scale or 0.75)
        SetBlipAsShortRange(b, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(g.blip.label or g.name or 'Garagem')
        EndTextCommandSetBlipName(b)
        blips[#blips+1] = b
      end
    end
  end
end

RegisterNetEvent('mri_garage:garagesSync', function(cache)
  GaragesCache = cache or {}
  CreateGarageZones()
end)

CreateThread(function()
  local cache = lib.callback.await('mri_garage:getGarages', false) or {}
  TriggerEvent('mri_garage:garagesSync', cache)
end)
