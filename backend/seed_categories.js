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
    name: 'Plumbing',
    description: 'Leak repairs, tap installations, pipe repairs, and other plumbing services',
    icon_url: 'https://img.icons8.com/color/96/plumbing.png'
  },
  {
    name: 'Cleaning',
    description: 'Deep home cleaning, bathroom cleaning, kitchen cleaning, and disinfection services',
    icon_url: 'https://img.icons8.com/color/96/cleaning-service.png'
  },
  {
    name: 'Electrical',
    description: 'Fan installation, switchboard repair, wiring, and general electrical works',
    icon_url: 'https://img.icons8.com/color/96/electricity.png'
  },
  {
    name: 'AC Service',
    description: 'AC installation, wet cleaning, gas charging, and repair services',
    icon_url: 'https://img.icons8.com/color/96/air-conditioner.png'
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
