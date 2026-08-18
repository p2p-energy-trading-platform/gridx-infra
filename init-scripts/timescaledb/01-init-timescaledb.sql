-- Bootstrap the TimescaleDB extension immediately
CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;

-- 1. Create Timescale Service Users (Roles)
DO $$
BEGIN
    EXECUTE format('CREATE USER %I WITH PASSWORD %L', sys_env('MARKET_TICKER_SERVICE_USER'), sys_env('MARKET_TICKER_SERVICE_PASSWORD'));
    EXECUTE format('CREATE USER %I WITH PASSWORD %L', sys_env('IOT_SERVICE_USER'), sys_env('IOT_SERVICE_PASSWORD'));
    EXECUTE format('CREATE USER %I WITH PASSWORD %L', sys_env('AI_SERVICE_USER'), sys_env('AI_SERVICE_PASSWORD'));
END $$;

-- 2. Create Schemas and Assign Ownership
DO $$
BEGIN
    EXECUTE format('CREATE SCHEMA market_data AUTHORIZATION %I', sys_env('MARKET_TICKER_SERVICE_USER'));
    EXECUTE format('CREATE SCHEMA iot_data AUTHORIZATION %I', sys_env('IOT_SERVICE_USER'));
END $$;

-- 3. Set Default Search Paths per Role
DO $$
BEGIN
    EXECUTE format('ALTER ROLE %I SET search_path TO market_data, public', sys_env('MARKET_TICKER_SERVICE_USER'));
    EXECUTE format('ALTER ROLE %I SET search_path TO iot_data, public', sys_env('IOT_SERVICE_USER'));
    EXECUTE format('ALTER ROLE %I SET search_path TO iot_data, market_data, public', sys_env('AI_SERVICE_USER'));
END $$;

-- 4. Revoke Global Public Privileges
REVOKE ALL ON SCHEMA public FROM PUBLIC;

DO $$
BEGIN
    EXECUTE format('REVOKE ALL ON DATABASE %I FROM PUBLIC', current_database());
END $$;

-- 5. Grant Explicit Database Connectivity & Public Schema Usage
DO $$
BEGIN
    EXECUTE format('GRANT CONNECT ON DATABASE %I TO %I, %I, %I', 
        current_database(),
        sys_env('MARKET_TICKER_SERVICE_USER'), 
        sys_env('IOT_SERVICE_USER'), 
        sys_env('AI_SERVICE_USER')
    );
    EXECUTE format('GRANT USAGE ON SCHEMA public TO %I, %I, %I', 
        sys_env('MARKET_TICKER_SERVICE_USER'), 
        sys_env('IOT_SERVICE_USER'), 
        sys_env('AI_SERVICE_USER')
    );
END $$;

-- 6. Cross-Schema Privileges for the AI Forecasting Engine Engine
DO $$
BEGIN
    -- Grant read/write access to market_data schema
    EXECUTE format('GRANT USAGE ON SCHEMA market_data TO %I', sys_env('AI_SERVICE_USER'));
    EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA market_data TO %I', sys_env('AI_SERVICE_USER'));
    EXECUTE format(
        'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA market_data GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO %I',
        sys_env('MARKET_TICKER_SERVICE_USER'), sys_env('AI_SERVICE_USER')
    );

    -- Grant read/write access to iot_data schema
    EXECUTE format('GRANT USAGE ON SCHEMA iot_data TO %I', sys_env('AI_SERVICE_USER'));
    EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA iot_data TO %I', sys_env('AI_SERVICE_USER'));
    EXECUTE format(
        'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA iot_data GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO %I',
        sys_env('IOT_SERVICE_USER'), sys_env('AI_SERVICE_USER')
    );
END $$;