const { SlashCommandBuilder, PermissionFlagsBits, EmbedBuilder } = require('discord.js');
const { clearWarnings, logModAction } = require('../../supabase/moderation');
const { sendModLog } = require('../../utils/modlog');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('clearwarnings')
    .setDescription('Menghapus semua peringatan seorang member')
    .addUserOption(opt =>
      opt.setName('user').setDescription('Member yang warning-nya ingin dihapus').setRequired(true))
    .setDefaultMemberPermissions(PermissionFlagsBits.ModerateMembers),

  async execute(interaction) {
    const target = interaction.options.getUser('user');
    await clearWarnings(interaction.guild.id, target.id);
    await logModAction({
      guildId: interaction.guild.id, actionType: 'clearwarnings', targetId: target.id, targetTag: target.tag,
      moderatorId: interaction.user.id, moderatorTag: interaction.user.tag, source: 'bot',
    });

    const embed = new EmbedBuilder()
      .setColor(0x00CC66)
      .setTitle('🧹 Peringatan Dihapus')
      .addFields(
        { name: 'Member', value: `<@${target.id}>`, inline: true },
        { name: 'Moderator', value: `<@${interaction.user.id}>`, inline: true }
      )
      .setTimestamp();

    await interaction.reply({ embeds: [embed] });
    await sendModLog(interaction.guild, embed);
  },
};
