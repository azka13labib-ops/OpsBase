const { Events } = require('discord.js');
const { logModAction } = require('../supabase/moderation');
const { notifyAdmins } = require('../services/push');

// Konfigurasi: berapa pesan dalam berapa detik dianggap spam
const MESSAGE_LIMIT = 5;      // maksimal 5 pesan
const TIME_WINDOW_MS = 5000;  // dalam 5 detik
const TIMEOUT_DURATION_MS = 60_000; // 1 menit timeout jika terdeteksi spam

// Menyimpan riwayat pesan per user secara in-memory
// Struktur: Map<userId, timestamp[]>
const userMessageLog = new Map();

module.exports = {
  name: Events.MessageCreate,
  async execute(message) {
    if (message.author.bot || !message.guild) return;

    const now = Date.now();
    const key = `${message.guild.id}-${message.author.id}`;
    const timestamps = userMessageLog.get(key) || [];

    // Buang timestamp yang sudah di luar window waktu
    const recentTimestamps = timestamps.filter(t => now - t < TIME_WINDOW_MS);
    recentTimestamps.push(now);
    userMessageLog.set(key, recentTimestamps);

    if (recentTimestamps.length > MESSAGE_LIMIT) {
      userMessageLog.set(key, []); // reset supaya tidak trigger berulang kali

      const member = message.member;
      if (member && member.moderatable) {
        try {
          await member.timeout(TIMEOUT_DURATION_MS, 'Terdeteksi spam otomatis');
          await message.channel.send({
            content: `⚠️ <@${message.author.id}> terdeteksi mengirim pesan terlalu cepat dan dibisukan sementara (1 menit).`,
          });
          await logModAction({
            guildId: message.guild.id, actionType: 'auto-mute-spam', targetId: message.author.id,
            targetTag: message.author.tag, moderatorId: 'system', moderatorTag: 'Auto-Moderation',
            reason: 'Terdeteksi spam otomatis', source: 'bot',
          });
          await notifyAdmins(message.guild.id, {
            title: '🚨 Spam Terdeteksi', body: `${message.author.tag} dibisukan otomatis karena spam`, type: 'spam',
          });
        } catch (err) {
          console.error('Gagal timeout user spam:', err.message);
        }
      }
    }
  },
};
