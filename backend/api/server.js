const express = require('express');
const cors = require('cors');
const http = require('http');
const { Server } = require('socket.io');
const { requireAuth } = require('./middleware/requireAuth');

function createApiServer(discordClient) {
  const app = express();
  app.use(cors());
  app.use(express.json());

  const server = http.createServer(app);
  const io = new Server(server, {
    cors: {
      origin: "*",
      methods: ["GET", "POST"]
    }
  });

  // Simpan referensi bot client supaya semua route bisa akses Discord API
  app.set('discordClient', discordClient);
  app.set('io', io);

  io.on('connection', (socket) => {
    console.log('📱 Klien mobile terhubung ke WebSockets');
    
    socket.on('join_guild', (guildId) => {
      socket.join(`guild_${guildId}`);
      console.log(`📱 Klien bergabung ke room: guild_${guildId}`);
    });

    socket.on('disconnect', () => {
      console.log('📱 Klien mobile terputus');
    });
  });

  app.get('/health', (req, res) => res.json({ status: 'ok' }));

  // Semua route di bawah ini wajib login (Supabase Auth + role admin/moderator)
  app.use('/api/auth', requireAuth, require('./routes/auth'));
  app.use('/api/dashboard', requireAuth, require('./routes/dashboard'));
  app.use('/api/moderation', requireAuth, require('./routes/moderation'));
  app.use('/api/events', requireAuth, require('./routes/events'));
  app.use('/api/devices', requireAuth, require('./routes/devices'));

  app.use((req, res) => res.status(404).json({ error: 'Endpoint tidak ditemukan' }));

  return { app, server, io };
}

module.exports = { createApiServer };
