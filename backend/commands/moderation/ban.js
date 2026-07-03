const { SlashCommandBuilder, PermissionFlagsBits, EmbedBuilder } = require('discord.js');
const { sendModLog } = require('../../utils/modlog');
const { logModAction } = require('../../supabase/moderation');
const { notifyAdmins } = require('../../services/push');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('ban')
    .setDescription('Mem-banned member dari server')
    .addUserOption(opt =>
      opt.setName('user').setDescription('Member yang akan di-ban').setRequired(true))
    .addStringOption(opt =>
      opt.setName('alasan').setDescription('Alasan ban').setRequired(false))
    .addIntegerOption(opt =>
      opt.setName('hapus_pesan_hari')
        .setDescription('Hapus pesan member dalam N hari terakhir (0-7)')
        .setMinValue(0)
        .setMaxValue(7)
        .setRequired(false))
    .setDefaultMemberPermissions(PermissionFlagsBits.BanMembers),

  async execute(interaction) {
    const target = interaction.options.getUser('user');
    const reason = interaction.options.getString('alasan') || 'Tidak ada alasan diberikan';
    const deleteDays = interaction.options.getInteger('hapus_pesan_hari') || 0;

    const member = await interaction.guild.members.fetch(target.id).catch(() => null);
    if (member && !member.bannable) {
      return interaction.reply({ content: 'Bot tidak punya izin untuk ban member ini (cek posisi role bot).', ephemeral: true });
    }

    try {
      await target.send(`Kamu telah di-ban dari server **${interaction.guild.name}**.\nAlasan: ${reason}`);
    } catch {
      // DM tertutup, abaikan
    }

    await interaction.guild.members.ban(target.id, {
      reason,
      deleteMessageSeconds: deleteDays * 24 * 60 * 60,
    });

    const embed = new EmbedBuilder()
      .setColor(0xFF0000)
      .setTitle('🔨 Member Di-ban')
      .addFields(
        { name: 'Member', value: `${target.tag} (${target.id})`, inline: true },
        { name: 'Moderator', value: `<@${interaction.user.id}>`, inline: true },
        { name: 'Alasan', value: reason }
      )
      .setTimestamp();

    await interaction.reply({ embeds: [embed] });
    await sendModLog(interaction.guild, embed);
    await logModAction({
      guildId: interaction.guild.id, actionType: 'ban', targetId: target.id, targetTag: target.tag,
      moderatorId: interaction.user.id, moderatorTag: interaction.user.tag, reason, source: 'bot',
    });
    await notifyAdmins(interaction.guild.id, {
      title: '🔨 Member Di-ban', body: `${target.tag} di-ban oleh ${interaction.user.tag}`, type: 'ban',
    });
  },
};
