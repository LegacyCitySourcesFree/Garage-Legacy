-- server/core.lua
-- Centraliza helpers de framework + permissões (QBX/Qbox e QB-Core)

Core = Core or {}

local function getQbxPlayer(src)
  if GetResourceState('qbx_core') ~= 'started' then return nil end
  local ok, player = pcall(function()
    return exports.qbx_core:GetPlayer(src)
  end)
  if ok then return player end
  return nil
end

local function getQbPlayer(src)
  if GetResourceState('qb-core') ~= 'started' then return nil end
  local ok, QB = pcall(function()
    return exports['qb-core']:GetCoreObject()
  end)
  if not ok or not QB then return nil end
  local p = QB.Functions.GetPlayer(src)
  return p
end

function Core.GetPlayer(src)
  return getQbxPlayer(src) or getQbPlayer(src)
end

function Core.GetCitizenId(src)
  local p = Core.GetPlayer(src)
  if not p then return nil end
  local pd = p.PlayerData
  return pd and pd.citizenid or nil
end

local function hasAce(src)
  -- Ace perms: Config.BuilderAcePermissions = {'group.admin', 'command.garagebuilder', ...}
  if type(Config.BuilderAcePermissions) == 'table' then
    for _,perm in ipairs(Config.BuilderAcePermissions) do
      if perm and IsPlayerAceAllowed(src, perm) then return true end
    end
  end

  -- compat antigo: Config.AdminGroups = { ['admin']=true, ['god']=true } (vai virar group.admin)
  if type(Config.AdminGroups) == 'table' then
    for group,_ in pairs(Config.AdminGroups) do
      local perm = tostring(group)
      -- se já veio "group.admin", usa direto; senão prefixa "group."
      if not perm:find('%.') then perm = ('group.%s'):format(perm) end
      if IsPlayerAceAllowed(src, perm) then return true end
    end
  end

  return false
end

local function hasQbxPermission(src)
  if GetResourceState('qbx_core') ~= 'started' then return false end

  -- Alguns servidores usam "exports.qbx_core:HasPermission(src, 'admin')" (varia).
  -- Vamos tentar de forma segura, sem travar o recurso.
  local perms = Config.BuilderQbxPermissions
  if type(perms) ~= 'table' then return false end

  for _,perm in ipairs(perms) do
    if perm and perm ~= '' then
      local ok, allowed = pcall(function()
        if exports.qbx_core.HasPermission then
          return exports.qbx_core:HasPermission(src, perm)
        end
        if exports.qbx_core.hasPermission then
          return exports.qbx_core:hasPermission(src, perm)
        end
        return false
      end)
      if ok and allowed == true then return true end
    end
  end
  return false
end

function Core.HasBuilderPermission(src)
  local cid = Core.GetCitizenId(src)

  if cid and type(Config.BuilderAllowedCitizenIds) == 'table' and Config.BuilderAllowedCitizenIds[cid] then
    return true
  end

  -- QBX perms (se existir no teu core)
  if hasQbxPermission(src) then return true end

  -- Ace perms
  if hasAce(src) then return true end

  return false
end
