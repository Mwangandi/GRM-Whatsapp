# GRM WhatsApp Bot - Grievance Redress Management System

A WhatsApp-based Grievance Redress Management (GRM) system built with **Twilio's WhatsApp API**, Node.js, Express, and SQLite.

## Features

- **Complaint Submission** - Users can file grievances via WhatsApp with categorization
- **Status Tracking** - Citizens can track their complaints using reference numbers
- **Automated Responses** - Instant acknowledgment and status updates
- **Admin Dashboard** - Real-time grievance monitoring and analytics
- **SQLite Database** - Persistent storage of grievances and user sessions
- **Webhook Integration** - Twilio handles all incoming/outgoing messages

## Project Structure

```
GRM-whatsapp/
├── index.js              # Express server & webhook handler
├── whatsapp.js           # Twilio WhatsApp API wrapper
├── db.js                 # SQLite database & session management
├── flow.js               # Conversation flow & business logic
├── package.json          # Dependencies
├── .env                  # Environment configuration (create this)
├── grm.db                # SQLite database (auto-created)
└── public/
    └── dashboard.html    # Admin dashboard UI
```

## Setup Instructions

### 1. Install Dependencies

```bash
cd /home/pantech-support/Desktop/GRM-whatsapp
npm install
```

### 2. Configure Twilio

1. Sign up for a [Twilio account](https://www.twilio.com)
2. Go to **WhatsApp Sandbox** in the Twilio console
3. Get your:
   - `TWILIO_ACCOUNT_SID`
   - `TWILIO_AUTH_TOKEN`
   - `TWILIO_WHATSAPP_NUMBER` (should be: `whatsapp:+14155238886` for sandbox)

4. Join the sandbox by sending `join trick-up` to **+1 415-523-8886** on WhatsApp

### 3. Update .env File

Create/edit `.env`:

```env
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your_auth_token_here
TWILIO_WHATSAPP_NUMBER=whatsapp:+14155238886

PORT=3000
COUNTY_NAME=Mombasa County
```

### 4. Set Webhook URL in Twilio

1. In Twilio Console → WhatsApp → Sandbox Settings
2. Set **Webhook URL**: `https://your-domain.com/webhook`
3. (For local testing, use ngrok: `ngrok http 3000`, then use the generated URL)

### 5. Run the Bot

```bash
npm start
```

The server will start on port 3000 and output:
```
✓ GRM WhatsApp Bot starting...
🚀 Server running on port 3000
📊 Dashboard: http://localhost:3000/dashboard
🔗 Webhook URL: http://localhost:3000/webhook
❤️ Health check: http://localhost:3000/health
```

## User Flow

### Submitting a Grievance

1. User sends any message to **+1 415-523-8886** (Twilio sandbox number)
2. Bot responds with welcome menu
3. User selects **SUBMIT** (option 1)
4. User describes the issue
5. User selects a category (Service Quality, Staff Conduct, etc.)
6. Bot generates reference number
7. User confirms submission
8. Bot sends confirmation with reference number

### Tracking a Grievance

1. User sends **TRACK** (option 2)
2. User enters reference number (e.g., `GRM-2026-0001`)
3. Bot displays current status and notes

## API Endpoints

### Dashboard & Data

- `GET /dashboard` - Admin dashboard UI
- `GET /api/stats` - Dashboard statistics
- `GET /api/grievances` - List all grievances
- `GET /api/grievance/:refNo` - Get specific grievance

### Testing

- `GET /api/test-message?phone=+254795752053&message=Hello` - Send test message
- `GET /health` - Health check

### Webhooks

- `POST /webhook` - Receive messages from Twilio (auto-configured)

## Database Schema

### sessions
- `phone` - User's WhatsApp number (PRIMARY KEY)
- `step` - Current conversation step
- `grievance_category` - Selected category
- `description` - Grievance description
- `ref_no` - Reference number
- `created_at`, `updated_at` - Timestamps

### grievances
- `id` - Unique ID
- `phone` - Submitter's number
- `ref_no` - Public reference (UNIQUE)
- `category` - Grievance category
- `description` - Full description
- `status` - open/in_progress/resolved/closed
- `department` - Assigned department
- `priority` - normal/high/urgent
- `resolution_notes` - Admin notes
- `created_at`, `updated_at`, `resolved_at` - Timestamps

### follow_ups
- `id` - Follow-up ID
- `grievance_id` - FK to grievances
- `message` - Follow-up message
- `status` - Follow-up status
- `created_at` - Timestamp

## Differences from Meta WhatsApp API

| Feature | Meta | Twilio |
|---------|------|--------|
| **Message Format** | JSON body | Form-encoded body |
| **Sender Format** | `254712345678` | `whatsapp:+254712345678` |
| **Webhook Verification** | GET request with token | None (always POST) |
| **SDK** | Axios/HTTP | Twilio SDK |
| **Sandbox Setup** | Limited test numbers | Join via code |

## Phone Number Handling

- **Input**: Accepts various formats (`254712345678`, `+254712345678`, `whatsapp:+254712345678`)
- **Storage**: Stored without `whatsapp:` prefix
- **Sending**: Automatically formatted as `whatsapp:+254712345678` for Twilio

## Webhook Security

In production, verify Twilio request authenticity:

```javascript
const twilio = require('twilio');
const token = process.env.TWILIO_AUTH_TOKEN;

app.post('/webhook', twilio.webhook({ validate: true }, (req, res) => {
  // Webhook is verified
}));
```

## Testing with ngrok

For local development:

```bash
# Terminal 1: Start ngrok
ngrok http 3000

# Terminal 2: Start the bot
npm start
```

Use the ngrok URL (`https://xxxx-xx-xx-xxx-xxx.ngrok-free.dev/webhook`) as your Twilio webhook.

## Common Issues

### "Recipient phone number not in allowed list"
- **Cause**: Number not whitelisted in Twilio sandbox
- **Fix**: Send `join trick-up` to Twilio number from that phone

### "Error: Missing Twilio configuration"
- **Cause**: .env variables not set
- **Fix**: Update `.env` with correct Twilio credentials

### "Webhook verification failed"
- **Cause**: URL not correctly set in Twilio console
- **Fix**: Ensure webhook URL is publicly accessible and ends with `/webhook`

## Admin Commands

To manually update a grievance status (database):

```bash
sqlite3 grm.db
UPDATE grievances SET status = 'in_progress' WHERE ref_no = 'GRM-2026-0001';
UPDATE grievances SET status = 'resolved', resolution_notes = 'Issue resolved' WHERE ref_no = 'GRM-2026-0001';
```

## License

MIT

## Support

For issues or questions:
- Twilio Support: https://www.twilio.com/help
- WhatsApp Business Help: https://www.whatsapp.com/business/help
