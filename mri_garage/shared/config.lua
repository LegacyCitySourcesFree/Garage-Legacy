Config = {}

Config.Framework = 'qbx' -- 'qbx' (MRI Qbox) ou 'qb' (caso adapte)
Config.UseOxTarget = true
Config.Debug = false

-- =========================
-- PERMISSÕES (BUILDER/ADMIN)
-- =========================
-- 1) Permitir por CitizenId (mais seguro e direto)
Config.BuilderAllowedCitizenIds = {
  -- coloque seu citizenid aqui (ex: ['ABC12345'] = true),
}

-- 2) Permitir por ACE permissions (recomendado para admins)
-- Dica: no server.cfg você pode setar:
-- add_ace group.admin "command.garagebuilder" allow
-- ou simplesmente usar "group.admin" (depende do seu setup)
Config.BuilderAcePermissions = {
  'group.admin',
  'group.superadmin',
  'command.garagebuilder',
}

-- 3) Permitir por perm do QBX (se o seu qbx_core expõe HasPermission/hasPermission)
-- Ex: 'admin', 'god', etc (ajuste conforme teu servidor)
Config.BuilderQbxPermissions = {
  'admin',
  'god',
}

-- Compat antigo (se você já usa isso em outros scripts):
-- Config.AdminGroups = { ['admin'] = true, ['god'] = true }
Config.AdminGroups = Config.AdminGroups or nil

-- Comando para abrir o builder
Config.BuilderCommand = 'garagebuilder'

-- =========================
-- INTEGRAÇÃO DE CHAVES
-- =========================
Config.Keys = {
  Enabled = true,
  -- tente em ordem (vai chamar o primeiro export existente)
  Providers = {
    { resource = 'mri_qcarkeys', export = 'GiveKey', args = function(src, plate) return { src, plate } end },
    { resource = 'qb-vehiclekeys', export = 'GiveVehicleKeys', args = function(src, plate) return { src, plate } end },
  }
}

-- =========================
-- FUEL / BATERIA
-- =========================
Config.FuelStateKey = 'fuel'        -- Entity(veh).state.fuel
Config.BatteryStateKey = 'battery'  -- Entity(veh).state.battery (se quiser separar)

-- =========================
-- REGRAS PADRÃO
-- =========================
Config.DefaultGarageSettings = {
  showInMap = true,
  storeAllowed = true,
  takeAllowed = true,
  allowTransfer = true,
  allowTrack = true,
  maxDistanceToStore = 35.0,
}

-- =========================
-- UI
-- =========================
Config.UI = {
  openKey = 'E',
  openDist = 2.0,
}
