const { SlashCommandBuilder, PermissionFlagsBits, EmbedBuilder } = require('discord.js');
const { sendModLog } = require('../../utils/modlog');
const { logModAction } = require('../../supabase/moderation');
const { notifyAdmins } = require('../../services/push');

// Konversi string durasi sederhana seperti "10m", "1h", "2d" menjadi milidetik
function parseDuration(str) {
  const match = str.match(/^(\d+)(m|h|d)$/i);
  if (!match) return null;
  const value = parseInt(match[1], 10);
  const unit = match[2].toLowerCase();
  const multipliers = { m: 60_000, h: 3_600_000, d: 86_400_000 };
  return value * multipliers[unit];
}

module.exports = {
  data: new SlashCommandBuilder()
    .setName('mute')
    .setDescription('Membisukan member sementara (timeout)')
    .addUserOption(opt =>
      opt.setName('user').setDescription('Member yang akan dibisukan').setRequired(true))
    .addStringOption(opt =>
      opt.setName('durasi').setDescription('Durasi, contoh: 10m, 1h, 2d (maks 28d)').setRequired(true))
    .addStringOption(opt =>
      opt.setName('alasan').setDescription('Alasan mute').setRequired(false))
    .setDefaultMemberPermissions(PermissionFlagsBits.ModerateMembers),

  async execute(interaction) {
    const target = interaction.options.getUser('user');
    const durasiStr = interaction.options.getString('durasi');
    const reason = interaction.options.getString('alasan') || 'Tidak ada alasan diberikan';

    const ms = parseDuration(durasiStr);
    if (!ms || ms > 28 * 86_400_000) {
      return interaction.reply({ content: 'Format durasi tidak valid. Gunakan contoh: 10m, 1h, 2d (maksimal 28d).', ephemeral: true });
    }

    const member = await interaction.guild.members.fetch(target.id).catch(() => null);
    if (!member) {
      return interaction.reply({ content: 'Member tidak ditemukan di server ini.', ephemeral: true });
    }
    if (!member.moderatable) {
      return interaction.reply({ content: 'Bot tidak punya izin untuk mute member ini (cek posisi role bot).', ephemeral: true });
    }

    await member.timeout(ms, reason);

    const embed = new EmbedBuilder()
      .setColor(0x9966FF)
      .setTitle('🔇 Member Dibisukan')
      .addFields(
        { name: 'Member', value: `<@${target.id}>`, inline: true },
        { name: 'Moderator', value: `<@${interaction.user.id}>`, inline: true },
        { name: 'Durasi', value: durasiStr, inline: true },
        { name: 'Alasan', value: reason }
      )
      .setTimestamp();

    await interaction.reply({ embeds: [embed] });
    await sendModLog(interaction.guild, embed);
    await logModAction({
      guildId: interaction.guild.id, actionType: 'mute', targetId: target.id, targetTag: target.tag,
      moderatorId: interaction.user.id, moderatorTag: interaction.user.tag, reason: `${reason} (${durasiStr})`, source: 'bot',
    });
  },
};
