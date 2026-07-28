require('dotenv').config();
const { pool } = require('./src/config/db');

// =============================================
// COMPLETE INDIA HOME SERVICE SEED DATA
// Categories → Sub-categories → Services
// =============================================

const data = [
  {
    name: 'Cleaning',
    description: 'Professional home and office cleaning services',
    icon_url: 'https://img.icons8.com/color/96/cleaning-service.png',
    subcategories: [
      {
        name: 'Home Cleaning',
        description: 'Full home deep clean and regular cleaning',
        icon_url: 'https://img.icons8.com/color/96/home.png',
        services: [
          { name: 'Full Home Deep Clean', description: 'Complete deep cleaning of your entire home including all rooms, kitchen, and bathrooms', price: 1499, estimated_time: 240 },
          { name: 'Living Room Cleaning', description: 'Sofa vacuuming, floor mopping, dusting of furniture and fans', price: 499, estimated_time: 90 },
          { name: 'Bedroom Cleaning', description: 'Bed cleaning, wardrobe dusting, floor mopping, and fan cleaning', price: 399, estimated_time: 60 },
          { name: 'Balcony Cleaning', description: 'Deep scrub of balcony tiles, grills, and removal of bird droppings', price: 299, estimated_time: 45 },
        ]
      },
      {
        name: 'Kitchen Cleaning',
        description: 'Deep kitchen cleaning and grease removal',
        icon_url: 'https://img.icons8.com/color/96/kitchen.png',
        services: [
          { name: 'Kitchen Deep Clean', description: 'Chimney, stove, countertop, sink, cabinets — full kitchen degreasing and sanitization', price: 799, estimated_time: 120 },
          { name: 'Chimney Cleaning', description: 'Professional chimney filter cleaning and degreasing', price: 499, estimated_time: 60 },
          { name: 'Refrigerator Cleaning', description: 'Inside and outside fridge cleaning, coil dusting', price: 299, estimated_time: 45 },
        ]
      },
      {
        name: 'Bathroom Cleaning',
        description: 'Bathroom sanitization and tile scrubbing',
        icon_url: 'https://img.icons8.com/color/96/bathroom.png',
        services: [
          { name: 'Bathroom Deep Clean', description: 'Toilet, tiles, sink, mirror, taps — full bathroom sanitization and scrubbing', price: 499, estimated_time: 60 },
          { name: 'Toilet Cleaning', description: 'Commode and toilet area deep cleaning and disinfection', price: 249, estimated_time: 30 },
        ]
      },
      {
        name: 'Sofa & Carpet',
        description: 'Sofa dry cleaning and carpet shampooing',
        icon_url: 'https://img.icons8.com/color/96/sofa.png',
        services: [
          { name: 'Sofa Dry Cleaning (3 Seater)', description: 'Professional dry cleaning of 3-seater sofa, stain removal and deodorizing', price: 699, estimated_time: 90 },
          { name: 'Sofa Dry Cleaning (5 Seater)', description: 'Professional dry cleaning of 5-seater sofa, stain removal and deodorizing', price: 999, estimated_time: 120 },
          { name: 'Carpet Shampooing', description: 'Machine carpet shampooing and deep cleaning', price: 599, estimated_time: 90 },
          { name: 'Mattress Cleaning', description: 'Mattress vacuuming, stain removal, and UV sanitization', price: 399, estimated_time: 60 },
        ]
      },
    ]
  },
  {
    name: 'Plumbing',
    description: 'All plumbing repair and installation services',
    icon_url: 'https://img.icons8.com/color/96/plumbing.png',
    subcategories: [
      {
        name: 'Tap & Pipe',
        description: 'Tap installation and pipe repair',
        icon_url: 'https://img.icons8.com/color/96/water-tap.png',
        services: [
          { name: 'Tap Installation', description: 'New tap fitting for kitchen or bathroom', price: 299, estimated_time: 30 },
          { name: 'Tap Repair / Leakage Fix', description: 'Fix dripping or broken taps', price: 199, estimated_time: 30 },
          { name: 'Pipe Leakage Repair', description: 'Fix pipeline leaks in walls, ceilings, or exposed pipes', price: 499, estimated_time: 60 },
          { name: 'Pipe Replacement', description: 'Replace damaged or corroded pipes', price: 799, estimated_time: 90 },
        ]
      },
      {
        name: 'Toilet & Drainage',
        description: 'Toilet and drain unblocking and repair',
        icon_url: 'https://img.icons8.com/color/96/toilet.png',
        services: [
          { name: 'Toilet Blockage Fix', description: 'Remove toilet blockage and restore flush functionality', price: 349, estimated_time: 45 },
          { name: 'Drain Unblocking', description: 'Clear kitchen or bathroom drain blockages', price: 299, estimated_time: 30 },
          { name: 'Commode Installation', description: 'New commode / Western toilet installation', price: 699, estimated_time: 90 },
          { name: 'Flush Tank Repair', description: 'Fix or replace flush tank mechanism', price: 299, estimated_time: 30 },
        ]
      },
      {
        name: 'Water Tank & Motor',
        description: 'Water tank and motor pump services',
        icon_url: 'https://img.icons8.com/color/96/water-tank.png',
        services: [
          { name: 'Motor Pump Repair', description: 'Diagnose and repair water motor pump issues', price: 599, estimated_time: 60 },
          { name: 'Motor Pump Installation', description: 'New motor pump fitting and piping', price: 999, estimated_time: 120 },
          { name: 'Water Tank Cleaning', description: 'Overhead or underground water tank cleaning and disinfection', price: 799, estimated_time: 120 },
        ]
      },
    ]
  },
  {
    name: 'Electrical',
    description: 'Electrical repair, installation, and wiring services',
    icon_url: 'https://img.icons8.com/color/96/electricity.png',
    subcategories: [
      {
        name: 'Fans & Lights',
        description: 'Fan and light installation and repair',
        icon_url: 'https://img.icons8.com/color/96/fan.png',
        services: [
          { name: 'Ceiling Fan Installation', description: 'New ceiling fan fitting with wiring and testing', price: 299, estimated_time: 30 },
          { name: 'Ceiling Fan Repair', description: 'Fix fan speed issues, capacitor replacement, or motor repair', price: 199, estimated_time: 30 },
          { name: 'Light/Bulb Installation', description: 'LED light or tubelight fitting', price: 149, estimated_time: 20 },
          { name: 'Chandelier Installation', description: 'Premium chandelier / decorative light fitting and wiring', price: 599, estimated_time: 60 },
        ]
      },
      {
        name: 'Switchboard & Wiring',
        description: 'Switchboard repair and new wiring',
        icon_url: 'https://img.icons8.com/color/96/electrical.png',
        services: [
          { name: 'Switchboard Repair', description: 'Fix faulty switches, sockets, or MCBs', price: 199, estimated_time: 30 },
          { name: 'New Switchboard Installation', description: 'New modular switchboard fitting with wiring', price: 499, estimated_time: 60 },
          { name: 'Power Point / Socket Repair', description: 'Fix or replace damaged power sockets', price: 149, estimated_time: 20 },
          { name: 'Wiring Inspection & Repair', description: 'Full home wiring check and repair of faulty circuits', price: 799, estimated_time: 120 },
        ]
      },
      {
        name: 'Appliance Fitting',
        description: 'Geyser, inverter, and other appliance fitting',
        icon_url: 'https://img.icons8.com/color/96/geyser.png',
        services: [
          { name: 'Geyser Installation', description: 'Electric water heater / geyser fitting and plumbing connection', price: 499, estimated_time: 60 },
          { name: 'Geyser Repair', description: 'Fix geyser not heating, leaking, or tripping issues', price: 349, estimated_time: 45 },
          { name: 'Inverter / UPS Installation', description: 'Home inverter and battery fitting with wiring', price: 699, estimated_time: 90 },
          { name: 'CCTV Camera Installation', description: 'Security camera fitting and DVR setup', price: 1299, estimated_time: 180 },
        ]
      },
    ]
  },
  {
    name: 'AC Service',
    description: 'Air conditioner installation, service, and repair',
    icon_url: 'https://img.icons8.com/color/96/air-conditioner.png',
    subcategories: [
      {
        name: 'AC Service & Clean',
        description: 'AC servicing and deep cleaning',
        icon_url: 'https://img.icons8.com/color/96/vacuum-cleaner.png',
        services: [
          { name: 'AC Regular Service', description: 'Filter cleaning, coil wash, and performance check for 1 unit', price: 499, estimated_time: 60 },
          { name: 'AC Deep Cleaning (Jet Wash)', description: 'High-pressure jet wash of indoor and outdoor AC unit', price: 799, estimated_time: 90 },
          { name: 'AC Gas Refill (Top Up)', description: 'Check and refill refrigerant gas for optimal cooling', price: 1299, estimated_time: 60 },
        ]
      },
      {
        name: 'AC Installation',
        description: 'New AC installation and uninstallation',
        icon_url: 'https://img.icons8.com/color/96/installation.png',
        services: [
          { name: 'AC Installation (1-1.5 Ton)', description: 'Split AC indoor and outdoor unit installation with copper piping', price: 1499, estimated_time: 120 },
          { name: 'AC Uninstallation', description: 'Safe removal of AC unit for shifting or storage', price: 699, estimated_time: 60 },
          { name: 'AC Reinstallation', description: 'Reinstall previously uninstalled AC unit at new location', price: 999, estimated_time: 90 },
        ]
      },
      {
        name: 'AC Repair',
        description: 'AC not cooling, leaking or not starting repair',
        icon_url: 'https://img.icons8.com/color/96/maintenance.png',
        services: [
          { name: 'AC Not Cooling Repair', description: 'Diagnose and fix AC not cooling problem (gas, compressor, or wiring)', price: 599, estimated_time: 60 },
          { name: 'AC Water Leaking Repair', description: 'Fix AC indoor unit water leakage', price: 399, estimated_time: 45 },
          { name: 'AC PCB Repair', description: 'AC circuit board (PCB) diagnosis and repair', price: 999, estimated_time: 90 },
        ]
      },
    ]
  },
  {
    name: 'Painting',
    description: 'Interior and exterior painting services',
    icon_url: 'https://img.icons8.com/color/96/paint-palette.png',
    subcategories: [
      {
        name: 'Interior Painting',
        description: 'Room and hall interior painting',
        icon_url: 'https://img.icons8.com/color/96/interior.png',
        services: [
          { name: 'Room Painting (1 Room)', description: 'Full interior painting of 1 room with primer and 2 coats paint (up to 150 sq ft)', price: 1999, estimated_time: 480 },
          { name: 'Hall Painting', description: 'Living room / hall interior painting with premium finish', price: 2999, estimated_time: 600 },
          { name: 'Full Home Painting (2BHK)', description: 'Complete 2BHK interior painting with Asian / Dulux paint', price: 14999, estimated_time: 2880 },
          { name: 'Full Home Painting (3BHK)', description: 'Complete 3BHK interior painting with Asian / Dulux paint', price: 21999, estimated_time: 4320 },
        ]
      },
      {
        name: 'Wall Texture & Polish',
        description: 'Texture, putty, and polish work',
        icon_url: 'https://img.icons8.com/color/96/texture.png',
        services: [
          { name: 'Wall Putty Work', description: 'Putty application for smooth wall finish before painting', price: 999, estimated_time: 240 },
          { name: 'Wall Texture Design', description: 'Decorative wall texture / pattern work per room', price: 2499, estimated_time: 480 },
          { name: 'Waterproofing (Bathroom)', description: 'Bathroom wall and floor waterproofing treatment', price: 1999, estimated_time: 240 },
        ]
      },
    ]
  },
  {
    name: 'Carpentry',
    description: 'Furniture repair, assembly, and woodwork',
    icon_url: 'https://img.icons8.com/color/96/carpenter.png',
    subcategories: [
      {
        name: 'Furniture Repair',
        description: 'Broken furniture fix and polish',
        icon_url: 'https://img.icons8.com/color/96/sofa.png',
        services: [
          { name: 'Door Repair / Alignment', description: 'Fix jammed, misaligned, or squeaky doors', price: 299, estimated_time: 45 },
          { name: 'Furniture Hinge Repair', description: 'Replace broken hinges on doors, wardrobes, or cabinets', price: 199, estimated_time: 30 },
          { name: 'Wardrobe Repair', description: 'Fix wardrobe doors, drawers, and internal fittings', price: 499, estimated_time: 60 },
          { name: 'Bed Repair', description: 'Fix broken bed frame, headboard, or slats', price: 399, estimated_time: 45 },
        ]
      },
      {
        name: 'Furniture Assembly',
        description: 'Flat-pack furniture assembly',
        icon_url: 'https://img.icons8.com/color/96/bookshelf.png',
        services: [
          { name: 'IKEA / Flat-pack Assembly', description: 'Assemble any flat-pack furniture (per item)', price: 399, estimated_time: 60 },
          { name: 'TV Unit / Shelf Installation', description: 'Wall-mount TV unit or shelving unit assembly and fitting', price: 599, estimated_time: 90 },
          { name: 'Study Table Assembly', description: 'Assemble study table with drawers and shelf', price: 299, estimated_time: 45 },
        ]
      },
    ]
  },
  {
    name: 'Pest Control',
    description: 'All types of pest control and termite treatment',
    icon_url: 'https://img.icons8.com/color/96/cockroach.png',
    subcategories: [
      {
        name: 'Cockroach & Ants',
        description: 'Cockroach and ant pest control',
        icon_url: 'https://img.icons8.com/color/96/cockroach.png',
        services: [
          { name: 'Cockroach Control (1BHK)', description: 'Gel-based cockroach treatment for kitchen and bathrooms — safe for family and pets', price: 599, estimated_time: 60 },
          { name: 'Cockroach Control (2BHK)', description: 'Gel-based cockroach treatment for full 2BHK home', price: 799, estimated_time: 90 },
          { name: 'Ant Control', description: 'Targeted ant control with spray and gel treatment', price: 399, estimated_time: 45 },
        ]
      },
      {
        name: 'Bed Bugs & Mosquito',
        description: 'Bed bug and mosquito treatment',
        icon_url: 'https://img.icons8.com/color/96/mosquito.png',
        services: [
          { name: 'Bed Bug Treatment', description: 'Heat or chemical treatment to eliminate bed bugs from mattress and furniture', price: 1299, estimated_time: 120 },
          { name: 'Mosquito Control', description: 'Indoor and outdoor mosquito fogging and larvicide treatment', price: 699, estimated_time: 60 },
        ]
      },
      {
        name: 'Termite Control',
        description: 'Pre-construction and post-construction termite treatment',
        icon_url: 'https://img.icons8.com/color/96/termite.png',
        services: [
          { name: 'Termite Treatment (Anti-Termite Spray)', description: 'Liquid anti-termite chemical spray for walls and floors (per room)', price: 999, estimated_time: 90 },
          { name: 'Wood Borer Treatment', description: 'Treatment for wood-boring beetles damaging furniture', price: 799, estimated_time: 60 },
        ]
      },
    ]
  },
];

