const { sendMessage } = require('./whatsapp');
const {
  getSession,
  saveSession,
  deleteSession,
  saveGrievance,
  getGrievance
} = require('./db');

const COUNTY_NAME = process.env.COUNTY_NAME || 'County';

function generateRefNo() {
  const year = new Date().getFullYear();
  const randomDigits = String(Math.floor(Math.random() * 10000)).padStart(4, '0');
  return `GRM-${year}-${randomDigits}`;
}

function mapFeedbackType(selection) {
  const types = {
    '1': 'Complaint',
    '2': 'Compliment',
    '3': 'Suggestion',
    '4': 'Question'
  };
  return types[selection] || null;
}

function mapGrievanceCategory(selection) {
  const categories = {
    '1': 'Health Facilities',
    '2': 'Water Access and Taveta',
    '3': 'Gender Based Violence Misconduct'
  };
  return categories[selection] || null;
}

async function handleMessage(phone, text) {
  try {
    const userInput = text.trim().toLowerCase();
    let session = getSession(phone);
    const currentStep = session?.step || 'start';

    console.log(`[${phone}] Current step: ${currentStep}, Input: ${userInput}`);

    // STATE: "start" - Initial entry point
    if (currentStep === 'start' || !session) {
      try {
        await sendMessage(
          phone,
          `*Welcome to ${COUNTY_NAME} Grievance Redress System*\n\nSubmit complaints and track their resolution through WhatsApp.\n\nPlease reply with:\n1️⃣ *SUBMIT* - File a new grievance\n2️⃣ *TRACK* - Check grievance status\n3️⃣ *HELP* - Contact information`
        );
      } catch (e) {
        console.error(`Failed to send welcome message to ${phone}:`, e.message);
      }
      saveSession(phone, { step: 'menu' });
      return;
    }

    // STATE: "menu" - Main menu options
    if (currentStep === 'menu') {
      if (userInput === 'submit' || userInput === '1') {
        try {
          await sendMessage(
            phone,
            '📋 Select the *Type of Feedback*:\n\n1. Complaint\n2. Compliment\n3. Suggestion\n4. Question'
          );
        } catch (e) {
          console.error(`Failed to send feedback type menu to ${phone}:`, e.message);
        }
        saveSession(phone, { step: 'get_feedback_type' });
      } else if (userInput === 'track' || userInput === '2') {
        try {
          await sendMessage(phone, 'Please enter your *reference number* (e.g. GRM-2026-0001):');
        } catch (e) {
          console.error(`Failed to send track prompt to ${phone}:`, e.message);
        }
        saveSession(phone, { step: 'check_status' });
      } else if (userInput === 'help' || userInput === '3') {
        try {
          await sendMessage(
            phone,
            '📞 *Contact Information*\n\nGrievance Office: 0800 XXX XXX\nEmail: grievances@county.go.ke\nOffice Hours: Mon-Fri 8am-5pm'
          );
        } catch (e) {
          console.error(`Failed to send help info to ${phone}:`, e.message);
        }
        saveSession(phone, { step: 'menu' });
      } else {
        try {
          await sendMessage(phone, 'Please reply with 1, 2, or 3.');
        } catch (e) {
          console.error(`Failed to send menu prompt to ${phone}:`, e.message);
        }
      }
      return;
    }

    // STATE: "get_feedback_type" - Get type of feedback
    if (currentStep === 'get_feedback_type') {
      const feedbackType = mapFeedbackType(userInput);

      if (!feedbackType) {
        try {
          await sendMessage(phone, '❌ Invalid selection. Please reply with 1-4.');
        } catch (e) {
          console.error(`Failed to send error to ${phone}:`, e.message);
        }
        return;
      }

      // Save session BEFORE sending message to preserve state
      saveSession(phone, {
        feedback_type: feedbackType,
        step: 'get_category'
      });

      try {
        await sendMessage(
          phone,
          '📋 Select the *Category*:\n\n1. Health Facilities\n2. Water Access and Taveta\n3. Gender Based Violence Misconduct'
        );
      } catch (e) {
        console.error(`Failed to send category menu to ${phone}:`, e.message);
      }

      return;
    }

    // STATE: "get_category" - Get grievance category
    if (currentStep === 'get_category') {
      const grievanceCategory = mapGrievanceCategory(userInput);

      if (!grievanceCategory) {
        try {
          await sendMessage(phone, '❌ Invalid selection. Please reply with 1-3.');
        } catch (e) {
          console.error(`Failed to send error to ${phone}:`, e.message);
        }
        return;
      }

      // Save session BEFORE sending message to preserve state
      saveSession(phone, {
        grievance_category: grievanceCategory,
        step: 'get_description'
      });

      try {
        await sendMessage(
          phone,
          '📝 Tell us about your grievance:\n\nWhat is the main issue? Please describe in detail.'
        );
      } catch (e) {
        console.error(`Failed to send description prompt to ${phone}:`, e.message);
      }

      return;
    }

    // STATE: "get_description" - Get grievance description
    if (currentStep === 'get_description') {
      const refNo = generateRefNo();
      const grievanceId = `grv_${Date.now()}`;
      const currentSession = getSession(phone);

      // Save session BEFORE sending message to preserve state
      saveSession(phone, {
        description: userInput,
        ref_no: refNo,
        step: 'confirm',
        id: grievanceId
      });

      try {
        await sendMessage(
          phone,
          `📋 *Grievance Summary*\n\nReference No: *${refNo}*\nType: ${currentSession.feedback_type}\nCategory: ${currentSession.grievance_category}\nDescription: ${userInput}\n\nReply *CONFIRM* to submit or *CANCEL* to start over.`
        );
      } catch (e) {
        console.error(`Failed to send summary to ${phone}:`, e.message);
      }

      return;
    }

    // STATE: "confirm" - Confirm and save grievance
    if (currentStep === 'confirm') {
      if (userInput === 'confirm') {
        const currentSession = getSession(phone);

        saveGrievance({
          id: currentSession.id,
          phone: phone,
          ref_no: currentSession.ref_no,
          feedback_type: currentSession.feedback_type,
          category: currentSession.grievance_category,
          description: currentSession.description,
          status: 'open',
          department: 'General',
          priority: 'normal'
        });

        try {
          await sendMessage(
            phone,
            `*Grievance Submitted Successfully*\n\nYour reference number: *${currentSession.ref_no}*\n\nWe will review your complaint and get back to you within 5 business days.\n\nReply *TRACK* anytime to check the status.`
          );
        } catch (e) {
          console.error(`Failed to send confirmation to ${phone}:`, e.message);
        }

        deleteSession(phone);
      } else if (userInput === 'cancel') {
        deleteSession(phone);
        try {
          await sendMessage(phone, 'Grievance cancelled. Type anything to start over.');
        } catch (e) {
          console.error(`Failed to send cancel message to ${phone}:`, e.message);
        }
      } else {
        try {
          await sendMessage(phone, 'Please reply *CONFIRM* or *CANCEL*.');
        } catch (e) {
          console.error(`Failed to send confirm prompt to ${phone}:`, e.message);
        }
      }
      return;
    }

    // STATE: "check_status" - Check grievance status
    if (currentStep === 'check_status') {
      const grievance = getGrievance(userInput.toUpperCase());

      if (grievance) {
        const statusEmoji = {
          'open': '📮',
          'in_progress': '⏳',
          'resolved': '✅',
          'closed': '🔒'
        };

        const emoji = statusEmoji[grievance.status] || '❓';

        try {
          await sendMessage(
            phone,
            `${emoji} *Grievance Status*\n\nRef No: ${grievance.ref_no}\nCategory: ${grievance.category}\nStatus: *${grievance.status.toUpperCase()}*\n${grievance.resolution_notes ? `\nNotes: ${grievance.resolution_notes}` : ''}`
          );
        } catch (e) {
          console.error(`Failed to send status to ${phone}:`, e.message);
        }
      } else {
        try {
          await sendMessage(phone, '❌ Reference number not found. Please check and try again.');
        } catch (e) {
          console.error(`Failed to send not found message to ${phone}:`, e.message);
        }
      }

      saveSession(phone, { step: 'menu' });
      return;
    }

    // Unrecognized state - restart
    console.log(`Unrecognized state: ${currentStep}`);
    deleteSession(phone);
    await handleMessage(phone, text);
  } catch (error) {
    console.error('Error in handleMessage:', error.message);
  }
}

module.exports = {
  handleMessage
};
