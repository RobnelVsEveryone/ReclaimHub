# Reclaim Hub

# Reclaim Hub — Lost & Found System

A real-time Lost & Found management system for campus use. Built with vanilla HTML/CSS/JS, Node.js, WebSocket, MySQL, and Leaflet.js.

---

## Features

- Public landing page showing recent found items and live system stats
- User registration and login with JWT authentication
- Role-based access — **Admin** and **User** roles
- Users can report lost items with description, date, location, and a map pin
- Users can browse all found items and view their own reports
- Admin dashboard with full CRUD for found items and lost item status management
- Real-time updates via WebSocket — all connected clients update instantly on any CRUD action
- Live metric cards showing total lost, found, pending, and resolved counts
- Audit trail — logs every action (who, what, when) stored in MySQL and visible to admins
- Interactive Leaflet.js map with OpenStreetMap for pinning lost item locations
- Activity feed that updates in real-time as events happen

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | HTML, CSS, JavaScript, Leaflet.js |
| Backend | Node.js, Express |
| Real-Time | WebSocket (ws) |
| Database | MySQL via XAMPP (mysql2/promise) |
| Auth | JWT (jsonwebtoken) + bcryptjs |

---

## Project Structure

```
findit/
├── index.html          # Full frontend — all pages in one file
├── server.js           # Node.js backend — API + WebSocket server
├── package.json        # Node dependencies
├── db_dump.sql         # Full database schema + 150 seed records
├── fix-passwords.js    # One-time script to fix bcrypt hashes after import
├── .env.example        # Environment variable template
├── README.md
└── AI_USAGE.md
```

---

## Database Tables

| Table | Description |
|---|---|
| `users` | Registered accounts with roles (admin / user) |
| `found_items` | Items turned in a nd posted by admin |
| `lost_items` | Items reported lost by users, with optional map coordinates |
| `audit_logs` | Full trail of all actions — who did what and when |

---

## Getting Started

### Requirements

- [Node.js](https://nodejs.org/) installed
- [XAMPP](https://www.apachefriends.org/) installed and running (Apache + MySQL)

---

### Step 1 — Clone or download the project

```bash
git clone https://github.com/yourusername/ReclaimHub.git
cd ReclaimHub
```

### Step 2 — Install dependencies

```bash
npm install
```

### Step 3 — Set up environment variables

```bash
cp .env.example .env
```

Edit `.env` and fill in your values (DB password, JWT secret, port).

### Step 4 — Import the database

1. Open **phpMyAdmin** at `http://localhost/phpmyadmin`
2. Create a new database named `reclaim_db`
3. Click **Import** → select `db_dump.sql` → click **Go**

### Step 5 — Fix seeded user passwords (run once only)

The SQL seed file contains placeholder password hashes. Run this script to generate real bcrypt hashes:

```bash
node fix-passwords.js
```

### Step 6 — Start the server

```bash
node server.js
```

You should see:

```
╔══════════════════════════════════════════╗
║       FindIt — Lost & Found System       ║
╚══════════════════════════════════════════╝
✅ Server started on http://localhost:3000
✅ WebSocket ready on ws://localhost:3000
✅ Database connected — MySQL (findit_db)
```

### Step 7 — Open the frontend

 run localhost/root-folder in a browser

---

## Default Credentials

| Role | Email | Password |
|---|---|---|
| Admin | `admin@school.edu` | `admin123` |
| User | `maria@school.edu` | `password123` |
| User | `juan@school.edu` | `password123` |

> Change the admin password after first login.


## WebSocket Events

The server broadcasts these events to all connected clients in real time:

| Event | Triggered When |
|---|---|
| `found_item_created` | Admin posts a new found item |
| `found_item_updated` | Admin edits a found item |
| `found_item_deleted` | Admin deletes a found item |
| `lost_item_created` | User reports a lost item |
| `lost_item_status_updated` | Admin changes a lost item's status |
| `lost_item_deleted` | Admin deletes a lost item |
| `audit_log` | Any action is logged (fires after every CRUD) |
| `user_login` | A user or admin logs in |
| `user_registered` | A new user registers |

---

## Console Acknowledgements

Every major event prints to the CMD terminal:

```
✅ Server started on http://localhost:3000
✅ Database connected — MySQL (findit_db)
✅ Admin logged in  — Admin User (admin@school.edu) | 10:24:01 AM
✅ Client logged in — Maria Santos (maria@school.edu) | 10:25:44 AM
✅ CREATE — found item "Blue Umbrella" added by admin@school.edu | ID: 31
✅ UPDATE — lost item ID: 4 status → "Resolved" by admin@school.edu
🗑️  DELETE — found item "USB Drive" (ID: 3) deleted by admin@school.edu
📋 AUDIT | user: admin@school.edu | action: CREATE_FOUND_ITEM | table: found_items
🔌 WebSocket client connected — IP: ::1 | Total clients: 1
```

---

## Contributors

- Developed by: The Reclaimers
- Institution: Palompon Institute of Technology
- Course: BSIT 2-A