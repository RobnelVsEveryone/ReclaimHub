// fix-passwords.js
// Run once: node fix-passwords.js
// This re-hashes all user passwords correctly using bcrypt

const mysql  = require('mysql2/promise');
const bcrypt = require('bcryptjs');

async function fixPasswords() {
  const db = await mysql.createPool({
    host    : 'localhost',
    user    : 'root',
    password: '',           // your XAMPP password
    database: 'reclaim_db', // your DB name
  });

  // Define which email gets which plain password
  /*const users = [
    { email: 'admin@school.edu',  password: 'admin123'    },
    { email: 'maria@school.edu',  password: 'password123' },
    { email: 'juan@school.edu',   password: 'password123' },
    { email: 'rizal@school.edu',  password: 'password123' },
    { email: 'lilis@school.edu',  password: 'password123' },
    { email: 'carlos@school.edu', password: 'password123' },
    { email: 'ana@school.edu',    password: 'password123' },
    { email: 'pedro@school.edu',  password: 'password123' },
    { email: 'sofia@school.edu',  password: 'password123' },
    { email: 'marco@school.edu',  password: 'password123' },
  ];*/

  for (const u of users) {
    const hashed = await bcrypt.hash(u.password, 10);
    await db.query('UPDATE users SET password = ? WHERE email = ?', [hashed, u.email]);
    console.log(`✅ Password fixed for: ${u.email}`);
  }

  console.log('\n✅ All passwords updated. You can now log in.');
  process.exit(0);
}

fixPasswords().catch(err => {
  console.error('❌ Error:', err.message);
  process.exit(1);
});