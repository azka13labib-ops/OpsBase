# Discord Community Suite — Backend (Bot + API)

Backend gabungan: bot Discord (moderasi, anti-spam) + REST API untuk aplikasi mobile
Flutter (dashboard, event management, quick moderation, push notification).

## 🏗️ Arsitektur

```
Flutter App ──(auth + baca data langsung, opsional)──> Supabase (Postgres + Auth + Realtime)
     │
     └──(login, aksi kick/ban/mute, buat event)──> Backend ini (Express + discord.js)
                                                          │
                                                          ├──> Discord (eksekusi aksi)
                                                          ├──> Supabase (baca/tulis data)
                                                          └──> Firebase (push notification)
```

- **Supabase**: database (Postgres), autentikasi admin (login via Discord OAuth provider),
  dan opsional realtime subscription untuk update live di app.
- **Backend ini**: satu-satunya pihak yang pegang **bot token Discord** — semua aksi
  moderasi (kick/ban/mute) dan pembuatan Scheduled Event Discord wajib lewat sini.
- **Firebase**: push notification ke HP admin (raid terdeteksi, spam, warning baru, event baru).

## 🔑 Sistem Role & Permission

Backend ini pakai **role Discord yang sudah ada** di server kamu untuk menentukan
apa yang boleh dilakukan seorang admin di app mobile. Bukan sistem level 1-2-3,
tapi kapabilitas per-role (lihat `config/permissions.js`).

Default mapping (edit di `config/permissions.js` atau lewat `.env` untuk ganti nama role):

| Role Discord | Warn | Mute | Kick | Ban | Kelola Event | Lihat Dashboard |
|---|---|---|---|---|---|---|
| Owner | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Developer | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Event Organizer | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| Brand Ambassador | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Supporter | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ |

- Member dengan permission **Administrator** di Discord otomatis dapat semua
  kapabilitas, apa pun nama role-nya (safety net).
- Member yang login tapi rolenya tidak ada di mapping akan ditolak (403) dengan
  pesan "Role kamu belum diberi akses apa pun di app ini."
- Kalau member punya lebih dari satu role (misal Developer + Support),
  kapabilitasnya digabung (union) — dapat kapabilitas dari kedua role tsb.
- Nama role harus **sama persis** (case-insensitive) dengan nama role di server
  Discord. Kalau kamu ganti nama role di Discord, update juga `ROLE_NAME_*` di `.env`.



### 1. Install dependencies
```bash
npm install
```

### 2. Setup Discord Bot
Sama seperti sebelumnya:
1. https://discord.com/developers/applications → New Application
2. Tab **Bot** → Reset Token → salin
3. Aktifkan intent: `SERVER MEMBERS INTENT`, `MESSAGE CONTENT INTENT`
4. Invite bot ke server dengan permission: Kick Members, Ban Members, Moderate Members,
   Manage Events, Send Messages, View Channels

### 3. Setup Supabase
1. Buka project Supabase kamu → **SQL Editor** → jalankan isi file `supabase/schema.sql`
2. Buka **Authentication → Providers → Discord** → aktifkan, isi Client ID & Client Secret
   dari Discord Developer Portal (Application kamu → OAuth2)
3. Di Discord Developer Portal → OAuth2 → Redirects, tambahkan URL redirect yang
   diberikan Supabase (format: `https://xxxxx.supabase.co/auth/v1/callback`)
4. Ambil `SUPABASE_URL`, `anon public key`, dan `service_role key` di
   **Project Settings → API**

### 4. Setup Firebase (push notification)
1. https://console.firebase.google.com → buat project baru
2. Project Settings → Service Accounts → **Generate new private key** → simpan sebagai
   `firebase-service-account.json` di root folder ini
3. Tambahkan Android/iOS app di Firebase project (dipakai nanti di Flutter)

### 5. Konfigurasi environment
```bash
cp .env.example .env
```
Isi semua variabel sesuai instruksi komentar di dalamnya.

### 6. Deploy slash command & jalankan
```bash
npm run deploy
npm start
```
Bot online + API server jalan di `http://localhost:3000` (atau sesuai `API_PORT`).

## 📂 Struktur Project
```
backend/
├── index.js                 # Entry point: start bot + API server bareng
├── deploy-commands.js        # Registrasi slash command
├── commands/moderation/      # warn, kick, ban, mute, unmute, dst (slash command)
├── events/                   # ready, interactionCreate, antiSpam
├── api/
│   ├── server.js             # Setup Express app + routing
│   ├── middleware/requireAuth.js   # Verifikasi token Supabase + cek role Discord
│   └── routes/
│       ├── auth.js           # GET /api/auth/me
│       ├── dashboard.js      # GET /api/dashboard/stats
│       ├── moderation.js     # warn/kick/ban/mute dari mobile + riwayat
│       ├── events.js         # CRUD event + RSVP
│       └── devices.js        # Registrasi FCM token
├── supabase/
│   ├── client.js              # Koneksi Supabase (service_role, dipakai backend)
│   ├── schema.sql             # Jalankan ini di Supabase SQL Editor
│   ├── moderation.js          # Query warnings + audit log
│   ├── events.js              # Query events + RSVP
│   └── devices.js             # Query FCM token
├── services/push.js          # Kirim push notification via Firebase
└── utils/modlog.js           # Kirim embed log ke channel Discord
```

## 📋 REST API Endpoints (untuk Flutter)

Semua endpoint (kecuali `/health`) wajib header:
`Authorization: Bearer <supabase_access_token>`

| Method | Endpoint | Keterangan |
|---|---|---|
| GET | `/api/auth/me` | Info user login + role |
| GET | `/api/dashboard/stats` | Ringkasan: member count, aksi terakhir, event mendatang |
| GET | `/api/moderation/history?limit=&offset=` | Audit log semua aksi moderasi |
| GET | `/api/moderation/warnings/:userId` | Riwayat warning seorang member |
| POST | `/api/moderation/warn` | `{ userId, userTag, reason }` |
| POST | `/api/moderation/kick` | `{ userId, reason }` |
| POST | `/api/moderation/ban` | `{ userId, reason, deleteMessageDays }` |
| POST | `/api/moderation/mute` | `{ userId, durationMs, reason }` |
| GET | `/api/events?upcoming=true` | Daftar event |
| POST | `/api/events` | `{ title, description, channelId, startTime, endTime, isRecurring, recurrenceRule, syncToDiscord }` |
| POST | `/api/events/:id/rsvp` | `{ status: 'going'\|'maybe'\|'declined' }` |
| DELETE | `/api/events/:id` | Hapus event |
| POST | `/api/devices/register` | `{ fcmToken, platform }` — daftar HP untuk push notif |

## 🔐 Alur Login dari Flutter (ringkas)
1. App panggil `supabase.auth.signInWithOAuth(OAuthProvider.discord)`
2. User login via Discord di browser/webview, redirect balik ke app
3. Supabase kasih `access_token` → app simpan (secure storage)
4. Setiap request ke backend ini, sertakan `Authorization: Bearer <access_token>`
5. Backend verifikasi ke Supabase + cek role Discord (admin/moderator) sebelum kasih akses

## ⚠️ Catatan Keamanan
- `SUPABASE_SERVICE_ROLE_KEY` **hanya** boleh ada di backend ini. Kalau bocor ke app
  mobile atau publik, semua RLS bisa dilewati siapa saja.
- `SUPABASE_ANON_KEY` aman untuk ditaruh di Flutter app (dibatasi RLS policy).
- Bot harus tetap jalan terus-menerus (VPS/server, bukan serverless) karena connect
  ke Discord Gateway lewat WebSocket.
