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
    ALTER TABLE bookings ADD COLUMN IF NOT EXISTS declined_worker_ids INTEGER[] DEFAULT '{}';
    ALTER TABLE services ADD COLUMN IF NOT EXISTS price NUMERIC(12,2) NOT NULL DEFAULT 0;
    ALTER TABLE services ADD COLUMN IF NOT EXISTS icon TEXT;
    ALTER TABLE services ALTER COLUMN category_id DROP NOT NULL;

    ALTER TABLE service_categories ADD COLUMN IF NOT EXISTS name_ta TEXT;
    ALTER TABLE service_categories ADD COLUMN IF NOT EXISTS name_hi TEXT;
    ALTER TABLE service_categories ADD COLUMN IF NOT EXISTS name_ml TEXT;
    ALTER TABLE service_categories ADD COLUMN IF NOT EXISTS name_kn TEXT;

    ALTER TABLE services ADD COLUMN IF NOT EXISTS name_ta TEXT;
    ALTER TABLE services ADD COLUMN IF NOT EXISTS name_hi TEXT;
    ALTER TABLE services ADD COLUMN IF NOT EXISTS name_ml TEXT;
    ALTER TABLE services ADD COLUMN IF NOT EXISTS name_kn TEXT;

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
    ALTER TABLE workers ADD COLUMN IF NOT EXISTS upi_id VARCHAR(100);
    ALTER TABLE workers ADD COLUMN IF NOT EXISTS bank_account_number VARCHAR(50);
    ALTER TABLE workers ADD COLUMN IF NOT EXISTS ifsc_code VARCHAR(30);
    ALTER TABLE workers ADD COLUMN IF NOT EXISTS account_holder_name VARCHAR(120);

    CREATE TABLE IF NOT EXISTS worker_settlements (
      id SERIAL PRIMARY KEY,
      worker_id INTEGER REFERENCES workers(id) ON DELETE CASCADE,
      settlement_period_start TIMESTAMPTZ,
      settlement_period_end TIMESTAMPTZ,
      total_jobs INTEGER DEFAULT 0,
      gross_amount NUMERIC(12,2) DEFAULT 0,
      platform_fee NUMERIC(12,2) DEFAULT 0,
      net_payout NUMERIC(12,2) DEFAULT 0,
      status VARCHAR(30) DEFAULT 'pending',
      payment_method VARCHAR(50) DEFAULT 'razorpay',
      transaction_ref VARCHAR(100),
      notes TEXT,
      paid_at TIMESTAMPTZ,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

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
    ALTER TABLE bookings ADD COLUMN IF NOT EXISTS payment_status VARCHAR(30) DEFAULT 'unpaid';

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

    -- Help & Support Modules Tables
    -- Drop & recreate support tables if schema has drifted (safe: these tables have no critical production data)
    DROP TABLE IF EXISTS account_requests CASCADE;
    DROP TABLE IF EXISTS ticket_attachments CASCADE;
    DROP TABLE IF EXISTS ticket_status_history CASCADE;
    DROP TABLE IF EXISTS ticket_messages CASCADE;
    DROP TABLE IF EXISTS support_tickets CASCADE;
    DROP TABLE IF EXISTS professional_reports CASCADE;
    DROP TABLE IF EXISTS support_faq CASCADE;
    DROP TABLE IF EXISTS support_policies CASCADE;
    DROP TABLE IF EXISTS support_categories CASCADE;

    CREATE TABLE IF NOT EXISTS support_categories (
      id SERIAL PRIMARY KEY,
      name VARCHAR(100) UNIQUE NOT NULL,
      icon VARCHAR(50) DEFAULT 'help_outline',
      status VARCHAR(30) NOT NULL DEFAULT 'active',
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS support_tickets (
      id SERIAL PRIMARY KEY,
      ticket_number VARCHAR(30) UNIQUE NOT NULL,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      booking_id INTEGER REFERENCES bookings(id) ON DELETE SET NULL,
      category_id INTEGER REFERENCES support_categories(id) ON DELETE SET NULL,
      category_name VARCHAR(100),
      subject VARCHAR(255) NOT NULL,
      description TEXT NOT NULL,
      status VARCHAR(30) NOT NULL DEFAULT 'Open',
      priority VARCHAR(30) NOT NULL DEFAULT 'Medium',
      assigned_admin_id INTEGER REFERENCES admins(id) ON DELETE SET NULL,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS ticket_messages (
      id SERIAL PRIMARY KEY,
      ticket_id INTEGER NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
      sender_type VARCHAR(30) NOT NULL DEFAULT 'user',
      sender_id INTEGER NOT NULL,
      sender_name VARCHAR(120),
      message TEXT NOT NULL,
      is_internal_note BOOLEAN NOT NULL DEFAULT FALSE,
      attachment_url TEXT,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS ticket_status_history (
      id SERIAL PRIMARY KEY,
      ticket_id INTEGER NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
      old_status VARCHAR(30),
      new_status VARCHAR(30) NOT NULL,
      changed_by_admin_id INTEGER REFERENCES admins(id) ON DELETE SET NULL,
      changed_by_name VARCHAR(120),
      notes TEXT,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS ticket_attachments (
      id SERIAL PRIMARY KEY,
      ticket_id INTEGER NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
      message_id INTEGER REFERENCES ticket_messages(id) ON DELETE CASCADE,
      file_url TEXT NOT NULL,
      file_type VARCHAR(50) DEFAULT 'image',
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS professional_reports (
      id SERIAL PRIMARY KEY,
      report_number VARCHAR(30) UNIQUE NOT NULL,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      worker_id INTEGER REFERENCES workers(id) ON DELETE SET NULL,
      worker_name VARCHAR(120),
      booking_id INTEGER REFERENCES bookings(id) ON DELETE SET NULL,
      reason VARCHAR(150) NOT NULL,
      description TEXT NOT NULL,
      photo_url TEXT,
      status VARCHAR(30) NOT NULL DEFAULT 'Pending',
      admin_action VARCHAR(100),
      admin_notes TEXT,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS support_faq (
      id SERIAL PRIMARY KEY,
      category VARCHAR(100) NOT NULL DEFAULT 'General',
      question TEXT NOT NULL,
      answer TEXT NOT NULL,
      is_active BOOLEAN NOT NULL DEFAULT TRUE,
      sort_order INTEGER NOT NULL DEFAULT 0,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS support_policies (
      id SERIAL PRIMARY KEY,
      slug VARCHAR(50) UNIQUE NOT NULL,
      title VARCHAR(150) NOT NULL,
      content TEXT NOT NULL,
      is_published BOOLEAN NOT NULL DEFAULT TRUE,
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS account_requests (
      id SERIAL PRIMARY KEY,
      request_number VARCHAR(30) UNIQUE NOT NULL,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      request_type VARCHAR(50) NOT NULL,
      details JSONB DEFAULT '{}'::jsonb,
      reason TEXT,
      status VARCHAR(30) NOT NULL DEFAULT 'Pending',
      admin_notes TEXT,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    -- Seed Support Categories
    INSERT INTO support_categories (name, icon) VALUES
      ('Booking & Scheduling', 'calendar_today'),
      ('Payment & Refunds', 'payments'),
      ('Service Quality', 'star'),
      ('Professional Behavior', 'person'),
      ('Account & Profile', 'account_circle'),
      ('General Inquiry', 'help')
    ON CONFLICT (name) DO NOTHING;

    -- Seed Initial FAQs if empty
    INSERT INTO support_faq (category, question, answer, sort_order)
    SELECT 'General', 'How do I book a service?', 'Select a service from home, choose your location, pick date/time slot, and confirm your booking.', 1
    WHERE NOT EXISTS (SELECT 1 FROM support_faq WHERE question = 'How do I book a service?');

    INSERT INTO support_faq (category, question, answer, sort_order)
    SELECT 'Payment', 'What payment methods are supported?', 'We accept UPI, Credit/Debit cards, Net Banking, and Cash on Delivery after job completion.', 2
    WHERE NOT EXISTS (SELECT 1 FROM support_faq WHERE question = 'What payment methods are supported?');

    INSERT INTO support_faq (category, question, answer, sort_order)
    SELECT 'Booking', 'Can I cancel my booking?', 'Yes, you can cancel your booking anytime before the service partner is dispatched without cancellation fee.', 3
    WHERE NOT EXISTS (SELECT 1 FROM support_faq WHERE question = 'Can I cancel my booking?');

    INSERT INTO support_faq (category, question, answer, sort_order)
    SELECT 'Safety', 'Are professionals background verified?', 'Yes, all our professionals undergo criminal record check, police verification, and Aadhaar verification before onboarding.', 4
    WHERE NOT EXISTS (SELECT 1 FROM support_faq WHERE question = 'Are professionals background verified?');

    -- Seed Initial Policies if empty
    INSERT INTO support_policies (slug, title, content) VALUES
      ('privacy', 'Privacy Policy', '## Privacy Policy\n\nWe value your trust and are committed to protecting your personal data.\n\n### Information We Collect\n- Name, phone number, and email address.\n- Service location and location coordinates.\n- Booking history and payment transaction records.\n\n### How We Use Your Data\n- To schedule and deliver home services efficiently.\n- To communicate booking updates and notifications.\n- To ensure safety and resolve customer complaints.')
    ON CONFLICT (slug) DO NOTHING;

    INSERT INTO support_policies (slug, title, content) VALUES
      ('terms', 'Terms of Service', '## Terms of Service\n\nBy accessing or using our platform, you agree to comply with our terms.\n\n### User Responsibilities\n- Provide accurate service location and details.\n- Ensure safe working conditions for service professionals.\n- Pay agreed inspection and service charges upon job completion.')
    ON CONFLICT (slug) DO NOTHING;

    INSERT INTO support_policies (slug, title, content) VALUES
      ('cancellation', 'Cancellation Policy', '## Cancellation Policy\n\n### Free Cancellation\n- Cancel anytime before a technician is assigned or dispatched.\n\n### Cancellation Charges\n- A nominal cancellation fee of ₹50 applies if cancelled after the technician is on the way.')
    ON CONFLICT (slug) DO NOTHING;

    INSERT INTO support_policies (slug, title, content) VALUES
      ('refund', 'Refund Policy', '## Refund Policy\n\n### Eligibility\n- Refunds are issued if services were unsatisfactory, double-charged, or cancelled according to policy.\n\n### Processing Time\n- Approved refunds will be credited back to your original payment source within 3-5 business days.')
    ON CONFLICT (slug) DO NOTHING;
  `);
}

module.exports = { pool, query, initDb };