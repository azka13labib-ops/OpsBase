const express = require('express');
const cors = require('cors');
const http = require('http');
const { Server } = require('socket.io');
const rateLimit = require('express-rate-limit');
const { createClient } = require('@supabase/supabase-js');
const { requireAuth } = require('./middleware/requireAuth');

// ─── [SEC-03] Whitelist CORS ────────────────────────────────────────────────
// Izinkan hanya origin dari env var FRONTEND_URL (production) atau localhost
// (development). App mobile Flutter menggunakan skema custom, bukan HTTP origin,
// sehingga tidak perlu di-whitelist di sini (Flutter tidak mengirim header Origin).
const rawOrigins = (process.env.FRONTEND_URL || '')
  .split(',')
  .map((o) => o.trim())
  .filter(Boolean);

// Selalu tambahkan localhost untuk kemudahan development
const allowedOrigins = [...rawOrigins, 'http://localhost:3000', 'http://127.0.0.1:3000'];

const corsOptions = {
  origin: (origin, callback) => {
    // origin undefined = request dari native mobile app atau curl — izinkan
    if (!origin || allowedOrigins.includes(origin)) return callback(null, true);
    callback(new Error(`Origin '${origin}' tidak diizinkan oleh CORS`));
  },
  methods: ['GET', 'POST', 'DELETE', 'PUT', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization'],
};

// ─── [SEC-04] Supabase client untuk validasi token di WebSocket ─────────────
const supabaseAuth = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY,
);

// ─── [SEC-05] Rate limiters ──────────────────────────────────────────────────
// Limiter umum: 60 request/menit per IP
const generalLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 60,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Terlalu banyak request, coba lagi dalam 1 menit.' },
});

// Limiter ketat untuk moderasi: 10 request/menit per IP
const moderationLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Terlalu banyak aksi moderasi, coba lagi dalam 1 menit.' },
});

function createApiServer(discordClient) {
  const app = express();

  // [SEC-03] Terapkan CORS whitelist
  app.use(cors(corsOptions));
  app.use(express.json());

  const server = http.createServer(app);

  // [SEC-03] Terapkan CORS whitelist yang sama di Socket.IO
  const io = new Server(server, {
    cors: {
      origin: corsOptions.origin,
      methods: ['GET', 'POST'],
    },
  });

  // Simpan referensi bot client supaya semua route bisa akses Discord API
  app.set('discordClient', discordClient);
  app.set('io', io);

  // ─── [SEC-04] Middleware autentikasi WebSocket ───────────────────────────
  // Setiap koneksi WebSocket harus menyertakan Supabase access token di
  // socket.handshake.auth.token. Tolak koneksi jika token tidak ada/tidak valid.
  io.use(async (socket, next) => {
    const token = socket.handshake.auth?.token;
    if (!token) {
      return next(new Error('WebSocket: token autentikasi wajib diisi'));
    }

    try {
      const { data: { user }, error } = await supabaseAuth.auth.getUser(token);
      if (error || !user) {
        return next(new Error('WebSocket: token tidak valid atau sudah kedaluwarsa'));
      }
      // Simpan userId di socket supaya bisa dipakai di handler berikutnya
      socket.userId = user.user_metadata?.provider_id || user.id;
      next();
    } catch (err) {
      next(new Error('WebSocket: gagal memverifikasi token'));
    }
  });

  io.on('connection', (socket) => {
    console.log(`📱 Klien mobile terhubung (userId: ${socket.userId})`);

    socket.on('join_guild', (guildId) => {
      socket.join(`guild_${guildId}`);
      console.log(`📱 Klien (userId: ${socket.userId}) bergabung ke room: guild_${guildId}`);
    });

    socket.on('disconnect', () => {
      console.log(`📱 Klien mobile terputus (userId: ${socket.userId})`);
    });
  });

  // ─── [SEC-05] Terapkan rate limiters ────────────────────────────────────
  // Rate limiter moderation HARUS dipasang sebelum limiter umum agar nilai
  // yang lebih ketat menang untuk path /api/moderation/*
  app.use('/api/moderation', moderationLimiter);
  app.use('/api/', generalLimiter);

  app.get('/health', (req, res) => res.json({ status: 'ok' }));

  // Semua route di bawah ini wajib login (Supabase Auth + role admin/moderator)
  app.use('/api/auth', requireAuth, require('./routes/auth'));
  app.use('/api/dashboard', requireAuth, require('./routes/dashboard'));
  app.use('/api/moderation', requireAuth, require('./routes/moderation'));
  app.use('/api/events', requireAuth, require('./routes/events'));
  app.use('/api/devices', requireAuth, require('./routes/devices'));

  app.use((req, res) => res.status(404).json({ error: 'Endpoint tidak ditemukan' }));

  // Global error handler untuk menangkap error (misal dari CORS) dan mencegah leak stack trace
  app.use((err, req, res, next) => {
    if (err.message && err.message.includes('oleh CORS')) {
      return res.status(403).json({ error: 'Origin tidak diizinkan' });
    }
    
    // Log error di server, tapi kirim pesan generik ke client (aman untuk production)
    console.error('Terjadi error:', err);
    res.status(500).json({ error: 'Terjadi kesalahan internal pada server' });
  });

  return { app, server, io };
}

module.exports = { createApiServer };
