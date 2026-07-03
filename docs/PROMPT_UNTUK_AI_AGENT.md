# Instruksi untuk AI Agent — Setup Community Suite (Bot + API + Mobile App)

Kamu adalah senior engineer yang bertanggung jawab menyiapkan project ini sampai bisa
dijalankan. Project ini terdiri dari dua bagian:
- `backend/` — Node.js: Discord bot + REST API (Express), pakai Supabase (Postgres) dan Firebase (push notification)
- `mobile-app/` — Flutter app untuk admin mengelola server dari HP

User (pemilik project) sudah mengisi semua kredensial di `backend/.env` dan
`mobile-app/lib/config.dart`. **Jangan minta user mengisi kredensial lewat kamu** —
anggap semua sudah terisi, tugasmu murni teknis: instalasi, validasi, konfigurasi
file, dan menjalankan project sampai bisa jalan tanpa error.

Kerjakan tahapan berikut secara berurutan. Di setiap tahap, verifikasi hasilnya
sebelum lanjut ke tahap berikutnya — jangan asumsikan sukses tanpa cek.

---

## Tahap 1 — Validasi environment backend
1. Masuk ke folder `backend/`.
2. Cek apakah file `.env` ada. Kalau belum ada, copy dari `.env.example` dan
   beri tahu user secara eksplisit variabel mana saja yang wajib diisi manual
   (jangan coba menebak/mengisi kredensial sendiri).
3. Baca `.env` yang ada, pastikan semua variabel berikut TERISI (bukan placeholder
   seperti `isi_token_bot_disini`): `DISCORD_TOKEN`, `CLIENT_ID`, `GUILD_ID`,
   `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_ANON_KEY`.
   Kalau ada yang masih placeholder, STOP dan laporkan ke user — jangan lanjut
   ke instalasi karena bot akan gagal connect.
4. Cek apakah file `firebase-service-account.json` ada di `backend/`. Kalau tidak
   ada, catat sebagai warning (bukan blocker) — push notification akan nonaktif
   otomatis tapi bot/API tetap bisa jalan.

## Tahap 2 — Install & validasi dependency backend
1. Jalankan `npm install` di `backend/`.
2. Setelah install, jalankan `node --check` ke semua file `.js` di project
   (kecuali `node_modules`) untuk pastikan tidak ada syntax error.
3. Jalankan smoke test require semua module utama (`api/server.js`,
   `supabase/client.js`, `services/push.js`, `config/permissions.js`, semua
   file di `commands/moderation/` dan `events/`) untuk mendeteksi module
   yang salah nama/path.
4. Kalau ada error `Cannot find module`, cek apakah nama package di error itu
   ada di `package.json` — kalau belum, tambahkan dan install ulang.

## Tahap 3 — Setup database Supabase
1. Baca isi `backend/supabase/schema.sql`.
2. Tanyakan ke user: apakah schema ini SUDAH dijalankan di Supabase SQL Editor?
   Kalau belum, user harus menjalankannya manual di dashboard Supabase (kamu
   tidak punya akses ke dashboard mereka) — beri instruksi jelas: buka Supabase
   Dashboard → SQL Editor → New Query → paste isi file → Run.
3. Setelah user konfirmasi sudah dijalankan, lanjut ke tahap berikutnya.

## Tahap 4 — Setup role Discord otomatis
1. Baca `backend/config/permissions.js` untuk tahu daftar role yang dibutuhkan
   sistem permission (default: Owner, Developer, Event Organizer, Brand
   Ambassador, Supporter — bisa beda kalau user sudah isi `ROLE_NAME_*` di `.env`).
2. Jalankan `npm run setup-roles` di `backend/` — script ini otomatis membuat
   role yang belum ada di server Discord, dan melewati yang sudah ada (aman
   dijalankan berkali-kali, tidak akan duplikat).
3. Kalau script gagal dengan pesan terkait permission "Manage Roles", STOP dan
   laporkan ke user — mereka perlu kasih izin **Manage Roles** ke bot lewat
   Server Settings → Roles di Discord (kamu tidak bisa lakukan ini, butuh
   akses dashboard Discord mereka).
4. Setelah role berhasil dibuat, INGATKAN user dengan jelas bahwa mereka masih
   perlu **assign role ke member satu per satu secara manual** di Discord
   (klik kanan member → Roles → centang role yang sesuai) — ini keputusan
   manusia (siapa dapat role apa), jangan coba tebak atau lakukan otomatis.

## Tahap 5 — Deploy slash command & jalankan bot
1. Jalankan `npm run deploy` di `backend/` — ini mendaftarkan slash command ke
   server Discord (`GUILD_ID` di `.env`).
2. Kalau sukses, jalankan `npm start` untuk menyalakan bot + API server.
3. Verifikasi log menunjukkan: bot online (`✅ Bot online sebagai ...`) dan API
   server jalan (`🌐 API server ... jalan di port ...`).
