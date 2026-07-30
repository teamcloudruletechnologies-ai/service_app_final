require('dotenv').config();
const { pool } = require('./src/config/db');

async function fixDb() {
  const client = await pool.connect();
  try {
    console.log('🔧 Starting DB fix...');

    await client.query('BEGIN');

    // ─────────────────────────────────────────────────────────
    // 1. Create complaints table if it doesn't exist
    // ─────────────────────────────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS complaints (
        id           SERIAL PRIMARY KEY,
        subject      VARCHAR(255) NOT NULL,
        description  TEXT,
        status       VARCHAR(50)  NOT NULL DEFAULT 'pending',
        admin_notes  TEXT DEFAULT '',
        created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
        updated_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW()
      );
    `);
    console.log('✅ complaints table created (or already exists)');

    // ─────────────────────────────────────────────────────────
    // 2. Fix bookings.user_id foreign key → ON DELETE CASCADE
    //    Drop the old constraint and recreate it
    // ─────────────────────────────────────────────────────────
    await client.query(`
      ALTER TABLE bookings
        DROP CONSTRAINT IF EXISTS bookings_user_id_fkey;
    `);
    await client.query(`
      ALTER TABLE bookings
        ADD CONSTRAINT bookings_user_id_fkey
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    `);
    console.log('✅ bookings.user_id FK fixed → ON DELETE CASCADE');

    // ─────────────────────────────────────────────────────────
    // 3. Fix bookings.worker_id foreign key → ON DELETE CASCADE
    // ─────────────────────────────────────────────────────────
    await client.query(`
      ALTER TABLE bookings
        DROP CONSTRAINT IF EXISTS bookings_worker_id_fkey;
    `);
    await client.query(`
      ALTER TABLE bookings
        ADD CONSTRAINT bookings_worker_id_fkey
          FOREIGN KEY (worker_id) REFERENCES workers(id) ON DELETE CASCADE;
    `);
    console.log('✅ bookings.worker_id FK fixed → ON DELETE CASCADE');

    // ─────────────────────────────────────────────────────────
    // 4. Fix invoices foreign keys → ON DELETE CASCADE
    // ─────────────────────────────────────────────────────────
    await client.query(`
      ALTER TABLE invoices
        DROP CONSTRAINT IF EXISTS invoices_booking_id_fkey,
        DROP CONSTRAINT IF EXISTS invoices_user_id_fkey,
        DROP CONSTRAINT IF EXISTS invoices_worker_id_fkey;
    `);
    await client.query(`
      ALTER TABLE invoices
        ADD CONSTRAINT invoices_booking_id_fkey
          FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
        ADD CONSTRAINT invoices_user_id_fkey
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        ADD CONSTRAINT invoices_worker_id_fkey
          FOREIGN KEY (worker_id) REFERENCES workers(id) ON DELETE CASCADE;
    `);
    console.log('✅ invoices FKs fixed → ON DELETE CASCADE');

    await client.query('COMMIT');
    console.log('\n🎉 DB fix completed successfully!');

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('\n❌ DB fix failed (rolled back):', err.message);
    throw err;
  } finally {
    client.release();
    await pool.end();
  }
}

fixDb();
