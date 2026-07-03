const { Events, AuditLogEvent } = require('discord.js');
const { logModAction } = require('../supabase/moderation');

module.exports = {
  name: Events.GuildAuditLogEntryCreate,
  async execute(auditLog, guild, client) {
    // Abaikan aksi yang dilakukan oleh bot ini sendiri (karena sudah dicatat otomatis saat hit API/Slash Command)
    if (auditLog.executorId === client.user.id) return;

    let actionType = null;
    let targetTag = auditLog.target?.tag || auditLog.targetId;
    
    switch (auditLog.action) {
      case AuditLogEvent.MemberKick:
        actionType = 'kick';
        break;
      case AuditLogEvent.MemberBanAdd:
        actionType = 'ban';
        break;
      case AuditLogEvent.MemberBanRemove:
        actionType = 'unban';
        break;
      case AuditLogEvent.MemberUpdate:
        // Cek apakah perubahan ini adalah pemberian Timeout (Mute)
        const timeoutChange = auditLog.changes.find(c => c.key === 'communication_disabled_until');
        if (timeoutChange) {
          if (timeoutChange.new) {
            actionType = 'mute';
          } else {
            actionType = 'unmute';
          }
        }
        break;
    }

    if (!actionType) return;

    try {
      await logModAction({
        guildId: guild.id,
        actionType,
        targetId: auditLog.targetId,
        targetTag,
        moderatorId: auditLog.executorId,
        moderatorTag: auditLog.executor?.tag || auditLog.executorId,
        reason: auditLog.reason || 'Dilakukan langsung dari Discord',
        source: 'discord',
      });
      client.io?.to(`guild_${guild.id}`).emit('stats_updated');
    } catch (err) {
      console.error('Gagal mencatat audit log Discord ke Supabase:', err);
    }
  },
};
