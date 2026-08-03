const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: false,
  },
});

const categories = [
  {
    name: 'Home Maintenance',
    description: 'Electrical, Plumbing, Carpentry, Painting and general home repairs',
    icon_url: 'https://img.icons8.com/color/96/home.png'
  },
  {
    name: 'Appliance Services',
    description: 'AC, Washing machine, Refrigerator and TV repair & installation',
    icon_url: 'https://img.icons8.com/color/96/air-conditioner.png'
  },
  {
    name: 'Beauty & Wellness',
    description: 'Salon at home, spa, massage, and grooming services for men and women',
    icon_url: 'https://img.icons8.com/color/96/spa-care.png'
  },
  {
    name: 'Cleaning',
    description: 'Full home deep clean, kitchen, bathroom, sofa and carpet cleaning',
    icon_url: 'https://img.icons8.com/color/96/cleaning-service.png'
  },
  {
    name: 'Security & CCTV',
    description: 'CCTV camera installation, smart locks, biometric security systems',
    icon_url: 'https://img.icons8.com/color/96/security-camera.png'
  }
];

async function seedCategories() {
  const client = await pool.connect();
  try {
    console.log('Seeding categories...');
    for (const cat of categories) {
      // Check if category name already exists
      const checkRes = await client.query('SELECT * FROM service_categories WHERE name = $1', [cat.name]);
      if (checkRes.rows.length === 0) {
        await client.query(
          `INSERT INTO service_categories (name, description, icon_url, status)
           VALUES ($1, $2, $3, 'active')`,
          [cat.name, cat.description, cat.icon_url]
        );
        console.log(`Category "${cat.name}" seeded.`);
      } else {
        console.log(`Category "${cat.name}" already exists.`);
      }
    }
    console.log('Seeding completed successfully!');
  } catch (err) {
    console.error('Error seeding categories:', err);
  } finally {
    client.release();
    await pool.end();
  }
}

seedCategories();
