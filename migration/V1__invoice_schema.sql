-- =====================================================================
-- Invoice Generator - PostgreSQL Schema (V1)
-- Flyway migration: V1__invoice_schema.sql
-- =====================================================================


-- -----------------------------
-- 0) Database and User
-- -----------------------------
CREATE DATABASE invoice;
CREATE USER invoice WITH PASSWORD 'invoice';


-- Grant privileges on database
GRANT ALL PRIVILEGES ON DATABASE invoice TO invoice;

-- Grant schema privileges
GRANT ALL ON SCHEMA public TO invoice;

-- Ensure future objects are accessible
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL ON TABLES TO invoice;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL ON SEQUENCES TO invoice;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL ON FUNCTIONS TO invoice;

-- Connect to the new database (using psql command)
-- \c invoice;

-- -----------------------------
-- 1) ENUM types
-- -----------------------------
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'invoice_type_enum') THEN
    CREATE TYPE invoice_type_enum AS ENUM ('SALES', 'SERVICE', 'PROFORMA');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'invoice_status_enum') THEN
    CREATE TYPE invoice_status_enum AS ENUM ('DRAFT', 'QUEUED', 'GENERATING', 'GENERATED', 'FAILED', 'VOID');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'party_type_enum') THEN
    CREATE TYPE party_type_enum AS ENUM ('CUSTOMER', 'DEALER', 'PARTNER');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'line_type_enum') THEN
    CREATE TYPE line_type_enum AS ENUM ('PURCHASE', 'SERVICE', 'PARTS', 'CONSUMABLE', 'ACCESSORY', 'FEE');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'asset_type_enum') THEN
    CREATE TYPE asset_type_enum AS ENUM ('VEHICLE', 'OTHER');
  END IF;
END $$;

-- -----------------------------
-- 2) party_snapshot
-- -----------------------------
CREATE TABLE IF NOT EXISTS party_snapshot (
  party_snapshot_id         UUID PRIMARY KEY,
  party_type                party_type_enum NOT NULL,

  external_party_id         VARCHAR(64),
  name                      VARCHAR(200) NOT NULL,
  email                     VARCHAR(200),
  phone                     VARCHAR(50),
  tax_id                    VARCHAR(50),

  address_line1             VARCHAR(200),
  address_line2             VARCHAR(200),
  city                      VARCHAR(100),
  state                     VARCHAR(100),
  postal_code               VARCHAR(20),
  country                   VARCHAR(2),

  created_at                TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by                VARCHAR(120)
);

CREATE INDEX IF NOT EXISTS idx_party_snapshot_type ON party_snapshot(party_type);
CREATE INDEX IF NOT EXISTS idx_party_snapshot_external_id ON party_snapshot(external_party_id);

-- -----------------------------
-- 3) invoice (header)
-- -----------------------------
CREATE TABLE IF NOT EXISTS invoice (
  invoice_id                  UUID PRIMARY KEY,

  invoice_type                invoice_type_enum NOT NULL,
  invoice_number              VARCHAR(64) NOT NULL,
  invoice_date                DATE NOT NULL,
  status                      invoice_status_enum NOT NULL DEFAULT 'DRAFT',

  currency                    VARCHAR(3) NOT NULL,

  customer_party_snapshot_id  UUID NOT NULL REFERENCES party_snapshot(party_snapshot_id),
  dealer_party_snapshot_id    UUID NOT NULL REFERENCES party_snapshot(party_snapshot_id),
  partner_party_snapshot_id   UUID REFERENCES party_snapshot(party_snapshot_id),

  dealer_scope_id             VARCHAR(64) NOT NULL,
  partner_scope_id            VARCHAR(64),
  customer_scope_id           VARCHAR(64),

  subtotal_amount             NUMERIC(14,2) NOT NULL CHECK (subtotal_amount >= 0),
  tax_amount                  NUMERIC(14,2) NOT NULL CHECK (tax_amount >= 0),
  discount_amount             NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (discount_amount >= 0),
  total_amount                NUMERIC(14,2) NOT NULL CHECK (total_amount >= 0),

  template_name               VARCHAR(100) NOT NULL,
  template_version            VARCHAR(30) NOT NULL,

  pdf_checksum                VARCHAR(64),
  s3_bucket                   VARCHAR(128),
  s3_key                      VARCHAR(512),
  generated_at                TIMESTAMPTZ,

  correlation_id              VARCHAR(64),

  created_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by                  VARCHAR(120),
  updated_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_by                  VARCHAR(120),
  row_version                 BIGINT NOT NULL DEFAULT 0,

  CONSTRAINT chk_invoice_s3_pair
    CHECK (
      (s3_bucket IS NULL AND s3_key IS NULL)
      OR (s3_bucket IS NOT NULL AND s3_key IS NOT NULL)
    ),

  CONSTRAINT chk_invoice_checksum_len
    CHECK (pdf_checksum IS NULL OR LENGTH(pdf_checksum) = 64)
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_invoice_dealer_scope_invoice_number
  ON invoice(dealer_scope_id, invoice_number);

CREATE INDEX IF NOT EXISTS idx_invoice_dealer_scope_date
  ON invoice(dealer_scope_id, invoice_date DESC);

CREATE INDEX IF NOT EXISTS idx_invoice_status
  ON invoice(status);

CREATE INDEX IF NOT EXISTS idx_invoice_customer_scope
  ON invoice(customer_scope_id);

CREATE INDEX IF NOT EXISTS idx_invoice_partner_scope
  ON invoice(partner_scope_id);

CREATE INDEX IF NOT EXISTS idx_invoice_correlation_id
  ON invoice(correlation_id);

CREATE UNIQUE INDEX IF NOT EXISTS ux_invoice_s3_object
  ON invoice(s3_bucket, s3_key)
  WHERE s3_bucket IS NOT NULL AND s3_key IS NOT NULL;

-- -----------------------------
-- 4) invoice_line_item
-- -----------------------------
CREATE TABLE IF NOT EXISTS invoice_line_item (
  line_item_id           UUID PRIMARY KEY,
  invoice_id             UUID NOT NULL REFERENCES invoice(invoice_id) ON DELETE CASCADE,

  line_type              line_type_enum NOT NULL,
  line_no                INT NOT NULL CHECK (line_no > 0),

  item_code              VARCHAR(64),
  description            VARCHAR(500) NOT NULL,

  quantity               NUMERIC(12,3) NOT NULL DEFAULT 1 CHECK (quantity > 0),
  uom                    VARCHAR(20),

  unit_price             NUMERIC(14,2) NOT NULL CHECK (unit_price >= 0),
  discount_amount        NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (discount_amount >= 0),

  tax_rate               NUMERIC(6,3) CHECK (tax_rate IS NULL OR tax_rate >= 0),
  tax_amount             NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (tax_amount >= 0),

  line_total_amount      NUMERIC(14,2) NOT NULL CHECK (line_total_amount >= 0),

  service_start_at       TIMESTAMPTZ,
  service_end_at         TIMESTAMPTZ,
  labor_hours            NUMERIC(8,2) CHECK (labor_hours IS NULL OR labor_hours >= 0),
  technician_id          VARCHAR(64),

  serial_number          VARCHAR(128),
  warranty_months        INT CHECK (warranty_months IS NULL OR warranty_months >= 0),

  CONSTRAINT ux_invoice_line_no UNIQUE (invoice_id, line_no),

  CONSTRAINT chk_service_time_range
    CHECK (service_start_at IS NULL OR service_end_at IS NULL OR service_end_at >= service_start_at)
);

