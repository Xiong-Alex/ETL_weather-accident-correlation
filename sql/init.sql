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






-- ----------------------------------


CREATE TABLE bronze.us_accidents (
    id                      TEXT PRIMARY KEY,
    source                  TEXT,
    severity                INTEGER,

    start_time              TIMESTAMP,
    end_time                TIMESTAMP,

    start_lat               DOUBLE PRECISION,
    start_lng               DOUBLE PRECISION,
    end_lat                 DOUBLE PRECISION,
    end_lng                 DOUBLE PRECISION,

    distance_mi             DOUBLE PRECISION,

    description             TEXT,

    street                  TEXT,
    city                    TEXT,
    county                  TEXT,
    state                   CHAR(2),
    zipcode                 TEXT,
    country                 CHAR(2),
    timezone                TEXT,

    airport_code            TEXT,

    weather_timestamp       TIMESTAMP,
    temperature_f           DOUBLE PRECISION,
    wind_chill_f            DOUBLE PRECISION,
    humidity_pct            DOUBLE PRECISION,
    pressure_in             DOUBLE PRECISION,
    visibility_mi           DOUBLE PRECISION,
    wind_direction          TEXT,
    wind_speed_mph          DOUBLE PRECISION,
    precipitation_in        DOUBLE PRECISION,
    weather_condition       TEXT,

    amenity                 BOOLEAN,
    bump                    BOOLEAN,
    crossing                BOOLEAN,
    give_way                BOOLEAN,
    junction                BOOLEAN,
    no_exit                 BOOLEAN,
    railway                 BOOLEAN,
    roundabout              BOOLEAN,
    station                 BOOLEAN,
    stop                    BOOLEAN,
    traffic_calming         BOOLEAN,
    traffic_signal          BOOLEAN,
    turning_loop            BOOLEAN,

    sunrise_sunset           TEXT,
    civil_twilight           TEXT,
    nautical_twilight        TEXT,
    astronomical_twilight    TEXT
);


-----------------------


CREATE TABLE silver.us_accidents (
    accident_id            TEXT PRIMARY KEY,

    severity               SMALLINT,

    start_time_utc          TIMESTAMPTZ,
    end_time_utc            TIMESTAMPTZ,
    duration_minutes        INTEGER,

    latitude                DOUBLE PRECISION,
    longitude               DOUBLE PRECISION,
    distance_mi             DOUBLE PRECISION,

    city                    TEXT,
    county                  TEXT,
    state                   CHAR(2),
    zipcode                 TEXT,

    weather_time_utc        TIMESTAMPTZ,
    temperature_f           DOUBLE PRECISION,
    wind_chill_f            DOUBLE PRECISION,
    humidity_pct            DOUBLE PRECISION,
    pressure_in             DOUBLE PRECISION,
    visibility_mi           DOUBLE PRECISION,
    wind_speed_mph          DOUBLE PRECISION,
    precipitation_in        DOUBLE PRECISION,
    weather_condition       TEXT,

    is_amenity              BOOLEAN,
    is_bump                 BOOLEAN,
    is_crossing             BOOLEAN,
    is_junction             BOOLEAN,
    is_railway              BOOLEAN,
    is_roundabout           BOOLEAN,
    is_station              BOOLEAN,
    is_stop                 BOOLEAN,
    is_traffic_calming      BOOLEAN,
    is_traffic_signal       BOOLEAN,

    sunrise_sunset          TEXT,
    civil_twilight          TEXT,
    nautical_twilight       TEXT,
    astronomical_twilight   TEXT
);


CREATE INDEX idx_bronze_accidents_start_time
ON bronze.us_accidents (start_time);

-- SILVER (important)
CREATE INDEX idx_silver_accidents_start_time
ON silver.us_accidents (start_time_utc);

CREATE INDEX idx_silver_accidents_state
ON silver.us_accidents (state);

CREATE INDEX idx_silver_accidents_weather_time
ON silver.us_accidents (weather_time_utc);

CREATE INDEX idx_silver_accidents_lat_lng
ON silver.us_accidents (latitude, longitude);
