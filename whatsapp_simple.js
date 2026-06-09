const twilio = require('twilio');

let client = null;

/**
 * Send a WhatsApp message via Twilio
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

    // Create client if not exists
    if (!client) {
      client = twilio(accountSid, authToken);
    }

    // Normalize phone
    let phone = to.replace('whatsapp:', '').replace(/[\s()\-]/g, '');
    if (!phone.startsWith('+')) phone = '+' + phone;

    // Send with timeout wrapper
    const messagePromise = client.messages.create({
      from: fromNumber,
      to: `whatsapp:${phone}`,
      body: body
    });

    // Add 30 second timeout
    const timeoutPromise = new Promise((_, reject) => 
      setTimeout(() => reject(new Error('Message send timeout')), 30000)
    );

    const message = await Promise.race([messagePromise, timeoutPromise]);

    console.log(`✓ WhatsApp sent to ${phone} (SID: ${message.sid})`);
    return {
      success: true,
      sid: message.sid,
      to: phone
    };
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
