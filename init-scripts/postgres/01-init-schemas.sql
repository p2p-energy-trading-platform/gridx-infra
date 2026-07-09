-- 1. Create Service Users (Roles)
-- Note: In pure SQL scripts running inside these official images, we can reference 
-- the environment variables directly using the \getenv command.

\getenv auth_user AUTH_SERVICE_USER
\getenv auth_pass AUTH_SERVICE_PASSWORD
\getenv order_user ORDER_SERVICE_USER
\getenv order_pass ORDER_SERVICE_PASSWORD
\getenv billing_user BILLING_SERVICE_USER
\getenv billing_pass BILLING_SERVICE_PASSWORD
\getenv notify_user NOTIFICATION_SERVICE_USER
\getenv notify_pass NOTIFICATION_SERVICE_PASSWORD

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
REVOKE ALL ON DATABASE current_database() FROM PUBLIC;

-- 4. Grant Explicit Database Connectivity to the Microservices
DO $$
BEGIN
    EXECUTE format('GRANT CONNECT ON DATABASE current_database() TO %I, %I, %I, %I', 
        sys_env('AUTH_SERVICE_USER'), 
        sys_env('ORDER_SERVICE_USER'), 
        sys_env('BILLING_SERVICE_USER'), 
        sys_env('NOTIFICATION_SERVICE_USER')
    );
END $$;