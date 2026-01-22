-- server/keys.lua
-- Centraliza entrega de chaves chamando o CLIENT (porque o mri_Qcarkeys/mm_carkeys depende do source no net event)

RegisterNetEvent('mri_garage:server:giveKeys', function(plate)
  local src = source
  if not plate or plate == '' then return end
  TriggerClientEvent('mri_garage:client:giveKeys', src, plate)
end)
