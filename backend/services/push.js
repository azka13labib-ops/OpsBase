const admin = require('firebase-admin');
const path = require('path');
const { getDeviceTokensForGuild, removeDevice } = require('../supabase/devices');

let initialized = false;

function initFirebase() {
  if (initialized) return;
  const keyPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
  if (!keyPath) {
    console.warn('⚠️  FIREBASE_SERVICE_ACCOUNT_PATH belum diset — push notification dinonaktifkan.');
    return;
  }
  admin.initializeApp({
    credential: admin.credential.cert(require(path.resolve(keyPath))),
  });
  initialized = true;
}

/**
 * Kirim push notification ke semua admin yang punya device terdaftar di suatu guild.
 * type: 'raid' | 'spam' | 'warn' | 'ban' | 'event' | 'ticket'
 */
async function notifyAdmins(guildId, { title, body, type = 'info', data = {} }) {
  if (!initialized) return; // Firebase belum dikonfigurasi, skip diam-diam

  const tokens = await getDeviceTokensForGuild(guildId);
  if (tokens.length === 0) return;

  const message = {
    notification: { title, body },
    data: { type, ...Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])) },
    tokens,
  };

  try {
    const response = await admin.messaging().sendEachForMulticast(message);
    // Bersihkan token yang sudah tidak valid (uninstall app, dll)
    response.responses.forEach((res, i) => {
      if (!res.success && res.error?.code === 'messaging/registration-token-not-registered') {
        removeDevice(tokens[i]).catch(() => {});
      }
    });
  } catch (err) {
    console.error('Gagal mengirim push notification:', err.message);
  }
}

module.exports = { initFirebase, notifyAdmins };
