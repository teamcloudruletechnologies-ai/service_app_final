const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://service_app_user:Kz10X1r0P3l4Y5t6@dpg-cuh5s3g8fa7c73b00000-a.singapore-postgres.render.com/service_app_db?ssl=true',
  ssl: {
    rejectUnauthorized: false,
  },
});

async function addSubServicesColumn() {
  const client = await pool.connect();
  try {
    console.log('Adding sub_services JSONB column to services table if not exists...');
    await client.query(`
      ALTER TABLE services ADD COLUMN IF NOT EXISTS sub_services JSONB DEFAULT '[]'::jsonb;
    `);
    console.log('sub_services column added successfully!');
  } catch (err) {
    console.error('Error adding sub_services column:', err);
  } finally {
    client.release();
    await pool.end();
  }
}

addSubServicesColumn();
