require('dotenv').config();
const express = require('express');
const path = require('path');
const { handleMessage } = require('./flow');
const { initializeDatabase, db, getGrievance } = require('./db');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true })); // Required for Twilio webhooks
app.use(express.static(path.join(__dirname, 'public')));

// Initialize database
initializeDatabase();

/**
 * GET /dashboard
 * Serve the admin dashboard
 */
app.get('/dashboard', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'dashboard.html'));
});

/**
 * GET /api/grievances
 * Get all grievances (sorted by most recent)
 */
app.get('/api/grievances', (req, res) => {
  try {
    const stmt = db.prepare(`
      SELECT * FROM grievances 
      ORDER BY created_at DESC 
      LIMIT 100
    `);
    const grievances = stmt.all();
    res.json(grievances);
  } catch (error) {
    console.error('Error fetching grievances:', error.message);
    res.status(500).json({ error: error.message });
  }
});

/**
 * GET /api/stats
 * Get dashboard statistics
 */
app.get('/api/stats', (req, res) => {
  try {
    // Total grievances
    const totalStmt = db.prepare('SELECT COUNT(*) as count FROM grievances');
    const totalGrievances = totalStmt.get().count;

    // Open grievances
    const openStmt = db.prepare("SELECT COUNT(*) as count FROM grievances WHERE status = 'open'");
    const openGrievances = openStmt.get().count;

    // In progress
    const inProgressStmt = db.prepare("SELECT COUNT(*) as count FROM grievances WHERE status = 'in_progress'");
    const inProgressGrievances = inProgressStmt.get().count;

    // Resolved grievances
    const resolvedStmt = db.prepare("SELECT COUNT(*) as count FROM grievances WHERE status = 'resolved'");
    const resolvedGrievances = resolvedStmt.get().count;

    // Resolution rate
    const resolutionRate = totalGrievances > 0 ? resolvedGrievances / totalGrievances : 0;

    res.json({
      totalGrievances,
      openGrievances,
      inProgressGrievances,
      resolvedGrievances,
      resolutionRate
    });
  } catch (error) {
    console.error('Error calculating stats:', error.message);
    res.status(500).json({ error: error.message });
  }
});

/**
 * GET /api/grievance/:refNo
 * Get a specific grievance
 */
app.get('/api/grievance/:refNo', (req, res) => {
  try {
    const stmt = db.prepare('SELECT * FROM grievances WHERE ref_no = ?');
    const grievance = stmt.get(req.params.refNo);

    if (!grievance) {
      return res.status(404).json({ error: 'Grievance not found' });
    }

    res.json(grievance);
  } catch (error) {
    console.error('Error fetching grievance:', error.message);
    res.status(500).json({ error: error.message });
  }
});

/**
 * Health check endpoint
 */
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date(),
    service: 'GRM WhatsApp Bot'
  });
});

/**
 * POST /webhook
 * Receive incoming WhatsApp messages from Twilio
 * 
 * Twilio sends form-encoded data:
 * - From: "whatsapp:+254795752053"
 * - To: "whatsapp:+14155238886"
 * - Body: "message text"
 * - MessageSid: "SMxxxxxxxxx"
 */
app.post('/webhook', (req, res) => {
  // Always respond 200 immediately to avoid Twilio retrying
  res.status(200).send('ok');

  try {
    const body = req.body;

    // Twilio sends From with 'whatsapp:' prefix
    const from = body.From; // e.g., "whatsapp:+254795752053"
    const messageText = body.Body;

    if (!from || !messageText) {
      console.log('Invalid webhook structure - missing From or Body');
      return;
    }

    // Extract phone number without 'whatsapp:' prefix
    const phone = from.replace('whatsapp:', '');

    console.log(`\n📨 Message received from ${phone}: "${messageText}"`);

    // Process message asynchronously
    handleMessage(phone, messageText).catch(error => {
      console.error('Error processing message:', error.message);
    });
  } catch (error) {
    console.error('Error in POST /webhook:', error.message);
  }
});

/**
 * GET /api/test-message
 * Debug endpoint to test sending a message
 */
app.get('/api/test-message', async (req, res) => {
  try {
    const { phone, message } = req.query;
    
    if (!phone || !message) {
      return res.status(400).json({
        error: 'Missing phone or message query parameters',
        example: '/api/test-message?phone=+254795752053&message=Hello%20World'
      });
    }

    const { sendMessage } = require('./whatsapp');
    const result = await sendMessage(phone, message);
    
    res.json({
      success: true,
      message: 'Test message sent successfully',
      result: result
    });
  } catch (error) {
    console.error('Test message error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * Start server
 */
app.listen(PORT, () => {
  console.log('\n✓ GRM WhatsApp Bot starting...');
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📊 Dashboard: http://localhost:${PORT}/dashboard`);
  console.log(`🔗 Webhook URL: http://localhost:${PORT}/webhook`);
  console.log(`❤️  Health check: http://localhost:${PORT}/health`);
  console.log('\nWaiting for messages...\n');
});
