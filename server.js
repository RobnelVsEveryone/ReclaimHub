
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
    console.log('✅ Database connected — MySQL (reclaim_db)');
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

function authMiddleware(requiredRole = null) {
  return (req, res, next) => {
    const authHeader = req.headers['authorization'];
    if (!authHeader) return res.status(401).json({ success: false, message: 'No token provided.' });

    const token = authHeader.split(' ')[1];
    if (!token) return res.status(401).json({ success: false, message: 'Malformed token.' });

    try {
      const decoded = jwt.verify(token, JWT_SECRET);
      req.user = decoded;

      if (requiredRole && decoded.role !== requiredRole) {
        return res.status(403).json({ success: false, message: `Access denied. Requires role: ${requiredRole}` });
      }
      next();
    } catch (err) {
      return res.status(401).json({ success: false, message: 'Invalid or expired token.' });
    }
  };
}

// ============================================================
//  ROUTES
// ============================================================

// ── Health Check ─────────────────────────────────────────
app.get('/', (req, res) => {
  res.json({ success: true, message: '✅ FindIt API is running.', timestamp: new Date().toISOString() });
});

// ╔══════════════════════════════════════════════════════════╗
//  AUTH ROUTES
// ╚══════════════════════════════════════════════════════════╝

// POST /api/auth/register
app.post('/api/auth/register', async (req, res) => {
  const { first_name, last_name, email, phone, password } = req.body;

  if (!first_name || !last_name || !email || !password) {
    return res.status(400).json({ success: false, message: 'All fields are required.' });
  }

  try {
    // Check duplicate email
    const [existing] = await db.query('SELECT id FROM users WHERE email = ?', [email]);
    if (existing.length > 0) {
      return res.status(409).json({ success: false, message: 'Email already registered.' });
    }

    const hashed = await bcrypt.hash(password, 10);
    const [result] = await db.query(
      `INSERT INTO users (first_name, last_name, email, phone, password, role, created_at)
       VALUES (?, ?, ?, ?, ?, 'user', NOW())`,
      [first_name, last_name, email, phone, hashed]
    );

    console.log(`✅ User registered — ${first_name} ${last_name} (${email}) | ID: ${result.insertId}`);
    await logAudit(result.insertId, email, 'REGISTER', 'users', result.insertId);
    broadcast('user_registered', { id: result.insertId, name: `${first_name} ${last_name}`, email });

    return res.status(201).json({ success: true, message: 'Account created successfully.', userId: result.insertId });
  } catch (err) {
    console.error('❌ Register error:', err.message);
    return res.status(500).json({ success: false, message: 'Server error during registration.' });
  }
});

// POST /api/auth/login
app.post('/api/auth/login', async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ success: false, message: 'Email and password are required.' });
  }

  try {
    const [rows] = await db.query('SELECT * FROM users WHERE email = ?', [email]);
    if (rows.length === 0) {
      return res.status(401).json({ success: false, message: 'Invalid credentials.' });
    }

    const user = rows[0];
    const match = await bcrypt.compare(password, user.password);
    if (!match) {
      return res.status(401).json({ success: false, message: 'Invalid credentials.' });
    }

    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role, name: `${user.first_name} ${user.last_name}` },
      JWT_SECRET,
      { expiresIn: '8h' }
    );

    // Console acknowledgement per role
    if (user.role === 'admin') {
      console.log(`✅ Admin logged in  — ${user.first_name} ${user.last_name} (${user.email}) | ${new Date().toLocaleTimeString()}`);
    } else {
      console.log(`✅ Client logged in — ${user.first_name} ${user.last_name} (${user.email}) | ${new Date().toLocaleTimeString()}`);
    }

    await logAudit(user.id, user.email, 'LOGIN', 'users', user.id);
    broadcast('user_login', { name: `${user.first_name} ${user.last_name}`, role: user.role });

    return res.json({
      success : true,
      message : `${user.role === 'admin' ? 'Admin' : 'Client'} logged in successfully.`,
      token,
      user    : { id: user.id, name: `${user.first_name} ${user.last_name}`, email: user.email, role: user.role }
    });
  } catch (err) {
    console.error('❌ Login error:', err.message);
    return res.status(500).json({ success: false, message: 'Server error during login.' });
  }
});

// GET /api/auth/me  — verify token & get current user
app.get('/api/auth/me', authMiddleware(), async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT id, first_name, last_name, email, phone, role, created_at FROM users WHERE id = ?',
      [req.user.id]
    );
    if (rows.length === 0) return res.status(404).json({ success: false, message: 'User not found.' });
    return res.json({ success: true, user: rows[0] });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
});


startServer();