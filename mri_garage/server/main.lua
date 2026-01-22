-- server/main.lua
-- Callbacks + init

lib.callback.register('mri_garage:isAdmin', function(source)
  return Core.HasBuilderPermission(source)
end)

AddEventHandler('onResourceStart', function(res)
  if res ~= GetCurrentResourceName() then return end
  CreateThread(function()
    -- pequeno delay pra garantir oxmysql pronto
    Wait(250)
    Garages.LoadAll()
  end)
end)

AddEventHandler('onResourceStop', function(res)
  if res ~= GetCurrentResourceName() then return end
  -- nada por enquanto
end)
