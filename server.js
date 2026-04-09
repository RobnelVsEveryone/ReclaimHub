
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

//  WEBSOCKET
// ============================================================

// Broadcast a JSON event to ALL connected WS clients
function broadcast(event, data) {
  const payload = JSON.stringify({ event, data, timestamp: new Date().toISOString() });
  wss.clients.forEach(client => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(payload);
    }
  });
}

wss.on('connection', (ws, req) => {
  const clientIp = req.socket.remoteAddress;
  console.log(`🔌 WebSocket client connected  — IP: ${clientIp}  | Total clients: ${wss.clients.size}`);

  ws.on('close', () => {
    console.log(`🔌 WebSocket client disconnected — Remaining: ${wss.clients.size}`);
  });

  // Send a welcome ping so the frontend knows WS is live
  ws.send(JSON.stringify({ event: 'connected', data: { message: 'WebSocket live — FindIt server' }, timestamp: new Date().toISOString() }));
});

// ============================================================
//  AUDIT TRAIL HELPER
//  Writes to DB + prints to console
// ============================================================
async function logAudit(userId, username, action, targetTable, targetId = null) {
  try {
    await db.query(
      `INSERT INTO audit_logs (user_id, username, action, target_table, target_id, created_at)
       VALUES (?, ?, ?, ?, ?, NOW())`,
      [userId, username, action, targetTable, targetId]
    );
    console.log(`📋 AUDIT | user: ${username} | action: ${action} | table: ${targetTable} | id: ${targetId ?? '—'} | ${new Date().toLocaleTimeString()}`);

    // Broadcast audit event in real-time
    broadcast('audit_log', { username, action, targetTable, targetId });
  } catch (err) {
    console.error('❌ Audit log failed:', err.message);
  }
}


// ============================================================
//  AUTH MIDDLEWARE  (JWT)
// ============================================================

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


//  USERS ROUTES  (admin only)
// ╚══════════════════════════════════════════════════════════╝

// GET /api/users
app.get('/api/users', authMiddleware('admin'), async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT id, first_name, last_name, email, phone, role, created_at FROM users ORDER BY created_at DESC'
    );
    console.log(`📄 READ — users table fetched (${rows.length} records)`);
    return res.json({ success: true, count: rows.length, data: rows });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
});

// DELETE /api/users/:id  (admin only)
app.delete('/api/users/:id', authMiddleware('admin'), async (req, res) => {
  const { id } = req.params;
  try {
    const [existing] = await db.query('SELECT * FROM users WHERE id = ?', [id]);
    if (existing.length === 0) return res.status(404).json({ success: false, message: 'User not found.' });

    await db.query('DELETE FROM users WHERE id = ?', [id]);
    console.log(`🗑️  DELETE — user ID: ${id} deleted by admin ${req.user.email}`);
    await logAudit(req.user.id, req.user.email, 'DELETE_USER', 'users', id);
    broadcast('user_deleted', { id });

    return res.json({ success: true, message: 'User deleted.' });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
});

// ╔══════════════════════════════════════════════════════════╗
//  FOUND ITEMS ROUTES
// ╚══════════════════════════════════════════════════════════╝

// GET /api/found  — public (no auth needed to browse)
app.get('/api/found', async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM found_items ORDER BY date_found DESC');
    console.log(`📄 READ — found_items fetched (${rows.length} records)`);
    return res.json({ success: true, count: rows.length, data: rows });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
});

// GET /api/found/:id
app.get('/api/found/:id', async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM found_items WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ success: false, message: 'Found item not found.' });
    return res.json({ success: true, data: rows[0] });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
});