async function seedFullServices() {
  const client = await pool.connect();
  try {
    console.log('\n🌱 Starting Full Service Seed...\n');

    // STEP 1: Add parent_id column if it doesn't exist
    await client.query(`
      ALTER TABLE service_categories ADD COLUMN IF NOT EXISTS parent_id INTEGER REFERENCES service_categories(id) ON DELETE CASCADE;
    `);
    console.log('✅ parent_id column ready');

    let totalCategories = 0;
    let totalSubcategories = 0;
    let totalServices = 0;

    for (const cat of data) {
      // Insert or get main category
      let catRow = (await client.query(
        `SELECT * FROM service_categories WHERE name = $1 AND parent_id IS NULL`,
        [cat.name]
      )).rows[0];

      if (!catRow) {
        catRow = (await client.query(
          `INSERT INTO service_categories (name, description, icon_url, status, parent_id)
           VALUES ($1, $2, $3, 'active', NULL) RETURNING *`,
          [cat.name, cat.description, cat.icon_url]
        )).rows[0];
        console.log(`  📁 Category: ${cat.name}`);
        totalCategories++;
      } else {
        console.log(`  📁 Category exists: ${cat.name}`);
      }

      // Insert sub-categories
      for (const sub of cat.subcategories) {
        let subRow = (await client.query(
          `SELECT * FROM service_categories WHERE name = $1 AND parent_id = $2`,
          [sub.name, catRow.id]
        )).rows[0];

        if (!subRow) {
          subRow = (await client.query(
            `INSERT INTO service_categories (name, description, icon_url, status, parent_id)
             VALUES ($1, $2, $3, 'active', $4) RETURNING *`,
            [sub.name, sub.description, sub.icon_url, catRow.id]
          )).rows[0];
          console.log(`    📂 Sub-category: ${sub.name}`);
          totalSubcategories++;
        } else {
          console.log(`    📂 Sub-category exists: ${sub.name}`);
        }

        // Insert services under this sub-category
        for (const svc of sub.services) {
          const exists = (await client.query(
            `SELECT id FROM services WHERE name = $1`, [svc.name]
          )).rows[0];

          if (!exists) {
            await client.query(
              `INSERT INTO services (category_id, name, description, price, estimated_time, status)
               VALUES ($1, $2, $3, $4, $5, 'active')`,
              [subRow.id, svc.name, svc.description, svc.price, svc.estimated_time]
            );
            console.log(`      ✅ Service: ${svc.name} — ₹${svc.price}`);
            totalServices++;
          } else {
            // Update category_id to point to sub-category
            await client.query(
              `UPDATE services SET category_id = $1 WHERE name = $2`,
              [subRow.id, svc.name]
            );
            console.log(`      🔄 Updated: ${svc.name}`);
          }
        }
      }
    }

    console.log('\n🎉 Seed Complete!');
    console.log(`   📁 Categories:    ${totalCategories} new`);
    console.log(`   📂 Sub-categories: ${totalSubcategories} new`);
    console.log(`   ✅ Services:       ${totalServices} new`);

  } catch (err) {
    console.error('\n❌ Seed Error:', err.message);
  } finally {
    client.release();
    process.exit();
  }
}

seedFullServices();
