const express = require('express');
const router = express.Router();
const { getModActions } = require('../../supabase/moderation');
const { listEvents } = require('../../supabase/events');

// GET /api/dashboard/stats — ringkasan untuk home screen app mobile
router.get('/stats', async (req, res) => {
  try {
    const client = req.app.get('discordClient');
    const guild = client.guilds.cache.get(req.auth.guildId);

    const recentActions = await getModActions(req.auth.guildId, { limit: 5 });
    const upcomingEvents = await listEvents(req.auth.guildId, { upcomingOnly: true });

    const textChannelCount = guild.channels.cache.filter(c => c.type === 0 || c.type === 5).size; // GUILD_TEXT or GUILD_ANNOUNCEMENT
    const voiceChannelCount = guild.channels.cache.filter(c => c.type === 2 || c.type === 13).size; // GUILD_VOICE or GUILD_STAGE_VOICE

    res.json({
      memberCount: guild.memberCount,
      onlineCount: guild.members.cache.filter(m => m.presence?.status && m.presence.status !== 'offline').size,
      textChannelCount,
      voiceChannelCount,
      roleCount: guild.roles.cache.size,
      boostCount: guild.premiumSubscriptionCount || 0,
      botPing: client.ws.ping,
      recentModActions: recentActions,
      upcomingEventsCount: upcomingEvents.length,
      nextEvent: upcomingEvents[0] || null,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Gagal mengambil statistik dashboard' });
  }
});

module.exports = router;
