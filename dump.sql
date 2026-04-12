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

-- ──────────────────────────────────────────────────────────
--  SEED: users  (password for all = "password123" hashed)
--  bcrypt hash of "password123" with salt 10
-- ──────────────────────────────────────────────────────────
INSERT INTO users (first_name, last_name, email, phone, password, role) VALUES
('Admin',     'User',      'admin@school.edu',   '09001110001', '$2a$10$Xv8wQZlpMNkG5sOjXQ1Xru4t2mKQeH7nJzVNqR0y5YhWkP3DLqSG6', 'admin'),
('Maria',     'Santos',    'maria@school.edu',   '09171234567', '$2a$10$Xv8wQZlpMNkG5sOjXQ1Xru4t2mKQeH7nJzVNqR0y5YhWkP3DLqSG6', 'user'),
('Juan',      'Dela Cruz', 'juan@school.edu',    '09281234567', '$2a$10$Xv8wQZlpMNkG5sOjXQ1Xru4t2mKQeH7nJzVNqR0y5YhWkP3DLqSG6', 'user'),
('Rizal',     'Reyes',     'rizal@school.edu',   '09391234567', '$2a$10$Xv8wQZlpMNkG5sOjXQ1Xru4t2mKQeH7nJzVNqR0y5YhWkP3DLqSG6', 'user'),
('Lilis',     'Gomez',     'lilis@school.edu',   '09451234567', '$2a$10$Xv8wQZlpMNkG5sOjXQ1Xru4t2mKQeH7nJzVNqR0y5YhWkP3DLqSG6', 'user'),
('Carlos',    'Tan',        'carlos@school.edu',  '09561234567', '$2a$10$Xv8wQZlpMNkG5sOjXQ1Xru4t2mKQeH7nJzVNqR0y5YhWkP3DLqSG6', 'user'),
('Ana',       'Flores',    'ana@school.edu',     '09671234567', '$2a$10$Xv8wQZlpMNkG5sOjXQ1Xru4t2mKQeH7nJzVNqR0y5YhWkP3DLqSG6', 'user'),
('Pedro',     'Cruz',      'pedro@school.edu',   '09781234567', '$2a$10$Xv8wQZlpMNkG5sOjXQ1Xru4t2mKQeH7nJzVNqR0y5YhWkP3DLqSG6', 'user'),
('Sofia',     'Lim',       'sofia@school.edu',   '09891234567', '$2a$10$Xv8wQZlpMNkG5sOjXQ1Xru4t2mKQeH7nJzVNqR0y5YhWkP3DLqSG6', 'user'),
('Marco',     'Bautista',  'marco@school.edu',   '09901234567', '$2a$10$Xv8wQZlpMNkG5sOjXQ1Xru4t2mKQeH7nJzVNqR0y5YhWkP3DLqSG6', 'user');

