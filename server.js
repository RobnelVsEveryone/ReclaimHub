
const express    = require('express');
const mysql      = require('mysql2/promise');
const http       = require('http');
const WebSocket  = require('ws');
const bcrypt     = require('bcryptjs');
const jwt        = require('jsonwebtoken');
const cors       = require('cors');
 
const app    = express();
const server = http.createServer(app);
const wss    = new WebSocket.Server({ server });
 
const PORT       = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'findit_secret_key_2025';
 
// ── Middleware ────────────────────────────────────────────
app.use(cors());
app.use(express.json());
 
// ============================================================
//  DATABASE CONNECTION
// ============================================================
let db;
 
async function connectDB() {
  try {
    db = await mysql.createPool({
      host     : 'localhost',
      user     : 'root',
      password : '',           // XAMPP default — change if needed
      database : 'reclaim_db',
      waitForConnections: true,
      connectionLimit   : 10,
    });
    // test the connection
    await db.query('SELECT 1');
    console.log('✅ Database connected — MySQL (findit_db)');
  } catch (err) {
    console.error('❌ Database connection failed:', err.message);
    process.exit(1);
  }
}

// ============================================================
//  START SERVER
// ============================================================
async function startServer() {
  await connectDB();

  server.listen(PORT, () => {
    console.log('');
    console.log('╔══════════════════════════════════════════╗');
    console.log('║       ReclaimHub — Lost & Found System   ║');
    console.log('╚══════════════════════════════════════════╝');
    console.log(`✅ Server started on http://localhost:${PORT}`);
    console.log(`✅ WebSocket ready on ws://localhost:${PORT}`);
    console.log(`✅ Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log('──────────────────────────────────────────');
  });
}

startServer();