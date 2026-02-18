-- -----------------------------
-- 0) Database and User
-- -----------------------------
CREATE DATABASE auth;
CREATE USER auth WITH PASSWORD 'auth';


-- Grant privileges on database
GRANT ALL PRIVILEGES ON DATABASE auth TO auth;

-- Grant schema privileges
GRANT ALL ON SCHEMA public TO auth;

-- Ensure future objects are accessible
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL ON TABLES TO auth;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL ON SEQUENCES TO auth;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL ON FUNCTIONS TO auth;

-- -----------------------------
-- 1. Connect to the new database (using psql command)
-- -----------------------------
-- \c auth;

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

CREATE TABLE IF NOT EXISTS roles (
  role_id UUID PRIMARY KEY,
  name VARCHAR(80) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS user_roles (
  user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  role_id UUID NOT NULL REFERENCES roles(role_id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, role_id)
);

CREATE TABLE IF NOT EXISTS refresh_tokens (
  refresh_token_id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  token_hash VARCHAR(64) NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  revoked_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user ON refresh_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_hash ON refresh_tokens(token_hash);

CREATE TABLE IF NOT EXISTS login_audit (
  login_audit_id UUID PRIMARY KEY,
  username VARCHAR(120),
  result VARCHAR(20) NOT NULL,
  reason VARCHAR(200),
  ip VARCHAR(64),
  user_agent VARCHAR(256),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
