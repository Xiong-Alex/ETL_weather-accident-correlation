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

-- ============================================================
-- BRONZE: DAILY WEATHER OBSERVATIONS (RAW)
-- ============================================================

CREATE TABLE IF NOT EXISTS bronze.weather_daily (
    station_id   TEXT NOT NULL,
    obs_date     TEXT NOT NULL,   -- YYYY-DDD (day-of-year, raw)
    element      TEXT NOT NULL,   -- PRCP, TMAX, TMIN, etc.
    value        INTEGER,         -- raw value (scaled)
    m_flag       TEXT,
    q_flag       TEXT,
    s_flag       TEXT,

    source_file  TEXT,
    ingested_at  TIMESTAMPTZ DEFAULT now()
);

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_bronze_weather_station
    ON bronze.weather_daily (station_id);

CREATE INDEX IF NOT EXISTS idx_bronze_weather_date
    ON bronze.weather_daily (obs_date);

CREATE INDEX IF NOT EXISTS idx_bronze_weather_element
    ON bronze.weather_daily (element);

-- ============================================================
-- SILVER: DAILY WEATHER OBSERVATIONS (CLEAN)
-- ============================================================

CREATE TABLE IF NOT EXISTS silver.weather_daily (
    station_id    TEXT NOT NULL,
    obs_date      DATE NOT NULL,
    element       TEXT NOT NULL,

    value         DOUBLE PRECISION,  -- real units (mm, °C)
    unit          TEXT NOT NULL,      -- 'mm', 'celsius', etc.

    created_at    TIMESTAMPTZ DEFAULT now(),
    last_updated  TIMESTAMPTZ DEFAULT now(),

    PRIMARY KEY (station_id, obs_date, element)
);

-- Indexes for analytics
CREATE INDEX IF NOT EXISTS idx_silver_weather_station_date
    ON silver.weather_daily (station_id, obs_date);

CREATE INDEX IF NOT EXISTS idx_silver_weather_element
    ON silver.weather_daily (element);
