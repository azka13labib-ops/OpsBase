const { createClient } = require('@supabase/supabase-js');
const { getCapabilitiesForMember } = require('../../config/permissions');

// Client khusus untuk verifikasi token user (pakai anon key, bukan service_role)
const supabaseAuth = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY);

// Cache kapabilitas per user supaya tidak fetch member Discord di setiap request (5 menit)
const authCache = new Map(); // userId -> { value, expiresAt }
const AUTH_CACHE_TTL_MS = 60 * 1000; // 60 detik

/**
 * Middleware: cek header Authorization: Bearer <supabase_access_token>,
 * verifikasi ke Supabase, lalu hitung kapabilitas user berdasarkan role
 * Discord yang dia punya (lihat config/permissions.js).
 * Hasil disimpan di req.auth = { userId, username, avatar, capabilities, roleNames, guildId }
 */
async function requireAuth(req, res, next) {
  const authHeader = req.headers.authorization || '';
  const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;

  if (!token) {
    return res.status(401).json({ error: 'Header Authorization: Bearer <token> wajib diisi' });
  }

  const { data: { user }, error } = await supabaseAuth.auth.getUser(token);
  if (error || !user) {
    return res.status(401).json({ error: 'Token tidak valid atau sudah kedaluwarsa' });
  }

  // Discord user ID disimpan Supabase di user_metadata.provider_id saat login via Discord OAuth
  const discordUserId = user.user_metadata?.provider_id || user.user_metadata?.sub;
  if (!discordUserId) {
    return res.status(400).json({ error: 'Akun ini tidak login lewat Discord' });
  }

  const cached = authCache.get(discordUserId);
  if (cached && cached.expiresAt > Date.now()) {
    req.auth = cached.value;
    return next();
  }

  try {
    const client = req.app.get('discordClient');
    const guild = client.guilds.cache.get(process.env.GUILD_ID);
    const member = await guild.members.fetch(discordUserId).catch(() => null);

    if (!member) {
      return res.status(403).json({ error: 'Kamu bukan member server ini' });
    }

    const capabilities = getCapabilitiesForMember(member);

    if (capabilities.length === 0) {
      return res.status(403).json({ error: 'Role kamu belum diberi akses apa pun di app ini. Hubungi Owner/Developer server.' });
    }

    const authValue = {
      userId: discordUserId,
      username: member.user.username,
      avatar: member.user.avatar,
      capabilities,
      roleNames: member.roles.cache.map(r => r.name),
      guildId: process.env.GUILD_ID,
    };

    authCache.set(discordUserId, { value: authValue, expiresAt: Date.now() + AUTH_CACHE_TTL_MS });
    req.auth = authValue;
    next();
  } catch (err) {
    console.error('Gagal verifikasi role:', err);
    res.status(500).json({ error: 'Gagal memverifikasi permission' });
  }
}

function logoutUser(discordUserId) {
  authCache.delete(discordUserId);
}

module.exports = { requireAuth, logoutUser };
