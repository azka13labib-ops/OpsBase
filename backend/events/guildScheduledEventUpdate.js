const { Events } = require('discord.js');
const { updateEvent } = require('../supabase/events');

module.exports = {
  name: Events.GuildScheduledEventUpdate,
  async execute(oldGuildScheduledEvent, newGuildScheduledEvent) {
    if (!newGuildScheduledEvent) return;
    try {
      await updateEvent(newGuildScheduledEvent.id, {
        title: newGuildScheduledEvent.name,
        description: newGuildScheduledEvent.description,
        channelId: newGuildScheduledEvent.channelId,
        location: newGuildScheduledEvent.entityMetadata?.location,
        startTime: newGuildScheduledEvent.scheduledStartAt,
        endTime: newGuildScheduledEvent.scheduledEndAt,
      });
      if (newGuildScheduledEvent.client && newGuildScheduledEvent.client.io) {
        newGuildScheduledEvent.client.io.to(`guild_${newGuildScheduledEvent.guildId}`).emit('stats_updated');
      }
    } catch (err) {
      console.error('Gagal sync event update:', err);
    }
  },
};
