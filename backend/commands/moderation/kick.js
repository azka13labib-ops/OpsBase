const { SlashCommandBuilder, PermissionFlagsBits, EmbedBuilder } = require('discord.js');
const { sendModLog } = require('../../utils/modlog');
const { logModAction } = require('../../supabase/moderation');
const { notifyAdmins } = require('../../services/push');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('kick')
    .setDescription('Mengeluarkan member dari server')
    .addUserOption(opt =>
      opt.setName('user').setDescription('Member yang akan dikeluarkan').setRequired(true))
    .addStringOption(opt =>
      opt.setName('alasan').setDescription('Alasan kick').setRequired(false))
    .setDefaultMemberPermissions(PermissionFlagsBits.KickMembers),

  async execute(interaction) {
    const target = interaction.options.getUser('user');
    const reason = interaction.options.getString('alasan') || 'Tidak ada alasan diberikan';

    const member = await interaction.guild.members.fetch(target.id).catch(() => null);
    if (!member) {
      return interaction.reply({ content: 'Member tidak ditemukan di server ini.', ephemeral: true });
    }
    if (!member.kickable) {
      return interaction.reply({ content: 'Bot tidak punya izin untuk kick member ini (cek posisi role bot).', ephemeral: true });
    }

    try {
      await target.send(`Kamu telah dikeluarkan dari server **${interaction.guild.name}**.\nAlasan: ${reason}`);
    } catch {
      // DM tertutup, abaikan
    }

    await member.kick(reason);

    const embed = new EmbedBuilder()
      .setColor(0xFF6600)
      .setTitle('👢 Member Dikeluarkan')
      .addFields(
        { name: 'Member', value: `${target.tag} (${target.id})`, inline: true },
        { name: 'Moderator', value: `<@${interaction.user.id}>`, inline: true },
        { name: 'Alasan', value: reason }
      )
      .setTimestamp();

    await interaction.reply({ embeds: [embed] });
    await sendModLog(interaction.guild, embed);
    await logModAction({
      guildId: interaction.guild.id, actionType: 'kick', targetId: target.id, targetTag: target.tag,
      moderatorId: interaction.user.id, moderatorTag: interaction.user.tag, reason, source: 'bot',
    });
    await notifyAdmins(interaction.guild.id, {
      title: '👢 Member Dikeluarkan', body: `${target.tag} di-kick oleh ${interaction.user.tag}`, type: 'kick',
    });
  },
};
