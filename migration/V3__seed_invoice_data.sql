-- ============================================================
-- Invoice Generator - Seed Data (UUID FIXED)
-- ============================================================

-- ----------------------------
-- 1) Party Snapshots
-- ----------------------------

-- Dealer-001 (Delhi)
INSERT INTO party_snapshot (party_snapshot_id, party_type, external_party_id, name, email,
  phone, tax_id, address_line1, city, postal_code, country, created_at, created_by)
VALUES ('11111111-1111-1111-1111-111111111111', 'DEALER', 'DEALER-001','Delhi Auto Motors Pvt Ltd', 'sales@delhiautomotors.in',
  '+91-11-45678900', 'GSTIN07AABCD1234E1Z5', 'A-15, Kirti Nagar Industrial Area', 'New Delhi', '110015', 'IN', NOW(), 'seed')
ON CONFLICT DO NOTHING;

-- Customer-001 (Gurgaon)
INSERT INTO party_snapshot (party_snapshot_id, party_type, external_party_id, name,
  email, phone, address_line1, city, postal_code, country, created_at, created_by)
VALUES ('22222222-2222-2222-2222-222222222222', 'CUSTOMER', 'CUSTOMER-001', 'Nitin Jain', 'nitin.jain@example.in',
  '+91-98765-11111', 'Tower B, DLF Cyber City, Phase 2', 'Gurgaon', '122002', 'IN', NOW(), 'seed')
ON CONFLICT DO NOTHING;

-- ----------------------------
-- 2) Invoice Header
-- ----------------------------
INSERT INTO invoice (
  invoice_id, invoice_type, invoice_number,
  invoice_date, status, currency,
  customer_party_snapshot_id, dealer_party_snapshot_id,
  dealer_scope_id, customer_scope_id,
  subtotal_amount, discount_amount, tax_amount, total_amount,
  template_name, template_version,
  s3_bucket, s3_key, pdf_checksum, generated_at,
  created_at, created_by, updated_at, updated_by, row_version
)
VALUES (
  '33333333-3333-3333-3333-333333333333', 'SALES',
  'INV-1001', CURRENT_DATE, 'GENERATED', 'INR',
  '22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111',
  'DEALER-001', 'CUSTOMER-001',
  1200000.00, 0.00, 216000.00, 1416000.00,
  'invoice-sales', 'v1',
  'invoice-pdf-bucket', 'invoices/33333333-3333-3333-3333-333333333333.pdf', 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef',
  NOW(), NOW(), 'seed', NOW(), 'seed', 0
)
ON CONFLICT DO NOTHING;

-- ----------------------------
-- 3) Invoice Line Items
-- ----------------------------
INSERT INTO invoice_line_item (
  line_item_id, invoice_id, line_type, line_no, item_code, description, quantity, uom,
  unit_price, discount_amount, tax_rate, tax_amount, line_total_amount)
VALUES ('44444444-4444-4444-4444-444444444444', '33333333-3333-3333-3333-333333333333', 'PURCHASE',
  1, 'SKU-001', 'Hyundai Creta SX - Base Price', 1, 'EA', 1200000.00, 0.00, 18.000, 216000.00, 1416000.00)
ON CONFLICT DO NOTHING;

-- ----------------------------
-- 4) Invoice Asset (Vehicle)
-- ----------------------------
INSERT INTO invoice_asset (asset_id, invoice_id, asset_type, vin, make, model, variant, model_year, registration_no, odometer)
VALUES ('55555555-5555-5555-5555-555555555555', '33333333-3333-3333-3333-333333333333', 'VEHICLE', 'MAL32KHSLEX123456',
  'Hyundai', 'Creta', 'SX', 2024, 'DL-01-AB-1234', 5.0)
ON CONFLICT DO NOTHING;

-- ----------------------------
-- 5) Request Audit (JSONB)
-- ----------------------------
INSERT INTO invoice_request_audit (invoice_request_id, invoice_id, source_system, request_payload, received_at, correlation_id)
VALUES ('66666666-6666-6666-6666-666666666666', '33333333-3333-3333-3333-333333333333', 'SEED',
  '{
    "invoiceNumber": "INV-1001",
    "dealer": { "externalPartyId": "DEALER-123" },
    "customer": { "externalPartyId": "CUSTOMER-001" },
    "totals": { "totalAmount": 1190.00 }
  }'::jsonb,
  NOW(), 'seed-correlation-001')

ON CONFLICT DO NOTHING;