-- ──────────────────────────────────────────────────────────
--  SEED: found_items  (30 records)
-- ──────────────────────────────────────────────────────────
INSERT INTO found_items (item_name, description, date_found, location, status, posted_by) VALUES
('Black Tumbler',        'with metal key chain attached',               '2025-12-10', 'Roundball Isulan',  'Available', 'admin@school.edu'),
('Calculator',           'with pink hard case, Casio fx-991',          '2025-11-27', 'Office Room 2',     'Available', 'admin@school.edu'),
('USB Drive',            'SanDisk 32GB, blue color',                   '2025-11-15', 'Library Table 4',   'Available', 'admin@school.edu'),
('Green Water Bottle',   'Hydro Flask, dented on the side',            '2025-11-10', 'Gymnasium',         'Available', 'admin@school.edu'),
('Reading Glasses',      'Black frame, inside a brown case',           '2025-11-08', 'Cafeteria',         'Available', 'admin@school.edu'),
('Yellow Umbrella',      'Foldable, has small scratch on handle',      '2025-11-05', 'Main Gate',         'Claimed',   'admin@school.edu'),
('Red Pencil Case',      'Contains 3 pens and an eraser',              '2025-11-03', 'Room 301',          'Available', 'admin@school.edu'),
('ID Card',              'Name: unknown, faded photo',                 '2025-11-01', 'Hallway Floor 1',   'Available', 'admin@school.edu'),
('Earphones',            'White wired earphones, no brand',            '2025-10-30', 'Library',           'Available', 'admin@school.edu'),
('House Keys',           '3 keys on a ring with red tag',              '2025-10-28', 'Canteen',           'Claimed',   'admin@school.edu'),
('Notebook',             'Green cover, half used, no name written',    '2025-10-25', 'Room 205',          'Available', 'admin@school.edu'),
('Phone Charger',        'Samsung fast charger, Type-C',               '2025-10-22', 'Charging Area',     'Available', 'admin@school.edu'),
('Cap',                  'Black cap with white logo, Nike',            '2025-10-20', 'Sports Area',       'Available', 'admin@school.edu'),
('Wallet',               'Brown leather, no cash inside',              '2025-10-18', 'Restroom Counter',  'Claimed',   'admin@school.edu'),
('Scissors',             'Small, orange handle',                       '2025-10-15', 'Art Room',          'Available', 'admin@school.edu'),
('Lunch Box',            'Blue plastic, has a cat sticker',            '2025-10-12', 'Cafeteria',         'Available', 'admin@school.edu'),
('Wristwatch',           'Silver analog, Casio brand',                 '2025-10-10', 'PE Area',           'Claimed',   'admin@school.edu'),
('Handkerchief',         'White with blue border, smells of perfume',  '2025-10-08', 'Room 102',          'Available', 'admin@school.edu'),
('Geometry Set',         'Complete set in a tin box',                  '2025-10-05', 'Math Room',         'Available', 'admin@school.edu'),
('Highlighter Set',      '4 colors, Stabilo brand',                   '2025-10-03', 'Library',           'Available', 'admin@school.edu'),
('Polo Shirt',           'White polo, medium size, no name tag',       '2025-09-30', 'Gymnasium',         'Available', 'admin@school.edu'),
('Slippers',             'Black rubber slippers, size 8',              '2025-09-28', 'PE Room',           'Available', 'admin@school.edu'),
('Backpack Keychain',    'Small wooden car keychain',                  '2025-09-25', 'Hallway Floor 2',   'Claimed',   'admin@school.edu'),
('Ruler',                '30cm metal ruler, scratched',                '2025-09-22', 'Room 404',          'Available', 'admin@school.edu'),
('Textbook',             'Science Grade 10, brown cover',              '2025-09-20', 'Library',           'Available', 'admin@school.edu'),
('Phone Stand',          'Clear acrylic, foldable',                   '2025-09-18', 'Computer Lab',      'Available', 'admin@school.edu'),
('Gloves',               'One pair, black cotton',                     '2025-09-15', 'Main Entrance',     'Available', 'admin@school.edu'),
('Coin Purse',           'Small red leather, has P50 inside',          '2025-09-12', 'Canteen',           'Claimed',   'admin@school.edu'),
('Comb',                 'Black plastic pocket comb',                  '2025-09-10', 'Restroom',          'Available', 'admin@school.edu'),
('Sticky Notes',         'Yellow pad, half used',                     '2025-09-08', 'Faculty Room',      'Available', 'admin@school.edu');