// POST /api/found  (admin only)
app.post('/api/found', authMiddleware('admin'), async (req, res) => {
  const { item_name, description, date_found, location, status } = req.body;

  if (!item_name || !description || !date_found || !location) {
    return res.status(400).json({ success: false, message: 'item_name, description, date_found and location are required.' });
  }

  try {
    const [result] = await db.query(
      `INSERT INTO found_items (item_name, description, date_found, location, status, posted_by, created_at)
       VALUES (?, ?, ?, ?, ?, ?, NOW())`,
      [item_name, description, date_found, location, status || 'Available', req.user.email]
    );

    console.log(`✅ CREATE — found item "${item_name}" added by ${req.user.email} | ID: ${result.insertId}`);
    await logAudit(req.user.id, req.user.email, 'CREATE_FOUND_ITEM', 'found_items', result.insertId);
    broadcast('found_item_created', { id: result.insertId, item_name, location, status: status || 'Available' });

    return res.status(201).json({ success: true, message: 'Found item posted.', id: result.insertId });
  } catch (err) {
    console.error('❌ Create found item error:', err.message);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
});

// PUT /api/found/:id  (admin only)
app.put('/api/found/:id', authMiddleware('admin'), async (req, res) => {
  const { id } = req.params;
  const { item_name, description, date_found, location, status } = req.body;

  try {
    const [existing] = await db.query('SELECT * FROM found_items WHERE id = ?', [id]);
    if (existing.length === 0) return res.status(404).json({ success: false, message: 'Found item not found.' });

    await db.query(
      `UPDATE found_items SET item_name=?, description=?, date_found=?, location=?, status=?, updated_at=NOW() WHERE id=?`,
      [item_name, description, date_found, location, status, id]
    );

    console.log(`✅ UPDATE — found item ID: ${id} updated by ${req.user.email}`);
    await logAudit(req.user.id, req.user.email, 'UPDATE_FOUND_ITEM', 'found_items', id);
    broadcast('found_item_updated', { id, item_name, location, status });

    return res.json({ success: true, message: 'Found item updated.' });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
});

// DELETE /api/found/:id  (admin only)
app.delete('/api/found/:id', authMiddleware('admin'), async (req, res) => {
  const { id } = req.params;
  try {
    const [existing] = await db.query('SELECT * FROM found_items WHERE id = ?', [id]);
    if (existing.length === 0) return res.status(404).json({ success: false, message: 'Found item not found.' });

    const itemName = existing[0].item_name;
    await db.query('DELETE FROM found_items WHERE id = ?', [id]);

    console.log(`🗑️  DELETE — found item "${itemName}" (ID: ${id}) deleted by ${req.user.email}`);
    await logAudit(req.user.id, req.user.email, 'DELETE_FOUND_ITEM', 'found_items', id);
    broadcast('found_item_deleted', { id, item_name: itemName });

    return res.json({ success: true, message: 'Found item deleted.' });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
});

// ╔══════════════════════════════════════════════════════════╗
//  LOST ITEMS ROUTES
// ╚══════════════════════════════════════════════════════════╝

// GET /api/lost  — auth required (users must log in to see full list)
app.get('/api/lost', authMiddleware(), async (req, res) => {
  try {
    let rows;
    if (req.user.role === 'admin') {
      // Admin sees all
      [rows] = await db.query(`
        SELECT l.*, CONCAT(u.first_name,' ',u.last_name) AS reporter_name
        FROM lost_items l
        LEFT JOIN users u ON l.user_id = u.id
        ORDER BY l.date_lost DESC
      `);
    } else {
      // Regular user sees all but can only edit their own
      [rows] = await db.query(`
        SELECT l.*, CONCAT(u.first_name,' ',u.last_name) AS reporter_name
        FROM lost_items l
        LEFT JOIN users u ON l.user_id = u.id
        ORDER BY l.date_lost DESC
      `);
    }
    console.log(`📄 READ — lost_items fetched (${rows.length} records) by ${req.user.email}`);
    return res.json({ success: true, count: rows.length, data: rows });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
});

// GET /api/lost/my  — get only current user's reports
app.get('/api/lost/my', authMiddleware(), async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT * FROM lost_items WHERE user_id = ? ORDER BY date_lost DESC',
      [req.user.id]
    );
    return res.json({ success: true, count: rows.length, data: rows });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
});

// GET /api/lost/:id
app.get('/api/lost/:id', authMiddleware(), async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM lost_items WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ success: false, message: 'Lost item not found.' });
    return res.json({ success: true, data: rows[0] });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
});

