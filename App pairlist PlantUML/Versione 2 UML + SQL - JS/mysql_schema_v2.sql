
-- MySQL Schema (v2) — Email Ingest + Drafts | DB: app_suite
CREATE DATABASE IF NOT EXISTS app_suite CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE app_suite;
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS email_attachments;
DROP TABLE IF EXISTS inbound_emails;
DROP TABLE IF EXISTS stores;
DROP TABLE IF EXISTS loyalty_cards;
DROP TABLE IF EXISTS reminders;
DROP TABLE IF EXISTS warranties;
DROP TABLE IF EXISTS receipts;
DROP TABLE IF EXISTS assets;
DROP TABLE IF EXISTS event_guests;
DROP TABLE IF EXISTS events;
DROP TABLE IF EXISTS list_items;
DROP TABLE IF EXISTS sections;
DROP TABLE IF EXISTS lists;
DROP TABLE IF EXISTS invites;
DROP TABLE IF EXISTS pair_members;
DROP TABLE IF EXISTS pairs;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  email_alias VARCHAR(64) NULL UNIQUE,
  pwd_hash VARCHAR(255) NOT NULL,
  name VARCHAR(120) NOT NULL,
  plan ENUM('free','pro','family','business') NOT NULL DEFAULT 'free',
  twofa_secret VARCHAR(64) NULL,
  created_at DATETIME NULL,
  updated_at DATETIME NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE pairs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  owner_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(120) NOT NULL,
  created_at DATETIME NULL,
  updated_at DATETIME NULL,
  INDEX idx_pairs_owner (owner_id),
  CONSTRAINT fk_pairs_owner FOREIGN KEY(owner_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE pair_members (
  pair_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  role ENUM('owner','member') NOT NULL,
  joined_at DATETIME NOT NULL,
  PRIMARY KEY (pair_id, user_id),
  CONSTRAINT fk_pm_pair FOREIGN KEY(pair_id) REFERENCES pairs(id) ON DELETE CASCADE,
  CONSTRAINT fk_pm_user FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE invites (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  type ENUM('pair','event') NOT NULL,
  creator_id BIGINT UNSIGNED NOT NULL,
  token CHAR(32) NOT NULL UNIQUE,
  target_email VARCHAR(255) NOT NULL,
  status ENUM('pending','accepted','expired') NOT NULL DEFAULT 'pending',
  expires_at DATETIME NOT NULL,
  created_at DATETIME NULL,
  INDEX idx_invites_creator (creator_id),
  CONSTRAINT fk_invites_creator FOREIGN KEY(creator_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE lists (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pair_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(120) NOT NULL,
  is_archived TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME NULL,
  updated_at DATETIME NULL,
  INDEX idx_lists_pair (pair_id),
  INDEX idx_lists_arch (is_archived),
  CONSTRAINT fk_lists_pair FOREIGN KEY(pair_id) REFERENCES pairs(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE sections (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  list_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(64) NOT NULL,
  icon VARCHAR(32) NULL,
  color VARCHAR(16) NULL,
  position INT NOT NULL DEFAULT 0,
  is_default TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME NULL,
  updated_at DATETIME NULL,
  INDEX idx_sections_list_pos (list_id, position),
  CONSTRAINT fk_sections_list FOREIGN KEY(list_id) REFERENCES lists(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE list_items (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  list_id BIGINT UNSIGNED NOT NULL,
  section_id BIGINT UNSIGNED NULL,
  title VARCHAR(255) NOT NULL,
  notes TEXT NULL,
  qty DECIMAL(10,2) NULL,
  unit VARCHAR(16) NULL,
  dept VARCHAR(32) NULL,
  is_pantry TINYINT(1) NOT NULL DEFAULT 0,
  assigned_to BIGINT UNSIGNED NULL,
  is_done TINYINT(1) NOT NULL DEFAULT 0,
  position INT NOT NULL DEFAULT 0,
  due_at DATETIME NULL,
  mongo_ref CHAR(24) NULL,
  created_at DATETIME NULL,
  updated_at DATETIME NULL,
  FULLTEXT KEY ft_items (title, notes),
  INDEX idx_items_done (is_done),
  INDEX idx_items_order (list_id, section_id, position),
  CONSTRAINT fk_items_list FOREIGN KEY(list_id) REFERENCES lists(id) ON DELETE CASCADE,
  CONSTRAINT fk_items_section FOREIGN KEY(section_id) REFERENCES sections(id) ON DELETE SET NULL,
  CONSTRAINT fk_items_assignee FOREIGN KEY(assigned_to) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE events (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  owner_id BIGINT UNSIGNED NOT NULL,
  title VARCHAR(255) NOT NULL,
  start_at DATETIME NOT NULL,
  end_at DATETIME NOT NULL,
  location VARCHAR(255) NULL,
  lat DECIMAL(9,6) NULL,
  lng DECIMAL(9,6) NULL,
  notes TEXT NULL,
  ics_hash CHAR(32) NULL,
  public_hash CHAR(12) NOT NULL UNIQUE,
  mongo_ref CHAR(24) NULL,
  created_at DATETIME NULL,
  updated_at DATETIME NULL,
  INDEX idx_events_owner_start (owner_id, start_at),
  CONSTRAINT fk_events_owner FOREIGN KEY(owner_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE event_guests (
  event_id BIGINT UNSIGNED NOT NULL,
  guest VARCHAR(255) NOT NULL,
  status ENUM('invited','accepted','declined') NOT NULL DEFAULT 'invited',
  PRIMARY KEY (event_id, guest),
  CONSTRAINT fk_evt_guest_event FOREIGN KEY(event_id) REFERENCES events(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE assets (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  owner_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(255) NOT NULL,
  category VARCHAR(64) NULL,
  brand VARCHAR(64) NULL,
  model VARCHAR(64) NULL,
  serial VARCHAR(64) NULL,
  purchase_date DATE NULL,
  price DECIMAL(10,2) NULL,
  notes TEXT NULL,
  mongo_ref CHAR(24) NULL,
  created_at DATETIME NULL,
  updated_at DATETIME NULL,
  INDEX idx_assets_owner (owner_id),
  CONSTRAINT fk_assets_owner FOREIGN KEY(owner_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE receipts (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  item_id BIGINT UNSIGNED NULL,
  file_url VARCHAR(255) NOT NULL,
  source ENUM('email','share_ext','browser_ext','upload') NOT NULL,
  status ENUM('draft','confirmed') NOT NULL DEFAULT 'draft',
  vendor VARCHAR(128) NULL,
  doc_date DATE NULL,
  doc_number VARCHAR(64) NULL,
  tax_id VARCHAR(32) NULL,
  total DECIMAL(10,2) NULL,
  mongo_ref CHAR(24) NULL,
  created_at DATETIME NULL,
  updated_at DATETIME NULL,
  INDEX idx_receipts_item (item_id),
  INDEX idx_receipts_status (status),
  CONSTRAINT fk_receipts_item FOREIGN KEY(item_id) REFERENCES assets(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE warranties (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  item_id BIGINT UNSIGNED NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  terms TEXT NULL,
  vendor_contact VARCHAR(255) NULL,
  INDEX idx_warranties_item (item_id),
  INDEX idx_warranties_end (end_date),
  CONSTRAINT fk_warranties_item FOREIGN KEY(item_id) REFERENCES assets(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE reminders (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  related_type ENUM('warranty','event','list_item') NOT NULL,
  related_id BIGINT UNSIGNED NOT NULL,
  due_at DATETIME NOT NULL,
  status ENUM('pending','sent','dismissed') NOT NULL DEFAULT 'pending',
  INDEX idx_reminders_due (due_at),
  INDEX idx_reminders_related (related_type, related_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE loyalty_cards (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  owner_id BIGINT UNSIGNED NOT NULL,
  store_name VARCHAR(128) NOT NULL,
  barcode_format ENUM('EAN13','CODE128','QR','PDF417','EAN8','CODE39') NOT NULL,
  code_value VARCHAR(64) NOT NULL,
  color VARCHAR(16) NULL,
  notes VARCHAR(255) NULL,
  created_at DATETIME NULL,
  INDEX idx_loyalty_owner (owner_id),
  INDEX idx_loyalty_store (store_name),
  CONSTRAINT fk_loyalty_owner FOREIGN KEY(owner_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE stores (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(128) NOT NULL,
  brand VARCHAR(64) NULL,
  address VARCHAR(255) NULL,
  lat DECIMAL(9,6) NULL,
  lng DECIMAL(9,6) NULL,
  created_at DATETIME NULL,
  INDEX idx_stores_name (name),
  INDEX idx_stores_brand (brand)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE inbound_emails (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  from_email VARCHAR(255) NOT NULL,
  to_email VARCHAR(255) NOT NULL,
  subject VARCHAR(255) NULL,
  storage_ref VARCHAR(255) NULL,
  received_at DATETIME NOT NULL,
  created_at DATETIME NULL,
  INDEX idx_inbound_user (user_id, received_at),
  CONSTRAINT fk_inbound_user FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE email_attachments (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  inbound_id BIGINT UNSIGNED NOT NULL,
  filename VARCHAR(255) NOT NULL,
  mime VARCHAR(128) NOT NULL,
  size_bytes INT UNSIGNED NOT NULL,
  storage_ref VARCHAR(255) NOT NULL,
  CONSTRAINT fk_attach_inbound FOREIGN KEY(inbound_id) REFERENCES inbound_emails(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS = 1;
