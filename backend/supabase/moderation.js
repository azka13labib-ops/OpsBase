const supabase = require('./client');

// ---------- Warnings ----------
async function addWarning(guildId, userId, reason, moderatorId) {
  const { data, error } = await supabase
    .from('warnings')
    .insert({ guild_id: guildId, user_id: userId, reason, moderator_id: moderatorId })
    .select()
    .single();
  if (error) throw error;
  return data;
}

async function getWarnings(guildId, userId) {
  const { data, error } = await supabase
    .from('warnings')
    .select('*')
    .eq('guild_id', guildId)
    .eq('user_id', userId)
    .order('created_at', { ascending: false });
  if (error) throw error;
  return data;
}

async function clearWarnings(guildId, userId) {
  const { error } = await supabase
    .from('warnings')
    .delete()
    .eq('guild_id', guildId)
    .eq('user_id', userId);
  if (error) throw error;
}

// ---------- Mod Action Log (audit log / dashboard mobile) ----------
async function logModAction({ guildId, actionType, targetId, targetTag, moderatorId, moderatorTag, reason, source = 'bot' }) {
  const { data, error } = await supabase
    .from('mod_actions')
    .insert({
      guild_id: guildId, action_type: actionType, target_id: targetId, target_tag: targetTag || null,
      moderator_id: moderatorId, moderator_tag: moderatorTag || null, reason: reason || null, source,
    })
    .select()
    .single();
  if (error) throw error;
  return data;
}

async function getModActions(guildId, { limit = 50, offset = 0 } = {}) {
  const { data, error } = await supabase
    .from('mod_actions')
    .select('*')
    .eq('guild_id', guildId)
    .order('created_at', { ascending: false })
    .range(offset, offset + limit - 1);
  if (error) throw error;
  return data;
}

module.exports = { addWarning, getWarnings, clearWarnings, logModAction, getModActions };
