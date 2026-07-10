const { Events } = require('discord.js');
const { logModAction } = require('../supabase/moderation');

module.exports = {
  name: Events.MessageDelete,
  async execute(message, client) {
    if (!message.guild) return;
    
    if (!message.author) return;
    
    if (message.author.bot) return;

    let executorId = message.author.id;
    let executorTag = message.author.tag;
    let reason = `Menghapus pesannya sendiri di #${message.channel.name}`;
    
    try {
      if (message.guild.members.me.permissions.has('ViewAuditLog')) {
        const fetchedLogs = await message.guild.fetchAuditLogs({
          limit: 1,
          type: 72, 
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

      // Send to discord log channel
      const logChannel = message.guild.channels.cache.find(c => c.name === 'admin-logs' || c.name === 'audit-log' || c.name === 'logs');
      if (logChannel) {
        const { EmbedBuilder } = require('discord.js');
        const embed = new EmbedBuilder()
          .setColor('#ED4245')
          .setAuthor({ name: message.author.tag, iconURL: message.author.displayAvatarURL() })
          .setDescription(`**Message sent by <@${message.author.id}> deleted in <#${message.channel.id}>**\n${message.content || '*No text content*'}`)
          .addFields(
            { name: 'Author', value: `<@${message.author.id}> (${message.author.id})`, inline: true },
            { name: 'Channel', value: `<#${message.channel.id}>`, inline: true }
          )
          .setTimestamp();
          
        if (executorId !== message.author.id) {
            embed.addFields({ name: 'Deleted By', value: `<@${executorId}> (${executorId})`, inline: false });
        }
        
        await logChannel.send({ embeds: [embed] }).catch(console.error);
      }
    } catch (err) {
      console.error('Failed to log messageDelete', err);
    }
  },
};
