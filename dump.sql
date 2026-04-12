-- ============================================================
--  ReclaimHub — Lost & Found System
--  db_dump.sql — Full Schema + Seed Data (~150 records)
-- ============================================================

CREATE DATABASE IF NOT EXISTS Reclaim_db;
USE Reclaim_db;

-- ──────────────────────────────────────────────────────────
--  TABLE: users
-- ──────────────────────────────────────────────────────────
DROP TABLE IF EXISTS audit_logs;
DROP TABLE IF EXISTS lost_items;
DROP TABLE IF EXISTS found_items;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(80)  NOT NULL,
  last_name  VARCHAR(80)  NOT NULL,
  email      VARCHAR(150) NOT NULL UNIQUE,
  phone      VARCHAR(20),
  password   VARCHAR(255) NOT NULL,
  role       ENUM('admin','user') NOT NULL DEFAULT 'user',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ──────────────────────────────────────────────────────────
--  TABLE: found_items
-- ──────────────────────────────────────────────────────────
CREATE TABLE found_items (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  item_name   VARCHAR(150) NOT NULL,
  description TEXT,
  date_found  DATE         NOT NULL,
  location    VARCHAR(200),
  status      ENUM('Available','Claimed') NOT NULL DEFAULT 'Available',
  posted_by   VARCHAR(150),
  image_path  VARCHAR(255),
  created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ──────────────────────────────────────────────────────────
--  TABLE: lost_items
-- ──────────────────────────────────────────────────────────
CREATE TABLE lost_items (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  user_id     INT,
  item_name   VARCHAR(150) NOT NULL,
  description TEXT,
  date_lost   DATE         NOT NULL,
  location    VARCHAR(200),
  latitude    DECIMAL(10,7),
  longitude   DECIMAL(10,7),
  status      ENUM('Pending','Resolved','Searching') NOT NULL DEFAULT 'Pending',
  image_path  VARCHAR(255),
  created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- ──────────────────────────────────────────────────────────
--  TABLE: audit_logs
-- ──────────────────────────────────────────────────────────
CREATE TABLE audit_logs (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  user_id      INT,
  username     VARCHAR(150),
  action       VARCHAR(200) NOT NULL,
  target_table VARCHAR(100),
  target_id    INT,
  created_at   DATETIME DEFAULT CURRENT_TIMESTAMP
);