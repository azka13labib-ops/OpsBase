const supabase = require('./client');

async function registerDevice(guildId, adminUserId, fcmToken, platform = 'android') {
  const { error } = await supabase
    .from('devices')
    .upsert({ guild_id: guildId, admin_user_id: adminUserId, fcm_token: fcmToken, platform, registered_at: new Date().toISOString() }, { onConflict: 'fcm_token' });
  if (error) throw error;
}

async function removeDevice(fcmToken) {
  const { error } = await supabase.from('devices').delete().eq('fcm_token', fcmToken);
  if (error) throw error;
}

async function getDeviceTokensForGuild(guildId) {
  const { data, error } = await supabase.from('devices').select('fcm_token').eq('guild_id', guildId);
  if (error) throw error;
  return data.map(r => r.fcm_token);
}

module.exports = { registerDevice, removeDevice, getDeviceTokensForGuild };
