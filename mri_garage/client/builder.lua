local function builderMenu()
  local isAdmin = lib.callback.await('mri_garage:isAdmin', false)
  if not isAdmin then
    lib.notify({ type='error', description='Sem permissão' })
    return
  end

  local cache = lib.callback.await('mri_garage:getGarages', false) or {}
  local opts = {
    {
      title = 'Criar nova garagem (no seu local)',
      icon = 'plus',
      onSelect = function()
        local input = lib.inputDialog('Nova Garagem', {
          { type='input', label='Nome', required=true },
          { type='select', label='Tipo', options = {
              { label='public', value='public' },
              { label='job', value='job' },
              { label='gang', value='gang' },
              { label='impound', value='impound' },
              { label='house', value='house' },
            }, default='public' },
          { type='input', label='Job (se tipo=job)', required=false },
          { type='input', label='Gang (se tipo=gang)', required=false },
        })
        if not input then return end

        local ped = PlayerPedId()
        local p = GetEntityCoords(ped)
        local h = GetEntityHeading(ped)

        local data = {
          name = input[1],
          type = input[2],
          job = input[3],
          gang = input[4],
          coords = { x=p.x, y=p.y, z=p.z },
          spawns = { { x=p.x+3.0, y=p.y, z=p.z, h=h } },
          blip = { sprite=357, color=2, scale=0.75, label=input[1] },
          settings = {}
        }

        local ok, msg = lib.callback.await('mri_garage:builderCreateGarage', false, data)
        lib.notify({ type = ok and 'success' or 'error', description = ok and 'Criada!' or (msg or 'Erro') })
      end
    }
  }

  for id,g in pairs(cache) do
    opts[#opts+1] = {
      title = ('[%s] %s'):format(id, g.name),
      description = ('Tipo: %s'):format(g.type),
      icon = 'warehouse',
      onSelect = function()
        local action = lib.inputDialog(g.name, {
          { type='select', label='Ação', options = {
            { label='Atualizar nome', value='rename' },
            { label='Atualizar posição (para seu local)', value='move' },
            { label='Adicionar spawn (no seu local)', value='addspawn' },
            { label='Deletar garagem', value='delete' },
          }, required=true }
        })
        if not action then return end
        local act = action[1]

        if act == 'rename' then
          local n = lib.inputDialog('Renomear', { { type='input', label='Novo nome', required=true } })
          if not n then return end
          lib.callback.await('mri_garage:builderUpdateGarage', false, id, { name = n[1] })
        elseif act == 'move' then
          local p = GetEntityCoords(PlayerPedId())
          lib.callback.await('mri_garage:builderUpdateGarage', false, id, { coords = { x=p.x, y=p.y, z=p.z } })
        elseif act == 'addspawn' then
          local p = GetEntityCoords(PlayerPedId())
          local h = GetEntityHeading(PlayerPedId())
          g.spawns[#g.spawns+1] = { x=p.x, y=p.y, z=p.z, h=h }
          lib.callback.await('mri_garage:builderUpdateGarage', false, id, { spawns = g.spawns })
        elseif act == 'delete' then
          lib.callback.await('mri_garage:builderDeleteGarage', false, id)
        end

        lib.notify({ type='success', description='Atualizado!' })
      end
    }
  end

  lib.registerContext({ id='mri_garage_builder', title='Garage Builder', options=opts })
  lib.showContext('mri_garage_builder')
end

RegisterCommand(Config.BuilderCommand, builderMenu)
