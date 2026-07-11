-- 1. Create Service Users (Roles) via Dynamic SQL
DO $$
BEGIN
    EXECUTE format('CREATE USER %I WITH PASSWORD %L', sys_env('AUTH_SERVICE_USER'), sys_env('AUTH_SERVICE_PASSWORD'));
    EXECUTE format('CREATE USER %I WITH PASSWORD %L', sys_env('ORDER_SERVICE_USER'), sys_env('ORDER_SERVICE_PASSWORD'));
    EXECUTE format('CREATE USER %I WITH PASSWORD %L', sys_env('BILLING_SERVICE_USER'), sys_env('BILLING_SERVICE_PASSWORD'));
    EXECUTE format('CREATE USER %I WITH PASSWORD %L', sys_env('NOTIFICATION_SERVICE_USER'), sys_env('NOTIFICATION_SERVICE_PASSWORD'));
END $$;

-- 2. Create Isolated Schemas and Assign Ownership
DO $$
BEGIN
    EXECUTE format('CREATE SCHEMA auth_data AUTHORIZATION %I', sys_env('AUTH_SERVICE_USER'));
    EXECUTE format('CREATE SCHEMA order_management_data AUTHORIZATION %I', sys_env('ORDER_SERVICE_USER'));
    EXECUTE format('CREATE SCHEMA billing_data AUTHORIZATION %I', sys_env('BILLING_SERVICE_USER'));
    EXECUTE format('CREATE SCHEMA notification_data AUTHORIZATION %I', sys_env('NOTIFICATION_SERVICE_USER'));
END $$;

-- 3. Revoke Global Public Privileges for Security Isolation
REVOKE ALL ON SCHEMA public FROM PUBLIC;

DO $$
BEGIN
    EXECUTE format('REVOKE ALL ON DATABASE %I FROM PUBLIC', current_database());
END $$;

-- 4. Grant Explicit Database Connectivity to the Microservices
DO $$
BEGIN
    EXECUTE format('GRANT CONNECT ON DATABASE %I TO %I, %I, %I, %I', 
        current_database(),
        sys_env('AUTH_SERVICE_USER'), 
        sys_env('ORDER_SERVICE_USER'), 
        sys_env('BILLING_SERVICE_USER'), 
        sys_env('NOTIFICATION_SERVICE_USER')
    );
END $$;