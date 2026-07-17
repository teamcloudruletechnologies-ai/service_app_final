require('dotenv').config();
const { pool } = require('./src/config/db');

async function run() {
  try {
    // Services table fixes
    await pool.query('ALTER TABLE services ADD COLUMN IF NOT EXISTS price NUMERIC(12,2) DEFAULT 0');
    await pool.query('ALTER TABLE services ADD COLUMN IF NOT EXISTS icon VARCHAR(50)');
    await pool.query('ALTER TABLE services ALTER COLUMN category_id DROP NOT NULL');

    // Workers table — state and address for onboarding
    await pool.query("ALTER TABLE workers ADD COLUMN IF NOT EXISTS state VARCHAR(100)");
    await pool.query("ALTER TABLE workers ADD COLUMN IF NOT EXISTS address TEXT");
    await pool.query("ALTER TABLE workers ADD COLUMN IF NOT EXISTS photo_url TEXT");
    await pool.query("ALTER TABLE workers ADD COLUMN IF NOT EXISTS rating NUMERIC(3,2) DEFAULT 4.5");
    // Allow empty name for auto-created accounts
    await pool.query("ALTER TABLE workers ALTER COLUMN name SET DEFAULT ''");

    // Users table — state and address for onboarding
    await pool.query("ALTER TABLE users ADD COLUMN IF NOT EXISTS state VARCHAR(100)");
    await pool.query("ALTER TABLE users ADD COLUMN IF NOT EXISTS address TEXT");
    // Allow empty name for auto-created accounts
    await pool.query("ALTER TABLE users ALTER COLUMN name SET DEFAULT ''");

    console.log('✅ DB altered successfully');
  } catch (e) {
    console.error('❌ Error altering DB:', e);
  } finally {
    process.exit();
  }
}

run();
