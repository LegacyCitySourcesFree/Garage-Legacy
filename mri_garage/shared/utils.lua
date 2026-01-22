Utils = {}

function Utils.vec3ToJson(v)
  return json.encode({ x = v.x, y = v.y, z = v.z })
end

function Utils.jsonToVec3(s)
  local t = json.decode(s)
  return vec3(t.x + 0.0, t.y + 0.0, t.z + 0.0)
end

function Utils.clamp(x, a, b)
  if x < a then return a end
  if x > b then return b end
  return x
end

-- Calcula "dano" em % (0 = perfeito, 100 = destruído)
-- engineHealth/bodyHealth vão 0..1000 normalmente.
function Utils.damagePercent(engineHealth, bodyHealth)
  engineHealth = tonumber(engineHealth) or 1000
  bodyHealth = tonumber(bodyHealth) or 1000
  local avg = (engineHealth + bodyHealth) / 2.0
  local condition = Utils.clamp(avg / 1000.0, 0.0, 1.0) * 100.0   -- 0..100 (saúde)
  local damage = 100.0 - condition                                 -- 0..100 (dano)
  return math.floor(damage + 0.5)
end
