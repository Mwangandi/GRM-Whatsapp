const twilio = require('twilio');
const http = require('http');
const https = require('https');

let client = null;

// Configure HTTP agents with extended timeout
const httpAgent = new http.Agent({
  keepAlive: true,
  timeout: 90000, // 90 seconds
  maxSockets: 50
});

const httpsAgent = new https.Agent({
  keepAlive: true,
  timeout: 90000, // 90 seconds
  maxSockets: 50
});

/**
 * Send a WhatsApp message via Twilio with 90-second timeout
 * @param {string} to - Recipient phone number
 * @param {string} body - Message body text
 * @returns {Promise<object>} Message response
 */
async function sendMessage(to, body) {
  try {
    const accountSid = process.env.TWILIO_ACCOUNT_SID;
    const authToken = process.env.TWILIO_AUTH_TOKEN;
    const fromNumber = process.env.TWILIO_WHATSAPP_NUMBER;

    if (!accountSid || !authToken || !fromNumber) {
      throw new Error('Missing Twilio credentials');
    }

    // Create client if not exists (connection pooling)
    if (!client) {
      // Create Twilio client with custom HTTP agent configuration
      client = twilio(accountSid, authToken);
      
      // Override the restClient to use our agents with extended timeout
      if (client.request && typeof client.request === 'function') {
        const originalRequest = client.request.bind(client);
        client.request = function(opts, callback) {
          opts.agent = opts.protocol === 'https:' ? httpsAgent : httpAgent;
          opts.timeout = 90000;
          return originalRequest(opts, callback);
        };
      }
    }

    // Normalize phone
    let phone = to.replace('whatsapp:', '').replace(/[\s()\-]/g, '');
    if (!phone.startsWith('+')) phone = '+' + phone;

    // Retry logic for timeout errors
    let lastError;
    const maxRetries = 5;
    const baseDelay = 500; // 500ms between retries

    for (let attempt = 0; attempt < maxRetries; attempt++) {
      try {
        if (attempt > 0) {
          const delay = baseDelay * attempt;
          console.log(`⏳ Retry attempt ${attempt} for ${phone}, waiting ${delay}ms...`);
          await new Promise(resolve => setTimeout(resolve, delay));
        }

        const messagePromise = client.messages.create({
          from: fromNumber,
          to: `whatsapp:${phone}`,
          body: body
        });

        // Increase overall timeout to 120 seconds
        const timeoutPromise = new Promise((_, reject) =>
          setTimeout(() => reject(new Error('Twilio API timeout (120s exceeded)')), 120000)
        );

        const message = await Promise.race([messagePromise, timeoutPromise]);

        console.log(`✓ WhatsApp sent to ${phone} (SID: ${message.sid})`);
        return {
          success: true,
          sid: message.sid,
          to: phone
        };
      } catch (error) {
        lastError = error;
        // Retry on timeout errors, fail immediately on other errors
        if (!error.message.includes('timeout') && attempt === 0) {
          throw error;
        }
        if (attempt === maxRetries - 1) {
          throw error;
        }
      }
    }

    throw lastError;
  } catch (error) {
    console.error('Error sending WhatsApp:', error.message);
    throw error;
  }
}

/**
 * Normalize phone number
 */
function normalizePhoneNumber(phone) {
  if (!phone) return phone;
  let cleaned = phone.replace('whatsapp:', '');
  cleaned = cleaned.replace(/[\s()\-]/g, '');
  if (!cleaned.startsWith('+')) cleaned = '+' + cleaned;
  return cleaned;
}

module.exports = {
  sendMessage,
  normalizePhoneNumber
};
