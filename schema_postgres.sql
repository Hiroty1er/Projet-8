-- =============================================================================
-- Schéma PostgreSQL pour la centralisation et l'agrégation de données météo
-- =============================================================================

-- Suppression optionnelle des tables si re-création
DROP TABLE IF EXISTS releves_horaires CASCADE;
DROP TABLE IF EXISTS stations CASCADE;

-- -----------------------------------------------------------------------------
-- Table : STATIONS
-- Stocke les métadonnées de chaque station météo
-- -----------------------------------------------------------------------------
CREATE TABLE stations (
    id VARCHAR(20) PRIMARY KEY,
    ville VARCHAR(100) NOT NULL,
    latitude NUMERIC(8, 5) NOT NULL,
    longitude NUMERIC(8, 5) NOT NULL,
    altitude NUMERIC(6, 2) NULL, -- élévation en mètres
    type VARCHAR(50) NULL,       -- ex: static, synop, etc.
    
    -- Informations de licence & provenance
    licence_nom VARCHAR(100) NULL,
    licence_url TEXT NULL,
    source VARCHAR(100) NULL,
    metadonnees_url TEXT NULL,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE stations IS 'Métadonnées relatives aux stations météorologiques.';
COMMENT ON COLUMN stations.id IS 'Identifiant unique de la station (ex: 07015, 00052, STATIC0010).';
COMMENT ON COLUMN stations.altitude IS 'Altitude / élévation de la station en mètres.';

-- -----------------------------------------------------------------------------
-- Table : RELEVES_HORAIRES
-- Stocke les relevés météo horaires (1 ligne par heure et par station)
-- -----------------------------------------------------------------------------
CREATE TABLE releves_horaires (
    id BIGSERIAL PRIMARY KEY,
    id_station VARCHAR(20) NOT NULL,
    dh_utc TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- Variables météorologiques (Unités calquées sur le JSON)
    temperature NUMERIC(4, 1) NULL,      -- degC
    pression NUMERIC(6, 1) NULL,         -- hPa (pression au niveau de la mer)
    humidite SMALLINT NULL,              -- % (humidité relative 0-100)
    point_de_rosee NUMERIC(4, 1) NULL,   -- degC
    visibilite INTEGER NULL,             -- m (visibilité horizontale)
    vent_moyen NUMERIC(5, 1) NULL,       -- km/h
    vent_rafales NUMERIC(5, 1) NULL,     -- km/h
    vent_direction SMALLINT NULL,        -- deg (0 à 360°)
    pluie_1h NUMERIC(5, 2) NULL,         -- mm (précipitations sur 1h)
    pluie_3h NUMERIC(5, 2) NULL,         -- mm (précipitations sur 3h)
    neige_au_sol NUMERIC(5, 1) NULL,     -- cm (hauteur de neige au sol)
    nebulosite SMALLINT NULL,            -- octas (couverture nuageuse 0-8)
    temps_omm VARCHAR(10) NULL,          -- Code temps présent OMM (ex: 10, 44, 45, 61)
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Clé étrangère vers la station
    CONSTRAINT fk_releves_station 
        FOREIGN KEY (id_station) 
        REFERENCES stations(id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,

    -- Unicité : un seul relevé par heure et par station
    CONSTRAINT uq_station_dh_utc 
        UNIQUE (id_station, dh_utc),

    -- Contraintes de cohérence (optionnelles)
    CONSTRAINT chk_humidite CHECK (humidite IS NULL OR (humidite >= 0 AND humidite <= 100)),
    CONSTRAINT chk_vent_direction CHECK (vent_direction IS NULL OR (vent_direction >= 0 AND vent_direction <= 360)),
    CONSTRAINT chk_nebulosite CHECK (nebulosite IS NULL OR (nebulosite >= 0 AND nebulosite <= 8))
);

COMMENT ON TABLE releves_horaires IS 'Relevés météorologiques agrégés par heure.';
COMMENT ON COLUMN releves_horaires.dh_utc IS 'Date et heure UTC de la mesure horaire.';
COMMENT ON COLUMN releves_horaires.temperature IS 'Température en °C (degC).';
COMMENT ON COLUMN releves_horaires.pression IS 'Pression moyenne au niveau de la mer en hPa.';
COMMENT ON COLUMN releves_horaires.humidite IS 'Humidité relative en %.';
COMMENT ON COLUMN releves_horaires.point_de_rosee IS 'Point de rosée en °C (degC).';
COMMENT ON COLUMN releves_horaires.visibilite IS 'Visibilité horizontale en mètres (m).';
COMMENT ON COLUMN releves_horaires.vent_moyen IS 'Vitesse moyenne du vent en km/h.';
COMMENT ON COLUMN releves_horaires.vent_rafales IS 'Vent en rafales en km/h.';
COMMENT ON COLUMN releves_horaires.vent_direction IS 'Direction du vent en degrés (°).';
COMMENT ON COLUMN releves_horaires.pluie_1h IS 'Précipitations cumulées sur 1 heure en mm.';
COMMENT ON COLUMN releves_horaires.pluie_3h IS 'Précipitations cumulées sur 3 heures en mm.';
COMMENT ON COLUMN releves_horaires.neige_au_sol IS 'Épaisseur de neige au sol en cm.';
COMMENT ON COLUMN releves_horaires.nebulosite IS 'Nébulosité en octas (0 à 8).';
COMMENT ON COLUMN releves_horaires.temps_omm IS 'Code temps présent OMM.';

-- -----------------------------------------------------------------------------
-- Index de performance
-- -----------------------------------------------------------------------------
CREATE INDEX idx_releves_dh_utc ON releves_horaires(dh_utc);
CREATE INDEX idx_releves_station_date ON releves_horaires(id_station, dh_utc DESC);