-- ──────────────────────────────────────────────────────────
--  SEED: lost_items  (80 records)
-- ──────────────────────────────────────────────────────────
INSERT INTO lost_items (user_id, item_name, description, date_lost, location, latitude, longitude, status) VALUES
(2,  'Canvas Tote Bag',    'Beige with a picture of a cat',             '2025-12-11', 'BDO Area',            6.9214,  122.0790, 'Resolved'),
(3,  'Android Phone',      'Samsung A14, cracked screen, blue case',   '2025-11-28', 'Biwang Canteen',      6.9210,  122.0784, 'Resolved'),
(4,  'Laptop Acer i5',     'With huge sticker at the monitor lid',     '2025-11-28', 'Roundball Isulan',    6.9215,  122.0792, 'Resolved'),
(5,  'Blue Backpack',      'Nike backpack, has dog keychain attached', '2025-12-05', 'Canteen Area',        6.9218,  122.0795, 'Pending'),
(6,  'Eyeglasses',         'Black frame, minus 1.5 grade',             '2025-12-01', 'Room 301',            NULL,    NULL,     'Pending'),
(7,  'Jacket',             'Gray hoodie, large size, no brand',        '2025-11-30', 'Library',             6.9212,  122.0788, 'Searching'),
(8,  'Wristwatch',         'Black digital Casio, rubber strap',        '2025-11-25', 'Gymnasium',           6.9220,  122.0796, 'Resolved'),
(9,  'Notebook',           'Red cover, has doodles on back',           '2025-11-22', 'Room 205',            NULL,    NULL,     'Pending'),
(10, 'Charger',            'Type-C white charger, Oppo brand',         '2025-11-20', 'Charging Station',    6.9213,  122.0789, 'Resolved'),
(2,  'Pencil Case',        'Blue with zipper, full of pens',           '2025-11-18', 'Room 401',            NULL,    NULL,     'Pending'),
(3,  'ID Lace',            'Green lace with school ID still attached', '2025-11-15', 'Main Hallway',        6.9216,  122.0793, 'Resolved'),
(4,  'Umbrella',           'Black automatic umbrella, Miniso brand',   '2025-11-12', 'Main Gate',           NULL,    NULL,     'Pending'),
(5,  'Calculator',         'Casio scientific, yellow sticker label',   '2025-11-10', 'Math Room',           6.9211,  122.0787, 'Resolved'),
(6,  'Water Tumbler',      'Stainless steel, blue lid',                '2025-11-08', 'Sports Field',        NULL,    NULL,     'Searching'),
(7,  'Keys',               '2 keys on a ring, no keychain',            '2025-11-05', 'Restroom',            6.9217,  122.0794, 'Pending'),
(8,  'Earbuds',            'Samsung Galaxy buds, white case',          '2025-11-03', 'Canteen',             NULL,    NULL,     'Resolved'),
(9,  'USB Flash Drive',    '16GB Kingston, black cap',                 '2025-11-01', 'Computer Lab',        6.9219,  122.0785, 'Pending'),
(10, 'Textbook',           'English for Academic Purposes, Grade 11',  '2025-10-30', 'Library',             NULL,    NULL,     'Pending'),
(2,  'Polo Shirt',         'White polo with school logo',              '2025-10-28', 'PE Room',             6.9214,  122.0791, 'Searching'),
(3,  'Coin Purse',         'Small brown leather with embossed flower', '2025-10-25', 'Cafeteria',           NULL,    NULL,     'Resolved'),
(4,  'Geometry Set',       'Blue tin box, complete inside',            '2025-10-22', 'Room 303',            6.9215,  122.0782, 'Pending'),
(5,  'Headphones',         'Wired, black, JBL brand',                  '2025-10-20', 'Library',             NULL,    NULL,     'Pending'),
(6,  'Power Bank',         '10000mAh Anker, dark blue',                '2025-10-18', 'Room 102',            6.9218,  122.0796, 'Resolved'),
(7,  'Slippers',           'Black foam slippers, size 7',              '2025-10-15', 'PE Changing Room',    NULL,    NULL,     'Pending'),
(8,  'Scarf',              'Pink knitted scarf, long',                 '2025-10-12', 'Admin Office',        6.9211,  122.0788, 'Searching'),
(9,  'Cap',                'Red cap, Adidas, bent brim',               '2025-10-10', 'Sports Area',         NULL,    NULL,     'Pending'),
(10, 'Lunch Box',          'Orange bento box with two compartments',   '2025-10-08', 'Cafeteria Table 5',   6.9216,  122.0793, 'Resolved'),
(2,  'Highlighter',        'Pink Stabilo, nearly empty',               '2025-10-05', 'Room 201',            NULL,    NULL,     'Pending'),
(3,  'Mouse',              'Wireless Logitech, black',                 '2025-10-03', 'Computer Lab',        6.9214,  122.0790, 'Resolved'),
(4,  'Scissors',           'Large silver scissors, red handle',        '2025-09-30', 'Art Room',            NULL,    NULL,     'Pending'),
(5,  'Bracelet',           'Gold-colored thin bangle',                 '2025-09-28', 'Room 404',            6.9213,  122.0789, 'Pending'),
(6,  'Ruler',              '50cm transparent plastic ruler',           '2025-09-25', 'Room 302',            NULL,    NULL,     'Resolved'),
(7,  'Book',               'Novel "Noli Me Tangere" soft cover',       '2025-09-22', 'Library',             6.9215,  122.0792, 'Pending'),
(8,  'Lanyard',            'Yellow school lanyard, no ID',             '2025-09-20', 'Hallway Floor 3',     NULL,    NULL,     'Pending'),
(9,  'Spectacles Case',    'Black hard case, empty inside',            '2025-09-18', 'Room 105',            6.9220,  122.0785, 'Resolved'),
(10, 'Phone',              'iPhone SE, black, small crack at back',    '2025-09-15', 'Gymnasium',           NULL,    NULL,     'Searching'),
(2,  'Wired Earphones',    'White, has foam eartips, Apple brand',     '2025-09-12', 'Library',             6.9212,  122.0788, 'Pending'),
(3,  'Art Supplies Bag',   'Clear zip bag with crayons and markers',   '2025-09-10', 'Art Room',            NULL,    NULL,     'Pending'),
(4,  'ID',                 'School ID with blue lanyard',              '2025-09-08', 'Canteen',             6.9217,  122.0794, 'Resolved'),
(5,  'Ballpen',            'Parker branded, black ink, silver body',   '2025-09-05', 'Office',              NULL,    NULL,     'Pending'),
(6,  'Gloves',             'Black cotton gloves, pair',                '2025-09-03', 'Main Entrance',       6.9214,  122.0791, 'Pending'),
(7,  'Notebook',           'Spiral notebook, yellow, Grade 10 Sci',    '2025-09-01', 'Room 402',            NULL,    NULL,     'Resolved'),
(8,  'Tote Bag',           'Black canvas tote, no design',             '2025-08-30', 'Library',             6.9211,  122.0787, 'Pending'),
(9,  'Scissors',           'Small craft scissors, green handle',       '2025-08-28', 'Art Room',            NULL,    NULL,     'Pending'),
(10, 'Umbrella',           'Purple polka dot umbrella',                '2025-08-25', 'Main Gate',           6.9218,  122.0795, 'Searching'),
(2,  'Belt',               'Black leather belt, metal buckle',         '2025-08-22', 'Restroom',            NULL,    NULL,     'Pending'),
(3,  'Folder',             'Clear plastic folder, papers inside',      '2025-08-20', 'Office',              6.9216,  122.0793, 'Resolved'),
(4,  'Comb',               'Black wide-tooth comb',                    '2025-08-18', 'Restroom',            NULL,    NULL,     'Pending'),
(5,  'Eraser',             'Big white eraser, Staedtler',              '2025-08-15', 'Room 201',            6.9213,  122.0789, 'Pending'),
(6,  'Mechanical Pencil',  '0.5mm Pentel pencil, green',               '2025-08-12', 'Room 303',            NULL,    NULL,     'Resolved'),
(7,  'School Bag',         'Blue trolley bag, brand unknown',          '2025-08-10', 'Main Hallway',        6.9219,  122.0785, 'Pending'),
(8,  'Phone Case',         'Clear silicone case with cat design',      '2025-08-08', 'Canteen',             NULL,    NULL,     'Pending'),
(9,  'Lip Balm',           'Vaseline brand, small tube',               '2025-08-05', 'Restroom',            6.9214,  122.0790, 'Resolved'),
(10, 'Sunglasses',         'Black aviator sunglasses, no case',        '2025-08-03', 'Sports Area',         NULL,    NULL,     'Pending'),
(2,  'Polo',               'Checkered blue polo, medium',              '2025-08-01', 'PE Area',             6.9215,  122.0792, 'Searching'),
(3,  'Sticky Notes',       'Pack of yellow stickies, used half',       '2025-07-30', 'Faculty Room',        NULL,    NULL,     'Pending'),
(4,  'Pocket Dictionary',  'English-Filipino, small paperback',        '2025-07-28', 'Library',             6.9212,  122.0788, 'Resolved'),
(5,  'Chair Cushion',      'Small round cushion, gray',                '2025-07-25', 'Room 504',            NULL,    NULL,     'Pending'),
(6,  'Extension Cord',     '2-meter white cord, 3 sockets',            '2025-07-22', 'Computer Lab',        6.9217,  122.0794, 'Pending'),
(7,  'Tablet',             'Android tablet, black, cracked screen',    '2025-07-20', 'Library Study Area',  NULL,    NULL,     'Searching'),
(8,  'Lunchbag',           'Insulated black bag, zipper damaged',      '2025-07-18', 'Cafeteria',           6.9220,  122.0796, 'Resolved'),
(9,  'Notebook',           'Composition notebook, no cover',           '2025-07-15', 'Room 101',            NULL,    NULL,     'Pending'),
(10, 'Airpods Case',       'White AirPods case, no earbuds inside',    '2025-07-12', 'Gymnasium Bleachers', 6.9213,  122.0789, 'Pending'),
(2,  'Ring',               'Silver ring, small stone on top',          '2025-07-10', 'Restroom',            NULL,    NULL,     'Resolved'),
(3,  'Shoes',              'White rubber shoes, size 6, no laces',     '2025-07-08', 'PE Room',             6.9215,  122.0782, 'Pending'),
(4,  'Watch',              'Gold analog watch, leather strap',         '2025-07-05', 'Canteen',             NULL,    NULL,     'Pending'),
(5,  'Comic Book',         'Tagalog komiks, old, torn cover',          '2025-07-03', 'Library',             6.9218,  122.0795, 'Resolved'),
(6,  'Perfume',            'Small bottle, floral scent',               '2025-07-01', 'Restroom',            NULL,    NULL,     'Pending'),
(7,  'Bag Tag',            'Colorful bag tag, initials CML',           '2025-06-28', 'Hallway',             6.9214,  122.0791, 'Resolved'),
(8,  'Earring',            'Single gold hoop earring',                 '2025-06-25', 'Room 302',            NULL,    NULL,     'Pending'),
(9,  'Pen Holder',         'Clay-made, blue, cracked slightly',        '2025-06-22', 'Faculty Room',        6.9211,  122.0787, 'Pending'),
(10, 'Jacket',             'Black waterproof jacket, L size',          '2025-06-20', 'Main Gate',           NULL,    NULL,     'Searching'),
(2,  'Calculator Cover',   'Hard plastic cover for Casio',             '2025-06-18', 'Math Room',           6.9216,  122.0793, 'Resolved'),
(3,  'Necklace',           'Thin silver chain, no pendant',            '2025-06-15', 'Gymnasium',           NULL,    NULL,     'Pending'),
(4,  'Paper Fan',          'Folded paper fan, painted flowers',        '2025-06-12', 'Cafeteria',           6.9219,  122.0785, 'Pending'),
(5,  'Lab Gown',           'White lab gown, stained at sleeve',        '2025-06-10', 'Science Lab',         NULL,    NULL,     'Resolved'),
(6,  'Knee Pad',           'Black sports knee pad, one piece',         '2025-06-08', 'Sports Area',         6.9212,  122.0788, 'Pending'),
(7,  'Colored Pencils',    'Box of 24 colors, Faber-Castell',          '2025-06-05', 'Art Room',            NULL,    NULL,     'Pending'),
(8,  'Diary',              'Small pink diary with lock, no key',       '2025-06-03', 'Room 201',            6.9214,  122.0790, 'Resolved'),
(9,  'Polo Uniform',       'School uniform polo, name tag removed',    '2025-06-01', 'PE Area',             NULL,    NULL,     'Pending'),
(10, 'Badge Holder',       'Clear hard case badge holder, cracked',    '2025-05-30', 'Main Office',         6.9215,  122.0792, 'Pending');