// POST /api/lost  — any logged-in user can report
app.post('/api/lost', authMiddleware(), async (req, res) => {
  const { item_name, description, date_lost, location, latitude, longitude } = req.body;

  if (!item_name || !description || !date_lost) {
    return res.status(400).json({ success: false, message: 'item_name, description and date_lost are required.' });
  }

  try {
    const [result] = await db.query(
      `INSERT INTO lost_items (user_id, item_name, description, date_lost, location, latitude, longitude, status, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, 'Pending', NOW())`,
      [req.user.id, item_name, description, date_lost, location || 'Unknown', latitude || null, longitude || null]
    );

    console.log(`✅ CREATE — lost item "${item_name}" reported by ${req.user.email} | ID: ${result.insertId}`);
    await logAudit(req.user.id, req.user.email, 'REPORT_LOST_ITEM', 'lost_items', result.insertId);
    broadcast('lost_item_created', { id: result.insertId, item_name, location, reporter: req.user.name });

    return res.status(201).json({ success: true, message: 'Lost item reported.', id: result.insertId });
  } catch (err) {
    console.error('❌ Report lost item error:', err.message);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
});

// PUT /api/lost/:id/status  — admin only: update status
app.put('/api/lost/:id/status', authMiddleware('admin'), async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;

  const validStatuses = ['Pending', 'Resolved', 'Searching'];
  if (!validStatuses.includes(status)) {
    return res.status(400).json({ success: false, message: `Status must be one of: ${validStatuses.join(', ')}` });
  }

  try {
    const [existing] = await db.query('SELECT * FROM lost_items WHERE id = ?', [id]);
    if (existing.length === 0) return res.status(404).json({ success: false, message: 'Lost item not found.' });

    await db.query('UPDATE lost_items SET status=?, updated_at=NOW() WHERE id=?', [status, id]);

    console.log(`✅ UPDATE — lost item ID: ${id} status → "${status}" by admin ${req.user.email}`);
    await logAudit(req.user.id, req.user.email, `STATUS_CHANGE_TO_${status.toUpperCase()}`, 'lost_items', id);
    broadcast('lost_item_status_updated', { id, item_name: existing[0].item_name, status });

    return res.json({ success: true, message: `Status updated to ${status}.` });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
});

// PUT /api/lost/:id  — full update (admin only)
app.put('/api/lost/:id', authMiddleware('admin'), async (req, res) => {
  const { id } = req.params;
  const { item_name, description, date_lost, location, status, latitude, longitude } = req.body;

  try {
    const [existing] = await db.query('SELECT * FROM lost_items WHERE id = ?', [id]);
    if (existing.length === 0) return res.status(404).json({ success: false, message: 'Lost item not found.' });

    await db.query(
      `UPDATE lost_items SET item_name=?, description=?, date_lost=?, location=?, status=?, latitude=?, longitude=?, updated_at=NOW() WHERE id=?`,
      [item_name, description, date_lost, location, status, latitude, longitude, id]
    );

    console.log(`✅ UPDATE — lost item ID: ${id} fully updated by ${req.user.email}`);
    await logAudit(req.user.id, req.user.email, 'UPDATE_LOST_ITEM', 'lost_items', id);
    broadcast('lost_item_updated', { id, item_name, status });

    return res.json({ success: true, message: 'Lost item updated.' });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
});

// DELETE /api/lost/:id  (admin only)
app.delete('/api/lost/:id', authMiddleware('admin'), async (req, res) => {
  const { id } = req.params;
  try {
    const [existing] = await db.query('SELECT * FROM lost_items WHERE id = ?', [id]);
    if (existing.length === 0) return res.status(404).json({ success: false, message: 'Lost item not found.' });

    const itemName = existing[0].item_name;
    await db.query('DELETE FROM lost_items WHERE id = ?', [id]);

    console.log(`🗑️  DELETE — lost item "${itemName}" (ID: ${id}) deleted by admin ${req.user.email}`);
    await logAudit(req.user.id, req.user.email, 'DELETE_LOST_ITEM', 'lost_items', id);
    broadcast('lost_item_deleted', { id, item_name: itemName });

    return res.json({ success: true, message: 'Lost item deleted.' });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
});

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