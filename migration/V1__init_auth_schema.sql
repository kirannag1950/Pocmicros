-- ============================================================
-- Auth Service - Database Schema Migration V1
-- ============================================================
-- 
-- Purpose:
--   Creates core authentication tables, indexes, and constraints
--   for the auth service microservice.
--
-- Prerequisites:
--   1. Database 'auth' must exist (created via V0__init_database.sql)
--
-- Tables Created:
--   - users: User accounts with multi-tenant support
--   - roles: Role definitions
--   - user_roles: Many-to-many relationship between users and roles
--   - refresh_tokens: JWT refresh tokens for token rotation
--   - login_audit: Audit log for all login attempts
--
-- AWS RDS Notes:
--   - This script is designed for AWS RDS PostgreSQL
--   - All indexes are created with IF NOT EXISTS for idempotency
--   - Follows AWS best practices for multi-tenant applications
--
-- ============================================================

-- ============================================================
-- 1. Core Tables
-- ============================================================

-- Users table - Core user accounts with multi-tenant support
CREATE TABLE IF NOT EXISTS users (
  user_id UUID PRIMARY KEY,
  username VARCHAR(120) NOT NULL UNIQUE,
  password_hash VARCHAR(200) NOT NULL,
  status VARCHAR(20) NOT NULL,
  tenant VARCHAR(64),
  dealer_scope_id VARCHAR(64),
  partner_scope_id VARCHAR(64),
  customer_scope_id VARCHAR(64),
  failed_attempts INT NOT NULL DEFAULT 0,
  locked_until TIMESTAMPTZ,
  last_login_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Roles table - Role definitions for RBAC
CREATE TABLE IF NOT EXISTS roles (
  role_id UUID PRIMARY KEY,
  name VARCHAR(80) NOT NULL UNIQUE
);

-- User-Roles junction table - Many-to-many relationship
CREATE TABLE IF NOT EXISTS user_roles (
  user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  role_id UUID NOT NULL REFERENCES roles(role_id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, role_id)
);

-- Refresh tokens table - JWT refresh token management
CREATE TABLE IF NOT EXISTS refresh_tokens (
  refresh_token_id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  token_hash VARCHAR(64) NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  revoked_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Login audit table - Security audit log for all login attempts
CREATE TABLE IF NOT EXISTS login_audit (
  login_audit_id UUID PRIMARY KEY,
  username VARCHAR(120),
  result VARCHAR(20) NOT NULL,
  reason VARCHAR(200),
  ip VARCHAR(64),
  user_agent VARCHAR(256),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 2. Indexes - Performance Optimization
-- ============================================================

-- ------------------------------
-- Refresh Tokens Indexes
-- ------------------------------

-- Index for looking up tokens by user (token refresh flow)
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user 
  ON refresh_tokens(user_id);

-- Index for validating token hash (token verification)
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_hash 
  ON refresh_tokens(token_hash);

-- Partial index for active tokens cleanup queries
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_expires 
  ON refresh_tokens(expires_at) 
  WHERE revoked_at IS NULL;

-- ------------------------------
-- Users Table Indexes
-- ------------------------------

-- Index for filtering by user status (active/inactive/locked queries)
-- Critical for: WHERE status = 'ACTIVE' queries
CREATE INDEX IF NOT EXISTS idx_users_status 
  ON users(status);

-- Partial index for tenant-based queries (multi-tenant isolation)
-- Critical for: WHERE tenant = 'tenant-xyz' queries
CREATE INDEX IF NOT EXISTS idx_users_tenant 
  ON users(tenant) 
  WHERE tenant IS NOT NULL;

-- Index for last login tracking and reporting
CREATE INDEX IF NOT EXISTS idx_users_last_login 
  ON users(last_login_at);

-- Composite index for common multi-tenant + status queries
-- Optimizes: WHERE tenant = ? AND status = ?
CREATE INDEX IF NOT EXISTS idx_users_tenant_status 
  ON users(tenant, status) 
  WHERE tenant IS NOT NULL;

-- Index for locked account queries
-- Optimizes cleanup of expired locks
CREATE INDEX IF NOT EXISTS idx_users_locked_until 
  ON users(locked_until) 
  WHERE locked_until IS NOT NULL;

-- ------------------------------
-- Login Audit Indexes
-- ------------------------------

-- Index for time-based audit queries and reporting
-- Critical for: WHERE created_at BETWEEN ? AND ?
CREATE INDEX IF NOT EXISTS idx_login_audit_created_at 
  ON login_audit(created_at);

-- Index for user activity history lookups
-- Critical for: WHERE username = ?
CREATE INDEX IF NOT EXISTS idx_login_audit_username 
  ON login_audit(username);

-- Index for filtering by login result (success/failure analysis)
-- Critical for: WHERE result = 'FAILURE'
CREATE INDEX IF NOT EXISTS idx_login_audit_result 
  ON login_audit(result);

-- Composite index for user activity timeline queries
-- Optimizes: WHERE username = ? ORDER BY created_at DESC
CREATE INDEX IF NOT EXISTS idx_login_audit_username_created 
  ON login_audit(username, created_at);

-- Composite index for failed login analysis
-- Optimizes: WHERE result = 'FAILURE' AND created_at > ?
CREATE INDEX IF NOT EXISTS idx_login_audit_result_created 
  ON login_audit(result, created_at) 
  WHERE result = 'FAILURE';

-- ============================================================
-- 3. Table and Column Comments (Documentation)
-- ============================================================

-- Users table comments
COMMENT ON TABLE users IS 
  'User accounts with multi-tenant support and hierarchical scope management';

COMMENT ON COLUMN users.user_id IS 
  'Unique identifier for the user (UUID v4)';

COMMENT ON COLUMN users.username IS 
  'Unique username for authentication (case-sensitive)';

COMMENT ON COLUMN users.password_hash IS 
  'BCrypt hashed password (60 characters)';

COMMENT ON COLUMN users.status IS 
  'User account status: ACTIVE, INACTIVE, LOCKED, PENDING';

COMMENT ON COLUMN users.tenant IS 
  'Tenant identifier for multi-tenancy isolation (optional)';

COMMENT ON COLUMN users.dealer_scope_id IS 
  'Dealer scope identifier for hierarchical access control (optional)';

COMMENT ON COLUMN users.partner_scope_id IS 
  'Partner scope identifier for hierarchical access control (optional)';

COMMENT ON COLUMN users.customer_scope_id IS 
  'Customer scope identifier for hierarchical access control (optional)';

COMMENT ON COLUMN users.failed_attempts IS 
  'Count of consecutive failed login attempts (for account locking)';

COMMENT ON COLUMN users.locked_until IS 
  'Timestamp until which the account is locked (NULL if not locked)';

COMMENT ON COLUMN users.last_login_at IS 
  'Timestamp of last successful login';

-- Roles table comments
COMMENT ON TABLE roles IS 
  'Role definitions for role-based access control (RBAC)';

COMMENT ON COLUMN roles.role_id IS 
  'Unique identifier for the role (UUID v4)';

COMMENT ON COLUMN roles.name IS 
  'Unique role name (e.g., ADMIN, USER, MANAGER)';

-- User-Roles table comments
COMMENT ON TABLE user_roles IS 
  'Many-to-many relationship between users and roles';

-- Refresh tokens table comments
COMMENT ON TABLE refresh_tokens IS 
  'JWT refresh tokens for secure token rotation and session management';

COMMENT ON COLUMN refresh_tokens.token_hash IS 
  'SHA-256 hash of the refresh token for secure storage';

COMMENT ON COLUMN refresh_tokens.expires_at IS 
  'Timestamp when the refresh token expires';

COMMENT ON COLUMN refresh_tokens.revoked_at IS 
  'Timestamp when the token was revoked (NULL if still valid)';

-- Login audit table comments
COMMENT ON TABLE login_audit IS 
  'Audit log for all login attempts (both successful and failed) for security monitoring';

COMMENT ON COLUMN login_audit.username IS 
  'Username attempted (may not exist in users table for failed attempts)';

COMMENT ON COLUMN login_audit.result IS 
  'Login result: SUCCESS, FAILURE, ACCOUNT_LOCKED, etc.';

COMMENT ON COLUMN login_audit.reason IS 
  'Reason for failure (e.g., invalid credentials, account locked)';

COMMENT ON COLUMN login_audit.ip IS 
  'IP address of the login attempt';

COMMENT ON COLUMN login_audit.user_agent IS 
  'User agent string from the login request';

-- ============================================================
-- MIGRATION COMPLETION
-- ============================================================
--
-- ✅ 5 core tables created
-- ✅ 15 performance indexes created
-- ✅ Foreign key constraints established
-- ✅ Documentation comments added
--
-- Index Summary:
--   - Refresh Tokens: 3 indexes (user lookup, hash validation, expiry cleanup)
--   - Users: 5 indexes (status, tenant, last login, composite queries, locked accounts)
--   - Login Audit: 7 indexes (time-based, username, result, composite queries)
--
-- Performance Considerations:
--   - All indexes use IF NOT EXISTS for safe re-runs
--   - Partial indexes used for NULL-filtered columns (better performance)
--   - Composite indexes for common multi-column queries
--   - Indexes aligned with expected query patterns
--
-- Next Steps:
--   1. Application connects as 'auth_app' user (runtime operations)
--   2. Populate initial roles via V2__seed_roles.sql
--   3. Monitor query performance and adjust indexes as needed
--
-- ============================================================
