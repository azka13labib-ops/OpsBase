const express = require('express');
const router = express.Router();
const { requireCapability } = require('../middleware/requireCapability');
const { CAPABILITIES } = require('../../config/permissions');

// GET /api/members/search?q=username
router.get('/search', requireCapability(CAPABILITIES.DASHBOARD_VIEW), async (req, res) => {
  const query = req.query.q?.toLowerCase() || '';
  console.log(`[API] Member search query received: "${query}"`);
  
  if (!query || query.length < 2) {
    return res.json({ members: [] });
  }

  try {
    const guild = req.app.get('discordClient').guilds.cache.get(req.auth.guildId);
    if (!guild) {
      return res.status(404).json({ error: 'Server tidak ditemukan' });
    }

    // Fetch members with a 5 second timeout to prevent Flutter TimeoutException
    const fetchPromise = guild.members.fetch({ query, limit: 15 });
    const timeoutPromise = new Promise((_, reject) => setTimeout(() => reject(new Error('Discord API timeout')), 5000));
    
    const fetchedMembers = await Promise.race([fetchPromise, timeoutPromise]);
    
    const results = fetchedMembers.map(member => ({
      id: member.id,
      username: member.user.username,
      tag: member.user.tag,
      displayName: member.displayName,
      avatarUrl: member.user.displayAvatarURL({ dynamic: true, size: 64 })
    }));

    res.json({ members: results });
  } catch (err) {
    console.error('Error searching members:', err);
    res.status(500).json({ error: `Gagal mencari member: ${err.message}` });
  }
});

module.exports = router;