-- ──────────────────────────────────────────────────────────
--  SEED: audit_logs  (40 records)
-- ──────────────────────────────────────────────────────────
INSERT INTO audit_logs (user_id, username, action, target_table, target_id, created_at) VALUES
(1, 'admin@school.edu',  'LOGIN',                     'users',       1,  '2025-12-13 08:00:00'),
(2, 'maria@school.edu',  'LOGIN',                     'users',       2,  '2025-12-13 08:05:12'),
(1, 'admin@school.edu',  'CREATE_FOUND_ITEM',         'found_items', 1,  '2025-12-13 08:10:33'),
(5, 'lilis@school.edu',  'REPORT_LOST_ITEM',          'lost_items',  1,  '2025-12-13 08:15:44'),
(1, 'admin@school.edu',  'STATUS_CHANGE_TO_RESOLVED', 'lost_items',  1,  '2025-12-13 09:00:01'),
(3, 'juan@school.edu',   'LOGIN',                     'users',       3,  '2025-12-12 09:10:00'),
(4, 'rizal@school.edu',  'REPORT_LOST_ITEM',          'lost_items',  3,  '2025-12-12 09:15:55'),
(1, 'admin@school.edu',  'CREATE_FOUND_ITEM',         'found_items', 2,  '2025-12-12 10:00:00'),
(1, 'admin@school.edu',  'STATUS_CHANGE_TO_RESOLVED', 'lost_items',  3,  '2025-12-12 11:30:00'),
(6, 'carlos@school.edu', 'REGISTER',                  'users',       6,  '2025-12-11 14:00:00'),
(6, 'carlos@school.edu', 'LOGIN',                     'users',       6,  '2025-12-11 14:01:00'),
(6, 'carlos@school.edu', 'REPORT_LOST_ITEM',          'lost_items',  5,  '2025-12-11 14:05:00'),
(1, 'admin@school.edu',  'DELETE_FOUND_ITEM',         'found_items', 6,  '2025-12-10 10:00:00'),
(7, 'ana@school.edu',    'LOGIN',                     'users',       7,  '2025-12-10 11:00:00'),
(7, 'ana@school.edu',    'REPORT_LOST_ITEM',          'lost_items',  7,  '2025-12-10 11:05:00'),
(1, 'admin@school.edu',  'UPDATE_FOUND_ITEM',         'found_items', 4,  '2025-12-09 09:00:00'),
(8, 'pedro@school.edu',  'LOGIN',                     'users',       8,  '2025-12-09 10:00:00'),
(8, 'pedro@school.edu',  'REPORT_LOST_ITEM',          'lost_items',  8,  '2025-12-09 10:10:00'),
(1, 'admin@school.edu',  'STATUS_CHANGE_TO_RESOLVED', 'lost_items',  8,  '2025-12-09 14:00:00'),
(9, 'sofia@school.edu',  'REGISTER',                  'users',       9,  '2025-12-08 13:00:00'),
(9, 'sofia@school.edu',  'LOGIN',                     'users',       9,  '2025-12-08 13:01:00'),
(9, 'sofia@school.edu',  'REPORT_LOST_ITEM',          'lost_items',  9,  '2025-12-08 13:05:00'),
(1, 'admin@school.edu',  'LOGIN',                     'users',       1,  '2025-12-08 08:00:00'),
(1, 'admin@school.edu',  'CREATE_FOUND_ITEM',         'found_items', 3,  '2025-12-08 08:30:00'),
(10,'marco@school.edu',  'LOGIN',                     'users',       10, '2025-12-07 09:00:00'),
(10,'marco@school.edu',  'REPORT_LOST_ITEM',          'lost_items',  10, '2025-12-07 09:10:00'),
(1, 'admin@school.edu',  'STATUS_CHANGE_TO_SEARCHING','lost_items',  14, '2025-12-07 10:00:00'),
(2, 'maria@school.edu',  'LOGIN',                     'users',       2,  '2025-12-06 08:00:00'),
(2, 'maria@school.edu',  'REPORT_LOST_ITEM',          'lost_items',  11, '2025-12-06 08:10:00'),
(1, 'admin@school.edu',  'STATUS_CHANGE_TO_RESOLVED', 'lost_items',  11, '2025-12-06 11:00:00'),
(3, 'juan@school.edu',   'LOGIN',                     'users',       3,  '2025-12-05 09:00:00'),
(4, 'rizal@school.edu',  'LOGIN',                     'users',       4,  '2025-12-05 09:05:00'),
(1, 'admin@school.edu',  'DELETE_LOST_ITEM',          'lost_items',  15, '2025-12-05 15:00:00'),
(1, 'admin@school.edu',  'CREATE_FOUND_ITEM',         'found_items', 5,  '2025-12-04 09:00:00'),
(5, 'lilis@school.edu',  'LOGIN',                     'users',       5,  '2025-12-04 09:30:00'),
(5, 'lilis@school.edu',  'REPORT_LOST_ITEM',          'lost_items',  20, '2025-12-04 09:35:00'),
(1, 'admin@school.edu',  'UPDATE_LOST_ITEM',          'lost_items',  20, '2025-12-04 12:00:00'),
(6, 'carlos@school.edu', 'LOGIN',                     'users',       6,  '2025-12-03 10:00:00'),
(7, 'ana@school.edu',    'LOGIN',                     'users',       7,  '2025-12-03 10:30:00'),
(1, 'admin@school.edu',  'STATUS_CHANGE_TO_RESOLVED', 'lost_items',  20, '2025-12-03 14:00:00');
