const { SlashCommandBuilder, PermissionFlagsBits, EmbedBuilder } = require('discord.js');
const { sendModLog } = require('../../utils/modlog');
const { logModAction } = require('../../supabase/moderation');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('unmute')
    .setDescription('Membatalkan mute (timeout) member')
    .addUserOption(opt =>
      opt.setName('user').setDescription('Member yang akan di-unmute').setRequired(true))
    .setDefaultMemberPermissions(PermissionFlagsBits.ModerateMembers),

  async execute(interaction) {
    const target = interaction.options.getUser('user');
    const member = await interaction.guild.members.fetch(target.id).catch(() => null);

    if (!member) {
      return interaction.reply({ content: 'Member tidak ditemukan di server ini.', ephemeral: true });
    }
    if (!member.isCommunicationDisabled()) {
      return interaction.reply({ content: 'Member ini sedang tidak dalam status mute.', ephemeral: true });
    }

    await member.timeout(null);

    const embed = new EmbedBuilder()
      .setColor(0x00CC66)
      .setTitle('🔊 Member Di-unmute')
      .addFields(
        { name: 'Member', value: `<@${target.id}>`, inline: true },
        { name: 'Moderator', value: `<@${interaction.user.id}>`, inline: true }
      )
      .setTimestamp();

    await interaction.reply({ embeds: [embed] });
    await sendModLog(interaction.guild, embed);
    await logModAction({
      guildId: interaction.guild.id, actionType: 'unmute', targetId: target.id, targetTag: target.tag,
      moderatorId: interaction.user.id, moderatorTag: interaction.user.tag, source: 'bot',
    });
  },
};
