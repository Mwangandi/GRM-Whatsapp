const Database = require('better-sqlite3');
const path = require('path');

// Initialize database
const dbPath = path.join(__dirname, 'grm.db');
const db = new Database(dbPath);

// Enable foreign keys
db.pragma('foreign_keys = ON');

/**
 * Initialize database schema
 */
function initializeDatabase() {
  // Sessions table - stores user conversation state
  db.exec(`
    CREATE TABLE IF NOT EXISTS sessions (
      phone TEXT PRIMARY KEY,
      step TEXT,
      feedback_type TEXT,
      grievance_category TEXT,
      description TEXT,
      ref_no TEXT,
      id TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  `);

  // Grievances table - stores submitted grievances
  db.exec(`
    CREATE TABLE IF NOT EXISTS grievances (
      id TEXT PRIMARY KEY,
      phone TEXT,
      ref_no TEXT UNIQUE,
      feedback_type TEXT,
      category TEXT,
      description TEXT,
      status TEXT DEFAULT 'open',
      department TEXT,
      assigned_to TEXT,
      priority TEXT DEFAULT 'normal',
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      resolved_at DATETIME,
      resolution_notes TEXT
    )
  `);

  // Follow-ups table - tracks grievance follow-ups
  db.exec(`
    CREATE TABLE IF NOT EXISTS follow_ups (
      id TEXT PRIMARY KEY,
      grievance_id TEXT,
      message TEXT,
      status TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (grievance_id) REFERENCES grievances(id)
    )
  `);

  console.log('✓ Database initialized at:', dbPath);
}

/**
 * Get or create a session
 * @param {string} phone - Customer phone number
 * @returns {object|null} Session object
 */
function getSession(phone) {
  const stmt = db.prepare('SELECT * FROM sessions WHERE phone = ?');
  return stmt.get(phone);
}

/**
 * Save or update session
 * @param {string} phone - Customer phone number
 * @param {object} data - Session data to update
 */
function saveSession(phone, data) {
  const existing = getSession(phone);
  
  if (existing) {
    const updates = Object.keys(data).map(key => `${key} = ?`).join(', ');
    const values = Object.values(data);
    const stmt = db.prepare(`UPDATE sessions SET ${updates}, updated_at = CURRENT_TIMESTAMP WHERE phone = ?`);
    stmt.run(...values, phone);
  } else {
    const keys = Object.keys(data).join(', ');
    const placeholders = Object.keys(data).map(() => '?').join(', ');
    const values = Object.values(data);
    const stmt = db.prepare(`INSERT INTO sessions (phone, ${keys}) VALUES (?, ${placeholders})`);
    stmt.run(phone, ...values);
  }
}

/**
 * Delete a session
 * @param {string} phone - Customer phone number
 */
function deleteSession(phone) {
  const stmt = db.prepare('DELETE FROM sessions WHERE phone = ?');
  stmt.run(phone);
}

/**
 * Save a grievance
 * @param {object} grievance - Grievance object
 */
function saveGrievance(grievance) {
  const keys = Object.keys(grievance).join(', ');
  const placeholders = Object.keys(grievance).map(() => '?').join(', ');
  const values = Object.values(grievance);
  
  const stmt = db.prepare(`INSERT INTO grievances (${keys}) VALUES (${placeholders})`);
  stmt.run(...values);
}

/**
 * Get grievance by reference number
 * @param {string} refNo - Reference number
 * @returns {object|null} Grievance object
 */
function getGrievance(refNo) {
  const stmt = db.prepare('SELECT * FROM grievances WHERE ref_no = ?');
  return stmt.get(refNo);
}

/**
 * Get grievance by ID
 * @param {string} id - Grievance ID
 * @returns {object|null} Grievance object
 */
function getGrievanceById(id) {
  const stmt = db.prepare('SELECT * FROM grievances WHERE id = ?');
  return stmt.get(id);
}

/**
 * Update grievance status
 * @param {string} refNo - Reference number
 * @param {string} status - New status
 * @param {string} notes - Resolution notes (optional)
 */
function updateGrievanceStatus(refNo, status, notes = null) {
  let stmt;
  if (notes) {
    stmt = db.prepare(`
      UPDATE grievances 
      SET status = ?, resolution_notes = ?, resolved_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP 
      WHERE ref_no = ?
    `);
    stmt.run(status, notes, refNo);
  } else {
    stmt = db.prepare(`
      UPDATE grievances 
      SET status = ?, updated_at = CURRENT_TIMESTAMP 
      WHERE ref_no = ?
    `);
    stmt.run(status, refNo);
  }
}

/**
 * Get session by reference number
 * @param {string} refNo - Reference number
 * @returns {object|null} Session object
 */
function getSessionByRefNo(refNo) {
  const stmt = db.prepare('SELECT * FROM sessions WHERE ref_no = ?');
  return stmt.get(refNo);
}

/**
 * Add follow-up
 * @param {string} grievanceId - Grievance ID
 * @param {string} message - Follow-up message
 * @param {string} status - Follow-up status
 */
function addFollowUp(grievanceId, message, status) {
  const id = `fup_${Date.now()}`;
  const stmt = db.prepare(`
    INSERT INTO follow_ups (id, grievance_id, message, status)
    VALUES (?, ?, ?, ?)
  `);
  stmt.run(id, grievanceId, message, status);
}

module.exports = {
  db,
  initializeDatabase,
  getSession,
  saveSession,
  deleteSession,
  saveGrievance,
  getGrievance,
  getGrievanceById,
  updateGrievanceStatus,
  getSessionByRefNo,
  addFollowUp
};
