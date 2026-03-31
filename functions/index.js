const { onDocumentWritten, onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onCall, HttpsError }                   = require('firebase-functions/v2/https');
const { defineSecret }                         = require('firebase-functions/params');
const { logger }                               = require('firebase-functions');
const admin                                    = require('firebase-admin');
const { GoogleGenerativeAI }                   = require('@google/generative-ai');

admin.initializeApp();

const GEMINI_API_KEY = defineSecret('GEMINI_API_KEY');

/**
 * Callable function — receives a base64-encoded scorecard image and uses
 * Gemini Flash vision to extract structured hole-by-hole data.
 *
 * Request:  { imageBase64: string, mimeType: string }
 * Response: { courseName, location, tees: [{name, courseRating, slopeRating, holes: [{hole, par, yardage, handicap}]}] }
 */
exports.analyzeScorecard = onCall(
  { secrets: [GEMINI_API_KEY], timeoutSeconds: 60 },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Must be signed in.');
    }

    const { imageBase64, mimeType } = request.data;
    if (!imageBase64 || !mimeType) {
      throw new HttpsError('invalid-argument', 'imageBase64 and mimeType are required.');
    }

    const genAI = new GoogleGenerativeAI(GEMINI_API_KEY.value());
    const model = genAI.getGenerativeModel({ model: 'gemini-2.0-flash' });

    const prompt = `You are extracting data from a golf scorecard image.
Return ONLY valid JSON with no markdown, no code fences, no extra text.
Schema:
{
  "courseName": "string",
  "location": "City, State or Country",
  "tees": [
    {
      "name": "tee name (e.g. White, Blue, Red)",
      "courseRating": number,
      "slopeRating": integer,
      "holes": [
        { "hole": integer, "par": integer, "yardage": integer, "handicap": integer }
      ]
    }
  ]
}
Rules:
- Include all tee sets visible on the scorecard (Men's and Ladies' if present).
- holes array must have exactly 9 or 18 entries.
- If a value is unreadable, use 0.
- courseRating and slopeRating default to 0 if not shown.`;

    try {
      const result = await model.generateContent([
        { text: prompt },
        { inlineData: { mimeType, data: imageBase64 } },
      ]);
      const raw = result.response.text().trim();
      // Strip markdown fences if Gemini adds them despite instructions
      const jsonText = raw.replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/i, '');
      const parsed = JSON.parse(jsonText);
      logger.info(`[analyzeScorecard] Extracted course: ${parsed.courseName}`);
      return parsed;
    } catch (err) {
      logger.error('[analyzeScorecard] Gemini error:', err.message);
      throw new HttpsError('internal', `Extraction failed: ${err.message}`);
    }
  },
);

/**
 * Watches groupRounds/{sessionId} for new 'invited' players and sends
 * an FCM push notification to each one using their stored fcmToken.
 */
exports.onGroupRoundInvite = onDocumentWritten(
  'groupRounds/{sessionId}',
  async (event) => {
    if (!event.data.after.exists) return; // document deleted — nothing to do

    const beforePlayers = event.data.before.exists
      ? (event.data.before.data()?.players ?? {})
      : {};
    const afterData    = event.data.after.data();
    const afterPlayers = afterData?.players ?? {};
    const sessionId    = event.params.sessionId;

    logger.info(`[${sessionId}] Processing write. Players: ${Object.keys(afterPlayers).join(', ')}`);

    const notifications = [];

    for (const [uid, player] of Object.entries(afterPlayers)) {
      const wasInvited = beforePlayers[uid]?.status === 'invited';
      logger.info(`[${sessionId}] uid=${uid} status=${player.status} wasInvited=${wasInvited}`);

      // Only notify when a player transitions INTO 'invited' state
      if (player.status === 'invited' && !wasInvited) {
        logger.info(`[${sessionId}] Sending invite notification to uid=${uid}`);
        notifications.push(sendInviteNotification(uid, afterData, sessionId));
      }
    }

    await Promise.allSettled(notifications);
    logger.info(`[${sessionId}] Done. Sent ${notifications.length} notification(s).`);
  },
);

async function sendInviteNotification(uid, session, sessionId) {
  const userDoc = await admin.firestore().collection('users').doc(uid).get();
  const token   = userDoc.data()?.fcmToken;

  if (!token) {
    logger.warn(`[${sessionId}] No fcmToken for uid=${uid} — skipping notification`);
    return;
  }

  logger.info(`[${sessionId}] Sending FCM to uid=${uid}, token=${token.slice(0, 20)}...`);

  try {
    await admin.messaging().send({
      token,
      notification: {
        title: '⛳ Round Invite',
        body: `${session.hostName} invited you to play at ${session.courseName}`,
      },
      data: {
        route:     'groupRound',
        sessionId: sessionId,
      },
      apns: {
        payload: { aps: { sound: 'default' } },
      },
      android: {
        notification: { sound: 'default' },
      },
    });
    logger.info(`[${sessionId}] FCM sent successfully to uid=${uid}`);
  } catch (err) {
    logger.error(`[${sessionId}] FCM send failed for uid=${uid}: ${err.message}`);
  }
}

/**
 * Watches users/{recipientUid}/friends/{senderUid} for a new 'pending_received'
 * document and sends an FCM push notification to the recipient.
 */
exports.onFriendRequest = onDocumentCreated(
  'users/{recipientUid}/friends/{senderUid}',
  async (event) => {
    const data = event.data?.data();
    if (!data || data.status !== 'pending_received') return;

    const recipientUid = event.params.recipientUid;
    const senderName   = data.displayName ?? 'Someone';

    logger.info(`[friendRequest] ${senderName} → uid=${recipientUid}`);

    // Fetch recipient's FCM token
    const recipientDoc = await admin.firestore().collection('users').doc(recipientUid).get();
    const token = recipientDoc.data()?.fcmToken;

    if (!token) {
      logger.warn(`[friendRequest] No fcmToken for uid=${recipientUid} — skipping`);
      return;
    }

    try {
      await admin.messaging().send({
        token,
        notification: {
          title: '🤝 Friend Request',
          body: `${senderName} wants to be your golf buddy!`,
        },
        data: {
          route: 'friendRequest',
        },
        apns: {
          payload: { aps: { sound: 'default' } },
        },
        android: {
          notification: { sound: 'default' },
        },
      });
      logger.info(`[friendRequest] FCM sent to uid=${recipientUid}`);
    } catch (err) {
      logger.error(`[friendRequest] FCM failed for uid=${recipientUid}: ${err.message}`);
    }
  },
);