-- ============================================================
-- Invoice Generator - Service Invoice Seed Data
-- Dealer-002 → Customer-002 | Currency: INR
-- ============================================================

-- ----------------------------
-- 1) Party Snapshots
-- ----------------------------

-- Dealer-002 (Noida)
INSERT INTO party_snapshot (party_snapshot_id, party_type, external_party_id, name, email,
  phone, tax_id, address_line1, city, postal_code, country, created_at, created_by)
VALUES ('77777777-7777-7777-7777-777777777777', 'DEALER', 'DEALER-002','Noida Auto Service Center Pvt Ltd', 'service@noidaautoservice.in',
  '+91-120-4567890', 'GSTIN09AABCU9603R1ZM', 'Plot 42, Sector 63', 'Noida', '201301', 'IN', NOW(), 'seed')
ON CONFLICT DO NOTHING;

-- Customer-002 (Gurgaon)
INSERT INTO party_snapshot (party_snapshot_id, party_type, external_party_id, name,
  email, phone, address_line1, city, postal_code, country, created_at, created_by)
VALUES ('88888888-8888-8888-8888-888888888888', 'CUSTOMER', 'CUSTOMER-002', 'Rajesh Kumar', 'rajesh.kumar@example.in',
  '+91-98765-22222', 'Flat 501, Unitech South City II', 'Gurgaon', '122018', 'IN', NOW(), 'seed')
ON CONFLICT DO NOTHING;

-- ----------------------------
-- 2) Invoice Header
-- ----------------------------
INSERT INTO invoice (
  invoice_id, invoice_type, invoice_number,
  invoice_date, status, currency,
  customer_party_snapshot_id, dealer_party_snapshot_id,
  dealer_scope_id, customer_scope_id,
  subtotal_amount, discount_amount, tax_amount, total_amount,
  template_name, template_version,
  s3_bucket, s3_key, pdf_checksum, generated_at,
  created_at, created_by, updated_at, updated_by, row_version
)
VALUES (
  '99999999-9999-9999-9999-999999999999', 'SERVICE',
  'INV-2001', CURRENT_DATE, 'GENERATED', 'INR',
  '88888888-8888-8888-8888-888888888888', '77777777-7777-7777-7777-777777777777',
  'DEALER-002', 'CUSTOMER-002',
  4050.00, 0.00, 729.00, 4779.00,
  'invoice-service', 'v1',
  'invoice-pdf-bucket', 'invoices/99999999-9999-9999-9999-999999999999.pdf', 'cafebabecafebabecafebabecafebabecafebabecafebabecafebabecafebabe',
  NOW(), NOW(), 'seed', NOW(), 'seed', 0
)
ON CONFLICT DO NOTHING;

-- ----------------------------
-- 3) Invoice Line Items
-- ----------------------------

-- Line 1: Labor charges
INSERT INTO invoice_line_item (
  line_item_id, invoice_id, line_type, line_no, item_code, description, quantity, uom,
  unit_price, discount_amount, tax_rate, tax_amount, line_total_amount)
VALUES ('aaaaaaaa-2222-3333-4444-555555555555', '99999999-9999-9999-9999-999999999999', 'SERVICE',
  1, 'SRV-LABOR-001', 'Annual Service - Labor (2 hours)', 2, 'HR', 600.00, 0.00, 18.000, 216.00, 1416.00)
ON CONFLICT DO NOTHING;

-- Line 2: Engine Oil
INSERT INTO invoice_line_item (
  line_item_id, invoice_id, line_type, line_no, item_code, description, quantity, uom,
  unit_price, discount_amount, tax_rate, tax_amount, line_total_amount)
VALUES ('bbbbbbbb-2222-3333-4444-555555555555', '99999999-9999-9999-9999-999999999999', 'PARTS',
  2, 'PART-OIL-001', 'Engine Oil 5W-30 Synthetic', 4, 'LTR', 450.00, 0.00, 18.000, 324.00, 2124.00)
ON CONFLICT DO NOTHING;

-- Line 3: Oil Filter
INSERT INTO invoice_line_item (
  line_item_id, invoice_id, line_type, line_no, item_code, description, quantity, uom,
  unit_price, discount_amount, tax_rate, tax_amount, line_total_amount)
VALUES ('cccccccc-2222-3333-4444-555555555555', '99999999-9999-9999-9999-999999999999', 'PARTS',
  3, 'PART-FILTER-001', 'Oil Filter', 1, 'EA', 350.00, 0.00, 18.000, 63.00, 413.00)
