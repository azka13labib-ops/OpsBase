const express = require('express');
const router = express.Router();

/**
 * Alur login (semua login sesungguhnya terjadi di Flutter app lewat Supabase Auth,
 * bukan di endpoint ini):
 *
 * 1. Flutter app pakai `supabase_flutter` SDK:
 *      supabase.auth.signInWithOAuth(OAuthProvider.discord)
 *    Aktifkan provider Discord di Supabase Dashboard → Authentication → Providers
 *    (butuh Client ID + Client Secret dari Discord Developer Portal, redirect URL
 *    dari Supabase ditempel di Discord OAuth2 settings).
 *
 * 2. Setelah sukses, Supabase kasih access_token ke app. App kirim token itu di
 *    header `Authorization: Bearer <token>` untuk setiap request ke backend ini.
 *
 * 3. Endpoint di bawah ini HANYA memverifikasi token tsb ke Supabase, lalu cek
 *    apakah user itu punya role admin/moderator di guild Discord kita (via bot).
 *    Backend tidak pernah menerbitkan token sendiri — cukup percaya Supabase.
 */

const { logoutUser } = require('../middleware/requireAuth');

// GET /api/auth/me — dipanggil app sekali setelah login untuk cek & simpan role
router.get('/me', async (req, res) => {
  // req.auth diisi oleh middleware requireAuth (lihat api/middleware/requireAuth.js)
  res.json({ user: req.auth });
});

// POST /api/auth/logout — menghapus cache user dari backend
router.post('/logout', (req, res) => {
  if (req.auth && req.auth.userId) {
    logoutUser(req.auth.userId);
  }
  res.json({ success: true, message: 'Logged out successfully' });
});

module.exports = router;
