require('dotenv').config();
const { Client, GatewayIntentBits } = require('discord.js');
const { ROLE_NAMES } = require('../config/permissions');

/**
 * Script sekali-jalan untuk membuat role Discord yang dipakai sistem
 * permission app mobile (lihat config/permissions.js), kalau belum ada
 * di server. Aman dijalankan berkali-kali — role yang sudah ada dilewati,
 * tidak dibuat dobel.
 *
 * Jalankan: npm run setup-roles
 *
 * Butuh bot punya permission "Manage Roles" di server (Server Settings →
 * Roles, posisi role bot juga harus di atas role yang mau dia kelola nanti
 * kalau mau assign — tapi untuk SEKADAR membuat role, posisi tidak masalah).
 */

// Warna default per role, biar langsung enak dilihat di member list Discord
const ROLE_COLORS = {
  [ROLE_NAMES.OWNER]: 0xE74C3C,            // merah
  [ROLE_NAMES.DEVELOPER]: 0x9B59B6,        // ungu
  [ROLE_NAMES.EVENT_ORGANIZER]: 0x3498DB,  // biru
  [ROLE_NAMES.BRAND_AMBASSADOR]: 0xF1C40F, // kuning
  [ROLE_NAMES.SUPPORTER]: 0x2ECC71,        // hijau
};

async function main() {
  if (!process.env.DISCORD_TOKEN || !process.env.GUILD_ID) {
    console.error('❌ DISCORD_TOKEN dan GUILD_ID wajib diisi di .env sebelum menjalankan script ini.');
    process.exit(1);
  }

  const client = new Client({ intents: [GatewayIntentBits.Guilds] });

  await client.login(process.env.DISCORD_TOKEN);
  console.log(`✅ Bot login sebagai ${client.user.tag}`);

  const guild = await client.guilds.fetch(process.env.GUILD_ID);
  await guild.roles.fetch(); // pastikan cache role lengkap

  const botMember = await guild.members.fetch(client.user.id);
  if (!botMember.permissions.has('ManageRoles')) {
    console.error('❌ Bot tidak punya permission "Manage Roles" di server ini.');
    console.error('   Buka Server Settings → Roles di Discord, kasih bot permission Manage Roles,');
    console.error('   atau invite ulang bot dengan permission tsb dicentang.');
    await client.destroy();
    process.exit(1);
  }

  const roleNames = Object.values(ROLE_NAMES);
  console.log(`\n🔍 Mengecek ${roleNames.length} role: ${roleNames.join(', ')}\n`);

  for (const roleName of roleNames) {
    const existing = guild.roles.cache.find(r => r.name.toLowerCase() === roleName.toLowerCase());

    if (existing) {
      console.log(`⏭️  "${roleName}" sudah ada (ID: ${existing.id}) — dilewati`);
      continue;
    }

    try {
      const newRole = await guild.roles.create({
        name: roleName,
        color: ROLE_COLORS[roleName] || 0x99AAB5,
        hoist: true,     // tampil terpisah di daftar member
        mentionable: true,
        reason: 'Dibuat otomatis oleh setup-roles script (Community Suite)',
      });
      console.log(`✅ Berhasil membuat role "${roleName}" (ID: ${newRole.id})`);
    } catch (err) {
      console.error(`❌ Gagal membuat role "${roleName}": ${err.message}`);
    }
  }

  console.log('\n🎉 Selesai. Sekarang assign role-role ini ke member yang sesuai lewat Discord');
  console.log('   (klik kanan member → Roles → centang), lalu login ke app mobile untuk test.');

  await client.destroy();
  process.exit(0);
}

main().catch((err) => {
  console.error('❌ Terjadi error:', err);
  process.exit(1);
});
