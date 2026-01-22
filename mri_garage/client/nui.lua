local UI = { open = false, currentGarage = nil }
local GaragesCache = {}

RegisterNetEvent('mri_garage:garagesSync', function(cache)
  GaragesCache = cache or {}
end)

local function setFocus(state)
  SetNuiFocus(state, state)
  -- não manter input do jogo enquanto NUI está aberta (evita soco/tiro ao clicar)
  SetNuiFocusKeepInput(false)
end

-- Desabilita controles chatos enquanto NUI aberta
CreateThread(function()
  while true do
    if UI.open then
      DisableControlAction(0, 24, true)  -- Attack
      DisableControlAction(0, 25, true)  -- Aim
      DisableControlAction(0, 37, true)  -- Weapon wheel
      DisableControlAction(0, 140, true) -- Melee light
      DisableControlAction(0, 141, true) -- Melee heavy
      DisableControlAction(0, 142, true) -- Melee alternate
      DisableControlAction(0, 257, true) -- Attack2
      DisableControlAction(0, 263, true) -- Melee
      DisableControlAction(0, 264, true) -- Melee2
      DisableControlAction(0, 200, true) -- Pause
      DisableControlAction(0, 322, true) -- ESC
      DisableControlAction(0, 18, true)  -- Enter
      Wait(0)
    else
      Wait(250)
    end
  end
end)

local function openUI(garageId)
  if UI.open then return end
  UI.open = true
  UI.currentGarage = garageId

  local vehicles = lib.callback.await('mri_garage:getMyVehicles', false) or {}

  -- marca elétricos pra UI (bateria ao invés de gasolina)
  for _,v in ipairs(vehicles) do
    local model = v.model
    if type(model) == 'table' and model.model then model = model.model end
    if type(model) == 'string' then model = joaat(model) end
    v.isElectric = ElectricModels[model] == true
  end

  SendNUIMessage({
    action = 'open',
    garageId = garageId,
    garages = GaragesCache,
    vehicles = vehicles
  })
  setFocus(true)
end

local function closeUI()
  if not UI.open then return end
  UI.open = false
  UI.currentGarage = nil
  SendNUIMessage({ action = 'close' })
  setFocus(false)
end

RegisterNUICallback('close', function(_, cb)
  closeUI()
  cb(true)
end)

RegisterNUICallback('setFavorite', function(data, cb)
  TriggerServerEvent('mri_garage:setFavorite', data.plate, data.favorite)
  cb(true)
end)

RegisterNUICallback('transfer', function(data, cb)
  local ok, msg = lib.callback.await('mri_garage:transferVehicle', false, data.plate, data.toCitizenId, data.price or 0)
  cb({ ok = ok, msg = msg })
end)

RegisterNUICallback('transferByPlayerId', function(data, cb)
  local ok, msg = lib.callback.await('mri_garage:transferVehicleByPlayerId', false, data.plate, tonumber(data.playerId), data.price or 0)
  cb({ ok = ok, msg = msg })
end)

-- Retirar
RegisterNUICallback('takeOut', function(data, cb)
  local ok, result = lib.callback.await('mri_garage:takeOutVehicle', false, data.plate, UI.currentGarage)
  if not ok then
    cb({ ok = false, msg = result })
    return
  end

  local g = GaragesCache[UI.currentGarage]
  if not g or not g.spawns or not g.spawns[1] then
    cb({ ok = false, msg = 'Garagem sem spawn' })
    return
  end

  local spawn = g.spawns[1]
  local model = result.vehicle.model or result.vehicle.hash or result.vehicle.name
  if type(model) == 'string' then model = joaat(model) end
  if not model then
    cb({ ok = false, msg = 'Modelo inválido' })
    return
  end

  lib.requestModel(model, 8000)
  local veh = CreateVehicle(model, spawn.x + 0.0, spawn.y + 0.0, spawn.z + 0.0, spawn.h + 0.0, true, false)
  SetVehicleNumberPlateText(veh, result.plate)

  -- depois do spawn e de setar a plate:
  local plate = result.plate or GetVehicleNumberPlateText(veh)
  -- garante que a entidade já está networked
  local netId = NetworkGetNetworkIdFromEntity(veh)
  TriggerServerEvent('mri_garage:server:giveKeys', plate)


  -- Aplicar “estado”
  Entity(veh).state:set(Config.FuelStateKey, result.fuel, true)

  SetVehicleEngineHealth(veh, result.engine + 0.0)
  SetVehicleBodyHealth(veh, result.body + 0.0)
  SetVehicleOnGroundProperly(veh)

  TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)

  cb({ ok = true })
end)

-- Guardar (pega veículo que o player está usando)
RegisterNUICallback('store', function(_, cb)
  local ped = PlayerPedId()
  local veh = GetVehiclePedIsIn(ped, false)
  if veh == 0 then cb({ ok=false, msg='Você precisa estar em um veículo' }) return end

  local plate = GetVehicleNumberPlateText(veh)
  local fuel = Entity(veh).state[Config.FuelStateKey] or GetVehicleFuelLevel(veh)
  local engine = GetVehicleEngineHealth(veh)
  local body = GetVehicleBodyHealth(veh)

  TriggerServerEvent('mri_garage:storeVehicle', {
    plate = plate,
    fuel = tonumber(fuel) or 100,
    engine = tonumber(engine) or 1000,
    body = tonumber(body) or 1000,
    garageId = UI.currentGarage
  })

  DeleteVehicle(veh)
  cb({ ok=true })
end)

exports('OpenGarageUI', openUI)
exports('CloseGarageUI', closeUI)


-- Entrega chaves após retirar (compat com mri_Qcarkeys/mm_carkeys e outros)
RegisterNetEvent('mri_garage:client:giveKeys', function(plate)
  if not plate or plate == '' then return end

  -- mri_Qcarkeys (preferido)
  if GetResourceState('mri_Qcarkeys') == 'started' then
    pcall(function()
      if exports['mri_Qcarkeys'] and exports['mri_Qcarkeys'].GiveKeyItem then
        exports['mri_Qcarkeys']:GiveKeyItem(plate)
        return
      end
    end)
    -- fallback: se não tiver export, tenta netevent direto
    TriggerServerEvent('mm_carkeys:server:acquirevehiclekeys', plate)
    return
  end

  -- qb-vehiclekeys
  if GetResourceState('qb-vehiclekeys') == 'started' then
    TriggerEvent('vehiclekeys:client:SetOwner', plate)
    TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', plate)
    return
  end
end)
