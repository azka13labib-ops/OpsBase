const { Events } = require('discord.js');
const supabase = require('../supabase/client');

module.exports = {
  name: Events.GuildScheduledEventDelete,
  async execute(guildScheduledEvent) {
    if (!guildScheduledEvent) return;
    try {
      await supabase.from('events').delete().eq('discord_event_id', guildScheduledEvent.id);
      
      if (guildScheduledEvent.client && guildScheduledEvent.client.io) {
        guildScheduledEvent.client.io.to(`guild_${guildScheduledEvent.guildId}`).emit('stats_updated');
      }
    } catch (err) {
      console.error('Gagal sync event delete:', err);
    }
  },
};
