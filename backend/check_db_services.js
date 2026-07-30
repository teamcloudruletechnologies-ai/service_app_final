const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: false,
  },
});

async function checkDb() {
  const client = await pool.connect();
  try {
    console.log('--- Categories in DB ---');
    const catRes = await client.query('SELECT * FROM service_categories');
    console.log(JSON.stringify(catRes.rows, null, 2));

    console.log('\n--- Services in DB ---');
    const servRes = await client.query('SELECT s.*, c.name AS category_name FROM services s LEFT JOIN service_categories c ON s.category_id = c.id');
    console.log(JSON.stringify(servRes.rows, null, 2));
  } catch (err) {
    console.error('Error querying DB:', err);
  } finally {
    client.release();
    await pool.end();
  }
}

checkDb();
