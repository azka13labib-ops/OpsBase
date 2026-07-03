const express = require('express');
const router = express.Router();
const { addWarning, getWarnings, clearWarnings, logModAction, getModActions } = require('../../supabase/moderation');
const { notifyAdmins } = require('../../services/push');
const { requireCapability } = require('../middleware/requireCapability');
const { CAPABILITIES } = require('../../config/permissions');

// GET /api/moderation/history — audit log untuk dashboard mobile
router.get('/history', requireCapability(CAPABILITIES.DASHBOARD_VIEW), async (req, res) => {
  const limit = Math.min(parseInt(req.query.limit) || 50, 100);
  const offset = parseInt(req.query.offset) || 0;
  try {
    const history = await getModActions(req.auth.guildId, { limit, offset });
    res.json({ history });
  } catch (err) {
    res.status(500).json({ error: 'Gagal mengambil riwayat moderasi' });
  }
});

// GET /api/moderation/warnings/:userId
router.get('/warnings/:userId', requireCapability(CAPABILITIES.DASHBOARD_VIEW), async (req, res) => {
  try {
    const warnings = await getWarnings(req.auth.guildId, req.params.userId);
    res.json({ warnings });
  } catch (err) {
    res.status(500).json({ error: 'Gagal mengambil warning' });
  }
});

// POST /api/moderation/warn  Body: { userId, userTag, reason }
router.post('/warn', requireCapability(CAPABILITIES.MODERATE_WARN), async (req, res) => {
  const { userId, userTag, reason } = req.body;
  if (!userId || !reason) return res.status(400).json({ error: 'userId dan reason wajib diisi' });

  try {
    const warning = await addWarning(req.auth.guildId, userId, reason, req.auth.userId);
    await logModAction({
      guildId: req.auth.guildId, actionType: 'warn', targetId: userId, targetTag: userTag,
      moderatorId: req.auth.userId, moderatorTag: req.auth.username, reason, source: 'mobile',
    });
    req.app.get('io')?.to(`guild_${req.auth.guildId}`).emit('stats_updated');
    res.json({ warning });
  } catch (err) {
    res.status(500).json({ error: 'Gagal menambah warning' });
  }
});

// POST /api/moderation/kick  Body: { userId, reason }
router.post('/kick', requireCapability(CAPABILITIES.MODERATE_KICK), async (req, res) => {
  const { userId, reason } = req.body;
  if (!userId) return res.status(400).json({ error: 'userId wajib diisi' });

  try {
    const guild = req.app.get('discordClient').guilds.cache.get(req.auth.guildId);
    const member = await guild.members.fetch(userId).catch(() => null);
    if (!member) return res.status(404).json({ error: 'Member tidak ditemukan' });
    if (!member.kickable) return res.status(403).json({ error: 'Bot tidak punya izin kick member ini' });

    const userTag = member.user.tag;
    await member.kick(reason || 'Dikeluarkan lewat aplikasi mobile');
    await logModAction({
      guildId: req.auth.guildId, actionType: 'kick', targetId: userId, targetTag: userTag,
      moderatorId: req.auth.userId, moderatorTag: req.auth.username, reason, source: 'mobile',
    });
    req.app.get('io')?.to(`guild_${req.auth.guildId}`).emit('stats_updated');
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Gagal kick member' });
  }
});

// POST /api/moderation/ban  Body: { userId, reason, deleteMessageDays }
router.post('/ban', requireCapability(CAPABILITIES.MODERATE_BAN), async (req, res) => {
  const { userId, reason, deleteMessageDays = 0 } = req.body;
  if (!userId) return res.status(400).json({ error: 'userId wajib diisi' });

  try {
    const guild = req.app.get('discordClient').guilds.cache.get(req.auth.guildId);
    const member = await guild.members.fetch(userId).catch(() => null);
    if (member && !member.bannable) return res.status(403).json({ error: 'Bot tidak punya izin ban member ini' });

    await guild.members.ban(userId, { reason, deleteMessageSeconds: deleteMessageDays * 86400 });
    await logModAction({
      guildId: req.auth.guildId, actionType: 'ban', targetId: userId, targetTag: member?.user.tag,
      moderatorId: req.auth.userId, moderatorTag: req.auth.username, reason, source: 'mobile',
    });
    req.app.get('io')?.to(`guild_${req.auth.guildId}`).emit('stats_updated');
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Gagal ban member' });
  }
});

// POST /api/moderation/mute  Body: { userId, durationMs, reason }
router.post('/mute', requireCapability(CAPABILITIES.MODERATE_MUTE), async (req, res) => {
  const { userId, durationMs, reason } = req.body;
  if (!userId || !durationMs) return res.status(400).json({ error: 'userId dan durationMs wajib diisi' });
  if (durationMs > 28 * 86400000) return res.status(400).json({ error: 'Durasi maksimal 28 hari' });

  try {
    const guild = req.app.get('discordClient').guilds.cache.get(req.auth.guildId);
    const member = await guild.members.fetch(userId).catch(() => null);
    if (!member) return res.status(404).json({ error: 'Member tidak ditemukan' });
    if (!member.moderatable) return res.status(403).json({ error: 'Bot tidak punya izin mute member ini' });

    await member.timeout(durationMs, reason || 'Dibisukan lewat aplikasi mobile');
    await logModAction({
      guildId: req.auth.guildId, actionType: 'mute', targetId: userId, targetTag: member.user.tag,
      moderatorId: req.auth.userId, moderatorTag: req.auth.username, reason, source: 'mobile',
    });
    req.app.get('io')?.to(`guild_${req.auth.guildId}`).emit('stats_updated');
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Gagal mute member' });
  }
});

module.exports = router;