CREATE INDEX IF NOT EXISTS idx_line_item_invoice ON invoice_line_item(invoice_id);
CREATE INDEX IF NOT EXISTS idx_line_item_type ON invoice_line_item(line_type);

-- -----------------------------
-- 5) invoice_asset
-- -----------------------------
CREATE TABLE IF NOT EXISTS invoice_asset (
  asset_id               UUID PRIMARY KEY,
  invoice_id             UUID NOT NULL REFERENCES invoice(invoice_id) ON DELETE CASCADE,

  asset_type             asset_type_enum NOT NULL DEFAULT 'VEHICLE',

  vin                    VARCHAR(50),
  make                   VARCHAR(50),
  model                  VARCHAR(50),
  variant                VARCHAR(50),
  model_year             INT CHECK (model_year IS NULL OR (model_year >= 1886 AND model_year <= 3000)),
  registration_no        VARCHAR(50),
  odometer               NUMERIC(12,1) CHECK (odometer IS NULL OR odometer >= 0)
);

CREATE INDEX IF NOT EXISTS idx_invoice_asset_invoice ON invoice_asset(invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoice_asset_vin ON invoice_asset(vin);

-- -----------------------------
-- 6) invoice_request_audit (JSONB)
-- -----------------------------
CREATE TABLE IF NOT EXISTS invoice_request_audit (
  invoice_request_id     UUID PRIMARY KEY,
  invoice_id             UUID NOT NULL REFERENCES invoice(invoice_id) ON DELETE CASCADE,

  source_system          VARCHAR(50),
  request_payload        JSONB NOT NULL,

  received_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  correlation_id         VARCHAR(64)
);

CREATE INDEX IF NOT EXISTS idx_request_audit_invoice ON invoice_request_audit(invoice_id);
CREATE INDEX IF NOT EXISTS idx_request_audit_received_at ON invoice_request_audit(received_at DESC);
CREATE INDEX IF NOT EXISTS idx_request_audit_correlation_id ON invoice_request_audit(correlation_id);

-- -----------------------------
-- 7) Trigger to auto-update updated_at + row_version
-- -----------------------------
CREATE OR REPLACE FUNCTION trg_invoice_set_updated_fields()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  NEW.row_version = OLD.row_version + 1;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_invoice_updated_fields ON invoice;

CREATE TRIGGER trg_invoice_updated_fields
BEFORE UPDATE ON invoice
FOR EACH ROW
EXECUTE FUNCTION trg_invoice_set_updated_fields();


-- -----------------------------
-- 8) idempotency_record
-- -----------------------------
CREATE TABLE IF NOT EXISTS idempotency_record (
  idempotency_record_id UUID PRIMARY KEY,

  scope_id              VARCHAR(64) NOT NULL,
  idempotency_key       VARCHAR(128) NOT NULL,

  request_hash          VARCHAR(64) NOT NULL, -- sha256 hex
  response_code         INT NOT NULL,
  response_body         JSONB NOT NULL,

  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_idempotency_scope_key
  ON idempotency_record(scope_id, idempotency_key);

CREATE INDEX IF NOT EXISTS idx_idempotency_created_at
  ON idempotency_record(created_at DESC);
