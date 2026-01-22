-- server/vehicles.lua
-- DB compat para diferentes schemas de player_vehicles (QBX/Qbox/QB)

local function safeDecode(s, fallback)
  if not s or s == '' then return fallback end
  local ok, val = pcall(json.decode, s)
  if ok and val ~= nil then return val end
  return fallback
end

Vehicles = Vehicles or {}

Vehicles.Schema = Vehicles.Schema or {
  columns = nil,     -- set<string,true>
  hasMods = false,
}

local function loadColumns()
  if Vehicles.Schema.columns then return Vehicles.Schema end

  local cols = {}
  local ok, rows = pcall(function()
    return MySQL.query.await('SHOW COLUMNS FROM player_vehicles', {})
  end)

  if ok and rows then
    for _,r in ipairs(rows) do
      if r.Field then cols[r.Field] = true end
    end
  end

  Vehicles.Schema.columns = cols
  Vehicles.Schema.hasMods = cols['mods'] == true
  return Vehicles.Schema
end

local function hasCol(name)
  local s = loadColumns()
  return s.columns and s.columns[name] == true
end

local function getVehiclePropsRow(r)
  loadColumns()
  if Vehicles.Schema.hasMods then
    local props = safeDecode(r.mods, {})
    if type(props) ~= 'table' then props = {} end
    -- Na maioria das bases: r.vehicle é o model string
    if r.vehicle and type(r.vehicle) == 'string' and r.vehicle ~= '' then
      props.model = props.model or r.vehicle
    end
    return props
  end
  -- schema antigo: vehicle guarda json
  return safeDecode(r.vehicle, {})
end

local function giveKeys(src, plate)
  if not Config.Keys or not Config.Keys.Enabled then return end
  for _,p in ipairs(Config.Keys.Providers or {}) do
    if GetResourceState(p.resource) == 'started' then
      local ok = pcall(function()
        exports[p.resource][p.export](table.unpack(p.args(src, plate)))
      end)
      if ok then return end
    end
  end
end

local function selectColumns()
  -- monta select só com colunas existentes, pra não quebrar em schemas diferentes
  local cols = { 'plate', 'vehicle' }
  if Vehicles.Schema.hasMods then table.insert(cols, 'mods') end
  if hasCol('state') then table.insert(cols, 'state') end
  if hasCol('stored') and not hasCol('state') then table.insert(cols, 'stored') end
  if hasCol('fuel') then table.insert(cols, 'fuel') end
  if hasCol('engine') then table.insert(cols, 'engine') end
  if hasCol('body') then table.insert(cols, 'body') end
  if hasCol('garage') then table.insert(cols, 'garage') end
  if hasCol('favorite') then table.insert(cols, 'favorite') end
  return table.concat(cols, ', ')
end

local function getStoredState(row)
  -- Preferência: state (1=guardado, 0=fora) | fallback: stored
  if row.state ~= nil then return tonumber(row.state) or 0 end
  if row.stored ~= nil then return tonumber(row.stored) or 0 end
  return 0
end

-- Lista veículos do player
lib.callback.register('mri_garage:getMyVehicles', function(src)
  local cid = Core.GetCitizenId(src)
  if not cid then return {} end

  loadColumns()

  local cols = selectColumns()
  local rows = MySQL.query.await(('SELECT %s FROM player_vehicles WHERE citizenid = ?'):format(cols), { cid }) or {}

  local out = {}
  for _,r in ipairs(rows) do
    local vehData = getVehiclePropsRow(r)
    out[#out+1] = {
      plate = r.plate,
      model = vehData.model or vehData.hash or vehData.name or r.vehicle,
      vehicle = vehData,
      state = getStoredState(r),
      fuel = tonumber(r.fuel) or 100,
      engine = tonumber(r.engine) or 1000,
      body = tonumber(r.body) or 1000,
      garage = r.garage,
      favorite = (tonumber(r.favorite) or 0) == 1
    }
  end
  return out
end)

-- Marcar favorito (só se coluna existir)
RegisterNetEvent('mri_garage:setFavorite', function(plate, fav)
  local src = source
  local cid = Core.GetCitizenId(src)
  if not cid then return end
  loadColumns()
  if not hasCol('favorite') then return end
  MySQL.query.await('UPDATE player_vehicles SET favorite=? WHERE citizenid=? AND plate=?', { fav and 1 or 0, cid, plate })
end)

