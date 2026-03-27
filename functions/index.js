const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { logger } = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

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