ON CONFLICT DO NOTHING;

-- Line 4: Air Filter
INSERT INTO invoice_line_item (
  line_item_id, invoice_id, line_type, line_no, item_code, description, quantity, uom,
  unit_price, discount_amount, tax_rate, tax_amount, line_total_amount)
VALUES ('dddddddd-2222-3333-4444-555555555555', '99999999-9999-9999-9999-999999999999', 'PARTS',
  4, 'PART-FILTER-002', 'Air Filter', 1, 'EA', 500.00, 0.00, 18.000, 90.00, 590.00)
ON CONFLICT DO NOTHING;

-- Line 5: Brake Fluid
INSERT INTO invoice_line_item (
  line_item_id, invoice_id, line_type, line_no, item_code, description, quantity, uom,
  unit_price, discount_amount, tax_rate, tax_amount, line_total_amount)
VALUES ('eeeeeeee-2222-3333-4444-555555555555', '99999999-9999-9999-9999-999999999999', 'CONSUMABLE',
  5, 'CONS-BRAKE-001', 'Brake Fluid DOT 4 Top-up', 0.5, 'LTR', 400.00, 0.00, 18.000, 36.00, 236.00)
ON CONFLICT DO NOTHING;

-- ----------------------------
-- 4) Invoice Asset (Vehicle being serviced)
-- ----------------------------
INSERT INTO invoice_asset (asset_id, invoice_id, asset_type, vin, make, model, variant, model_year, registration_no, odometer)
VALUES ('ffffffff-2222-3333-4444-555555555555', '99999999-9999-9999-9999-999999999999', 'VEHICLE', 'MA3ERLF3S00123456',
  'Maruti Suzuki', 'Swift', 'VXI', 2022, 'DL-03-CD-5678', 25450.0)
ON CONFLICT DO NOTHING;

-- ----------------------------
-- 5) Request Audit (JSONB)
-- ----------------------------
INSERT INTO invoice_request_audit (invoice_request_id, invoice_id, source_system, request_payload, received_at, correlation_id)
VALUES ('12121212-3434-5656-7878-909090909090', '99999999-9999-9999-9999-999999999999', 'SEED',
  '{
    "invoiceNumber": "INV-2001",
    "invoiceType": "SERVICE",
    "dealer": { 
      "externalPartyId": "DEALER-002",
      "name": "Mumbai Auto Service Center Pvt Ltd"
    },
    "customer": { 
      "externalPartyId": "CUSTOMER-002",
      "name": "Rajesh Kumar"
    },
    "vehicle": {
      "vin": "MA3ERLF3S00123456",
      "registrationNo": "MH-02-CD-5678",
      "make": "Maruti Suzuki",
      "model": "Swift",
      "odometer": 25450
    },
    "serviceDetails": {
      "serviceType": "ANNUAL_MAINTENANCE",
      "laborHours": 2,
      "partsUsed": ["Engine Oil", "Oil Filter", "Air Filter", "Brake Fluid"]
    },
    "totals": { 
      "subtotal": 4050.00,
      "taxAmount": 729.00,
      "totalAmount": 4779.00,
      "currency": "INR"
    }
  }'::jsonb,
  NOW(), 'seed-correlation-002')
ON CONFLICT DO NOTHING;


-- ============================================================
-- Sales Invoice: Dealer-001 → Customer-002 | Currency: INR
-- ============================================================

-- Note: Party snapshots for DEALER-001 and CUSTOMER-002 already exist above
-- This represents a cross-border vehicle sale transaction

-- ----------------------------
-- 2) Invoice Header - Sales Invoice
-- ----------------------------
INSERT INTO invoice (
  invoice_id, invoice_type, invoice_number,
  invoice_date, status, currency,
  customer_party_snapshot_id, dealer_party_snapshot_id,
  dealer_scope_id, customer_scope_id,
  subtotal_amount, discount_amount, tax_amount, total_amount,
  template_name, template_version,
  s3_bucket, s3_key, pdf_checksum, generated_at,
  created_at, created_by, updated_at, updated_by, row_version
)
VALUES (
  'aaaabbbb-cccc-dddd-eeee-fff000111222', 'SALES',
  'INV-3001', CURRENT_DATE, 'GENERATED', 'INR',
  '88888888-8888-8888-8888-888888888888', '11111111-1111-1111-1111-111111111111',
  'DEALER-001', 'CUSTOMER-002',
  850000.00, 0.00, 153000.00, 1003000.00,
  'invoice-sales', 'v1',
  'invoice-pdf-bucket', 'invoices/aaaabbbb-cccc-dddd-eeee-fff000111222.pdf', '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
  NOW(), NOW(), 'seed', NOW(), 'seed', 0
)
ON CONFLICT DO NOTHING;

