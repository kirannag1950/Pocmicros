-- =========================================================
-- Auth Service - Seed Data
-- Default Roles + Test User
-- =========================================================
--
-- psql -h localhost -U auth -d auth -f seed_auth_data.sql
--
-- -------------------------
-- 1) Insert roles
-- -------------------------
INSERT INTO roles (role_id, name)
VALUES
  ('11111111-1111-1111-1111-111111111111', 'INVOICE_CREATE'),
  ('22222222-2222-2222-2222-222222222222', 'INVOICE_READ'),
  ('33333333-3333-3333-3333-333333333333', 'INVOICE_LIST'),
  ('44444444-4444-4444-4444-444444444444', 'INVOICE_PDF_READ'),
  ('55555555-5555-5555-5555-555555555555', 'INVOICE_ADMIN'),
  ('66666666-6666-6666-6666-666666666666', 'ACTOR_DEALER'),
  ('77777777-7777-7777-7777-777777777777', 'ACTOR_CUSTOMER')
ON CONFLICT (name) DO NOTHING;

-- -------------------------
-- 2) Insert test user
-- -------------------------
INSERT INTO users (
  user_id, username, password_hash, status, tenant, dealer_scope_id, partner_scope_id, customer_scope_id, failed_attempts, locked_until, last_login_at, created_at, updated_at
)
VALUES (
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  'dealer001',
  '$2a$12$iXR69zvemCEf9kV9vO7pSOIURNG.kMtvD16Kz/Deejm6f028zGqvu',
  'ACTIVE',
  'TENANT-1',
  'DEALER-001',
  NULL,
  NULL,
  0,
  NULL,
  NULL,
  NOW(),
  NOW()
)
ON CONFLICT (username) DO NOTHING;

-- Seed customer user for testing Customer Portal access
INSERT INTO users (
  user_id, username, password_hash, status, tenant, dealer_scope_id, partner_scope_id, customer_scope_id, failed_attempts, locked_until, last_login_at, created_at, updated_at
)
VALUES (
  'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
  'customer001',
  '$2a$12$iXR69zvemCEf9kV9vO7pSOIURNG.kMtvD16Kz/Deejm6f028zGqvu', -- BCrypt of Password@123 (same as test.user)
  'ACTIVE',
  'TENANT-1',
  NULL,
  NULL,
  'CUSTOMER-001',
  0,
  NULL,
  NULL,
  NOW(),
  NOW()
)
ON CONFLICT (username) DO NOTHING;

-- Seed customer user for testing Customer Portal access
INSERT INTO users (
  user_id, username, password_hash, status, tenant, dealer_scope_id, partner_scope_id, customer_scope_id, failed_attempts, locked_until, last_login_at, created_at, updated_at
)
VALUES (
  'cccccccc-cccc-cccc-cccc-cccccccccccc',
  'dealer002',
  '$2a$12$iXR69zvemCEf9kV9vO7pSOIURNG.kMtvD16Kz/Deejm6f028zGqvu', -- BCrypt of Password@123 (same as test.user)
  'ACTIVE',
  'TENANT-1',
  'DEALER-002',
  NULL,
  NULL,
  0,
  NULL,
  NULL,
  NOW(),
  NOW()
)
ON CONFLICT (username) DO NOTHING;

-- Seed customer user for testing Customer Portal access
INSERT INTO users (
  user_id, username, password_hash, status, tenant, dealer_scope_id, partner_scope_id, customer_scope_id, failed_attempts, locked_until, last_login_at, created_at, updated_at
)
VALUES (
  'dddddddd-dddd-dddd-dddd-dddddddddddd',
  'customer002',
  '$2a$12$iXR69zvemCEf9kV9vO7pSOIURNG.kMtvD16Kz/Deejm6f028zGqvu', -- BCrypt of Password@123 (same as test.user)
  'ACTIVE',
  'TENANT-1',
  NULL,
  NULL,
  'CUSTOMER-002',
  0,
  NULL,
  NULL,
  NOW(),
  NOW()
)
ON CONFLICT (username) DO NOTHING;

-- -------------------------
-- 3) Assign roles to user
-- -------------------------
INSERT INTO user_roles (user_id, role_id)
VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111'), -- INVOICE_CREATE
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222222'), -- INVOICE_READ
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '33333333-3333-3333-3333-333333333333'), -- INVOICE_LIST
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '44444444-4444-4444-4444-444444444444'), -- INVOICE_PDF_READ
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '66666666-6666-6666-6666-666666666666'), -- ACTOR_DEALER
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '77777777-7777-7777-7777-777777777777'), -- ACTOR_CUSTOMER
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '22222222-2222-2222-2222-222222222222'), -- INVOICE_READ
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '33333333-3333-3333-3333-333333333333'), -- INVOICE_LIST
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '11111111-1111-1111-1111-111111111111'), -- INVOICE_CREATE
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '22222222-2222-2222-2222-222222222222'), -- INVOICE_READ
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '33333333-3333-3333-3333-333333333333'), -- INVOICE_LIST
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '44444444-4444-4444-4444-444444444444'), -- INVOICE_PDF_READ
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '66666666-6666-6666-6666-666666666666'), -- ACTOR_DEALER
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', '77777777-7777-7777-7777-777777777777'),  -- ACTOR_CUSTOMER
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', '22222222-2222-2222-2222-222222222222'), -- INVOICE_READ
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', '33333333-3333-3333-3333-333333333333') -- INVOICE_LIST
ON CONFLICT DO NOTHING;
