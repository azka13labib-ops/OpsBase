/**
 * Middleware factory: pastikan req.auth.capabilities (diisi oleh requireAuth)
 * mengandung kapabilitas yang dibutuhkan. Pakai SETELAH requireAuth di route.
 *
 * Contoh: router.post('/ban', requireCapability(CAPABILITIES.MODERATE_BAN), handler)
 */
function requireCapability(capability) {
  return (req, res, next) => {
    if (!req.auth?.capabilities?.includes(capability)) {
      return res.status(403).json({
        error: `Role kamu (${req.auth?.roleNames?.join(', ') || 'tidak diketahui'}) tidak punya akses untuk aksi ini`,
        requiredCapability: capability,
      });
    }
    next();
  };
}

module.exports = { requireCapability };
