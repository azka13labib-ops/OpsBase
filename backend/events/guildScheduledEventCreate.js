const { Events } = require('discord.js');
const { createEvent, getEventByDiscordId } = require('../supabase/events');

module.exports = {
  name: Events.GuildScheduledEventCreate,
  execute(guildScheduledEvent) {
    if (!guildScheduledEvent) return;
    
    // Tunggu 2 detik untuk menghindari race condition dengan API pembuatan event kita sendiri.
    // Jika event dibuat via API, maka dalam 2 detik Supabase sudah selesai menyimpan datanya.
    setTimeout(async () => {
      // Cegah race condition: jika event dibuat oleh bot ini sendiri (lewat API), abaikan.
      if (guildScheduledEvent.creatorId === guildScheduledEvent.client.user?.id) return;

      try {
        const existing = await getEventByDiscordId(guildScheduledEvent.id);
        if (existing) return; // Fallback cek database

        await createEvent({
          guildId: guildScheduledEvent.guildId,
          discordEventId: guildScheduledEvent.id,
          title: guildScheduledEvent.name,
          description: guildScheduledEvent.description,
          channelId: guildScheduledEvent.channelId,
          location: guildScheduledEvent.entityMetadata?.location,
          startTime: guildScheduledEvent.scheduledStartAt,
          endTime: guildScheduledEvent.scheduledEndAt,
          createdBy: guildScheduledEvent.creatorId || 'bot',
        });
        if (guildScheduledEvent.client && guildScheduledEvent.client.io) {
          guildScheduledEvent.client.io.to(`guild_${guildScheduledEvent.guildId}`).emit('stats_updated');
        }
      } catch (err) {
        console.error('Gagal sync event creation:', err);
      }
    }, 2000); // delay 2 detik
  },
};
