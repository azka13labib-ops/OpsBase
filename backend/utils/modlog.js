async function sendModLog(guild, embed) {
  const channelId = process.env.MOD_LOG_CHANNEL_ID;
  if (!channelId) return; // Belum dikonfigurasi, lewati saja

  const channel = guild.channels.cache.get(channelId);
  if (!channel) return;

  try {
    await channel.send({ embeds: [embed] });
  } catch (err) {
    console.error('Gagal mengirim mod log:', err.message);
  }
}

module.exports = { sendModLog };
