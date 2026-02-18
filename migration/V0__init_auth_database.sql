-- ============================================================
-- Auth Service - Database Initialization Script
-- ============================================================
-- 
-- 
-- Purpose:
--   Creates the auth database and application users with proper privileges
--   for AWS RDS PostgreSQL deployment.
--
-- Prerequisites:
--   - AWS RDS PostgreSQL instance running
--   - Connection as RDS master user (postgres)
--   - Connected to 'postgres' database (NOT auth database)
--
-- Usage:
--   psql -h <rds-endpoint> -U postgres -d postgres -f V0__init_database.sql
--
-- AWS Deployment Notes:
--   1. This should be run ONCE during initial infrastructure setup
--   2. Passwords should be retrieved from AWS Secrets Manager
--   3. For Terraform/IaC deployments, use provisioner or init containers
--   4. After running this, Flyway can run V1__auth_schema.sql
--
-- ============================================================

-- ============================================================
-- 1. Create Auth Database
-- ============================================================

-- Check if database exists, create if not
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'auth') THEN
    CREATE DATABASE auth
      WITH OWNER = postgres
      ENCODING = 'UTF8'
      LC_COLLATE = 'en_US.UTF-8'
      LC_CTYPE = 'en_US.UTF-8'
      TABLESPACE = pg_default
      CONNECTION LIMIT = -1;
    RAISE NOTICE 'Database "auth" created successfully';
  ELSE
    RAISE NOTICE 'Database "auth" already exists, skipping creation';
  END IF;
END $$;

-- ============================================================
-- 2. Create Application User (Runtime Operations)
-- ============================================================

-- Create application user for runtime database operations
-- Password should come from AWS Secrets Manager: auth-service/rds-app-password
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'auth_app') THEN
    CREATE USER auth_app WITH
      LOGIN
      NOSUPERUSER
      INHERIT
      NOCREATEDB
      NOCREATEROLE
      NOREPLICATION
      ENCRYPTED PASSWORD 'auth_app';
    RAISE NOTICE 'User "auth_app" created successfully';
  ELSE
    RAISE NOTICE 'User "auth_app" already exists, skipping creation';
  END IF;
END $$;

-- ============================================================
-- 3. Grant Database-Level Privileges
-- ============================================================

-- Grant connection privileges
GRANT CONNECT ON DATABASE auth TO auth_app;
GRANT CONNECT ON DATABASE auth TO auth_migration;
GRANT TEMPORARY ON DATABASE auth TO auth_app;
GRANT TEMPORARY ON DATABASE auth TO auth_migration;

RAISE NOTICE 'Database-level privileges granted successfully';

-- ============================================================
-- 4. Switch to Auth Database for Schema-Level Grants
-- ============================================================

-- NOTE: The following commands must be run after connecting to auth database
-- Use: psql -h <rds-endpoint> -U postgres -d auth

-- Run the following in auth database context:
\c auth

-- ============================================================
-- 5. Grant Schema-Level Privileges to Application User
-- ============================================================

-- Runtime application user - limited to DML operations
GRANT USAGE ON SCHEMA public TO auth_app;

-- Grant privileges on existing tables (if any)
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO auth_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO auth_app;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO auth_app;

-- Grant privileges on future objects created by migration user
ALTER DEFAULT PRIVILEGES FOR ROLE auth_migration IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO auth_app;

ALTER DEFAULT PRIVILEGES FOR ROLE auth_migration IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO auth_app;

ALTER DEFAULT PRIVILEGES FOR ROLE auth_migration IN SCHEMA public
  GRANT EXECUTE ON FUNCTIONS TO auth_app;

-- ============================================================
-- 6. Verify Privileges (Optional)
-- ============================================================

-- Check database privileges
SELECT 
  datname,
  array_agg(DISTINCT privilege_type) as privileges
FROM 
  information_schema.role_usage_grants
WHERE 
  grantee IN ('auth_app')
  AND object_type = 'DATABASE'
GROUP BY 
  datname;

-- Check schema privileges
SELECT 
  grantee,
  privilege_type
FROM 
  information_schema.usage_privileges
WHERE 
  grantee IN ('auth_app')
  AND object_schema = 'public';

-- ============================================================
-- COMPLETION NOTES
-- ============================================================
--
-- ✅ Database 'auth' created
-- ✅ User 'auth_app' created (runtime operations)
-- ✅ Privileges granted following principle of least privilege
--
-- SECURITY REMINDERS:
-- 1. Change passwords immediately using AWS Secrets Manager
-- 2. Never commit actual passwords to version control
-- 3. Use IAM database authentication where possible
-- 4. Enable RDS encryption at rest
-- 5. Enable SSL/TLS for connections
-- 6. Rotate passwords regularly (90 days recommended)
--
--
-- ============================================================
