require('dotenv').config();
const { pool } = require('./src/config/db');
const { hashPassword } = require('./src/utils/hash');

async function seed() {
  try {
    console.log('Starting DB Seeding...');

    // 1. Seed Super Admin
    const adminEmail = 'admin@urbanserve.com';
    const adminPasswordHash = await hashPassword('admin123');
    
    // Check if admin already exists
    const adminCheck = await pool.query('SELECT * FROM admins WHERE email = $1', [adminEmail]);
    let adminId;
    if (adminCheck.rows.length === 0) {
      const adminResult = await pool.query(
        `INSERT INTO admins (name, email, password_hash, role, status)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING id`,
        ['Prakash A.', adminEmail, adminPasswordHash, 'admin', 'active']
      );
      adminId = adminResult.rows[0].id;
      console.log('Admin user seeded.');
    } else {
      adminId = adminCheck.rows[0].id;
      console.log('Admin user already exists.');
    }

    // 2. Seed Users
    const usersData = [
      { name: 'Ramesh Kumar', email: 'ramesh@gmail.com', phone: '+919876543210', status: 'active' },
      { name: 'Priya Sharma', email: 'priya@gmail.com', phone: '+919876543211', status: 'active' },
      { name: 'Amit Patel', email: 'amit@gmail.com', phone: '+919876543212', status: 'active' },
      { name: 'Sneha Reddy', email: 'sneha@gmail.com', phone: '+919876543213', status: 'active' },
      { name: 'Rahul Verma', email: 'rahul@gmail.com', phone: '+919876543214', status: 'suspended' },
    ];

    const seededUsers = [];
    for (const u of usersData) {
      const check = await pool.query('SELECT * FROM users WHERE email = $1', [u.email]);
      if (check.rows.length === 0) {
        const hash = await hashPassword('user123');
        const res = await pool.query(
          `INSERT INTO users (name, email, phone, password_hash, status)
           VALUES ($1, $2, $3, $4, $5)
           RETURNING id, name, email, phone, status`,
          [u.name, u.email, u.phone, hash, u.status]
        );
        seededUsers.push(res.rows[0]);
      } else {
        seededUsers.push(check.rows[0]);
      }
    }
    console.log(`Seeded/verified ${seededUsers.length} users.`);

    // 3. Seed Workers
    const workersData = [
      { name: 'Rajesh Carpenter', email: 'rajesh@gmail.com', phone: '+918765432100', service_type: 'Plumbing', experience_years: 5, city: 'Chennai', status: 'active', kyc_status: 'approved', current_lat: 13.0827, current_lng: 80.2707, photo_url: 'https://images.unsplash.com/photo-1540569014015-19a7be504e3a?w=150', rating: 4.8 },
      { name: 'Suresh Cleaner', email: 'suresh@gmail.com', phone: '+918765432101', service_type: 'Cleaning', experience_years: 3, city: 'Chennai', status: 'active', kyc_status: 'approved', current_lat: 13.0900, current_lng: 80.2600, photo_url: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=150', rating: 4.2 },
      { name: 'Vikram Electrician', email: 'vikram@gmail.com', phone: '+918765432102', service_type: 'Electrical', experience_years: 8, city: 'Chennai', status: 'active', kyc_status: 'approved', current_lat: 13.0600, current_lng: 80.2500, photo_url: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150', rating: 4.6 },
      { name: 'Anita Beautician', email: 'anita@gmail.com', phone: '+918765432105', service_type: 'AC Service', experience_years: 4, city: 'Chennai', status: 'active', kyc_status: 'approved', current_lat: 13.0800, current_lng: 80.3200, photo_url: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150', rating: 4.9 },
      { name: 'Far Away Plumbing', email: 'faraway@gmail.com', phone: '+918765432106', service_type: 'Plumbing', experience_years: 6, city: 'Chennai', status: 'active', kyc_status: 'approved', current_lat: 13.2000, current_lng: 80.3500, photo_url: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150', rating: 4.5 },
      { name: 'Karan Sharma', email: 'karan@gmail.com', phone: '+918765432103', service_type: 'AC Service', experience_years: 4, city: 'Chennai', status: 'pending', kyc_status: 'pending', current_lat: 13.0400, current_lng: 80.2400, photo_url: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=150', rating: 3.5 },
      { name: 'Anil Painter', email: 'anil@gmail.com', phone: '+918765432104', service_type: 'Others', experience_years: 6, city: 'Mumbai', status: 'suspended', kyc_status: 'approved', current_lat: 19.0760, current_lng: 72.8777, photo_url: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150', rating: 4.0 },
    ];

    const seededWorkers = [];
    for (const w of workersData) {
      const check = await pool.query('SELECT * FROM workers WHERE phone = $1', [w.phone]);
      if (check.rows.length === 0) {
        const hash = await hashPassword('worker123');
        const res = await pool.query(
          `INSERT INTO workers (name, email, phone, password_hash, service_type, experience_years, city, status, kyc_status, current_lat, current_lng, last_location_update, photo_url, rating)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, NOW(), $12, $13)
           RETURNING id, name, phone, service_type, status, kyc_status, photo_url, rating`,
          [w.name, w.email, w.phone, hash, w.service_type, w.experience_years, w.city, w.status, w.kyc_status, w.current_lat || null, w.current_lng || null, w.photo_url || null, w.rating || 4.5]
        );
        seededWorkers.push(res.rows[0]);
      } else {
        // Update the location and info of existing worker for testing
        const res = await pool.query(
          `UPDATE workers SET current_lat = $1, current_lng = $2, last_location_update = NOW(), status = $3, kyc_status = $4, photo_url = $5, rating = $6 WHERE id = $7 RETURNING id, name, phone, service_type, status, kyc_status, photo_url, rating`,
          [w.current_lat || null, w.current_lng || null, w.status, w.kyc_status, w.photo_url || null, w.rating || 4.5, check.rows[0].id]
        );
        seededWorkers.push(res.rows[0]);
      }
    }
    console.log(`Seeded/verified ${seededWorkers.length} workers.`);

    // 4. Seed Worker KYC Records
    for (const worker of seededWorkers) {
      const check = await pool.query('SELECT * FROM worker_kyc WHERE worker_id = $1', [worker.id]);
      if (check.rows.length === 0) {
        const kycStatus = worker.kyc_status;
        await pool.query(
          `INSERT INTO worker_kyc (
            worker_id, aadhaar_number, aadhaar_url, aadhaar_status,
            pan_number, pan_url, pan_status,
            bank_account_number, bank_passbook_url, bank_passbook_status,
            selfie_url, selfie_status, status, reviewed_by, reviewed_at
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, NOW())`,
          [
            worker.id,
            '123456789012', 'https://images.unsplash.com/photo-1554415707-6e8cfc93fe23?w=500', kycStatus,
            'ABCDE1234F', 'https://images.unsplash.com/photo-1554415707-6e8cfc93fe23?w=500', kycStatus,
            '9876543210123', 'https://images.unsplash.com/photo-1554415707-6e8cfc93fe23?w=500', kycStatus,
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500', kycStatus,
            kycStatus,
            adminId
          ]
        );
      }
    }
    console.log('Worker KYC records seeded.');

    // 5. Seed Bookings
    const bookingsCheck = await pool.query('SELECT COUNT(*) FROM bookings');
    if (Number(bookingsCheck.rows[0].count) === 0) {
      const bookingData = [
        { userIdx: 0, workerIdx: 0, status: 'completed', amount: 1500, daysAgo: 6 },
        { userIdx: 1, workerIdx: 1, status: 'completed', amount: 2500, daysAgo: 4 },
        { userIdx: 2, workerIdx: 2, status: 'in_progress', amount: 1800, daysAgo: 2 },
        { userIdx: 3, workerIdx: 3, status: 'pending', amount: 1200, daysAgo: 1 },
        { userIdx: 0, workerIdx: 2, status: 'completed', amount: 3200, daysAgo: 0 },
        { userIdx: 1, workerIdx: 0, status: 'cancelled', amount: 1500, daysAgo: 3 },
      ];

      for (const b of bookingData) {
        const userId = seededUsers[b.userIdx].id;
        const workerId = seededWorkers[b.workerIdx].id;
        
        await pool.query(
          `INSERT INTO bookings (user_id, worker_id, status, amount, created_at, updated_at)
           VALUES ($1, $2, $3, $4, NOW() - $5 * INTERVAL '1 day', NOW())`,
          [userId, workerId, b.status, b.amount, b.daysAgo]
        );
      }
      console.log('Bookings seeded.');
    } else {
      console.log('Bookings already exist.');
    }

    // 6. Seed Activity Logs
    const logsCheck = await pool.query('SELECT COUNT(*) FROM activity_logs');
    if (Number(logsCheck.rows[0].count) === 0) {
      const logsData = [
        { userIdx: 0, action: 'login', details: 'User logged in from IP 192.168.1.1' },
        { userIdx: 1, action: 'booking_create', details: 'Created service booking #102 for Cleaning' },
        { userIdx: 2, action: 'profile_update', details: 'Updated profile contact phone number' },
        { userIdx: 3, action: 'login', details: 'User logged in from IP 192.168.1.4' },
      ];

      for (const l of logsData) {
        const userId = seededUsers[l.userIdx].id;
        await pool.query(
          `INSERT INTO activity_logs (user_id, action, details, created_at)
           VALUES ($1, $2, $3, NOW())`,
          [userId, l.action, l.details]
        );
      }
      console.log('Activity logs seeded.');
    } else {
      console.log('Activity logs already exist.');
    }

    console.log('Database Seeding Completed Successfully! 🎉');
  } catch (err) {
    console.error('Seeding Error:', err);
  } finally {
    process.exit();
  }
}

seed();