-- Transferir veículo
lib.callback.register('mri_garage:transferVehicle', function(src, plate, toCitizenId, price)
  local cid = Core.GetCitizenId(src)
  if not cid then return false, 'Sem player' end
  if not plate or plate == '' then return false, 'Placa inválida' end
  if not toCitizenId or toCitizenId == '' then return false, 'Destino inválido' end

  local r = MySQL.single.await('SELECT plate FROM player_vehicles WHERE citizenid=? AND plate=?', { cid, plate })
  if not r then return false, 'Veículo não encontrado' end

  MySQL.query.await('UPDATE player_vehicles SET citizenid=? WHERE plate=? AND citizenid=?', { toCitizenId, plate, cid })
  MySQL.insert.await('INSERT INTO mri_garage_transfers (plate, from_cid, to_cid, price) VALUES (?,?,?,?)', { plate, cid, toCitizenId, tonumber(price) or 0 })

  return true
end)
-- Transferir por PlayerID (server id)
lib.callback.register('mri_garage:transferVehicleByPlayerId', function(src, plate, playerId, price)
  local cid = Core.GetCitizenId(src)
  if not cid then return false, 'Sem player' end
  if not plate or plate == '' then return false, 'Placa inválida' end
  if not playerId or tonumber(playerId) == nil then return false, 'ID inválido' end

  local targetSrc = tonumber(playerId)
  if targetSrc == src then return false, 'Você não pode transferir pra si mesmo' end
  local toCitizenId = Core.GetCitizenId(targetSrc)
  if not toCitizenId then return false, 'Player alvo offline/inválido' end

  local r = MySQL.single.await('SELECT plate FROM player_vehicles WHERE citizenid=? AND plate=?', { cid, plate })
  if not r then return false, 'Veículo não encontrado' end

  MySQL.query.await('UPDATE player_vehicles SET citizenid=? WHERE plate=? AND citizenid=?', { toCitizenId, plate, cid })
  MySQL.insert.await('INSERT INTO mri_garage_transfers (plate, from_cid, to_cid, price) VALUES (?,?,?,?)', { plate, cid, toCitizenId, tonumber(price) or 0 })

  return true
end)


local function updateStored(plate, cid, storedVal)
  loadColumns()
  if hasCol('state') then
    MySQL.query.await('UPDATE player_vehicles SET state=? WHERE citizenid=? AND plate=?', { storedVal, cid, plate })
    return
  end
  if hasCol('stored') then
    MySQL.query.await('UPDATE player_vehicles SET stored=? WHERE citizenid=? AND plate=?', { storedVal, cid, plate })
    return
  end
  -- sem coluna state/stored: não tem como marcar guardado/fora; não quebra.
end

-- Atualiza estado quando guardar
RegisterNetEvent('mri_garage:storeVehicle', function(payload)
  local src = source
  local cid = Core.GetCitizenId(src)
  if not cid then return end
  if type(payload) ~= 'table' then return end
  if not payload.plate then return end

  loadColumns()

  local sets, vals = {}, {}
  -- marca guardado
  if hasCol('state') then
    sets[#sets+1] = 'state=1'
  elseif hasCol('stored') then
    sets[#sets+1] = 'stored=1'
  end

  if hasCol('fuel') then sets[#sets+1] = 'fuel=?'; vals[#vals+1] = payload.fuel end
  if hasCol('engine') then sets[#sets+1] = 'engine=?'; vals[#vals+1] = payload.engine end
  if hasCol('body') then sets[#sets+1] = 'body=?'; vals[#vals+1] = payload.body end
  if hasCol('garage') then sets[#sets+1] = 'garage=?'; vals[#vals+1] = tostring(payload.garageId) end

  if #sets == 0 then return end

  vals[#vals+1] = cid
  vals[#vals+1] = payload.plate

  MySQL.query.await(('UPDATE player_vehicles SET %s WHERE citizenid=? AND plate=?'):format(table.concat(sets, ', ')), vals)
end)

-- Marca como retirado e devolve dados pra spawn
lib.callback.register('mri_garage:takeOutVehicle', function(src, plate, garageId)
  local cid = Core.GetCitizenId(src)
  if not cid then return false, 'Sem player' end
  if not plate or plate == '' then return false, 'Placa inválida' end

  loadColumns()

  local cols = selectColumns()
  local r = MySQL.single.await(('SELECT %s FROM player_vehicles WHERE citizenid=? AND plate=?'):format(cols), { cid, plate })
  if not r then return false, 'Veículo não encontrado' end

  updateStored(plate, cid, 0)

  local vehData = getVehiclePropsRow(r)
  giveKeys(src, plate)

  return true, {
    plate = r.plate,
    vehicle = vehData,
    fuel = tonumber(r.fuel) or 100,
    engine = tonumber(r.engine) or 1000,
    body = tonumber(r.body) or 1000,
  }
end)
