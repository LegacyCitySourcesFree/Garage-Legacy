CREATE TABLE IF NOT EXISTS mri_garages (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(64) NOT NULL,
  type VARCHAR(16) NOT NULL DEFAULT 'public',  -- public/job/gang/impound/house
  owner VARCHAR(64) NULL,                      -- citizenid (se for privada)
  job VARCHAR(32) NULL,
  gang VARCHAR(32) NULL,
  coords LONGTEXT NOT NULL,                    -- JSON {x,y,z}
  spawns LONGTEXT NOT NULL,                    -- JSON [{x,y,z,h}, ...]
  blip LONGTEXT NULL,                          -- JSON {sprite,color,scale,label}
  settings LONGTEXT NULL,                      -- JSON {showInMap=true, storeAllowed=true, ...}
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Opcional: log de transferências (se quiser)
CREATE TABLE IF NOT EXISTS mri_garage_transfers (
  id INT AUTO_INCREMENT PRIMARY KEY,
  plate VARCHAR(16) NOT NULL,
  from_cid VARCHAR(64) NOT NULL,
  to_cid VARCHAR(64) NOT NULL,
  price INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
