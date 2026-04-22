const { onDocumentWritten, onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onCall, HttpsError }                   = require('firebase-functions/v2/https');
const { onSchedule }                           = require('firebase-functions/v2/scheduler');
const { defineSecret }                         = require('firebase-functions/params');
const { logger }                               = require('firebase-functions');
const admin                                    = require('firebase-admin');
const { GoogleGenerativeAI }                   = require('@google/generative-ai');

admin.initializeApp();

const GEMINI_API_KEY  = defineSecret('GEMINI_API_KEY');
const CLOUD_RUN_URL   = defineSecret('CLOUD_RUN_URL');

/**
 * Triggered when a new swingJobs document is created.
 * Posts the job to the Cloud Run Python processing service.
 */
exports.onSwingJobCreated = onDocumentCreated(
  { document: 'swingJobs/{jobId}', secrets: [CLOUD_RUN_URL], timeoutSeconds: 10 },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const { jobId, inputUrl, userId } = data;
    const cloudRunUrl = CLOUD_RUN_URL.value();

    logger.info(`[swingJob] Dispatching job ${jobId} to Cloud Run`);

    // Fire-and-forget: abort after 8s so the Cloud Function doesn't time out.
    // Cloud Run processes synchronously and keeps its instance alive up to 600s.
    // An AbortError just means Cloud Run is still running — that's expected.
    const ctrl = new AbortController();
    const timer = setTimeout(() => ctrl.abort(), 8000);

    try {
      const response = await fetch(`${cloudRunUrl}/process-video`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ job_id: jobId, input_url: inputUrl, user_id: userId }),
        signal: ctrl.signal,
      });
      clearTimeout(timer);
      if (!response.ok) {
        const body = await response.text().catch(() => '');
        logger.error(`[swingJob] Cloud Run returned ${response.status}: ${body}`);
        await admin.firestore().collection('swingJobs').doc(jobId).update({
          status: 'failed',
          errorMessage: `Cloud Run dispatch failed (${response.status})`,
        });
      } else {
        logger.info(`[swingJob] Job ${jobId} completed`);
      }
    } catch (err) {
      clearTimeout(timer);
      if (err.name === 'AbortError') {
        // Expected: Cloud Run is processing (>8s). Not an error.
        logger.info(`[swingJob] Job ${jobId} running on Cloud Run (async)`);
      } else {
        logger.error(`[swingJob] Dispatch error for job ${jobId}:`, err.message);
        await admin.firestore().collection('swingJobs').doc(jobId).update({
          status: 'failed',
          errorMessage: `Dispatch error: ${err.message}`,
        });
      }
    }
  },
);


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

/**
 * Runs every hour. For each user whose local time is currently Monday 9am,
 * sends a personalised FCM push summarising their past 7 days.
 * Each user's timezone is stored as an IANA string in users/{uid}.timezone
 * (e.g. "America/New_York"). Falls back to UTC if missing.
 */
exports.weeklyDigest = onSchedule(
  { schedule: 'every 1 hours', timeoutSeconds: 300 },
  async () => {
    const db  = admin.firestore();
    const now = new Date();

    const usersSnap = await db.collection('users')
      .where('fcmToken', '!=', null)
      .get();

    logger.info(`[weeklyDigest] Checking ${usersSnap.size} users`);

    const jobs = usersSnap.docs.map(userDoc => {
      const data     = userDoc.data();
      const timezone = data.timezone ?? 'UTC';

      // Convert current UTC time to the user's local time.
      // Supports both IANA names ("America/New_York") and UTC offset strings ("UTC+5:30").
      let localHour, weekday;
      try {
        const localStr = now.toLocaleString('en-US', {
          timeZone: timezone, hour12: false,
          weekday: 'long', hour: 'numeric',
        });
        [weekday, localHour] = localStr.split(', ');
        localHour = parseInt(localHour, 10);
      } catch (_) {
        // Fallback: parse "UTC+5" / "UTC+5:30" manually
        const match = timezone.match(/UTC([+-]\d+)(?::(\d+))?/);
        if (match) {
          const offsetMins = parseInt(match[1], 10) * 60 + (match[2] ? parseInt(match[2], 10) : 0);
          const local = new Date(now.getTime() + offsetMins * 60000);
          localHour = local.getUTCHours();
          weekday = ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'][local.getUTCDay()];
        } else {
          return Promise.resolve(); // can't determine timezone — skip
        }
      }

      if (weekday !== 'Monday' || localHour !== 9) return Promise.resolve();

      const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
      return sendWeeklyDigest(userDoc.id, data.fcmToken, weekAgo, db);
    });

    await Promise.allSettled(jobs);
    logger.info('[weeklyDigest] Done');
  },
);

async function sendWeeklyDigest(uid, token, weekAgo, db) {
  try {
    const snap = await db.collection('rounds')
      .where('userId',     '==', uid)
      .where('status',     '==', 'completed')
      .where('isPractice', '==', false)
      .where('completedAt', '>=', admin.firestore.Timestamp.fromDate(weekAgo))
      .get();

    if (snap.empty) return; // no rounds this week — skip

    const rounds = snap.docs.map(d => d.data());
    const count  = rounds.length;

    // Score diffs (score - par per round)
    const diffs   = rounds.map(r => (r.totalScore ?? 0) - (r.totalPar ?? 0));
    const avgDiff = diffs.reduce((a, b) => a + b, 0) / count;

    // Best round (lowest score vs par)
    const bestRound = rounds.reduce((best, r) => {
      const d = (r.totalScore ?? 99) - (r.totalPar ?? 72);
      return d < ((best.totalScore ?? 99) - (best.totalPar ?? 72)) ? r : best;
    });

    // Total birdies across all rounds
    const totalBirdies = rounds.reduce((sum, r) => {
      return sum + (r.scores ?? []).filter(h => h.score - h.par === -1).length;
    }, 0);

    // Format diff strings
    const fmt    = n => n === 0 ? 'E' : n > 0 ? `+${n.toFixed(1)}` : n.toFixed(1);
    const fmtInt = n => n === 0 ? 'E' : n > 0 ? `+${n}` : `${n}`;
    const avgStr   = fmt(avgDiff);
    const bestDiff = (bestRound.totalScore ?? 0) - (bestRound.totalPar ?? 0);
    const bestStr  = fmtInt(bestDiff);

    const birdieTxt = `${totalBirdies} birdie${totalBirdies !== 1 ? 's' : ''}`;
    const body = count === 1
      ? `1 round · ${bestRound.totalScore ?? '?'} at ${bestRound.courseName} (${bestStr}) · ${birdieTxt}`
      : `${count} rounds · avg ${avgStr} · best ${bestRound.totalScore ?? '?'} at ${bestRound.courseName} · ${birdieTxt}`;

    await admin.messaging().send({
      token,
      notification: { title: '⛳ Your Week in Golf', body },
      data:         { route: 'weeklyDigest' },
      apns:         { payload: { aps: { sound: 'default' } } },
      android:      { notification: { sound: 'default' } },
    });
    logger.info(`[weeklyDigest] Sent to uid=${uid}: ${body}`);
  } catch (err) {
    logger.error(`[weeklyDigest] Failed for uid=${uid}: ${err.message}`);
  }
}
