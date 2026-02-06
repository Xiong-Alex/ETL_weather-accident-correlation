-- ============================================================
-- SCHEMAS
-- ============================================================

CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;

-- ============================================================
-- BRONZE: RAW STATION METADATA
-- ============================================================

CREATE TABLE IF NOT EXISTS bronze.stations (
    station_id   TEXT NOT NULL,

    latitude     TEXT,
    longitude    TEXT,
    elevation    TEXT,
    state        TEXT,
    name         TEXT,
    gsn          TEXT,
    hcn          TEXT,
    wmo          TEXT,

    source_file  TEXT,
    ingested_at  TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_bronze_stations_station_id
    ON bronze.stations (station_id);

-- ============================================================
-- SILVER: CLEANED STATION REFERENCE
-- ============================================================

CREATE TABLE IF NOT EXISTS silver.stations (
    station_id       TEXT PRIMARY KEY,

    country_code     CHAR(2) NOT NULL,
    state            CHAR(2),

    name             TEXT,

    latitude         DOUBLE PRECISION,
    longitude        DOUBLE PRECISION,
    elevation_m      DOUBLE PRECISION,

    is_gsn           BOOLEAN,
    is_hcn           BOOLEAN,

    created_at       TIMESTAMPTZ DEFAULT now(),
    last_updated_at  TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_silver_stations_lat_lon
    ON silver.stations (latitude, longitude);

-- ============================================================
-- NOTES
-- ============================================================
-- - bronze.stations:
--     * append-friendly
--     * raw text values
--     * ingestion metadata lives here
--
-- - silver.stations:
--     * clean, typed, canonical
--     * one row per station
--     * safe to join with fact tables
-- ============================================================