4. Test endpoint health check: `curl http://localhost:3000/health` harus
   mengembalikan `{"status":"ok"}`.
5. Kalau bot gagal login, cek apakah `DISCORD_TOKEN` valid dan intent
   `SERVER MEMBERS INTENT` + `MESSAGE CONTENT INTENT` sudah aktif di Discord
   Developer Portal (informasikan ke user kalau ini penyebabnya — kamu tidak
   bisa mengaktifkan ini sendiri).

## Tahap 6 — Validasi Flutter app
1. Masuk ke folder `mobile-app/`.
2. Cek `flutter --version` untuk pastikan Flutter SDK terpasang. Kalau tidak
   ada, hentikan dan minta user install Flutter SDK dulu.
3. Jalankan `flutter pub get`.
4. Buka `lib/config.dart`, verifikasi `supabaseUrl` dan `supabaseAnonKey` SAMA
   PERSIS dengan nilai `SUPABASE_URL` dan `SUPABASE_ANON_KEY` di `backend/.env`.
   Kalau beda, itu bug — perbaiki agar konsisten.
5. Jalankan `flutter analyze` — perbaiki semua error (warning boleh diabaikan
   kalau tidak kritikal, tapi laporkan ke user).

## Tahap 7 — Setup Firebase di Flutter (push notification)
1. Cek apakah `flutterfire_cli` sudah terpasang (`flutterfire --version`).
   Kalau belum: `dart pub global activate flutterfire_cli`.
2. Jalankan `flutterfire configure` — **ini butuh login interaktif Firebase**,
   jadi jalankan di terminal yang usernya bisa lihat & respons prompt (jangan
   dijalankan di background/headless). Ikuti instruksi CLI-nya, pilih project
   Firebase yang sama dengan yang dipakai `backend/firebase-service-account.json`.
3. Setelah selesai, akan muncul file `lib/firebase_options.dart` otomatis.
4. Edit `lib/main.dart`: tambahkan import `firebase_core` dan `firebase_options.dart`,
   lalu panggil `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);`
   sebelum `await AuthService.init();` di fungsi `main()`.

## Tahap 8 — Setup deep link OAuth Discord
1. Baca nilai `oauthRedirectUrl` di `lib/config.dart` (formatnya seperti
   `com.komunitas.suite://login-callback`).
2. **Android**: edit `android/app/src/main/AndroidManifest.xml`, tambahkan
   `<intent-filter>` di dalam tag `<activity>` utama dengan `android:scheme`
   dan `android:host` sesuai `oauthRedirectUrl` (pecah scheme dan host dari URL
   tsb), plus `android:autoVerify="true"` dan action `VIEW` + category
   `DEFAULT`, `BROWSABLE`.
3. **iOS**: edit `ios/Runner/Info.plist`, tambahkan entry `CFBundleURLTypes`
   dengan `CFBundleURLSchemes` berisi scheme yang sama.
4. Verifikasi juga redirect URL yang sama sudah didaftarkan di Supabase Auth
   settings — kalau user belum lakukan ini, ingatkan (kamu tidak bisa akses
   dashboard Supabase mereka).

## Tahap 9 — Build & jalankan
1. Jalankan `flutter run` (dengan emulator/device terhubung) atau
   `flutter build apk --debug` untuk verifikasi build sukses tanpa error.
2. Laporkan hasil akhir ke user: bagian mana yang sudah jalan otomatis, dan
   bagian mana (kalau ada) yang masih butuh aksi manual dari mereka.

---

## Batasan — JANGAN lakukan ini
- Jangan pernah membuat, menebak, atau mengisi API key/token/secret apa pun.
- Jangan mencoba login ke Discord Developer Portal, Supabase Dashboard, atau
  Firebase Console atas nama user — semua itu butuh sesi browser milik mereka.
- Jangan assign role Discord ke member tertentu — itu keputusan manusia.
  Kamu hanya boleh MEMBUAT role (lewat `npm run setup-roles`), bukan menentukan
  siapa dapat role apa.
- Kalau menemukan kredensial kosong/placeholder, STOP dan laporkan — jangan
  lanjut proses yang bergantung padanya.
- Jangan commit file `.env`, `firebase-service-account.json`, atau
  `firebase_options.dart` ke git kalau kamu menjalankan perintah git apa pun
  (harusnya sudah masuk `.gitignore`, tapi verifikasi).

## Setelah selesai, berikan ringkasan ke user berisi:
1. Status tiap tahap (✅ sukses / ⚠️ butuh aksi manual / ❌ gagal + alasan)
2. Command yang perlu user jalankan sendiri secara interaktif (kalau ada,
   misal `flutterfire configure`)
3. Link/instruksi persis untuk hal yang cuma bisa dilakukan lewat dashboard
   browser (Discord/Supabase/Firebase)
4. Daftar role yang berhasil dibuat lewat `setup-roles`, dan pengingat bahwa
   user masih perlu assign role tsb ke member secara manual
