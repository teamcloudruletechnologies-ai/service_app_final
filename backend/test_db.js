const { Pool } = require('pg');
const pool = new Pool({
  connectionString: 'postgresql://postgres.nqlyhlrqiabtrtnfipoe:clouderuletech26@aws-1-ap-south-1.pooler.supabase.com:5432/postgres'
});

async function run() {
  const res = await pool.query("SELECT id, name, status, kyc_status, current_lat, current_lng, city, service_type FROM workers WHERE name ILIKE '%praveen%'");
  console.log(res.rows);
  const typesRes = await pool.query("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'notifications'");
  console.log('notifications table:', typesRes.rows);
  pool.end();
}
run();
