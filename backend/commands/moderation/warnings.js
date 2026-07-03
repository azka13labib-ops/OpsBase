const { SlashCommandBuilder, PermissionFlagsBits, EmbedBuilder } = require('discord.js');
const { getWarnings } = require('../../supabase/moderation');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('warnings')
    .setDescription('Melihat daftar peringatan seorang member')
    .addUserOption(opt =>
      opt.setName('user').setDescription('Member yang ingin dicek').setRequired(true))
    .setDefaultMemberPermissions(PermissionFlagsBits.ModerateMembers),

  async execute(interaction) {
    const target = interaction.options.getUser('user');
    const warnings = await getWarnings(interaction.guild.id, target.id);

    if (warnings.length === 0) {
      return interaction.reply({ content: `${target.username} belum pernah mendapat peringatan.`, ephemeral: true });
    }

    const embed = new EmbedBuilder()
      .setColor(0xFFCC00)
      .setTitle(`Riwayat Peringatan: ${target.username}`)
      .setDescription(
        warnings
          .map((w, i) => `**${i + 1}.** [${w.id}] ${w.reason}\n> Oleh <@${w.moderator_id}> pada ${new Date(w.created_at).toLocaleString('id-ID')}`)
          .join('\n\n')
      )
      .setFooter({ text: `Total: ${warnings.length} peringatan` });

    await interaction.reply({ embeds: [embed], ephemeral: true });
  },
};
