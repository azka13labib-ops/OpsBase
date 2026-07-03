# Checklist Manual — Ini HARUS Kamu Sendiri yang Lakukan

AI agent tidak punya akses ke akun/dashboard kamu, jadi bagian-bagian ini
wajib kamu kerjakan sendiri lewat browser. Setelah semua ini beres, baru
suruh AI agent kamu jalankan `PROMPT_UNTUK_AI_AGENT.md`.

## 1. Discord Developer Portal (https://discord.com/developers/applications)
- [ ] Buka aplikasi bot kamu → tab **Bot**
- [ ] Aktifkan toggle `SERVER MEMBERS INTENT` dan `MESSAGE CONTENT INTENT`
- [ ] Klik **Reset Token** → salin token → tempel ke `backend/.env` sebagai `DISCORD_TOKEN`
- [ ] Tab **General Information** → salin **Application ID** → tempel sebagai `CLIENT_ID`
- [ ] Tab **OAuth2** → salin **Client Secret** (dipakai nanti di langkah Supabase)
- [ ] Tab **OAuth2 → URL Generator** → centang scope `bot` + `applications.commands`,
      centang permission: Kick Members, Ban Members, Moderate Members, Manage Events,
      **Manage Roles** (penting — dipakai script otomatis buat role), Send Messages,
      View Channels → buka URL yang muncul → invite bot ke server kamu
- [ ] Aktifkan Developer Mode di Discord (Settings → Advanced) → klik kanan nama
      server kamu → Copy Server ID → tempel sebagai `GUILD_ID` di `.env`

## 2. Supabase Dashboard (https://supabase.com/dashboard)
- [ ] Buka project kamu → **SQL Editor** → New Query → paste isi `backend/supabase/schema.sql` → **Run**
- [ ] **Authentication → Providers → Discord** → aktifkan, isi:
      - Client ID = Application ID dari Discord (langkah 1)
      - Client Secret = Client Secret dari Discord (langkah 1)
- [ ] Copy **Callback URL** yang muncul di halaman itu (formatnya
      `https://xxxxx.supabase.co/auth/v1/callback`)
- [ ] Balik ke Discord Developer Portal → tab **OAuth2 → Redirects** → tempel
      Callback URL tadi → Save
- [ ] **Project Settings → API** → salin 3 nilai ini:
      - `Project URL` → tempel sebagai `SUPABASE_URL` di `backend/.env` DAN di
        `mobile-app/lib/config.dart`
      - `anon public` key → tempel sebagai `SUPABASE_ANON_KEY` (di kedua tempat juga)
      - `service_role` key → tempel HANYA sebagai `SUPABASE_SERVICE_ROLE_KEY` di
        `backend/.env` — **JANGAN PERNAH** taruh key ini di `config.dart` / mobile app

## 3. Firebase Console (https://console.firebase.google.com)
- [ ] Buat project baru (atau pakai yang sudah ada)
- [ ] **Project Settings → Service Accounts** → tab ini → klik
      **Generate new private key** → file JSON ke-download
- [ ] Rename file itu jadi `firebase-service-account.json` → taruh di folder `backend/`
- [ ] Tambahkan app Android & iOS di project Firebase ini (Project Settings →
      General → Add app) — nanti dipakai otomatis saat AI agent jalankan
      `flutterfire configure`

## 4. Nama Role Discord (kalau beda dari default)
Sistem permission app pakai role Discord: **Owner, Developer, Event Organizer,
Brand Ambassador, Supporter**. AI agent akan buatkan role ini OTOMATIS lewat
script (`npm run setup-roles`) — kamu tidak perlu bikin manual.
- [ ] Kalau kamu mau nama role BEDA dari default di atas, isi dulu variabel
      `ROLE_NAME_*` di `backend/.env` SEBELUM minta agent jalankan script setup-roles
- [ ] Setelah role dibuat (oleh agent), **kamu** yang assign role ke tiap
      member (klik kanan member → Roles → centang) — ini keputusan manusia,
      agent tidak akan menebak siapa dapat role apa

## 5. Setelah semua di atas beres
- [ ] Buka `backend/.env`, pastikan tidak ada lagi teks placeholder seperti
      `isi_token_bot_disini` — semua sudah terisi nilai asli
- [ ] Buka `mobile-app/lib/config.dart`, pastikan `supabaseUrl` dan
      `supabaseAnonKey` sudah terisi nilai asli (sama dengan yang di `.env`)
- [ ] **Baru setelah ini**, kasih file `PROMPT_UNTUK_AI_AGENT.md` ke AI agent
      kamu (Claude Code atau sejenisnya) dan minta dia jalankan semua tahapnya

## Yang perlu kamu lakukan interaktif SAAT proses (agent akan minta ini)
- `flutterfire configure` — ini akan buka browser untuk login akun Google/Firebase
  kamu, agent tidak bisa lakukan ini secara otomatis/headless
- `flutter run` pertama kali di device fisik mungkin minta kamu unlock/authorize
  device (Android: "Allow USB debugging?", iOS: trust developer certificate)
- Assign role ke member di Discord (lihat poin 4 di atas)
