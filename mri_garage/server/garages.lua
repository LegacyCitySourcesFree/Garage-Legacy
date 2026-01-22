-- server/garages.lua
Garages = Garages or {}
Garages.Cache = Garages.Cache or {}

local function safeDecode(s, fallback)
  if not s then return fallback end
  local ok, val = pcall(json.decode, s)
  if ok and val ~= nil then return val end
  return fallback
end

function Garages.LoadAll()
  local rows = MySQL.query.await('SELECT * FROM mri_garages', {}) or {}
  Garages.Cache = {}

  for _,r in ipairs(rows) do
    Garages.Cache[r.id] = {
      id = r.id,
      name = r.name,
      type = r.type or 'public',
      owner = r.owner,
      job = r.job,
      gang = r.gang,
      coords = safeDecode(r.coords, { x = 0.0, y = 0.0, z = 0.0 }),
      spawns = safeDecode(r.spawns, {}),
      blip = safeDecode(r.blip, nil),
      settings = safeDecode(r.settings, {}),
    }
  end

  TriggerClientEvent('mri_garage:garagesSync', -1, Garages.Cache)
end

lib.callback.register('mri_garage:getGarages', function()
  return Garages.Cache
end)

lib.callback.register('mri_garage:builderCreateGarage', function(src, data)
  if not Core.HasBuilderPermission(src) then return false, 'Sem permissão' end
  if type(data) ~= 'table' then return false, 'Dados inválidos' end
  if not data.name or data.name == '' then return false, 'Nome inválido' end
  if not data.coords or not data.coords.x then return false, 'Coords inválidas' end
  if type(data.spawns) ~= 'table' or not data.spawns[1] then return false, 'Spawn inválido' end

  data.settings = data.settings or {}
  for k,v in pairs(Config.DefaultGarageSettings) do
    if data.settings[k] == nil then data.settings[k] = v end
  end

  local id = MySQL.insert.await([[
    INSERT INTO mri_garages (name,type,owner,job,gang,coords,spawns,blip,settings)
    VALUES (?,?,?,?,?,?,?,?,?)
  ]], {
    tostring(data.name),
    tostring(data.type or 'public'),
    data.owner,
    data.job,
    data.gang,
    json.encode(data.coords),
    json.encode(data.spawns),
    data.blip and json.encode(data.blip) or nil,
    json.encode(data.settings),
  })

  Garages.LoadAll()
  return true, id
end)

lib.callback.register('mri_garage:builderDeleteGarage', function(src, id)
  if not Core.HasBuilderPermission(src) then return false, 'Sem permissão' end
  if not id then return false, 'ID inválido' end

  MySQL.query.await('DELETE FROM mri_garages WHERE id = ?', { id })
  Garages.LoadAll()
  return true
end)

lib.callback.register('mri_garage:builderUpdateGarage', function(src, id, patch)
  if not Core.HasBuilderPermission(src) then return false, 'Sem permissão' end
  if not id then return false, 'ID inválido' end
  if type(patch) ~= 'table' then return false, 'Patch inválido' end

  local current = Garages.Cache[id]
  if not current then return false, 'Garagem não encontrada' end

  local merged = {}
  for k,v in pairs(current) do merged[k] = v end
  for k,v in pairs(patch) do merged[k] = v end

  MySQL.query.await([[
    UPDATE mri_garages
    SET name=?, type=?, owner=?, job=?, gang=?, coords=?, spawns=?, blip=?, settings=?
    WHERE id=?
  ]], {
    merged.name,
    merged.type,
    merged.owner,
    merged.job,
    merged.gang,
    json.encode(merged.coords),
    json.encode(merged.spawns),
    merged.blip and json.encode(merged.blip) or nil,
    json.encode(merged.settings or {}),
    id
  })

  Garages.LoadAll()
  return true
end)
