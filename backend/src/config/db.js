const { Pool, types } = require("pg");

// Parse NUMERIC (type OID 1700) as float to avoid type-cast errors on mobile client
types.setTypeParser(types.builtins.NUMERIC, (val) => val === null ? null : parseFloat(val));

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: false,
  },
});

const query = (text, params) => pool.query(text, params);

async function initDb() {
  await query(`
    CREATE TABLE IF NOT EXISTS admins (
      id SERIAL PRIMARY KEY,
      name VARCHAR(120) NOT NULL,
      email VARCHAR(160) UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      role VARCHAR(30) NOT NULL DEFAULT 'admin',
      status VARCHAR(30) NOT NULL DEFAULT 'active',
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS users (
      id SERIAL PRIMARY KEY,
      name VARCHAR(120) NOT NULL,
      email VARCHAR(160) UNIQUE,
      phone VARCHAR(30) UNIQUE,
      password_hash TEXT,
      status VARCHAR(30) NOT NULL DEFAULT 'active',
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS workers (
      id SERIAL PRIMARY KEY,
      name VARCHAR(120) NOT NULL,
      email VARCHAR(160) UNIQUE,
      phone VARCHAR(30) UNIQUE NOT NULL,
      password_hash TEXT,
      service_type VARCHAR(120),
      experience_years INTEGER NOT NULL DEFAULT 0,
      city VARCHAR(100),
      status VARCHAR(30) NOT NULL DEFAULT 'pending',
      kyc_status VARCHAR(30) NOT NULL DEFAULT 'not_submitted',
      photo_url TEXT,
      rating NUMERIC(3,2) DEFAULT 4.5,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS worker_kyc (
      id SERIAL PRIMARY KEY,
      worker_id INTEGER NOT NULL REFERENCES workers(id) ON DELETE CASCADE,
      aadhaar_number VARCHAR(120) NOT NULL,
      aadhaar_url TEXT NOT NULL,
      aadhaar_status VARCHAR(30) NOT NULL DEFAULT 'pending',
      pan_number VARCHAR(120) NOT NULL,
      pan_url TEXT NOT NULL,
      pan_status VARCHAR(30) NOT NULL DEFAULT 'pending',
      bank_account_number VARCHAR(120) NOT NULL,
      bank_passbook_url TEXT NOT NULL,
      bank_passbook_status VARCHAR(30) NOT NULL DEFAULT 'pending',
      selfie_url TEXT NOT NULL,
      selfie_status VARCHAR(30) NOT NULL DEFAULT 'pending',
      status VARCHAR(30) NOT NULL DEFAULT 'pending',
      rejection_reason TEXT,
      reviewed_by INTEGER REFERENCES admins(id),
      reviewed_at TIMESTAMPTZ,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS bookings (
      id SERIAL PRIMARY KEY,
      user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
      worker_id INTEGER REFERENCES workers(id) ON DELETE CASCADE,
      status VARCHAR(30) NOT NULL DEFAULT 'pending',
      amount NUMERIC(12,2) NOT NULL DEFAULT 0,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS invoices (
      id SERIAL PRIMARY KEY,
      booking_id INTEGER REFERENCES bookings(id) ON DELETE CASCADE,
      user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
      worker_id INTEGER REFERENCES workers(id) ON DELETE CASCADE,
      invoice_number VARCHAR(80) UNIQUE NOT NULL,
      status VARCHAR(30) NOT NULL DEFAULT 'pending',
      amount NUMERIC(12,2) NOT NULL DEFAULT 0,
      platform_fee NUMERIC(12,2) NOT NULL DEFAULT 0,
      worker_payout NUMERIC(12,2) NOT NULL DEFAULT 0,
      paid_at TIMESTAMPTZ,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS activity_logs (
      id SERIAL PRIMARY KEY,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      action VARCHAR(100) NOT NULL,
      details TEXT,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS service_categories (
      id SERIAL PRIMARY KEY,
      name VARCHAR(100) UNIQUE NOT NULL,
      description TEXT,
      icon_url TEXT,
      status VARCHAR(30) NOT NULL DEFAULT 'active',
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS services (
      id SERIAL PRIMARY KEY,
      category_id INTEGER NOT NULL REFERENCES service_categories(id) ON DELETE CASCADE,
      name VARCHAR(120) UNIQUE NOT NULL,
      description TEXT,
      image_url TEXT,
      status VARCHAR(30) NOT NULL DEFAULT 'active',
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    ALTER TABLE bookings ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
    ALTER TABLE bookings ADD COLUMN IF NOT EXISTS service_id INTEGER REFERENCES services(id) ON DELETE SET NULL;
    ALTER TABLE bookings DROP CONSTRAINT IF EXISTS bookings_service_id_fkey;
    ALTER TABLE bookings ADD CONSTRAINT bookings_service_id_fkey FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE SET NULL;
    ALTER TABLE bookings ADD COLUMN IF NOT EXISTS address TEXT;
    ALTER TABLE bookings ADD COLUMN IF NOT EXISTS notes TEXT;
    ALTER TABLE bookings ADD COLUMN IF NOT EXISTS scheduled_at TIMESTAMPTZ;
    ALTER TABLE services ADD COLUMN IF NOT EXISTS price NUMERIC(12,2) NOT NULL DEFAULT 0;
    ALTER TABLE services ADD COLUMN IF NOT EXISTS icon TEXT;
    ALTER TABLE services ALTER COLUMN category_id DROP NOT NULL;

    CREATE TABLE IF NOT EXISTS zones (
      id SERIAL PRIMARY KEY,
      name VARCHAR(120) NOT NULL,
      city VARCHAR(100),
      status VARCHAR(30) NOT NULL DEFAULT 'active',
      radius_km NUMERIC DEFAULT 10,
      center_lat NUMERIC,
      center_lng NUMERIC,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS pincodes (
      id SERIAL PRIMARY KEY,
      code VARCHAR(20) UNIQUE NOT NULL,
      zone_id INTEGER REFERENCES zones(id) ON DELETE CASCADE,
      lat NUMERIC,
      lng NUMERIC,
      status VARCHAR(30) NOT NULL DEFAULT 'active',
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    ALTER TABLE workers ADD COLUMN IF NOT EXISTS current_lat NUMERIC;
    ALTER TABLE workers ADD COLUMN IF NOT EXISTS current_lng NUMERIC;
    ALTER TABLE workers ADD COLUMN IF NOT EXISTS last_location_update TIMESTAMPTZ;
    ALTER TABLE workers ADD COLUMN IF NOT EXISTS pincode VARCHAR(20);

    CREATE TABLE IF NOT EXISTS admin_permissions (
      id SERIAL PRIMARY KEY,
      admin_id INTEGER NOT NULL REFERENCES admins(id) ON DELETE CASCADE,
      permission VARCHAR(100) NOT NULL,
      UNIQUE(admin_id, permission)
    );

    CREATE TABLE IF NOT EXISTS notifications (
      id SERIAL PRIMARY KEY,
      title VARCHAR(255) NOT NULL,
      message TEXT NOT NULL,
      type VARCHAR(50) NOT NULL DEFAULT 'system',
      priority VARCHAR(20) NOT NULL DEFAULT 'normal',
      read BOOLEAN NOT NULL DEFAULT FALSE,
      entity_id VARCHAR(100),
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS complaints (
      id SERIAL PRIMARY KEY,
      subject VARCHAR(255) NOT NULL,
      description TEXT,
      status VARCHAR(50) NOT NULL DEFAULT 'pending',
      admin_notes TEXT DEFAULT '',
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS banners (
      id SERIAL PRIMARY KEY,
      title VARCHAR(120),
      image_url TEXT NOT NULL,
      link_url TEXT,
      status VARCHAR(30) NOT NULL DEFAULT 'active',
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS reviews (
      id SERIAL PRIMARY KEY,
      booking_id INTEGER UNIQUE NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      worker_id INTEGER NOT NULL REFERENCES workers(id) ON DELETE CASCADE,
      rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
      comment TEXT,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS payments (
      id SERIAL PRIMARY KEY,
      booking_id INTEGER UNIQUE NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      razorpay_order_id VARCHAR(255) NOT NULL,
      razorpay_payment_id VARCHAR(255),
      razorpay_signature VARCHAR(255),
      amount NUMERIC(12,2) NOT NULL,
      status VARCHAR(50) NOT NULL DEFAULT 'pending',
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS user_addresses (
      id SERIAL PRIMARY KEY,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      title VARCHAR(60) NOT NULL DEFAULT 'Home',
      address_line TEXT NOT NULL,
      city VARCHAR(100),
      state VARCHAR(100),
      pincode VARCHAR(20),
      landmark TEXT,
      lat NUMERIC,
      lng NUMERIC,
      is_default BOOLEAN NOT NULL DEFAULT FALSE,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    ALTER TABLE bookings ADD COLUMN IF NOT EXISTS start_photo_url TEXT;
    ALTER TABLE bookings ADD COLUMN IF NOT EXISTS completion_photo_url TEXT;
    ALTER TABLE bookings ADD COLUMN IF NOT EXISTS start_notes TEXT;
    ALTER TABLE bookings ADD COLUMN IF NOT EXISTS completion_notes TEXT;
    ALTER TABLE bookings ADD COLUMN IF NOT EXISTS job_started_at TIMESTAMPTZ;
    ALTER TABLE bookings ADD COLUMN IF NOT EXISTS job_completed_at TIMESTAMPTZ;

    -- Add address fields and FCM tokens to users and workers if missing
    ALTER TABLE users ADD COLUMN IF NOT EXISTS address TEXT;
    ALTER TABLE users ADD COLUMN IF NOT EXISTS state VARCHAR(100);
    ALTER TABLE users ADD COLUMN IF NOT EXISTS credits INTEGER DEFAULT 0;
    ALTER TABLE users ADD COLUMN IF NOT EXISTS fcm_token TEXT;
    ALTER TABLE workers ADD COLUMN IF NOT EXISTS fcm_token TEXT;
    ALTER TABLE bookings ADD COLUMN IF NOT EXISTS otp VARCHAR(10);

    ALTER TABLE services ADD COLUMN IF NOT EXISTS estimated_time INTEGER DEFAULT 60;

    -- Seed realistic prices for services that still have price = 0
    UPDATE services SET price = CASE
      WHEN name ILIKE '%plumb%' THEN 499
      WHEN name ILIKE '%paint%' THEN 799
      WHEN name ILIKE '%clean%' THEN 399
      WHEN name ILIKE '%electric%' THEN 599
      WHEN name ILIKE '%ac%' THEN 699
      WHEN name ILIKE '%carpent%' THEN 549
      WHEN name ILIKE '%pest%' THEN 449
      WHEN name ILIKE '%appliance%' THEN 649
      WHEN name ILIKE '%laundry%' THEN 299
      WHEN name ILIKE '%movers%' OR name ILIKE '%shifting%' THEN 1499
      WHEN name ILIKE '%beauty%' OR name ILIKE '%salon%' THEN 599
      WHEN name ILIKE '%massage%' THEN 799
      WHEN name ILIKE '%tutor%' THEN 499
      WHEN name ILIKE '%repair%' THEN 549
      ELSE 499
    END
    WHERE price = 0 OR price IS NULL;
  `);
}

module.exports = { pool, query, initDb };