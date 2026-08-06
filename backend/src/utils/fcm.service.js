const path = require("path");
const fs = require("fs");
const db = require("../config/db");
const logger = require("./logger");

const { initializeApp, cert } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");

let isFcmInitialized = false;

try {
  let serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH || "/etc/secrets/serviceAccountKey.json";
  if (!fs.existsSync(serviceAccountPath)) {
    serviceAccountPath = path.join(__dirname, "../config/serviceAccountKey.json");
  }

  if (fs.existsSync(serviceAccountPath)) {
    const serviceAccount = require(serviceAccountPath);
    initializeApp({
      credential: cert(serviceAccount),
    });
    isFcmInitialized = true;
    logger.info("Firebase Admin SDK initialized successfully with service account.");
  } else if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
    initializeApp({
      credential: cert(serviceAccount),
    });
    isFcmInitialized = true;
    logger.info("Firebase Admin SDK initialized successfully with environment JSON.");
  } else {
    logger.warn("Firebase serviceAccountKey.json not found. FCM push notifications will run in fallback DB mode.");
  }
} catch (err) {
  logger.warn(`Firebase Admin SDK setup skipped: ${err.message}`);
}

/**
 * Save user FCM token in database
 */
async function saveUserFcmToken(userId, token) {
  if (!userId || !token) return false;
  await db.query("UPDATE users SET fcm_token = $1, updated_at = NOW() WHERE id = $2", [token, userId]);
  return true;
}

/**
 * Save worker FCM token in database
 */
async function saveWorkerFcmToken(workerId, token) {
  if (!workerId || !token) return false;
  await db.query("UPDATE workers SET fcm_token = $1, updated_at = NOW() WHERE id = $2", [token, workerId]);
  return true;
}

/**
 * Send FCM Push Notification to User
 */
async function sendToUser(userId, { title, body, data = {} }) {
  try {
    // 1. Save in-app notification in DB
    await db.query(
      `INSERT INTO notifications (title, message, type, priority, entity_id, created_at)
       VALUES ($1, $2, 'user_push', 'high', $3, NOW())`,
      [title, body, String(userId)]
    );

    // 2. Fetch FCM Token
    const res = await db.query("SELECT fcm_token FROM users WHERE id = $1", [userId]);
    const fcmToken = res.rows[0]?.fcm_token;

    if (!fcmToken) {
      logger.info(`[FCM User Notification] No token registered for user #${userId}. Title: "${title}"`);
      return false;
    }

    if (isFcmInitialized) {
      const message = {
        token: fcmToken,
        notification: { title, body },
        data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
        android: {
          priority: "high",
          notification: {
            channelId: "high_importance_channel",
            sound: "default",
            defaultSound: true,
            defaultVibrateTimings: true,
            visibility: "public",
          }
        }
      };
      try {
        const response = await getMessaging().send(message);
        logger.info(`[FCM Push Success] Sent to User #${userId}: ${response}`);
        return true;
      } catch (sendErr) {
        logger.error(`Error sending FCM push to User #${userId}: ${sendErr.message}`);
        await db.query("INSERT INTO notifications (title, message, type, priority, entity_id, created_at) VALUES ('[FCM ERROR User]', $1, 'admin_log', 'high', $2, NOW())", [String(sendErr.message), String(userId)]);
        return false;
      }
    } else {
      logger.info(`[FCM Push Fallback] User #${userId} (Token: ${fcmToken.slice(0, 10)}...): "${title}" - ${body}`);
      await db.query("INSERT INTO notifications (title, message, type, priority, entity_id, created_at) VALUES ('[FCM FALLBACK User]', 'FCM Not Initialized', 'admin_log', 'high', $1, NOW())", [String(userId)]);
      return true;
    }
  } catch (err) {
    logger.error(`Error sending FCM push to User #${userId}: ${err.message}`);
    return false;
  }
}

/**
 * Send FCM Push Notification to Worker
 */
async function sendToWorker(workerId, { title, body, data = {} }) {
  try {
    // 1. Save in-app notification in DB
    await db.query(
      `INSERT INTO notifications (title, message, type, priority, entity_id, created_at)
       VALUES ($1, $2, 'worker_push', 'high', $3, NOW())`,
      [title, body, String(workerId)]
    );

    // 2. Fetch FCM Token
    const res = await db.query("SELECT fcm_token FROM workers WHERE id = $1", [workerId]);
    const fcmToken = res.rows[0]?.fcm_token;

    if (!fcmToken) {
      logger.info(`[FCM Worker Notification] No token registered for worker #${workerId}. Title: "${title}"`);
      return false;
    }

    if (isFcmInitialized) {
      const message = {
        token: fcmToken,
        notification: { title, body },
        data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
        android: {
          priority: "high",
          notification: {
            channelId: "high_importance_channel",
            sound: "default",
            defaultSound: true,
            defaultVibrateTimings: true,
            visibility: "public",
          }
        }
      };
      try {
        const response = await getMessaging().send(message);
        logger.info(`[FCM Push Success] Sent to Worker #${workerId}: ${response}`);
        return true;
      } catch (sendErr) {
        logger.error(`Error sending FCM push to Worker #${workerId}: ${sendErr.message}`);
        await db.query("INSERT INTO notifications (title, message, type, priority, entity_id, created_at) VALUES ('[FCM ERROR Worker]', $1, 'admin_log', 'high', $2, NOW())", [String(sendErr.message), String(workerId)]);
        return false;
      }
    } else {
      logger.info(`[FCM Push Fallback] Worker #${workerId} (Token: ${fcmToken.slice(0, 10)}...): "${title}" - ${body}`);
      await db.query("INSERT INTO notifications (title, message, type, priority, entity_id, created_at) VALUES ('[FCM FALLBACK Worker]', 'FCM Not Initialized', 'admin_log', 'high', $1, NOW())", [String(workerId)]);
      return true;
    }
  } catch (err) {
    logger.error(`Error sending FCM push to Worker #${workerId}: ${err.message}`);
    return false;
  }
}

/**
 * Broadcast FCM Push Notification to All Active Workers
 */
async function sendToAllActiveWorkers({ title, body, data = {} }) {
  try {
    const res = await db.query("SELECT id FROM workers WHERE fcm_token IS NOT NULL");
    for (const row of res.rows) {
      await sendToWorker(row.id, { title, body, data });
    }
  } catch (err) {
    logger.error(`Error broadcasting FCM to workers: ${err.message}`);
  }
}

module.exports = {
  saveUserFcmToken,
  saveWorkerFcmToken,
  sendToUser,
  sendToWorker,
  sendToAllActiveWorkers,
};
