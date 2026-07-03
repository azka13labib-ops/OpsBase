const express = require('express');
const router = express.Router();
const { registerDevice, removeDevice } = require('../../supabase/devices');

// POST /api/devices/register  Body: { fcmToken, platform }
router.post('/register', async (req, res) => {
  const { fcmToken, platform } = req.body;
  if (!fcmToken) return res.status(400).json({ error: 'fcmToken wajib diisi' });

  try {
    await registerDevice(req.auth.guildId, req.auth.userId, fcmToken, platform);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Gagal mendaftarkan device' });
  }
});

// DELETE /api/devices/:fcmToken — dipanggil saat logout supaya berhenti menerima notif
router.delete('/:fcmToken', async (req, res) => {
  try {
    await removeDevice(req.params.fcmToken);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Gagal menghapus device' });
  }
});

module.exports = router;
