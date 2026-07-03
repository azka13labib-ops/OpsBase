const express = require('express');
const router = express.Router();
const { createEvent, listEvents, getEvent, deleteEvent, upsertRsvp, getRsvps } = require('../../supabase/events');
const { notifyAdmins } = require('../../services/push');
const { GuildScheduledEventPrivacyLevel, GuildScheduledEventEntityType } = require('discord.js');
const { requireCapability } = require('../middleware/requireCapability');
const { CAPABILITIES } = require('../../config/permissions');

// GET /api/events?upcoming=true
router.get('/', requireCapability(CAPABILITIES.DASHBOARD_VIEW), async (req, res) => {
  const upcomingOnly = req.query.upcoming !== 'false';
  try {
    const events = await listEvents(req.auth.guildId, { upcomingOnly });
    res.json({ events });
  } catch (err) {
    res.status(500).json({ error: 'Gagal mengambil daftar event' });
  }
});

// GET /api/events/:id  (termasuk daftar RSVP)
router.get('/:id', requireCapability(CAPABILITIES.DASHBOARD_VIEW), async (req, res) => {
  try {
    const event = await getEvent(req.params.id);
    const rsvps = await getRsvps(req.params.id);
    res.json({ event, rsvps });
  } catch (err) {
    res.status(404).json({ error: 'Event tidak ditemukan' });
  }
});

// POST /api/events  Body: { title, description, channelId, startTime, endTime, isRecurring, recurrenceRule, syncToDiscord }
router.post('/', requireCapability(CAPABILITIES.EVENTS_CREATE), async (req, res) => {
  const { title, description, channelId, startTime, endTime, isRecurring, recurrenceRule, syncToDiscord } = req.body;
  if (!title || !startTime) return res.status(400).json({ error: 'title dan startTime wajib diisi' });

  try {
    let discordEventId = null;

    // Opsional: buat juga "Scheduled Event" native di Discord biar muncul di app Discord
    if (syncToDiscord) {
      const guild = req.app.get('discordClient').guilds.cache.get(req.auth.guildId);
      const scheduledEvent = await guild.scheduledEvents.create({
        name: title,
        description: description || undefined,
        scheduledStartTime: new Date(startTime),
        scheduledEndTime: endTime ? new Date(endTime) : new Date(new Date(startTime).getTime() + 3600000),
        privacyLevel: GuildScheduledEventPrivacyLevel.GuildOnly,
        entityType: channelId ? GuildScheduledEventEntityType.Voice : GuildScheduledEventEntityType.External,
        channel: channelId || undefined,
        entityMetadata: channelId ? undefined : { location: 'Lihat di app' },
      });
      discordEventId = scheduledEvent.id;
    }

    const event = await createEvent({
      guildId: req.auth.guildId, discordEventId, title, description, channelId,
      startTime, endTime, isRecurring, recurrenceRule, createdBy: req.auth.userId,
    });

    await notifyAdmins(req.auth.guildId, {
      title: '📅 Event Baru', body: `${title} — dijadwalkan oleh ${req.auth.username}`, type: 'event',
    });

    req.app.get('io')?.to(`guild_${req.auth.guildId}`).emit('stats_updated');
    res.json({ event });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Gagal membuat event' });
  }
});

// POST /api/events/:id/rsvp  Body: { status: 'going'|'maybe'|'declined' }
// Catatan: RSVP biasanya dilakukan member biasa, bukan cuma admin — kalau mau dibuka
// untuk semua member (bukan cuma admin), longgarkan requireAuth khusus route ini.
router.post('/:id/rsvp', async (req, res) => {
  const { status = 'going' } = req.body;
  try {
    await upsertRsvp(req.params.id, req.auth.userId, req.auth.username, status);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Gagal RSVP' });
  }
});

// DELETE /api/events/:id
router.delete('/:id', requireCapability(CAPABILITIES.EVENTS_DELETE), async (req, res) => {
  try {
    await deleteEvent(req.params.id);
    req.app.get('io')?.to(`guild_${req.auth.guildId}`).emit('stats_updated');
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Gagal menghapus event' });
  }
});

module.exports = router;