-- ----------------------------
-- 3) Invoice Line Items - Vehicle Purchase
-- ----------------------------

-- Line 1: Vehicle Base Price
INSERT INTO invoice_line_item (
  line_item_id, invoice_id, line_type, line_no, item_code, description, quantity, uom,
  unit_price, discount_amount, tax_rate, tax_amount, line_total_amount)
VALUES ('11112222-3333-4444-5555-666677778888', 'aaaabbbb-cccc-dddd-eeee-fff000111222', 'PURCHASE',
  1, 'VEH-TATA-001', 'Tata Nexon EV Max - Base Price', 1, 'EA', 750000.00, 0.00, 18.000, 135000.00, 885000.00)
ON CONFLICT DO NOTHING;

-- Line 2: Extended Warranty
INSERT INTO invoice_line_item (
  line_item_id, invoice_id, line_type, line_no, item_code, description, quantity, uom,
  unit_price, discount_amount, tax_rate, tax_amount, line_total_amount)
VALUES ('22223333-4444-5555-6666-777788889999', 'aaaabbbb-cccc-dddd-eeee-fff000111222', 'ACCESSORY',
  2, 'WARR-EXT-003', 'Extended Warranty - 3 Years', 1, 'EA', 50000.00, 0.00, 18.000, 9000.00, 59000.00)
ON CONFLICT DO NOTHING;

-- Line 3: Registration & RTO Charges
INSERT INTO invoice_line_item (
  line_item_id, invoice_id, line_type, line_no, item_code, description, quantity, uom,
  unit_price, discount_amount, tax_rate, tax_amount, line_total_amount)
VALUES ('33334444-5555-6666-7777-888899990000', 'aaaabbbb-cccc-dddd-eeee-fff000111222', 'FEE',
  3, 'FEE-RTO-001', 'Registration & RTO Charges', 1, 'EA', 50000.00, 0.00, 18.000, 9000.00, 59000.00)
ON CONFLICT DO NOTHING;

-- ----------------------------
-- 4) Invoice Asset - New Vehicle
-- ----------------------------
INSERT INTO invoice_asset (asset_id, invoice_id, asset_type, vin, make, model, variant, model_year, registration_no, odometer)
VALUES ('44445555-6666-7777-8888-999900001111', 'aaaabbbb-cccc-dddd-eeee-fff000111222', 'VEHICLE', 'MAT451234EV567890',
  'Tata Motors', 'Nexon EV', 'Max LR', 2025, 'DL-08-EF-9876', 0.0)
ON CONFLICT DO NOTHING;

-- ----------------------------
-- 5) Request Audit (JSONB)
-- ----------------------------
INSERT INTO invoice_request_audit (invoice_request_id, invoice_id, source_system, request_payload, received_at, correlation_id)
VALUES ('55556666-7777-8888-9999-000011112222', 'aaaabbbb-cccc-dddd-eeee-fff000111222', 'SEED',
  '{
    "invoiceNumber": "INV-3001",
    "invoiceType": "SALES",
    "dealer": { 
      "externalPartyId": "DEALER-001",
      "name": "Berlin Dealer GmbH"
    },
    "customer": { 
      "externalPartyId": "CUSTOMER-002",
      "name": "Rajesh Kumar"
    },
    "vehicle": {
      "vin": "MAT451234EV567890",
      "registrationNo": "MH-01-EF-9876",
      "make": "Tata Motors",
      "model": "Nexon EV",
      "variant": "Max LR",
      "modelYear": 2025,
      "isNew": true
    },
    "lineItems": [
      {
        "itemCode": "VEH-TATA-001",
        "description": "Tata Nexon EV Max - Base Price",
        "amount": 750000.00
      },
      {
        "itemCode": "WARR-EXT-003",
        "description": "Extended Warranty - 3 Years",
        "amount": 50000.00
      },
      {
        "itemCode": "FEE-RTO-001",
        "description": "Registration & RTO Charges",
        "amount": 50000.00
      }
    ],
    "totals": { 
      "subtotal": 850000.00,
      "taxAmount": 153000.00,
      "totalAmount": 1003000.00,
      "currency": "INR"
    }
  }'::jsonb,
  NOW(), 'seed-correlation-003')
ON CONFLICT DO NOTHING;
