const supabase = require('./client');

async function createEvent({ guildId, discordEventId, title, description, channelId, startTime, endTime, isRecurring, recurrenceRule, createdBy }) {
  const { data, error } = await supabase
    .from('events')
    .insert({
      guild_id: guildId, discord_event_id: discordEventId || null, title, description: description || null,
      channel_id: channelId || null, start_time: startTime, end_time: endTime || null,
      is_recurring: !!isRecurring, recurrence_rule: recurrenceRule || null, created_by: createdBy,
    })
    .select()
    .single();
  if (error) throw error;
  return data;
}

async function listEvents(guildId, { upcomingOnly = true } = {}) {
  let query = supabase.from('events').select('*').eq('guild_id', guildId);
  query = upcomingOnly
    ? query.gte('start_time', new Date().toISOString()).order('start_time', { ascending: true })
    : query.order('start_time', { ascending: false });

  const { data, error } = await query;
  if (error) throw error;
  return data;
}

async function getEvent(eventId) {
  const { data, error } = await supabase.from('events').select('*').eq('id', eventId).single();
  if (error) throw error;
  return data;
}

async function deleteEvent(eventId) {
  const { error } = await supabase.from('events').delete().eq('id', eventId);
  if (error) throw error;
}

async function upsertRsvp(eventId, userId, userTag, status) {
  const { error } = await supabase
    .from('event_rsvps')
    .upsert({ event_id: eventId, user_id: userId, user_tag: userTag, status, responded_at: new Date().toISOString() }, { onConflict: 'event_id,user_id' });
  if (error) throw error;
}

async function getRsvps(eventId) {
  const { data, error } = await supabase.from('event_rsvps').select('*').eq('event_id', eventId);
  if (error) throw error;
  return data;
}

module.exports = { createEvent, listEvents, getEvent, deleteEvent, upsertRsvp, getRsvps };
