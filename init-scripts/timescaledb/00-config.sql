CREATE OR REPLACE FUNCTION sys_env(var_name text) RETURNS text AS $$
    SELECT current_setting('docker_env.' || var_name, true);
$$ LANGUAGE sql IMMUTABLE;