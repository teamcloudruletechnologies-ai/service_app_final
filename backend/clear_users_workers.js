const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://service_app_user:Kz10X1r0P3l4Y5t6@dpg-cuh5s3g8fa7c73b00000-a.singapore-postgres.render.com/service_app_db?ssl=true',
  ssl: {
    rejectUnauthorized: false,
  },
});

async function clearUsersAndWorkers() {
  const client = await pool.connect();
  try {
    console.log('Clearing all users and workers from database...');
    
    await client.query('DELETE FROM users;');
    await client.query('DELETE FROM workers;');
    
    console.log('✅ All users and workers deleted successfully!');
  } catch (err) {
    console.error('❌ Error clearing users and workers:', err.message);
  } finally {
    client.release();
    await pool.end();
  }
}

clearUsersAndWorkers();
