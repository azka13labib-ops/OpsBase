const { SlashCommandBuilder, PermissionFlagsBits, EmbedBuilder } = require('discord.js');
const { addWarning, logModAction } = require('../../supabase/moderation');
const { sendModLog } = require('../../utils/modlog');
const { notifyAdmins } = require('../../services/push');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('warn')
    .setDescription('Memberi peringatan kepada member')
    .addUserOption(opt =>
      opt.setName('user').setDescription('Member yang akan diperingatkan').setRequired(true))
    .addStringOption(opt =>
      opt.setName('alasan').setDescription('Alasan peringatan').setRequired(true))
    .setDefaultMemberPermissions(PermissionFlagsBits.ModerateMembers),

  async execute(interaction) {
    const target = interaction.options.getUser('user');
    const reason = interaction.options.getString('alasan');

    if (target.id === interaction.user.id) {
      return interaction.reply({ content: 'Kamu tidak bisa memperingatkan dirimu sendiri.', ephemeral: true });
    }

    const warning = await addWarning(interaction.guild.id, target.id, reason, interaction.user.id);
    await logModAction({
      guildId: interaction.guild.id, actionType: 'warn', targetId: target.id, targetTag: target.tag,
      moderatorId: interaction.user.id, moderatorTag: interaction.user.tag, reason, source: 'bot',
    });

    const embed = new EmbedBuilder()
      .setColor(0xFFCC00)
      .setTitle('⚠️ Member Diperingatkan')
      .addFields(
        { name: 'Member', value: `<@${target.id}>`, inline: true },
        { name: 'Moderator', value: `<@${interaction.user.id}>`, inline: true },
        { name: 'Alasan', value: reason },
        { name: 'ID Warning', value: warning.id }
      )
      .setTimestamp();

    await interaction.reply({ embeds: [embed] });
    await sendModLog(interaction.guild, embed);
    await notifyAdmins(interaction.guild.id, {
      title: '⚠️ Warning Baru',
      body: `${target.tag} diperingatkan oleh ${interaction.user.tag}`,
      type: 'warn',
      data: { targetId: target.id, warningId: warning.id },
    });

    // Kirim DM ke user (opsional, jangan sampai error kalau DM tertutup)
    try {
      await target.send(`Kamu menerima peringatan di server **${interaction.guild.name}**.\nAlasan: ${reason}`);
    } catch {
      // DM ditutup, abaikan
    }
  },
};
