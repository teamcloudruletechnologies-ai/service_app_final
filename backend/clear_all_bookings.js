const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://service_app_user:Kz10X1r0P3l4Y5t6@dpg-cuh5s3g8fa7c73b00000-a.singapore-postgres.render.com/service_app_db?ssl=true',
  ssl: {
    rejectUnauthorized: false,
  },
});

async function clearBookings() {
  const client = await pool.connect();
  try {
    console.log('Clearing all bookings and invoices from database...');
    
    await client.query('DELETE FROM invoices;');
    await client.query('DELETE FROM payments;');
    await client.query('DELETE FROM reviews;');
    await client.query('DELETE FROM complaints;');
    await client.query('DELETE FROM bookings;');
    
    console.log('✅ All bookings, invoices, payments, and reviews deleted successfully!');
  } catch (err) {
    console.error('❌ Error clearing bookings:', err.message);
  } finally {
    client.release();
    await pool.end();
  }
}

clearBookings();
