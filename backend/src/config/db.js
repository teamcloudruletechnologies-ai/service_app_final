const { Pool } = require("pg");
const env = require("./env");

const pool = new Pool({
  connectionString: env.databaseUrl,
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
      user_id INTEGER REFERENCES users(id),
      worker_id INTEGER REFERENCES workers(id),
      status VARCHAR(30) NOT NULL DEFAULT 'pending',
      amount NUMERIC(12,2) NOT NULL DEFAULT 0,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS invoices (
      id SERIAL PRIMARY KEY,
      booking_id INTEGER REFERENCES bookings(id),
      user_id INTEGER REFERENCES users(id),
      worker_id INTEGER REFERENCES workers(id),
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
  `);
}

module.exports = { pool, query, initDb };
