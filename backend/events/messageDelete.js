const { Events } = require('discord.js');
const { logModAction } = require('../supabase/moderation');

module.exports = {
  name: Events.MessageDelete,
  async execute(message, client) {
    if (!message.guild) return;
    
    // If message is partial and author is missing, we can't get their ID directly.
    if (!message.author) return;
    
    if (message.author.bot) return;

    // Default assume the user deleted it themselves
    let executorId = message.author.id;
    let executorTag = message.author.tag;
    let reason = `Menghapus pesannya sendiri di #${message.channel.name}`;
    
    // Attempt to fetch audit logs to see if a moderator deleted it
    try {
      if (message.guild.members.me.permissions.has('ViewAuditLog')) {
        const fetchedLogs = await message.guild.fetchAuditLogs({
          limit: 1,
          type: 72, // AuditLogEvent.MessageDelete
        });
        
        const deletionLog = fetchedLogs.entries.first();
        
        if (deletionLog) {
          const { executor, target, createdTimestamp, extra } = deletionLog;
          
          // Check if the log is recent (within 5 seconds) and matches the target/channel
          if (target.id === message.author.id && extra.channel.id === message.channel.id) {
            if (Date.now() - createdTimestamp < 5000) {
              executorId = executor.id;
              executorTag = executor.tag;
              reason = `Dihapus oleh moderator di #${message.channel.name}`;
            }
          }
        }
      }
      
      // Append some content if available
      if (message.content) {
        reason += ` - Isi: "${message.content.substring(0, 100)}"`;
      }

      await logModAction({
        guildId: message.guild.id,
        actionType: 'message_delete',
        targetId: message.author.id,
        targetTag: message.author.tag,
        moderatorId: executorId,
        moderatorTag: executorTag,
        reason: reason.substring(0, 1000),
        source: 'discord',
      });
      
      client.io?.to(`guild_${message.guild.id}`).emit('stats_updated');
    } catch (err) {
      console.error('Failed to log messageDelete', err);
    }
  },
};
