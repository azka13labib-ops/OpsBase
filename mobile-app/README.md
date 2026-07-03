# Community Suite — Mobile App (Flutter)

Aplikasi mobile untuk admin/moderator mengelola server Discord: dashboard,
moderasi cepat, dan manajemen event — semua langsung dari HP.

## 🏗️ Cara Kerja
- Login pakai akun Discord (lewat Supabase Auth OAuth)
- Semua data & aksi (moderasi, event) lewat REST API `backend/` yang sudah dibuat
- Push notification pakai Firebase Cloud Messaging

## 🚀 Setup

### 1. Prasyarat
- Flutter SDK terpasang (`flutter --version` untuk cek)
- Backend (`../backend`) sudah jalan dan bisa diakses dari HP/emulator

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Isi konfigurasi
Buka `lib/config.dart`, isi:
- `supabaseUrl` & `supabaseAnonKey` → sama persis dengan yang di `backend/.env`
- `backendApiUrl` → alamat backend kamu
  - Emulator Android: `http://10.0.2.2:3000`
  - HP fisik (WiFi sama dengan komputer): `http://192.168.x.x:3000`
  - Production: domain HTTPS kamu

### 4. Setup Firebase (push notification)
1. Buka https://console.firebase.google.com → project yang sama dengan backend
2. Tambahkan app Android (`flutterfire configure` paling gampang, wajib install
   `flutterfire_cli` dulu: `dart pub global activate flutterfire_cli`)
3. Jalankan `flutterfire configure` di folder ini — otomatis generate
   `lib/firebase_options.dart` dan file konfigurasi native (google-services.json, dll)
4. Di `lib/main.dart`, tambahkan sebelum `runApp`:
   ```dart
   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
   ```

### 5. Setup Deep Link (untuk redirect OAuth Discord)
Login Discord akan redirect balik ke app lewat custom URL scheme.
- **Android**: tambahkan intent-filter di `android/app/src/main/AndroidManifest.xml`
  untuk scheme `com.komunitas.suite://login-callback` (sesuaikan dengan `AppConfig.oauthRedirectUrl`)
- **iOS**: tambahkan URL scheme yang sama di `ios/Runner/Info.plist`
- Detail lengkap: https://supabase.com/docs/guides/auth/native-mobile-deep-linking

### 6. Jalankan
```bash
flutter run
```

## 📂 Struktur
```
lib/
├── main.dart                  # Entry point, tema, routing login/home
├── config.dart                # URL Supabase & backend API
├── models/models.dart         # ModAction, CommunityEvent, DashboardStats
├── services/
│   ├── auth_service.dart      # Login/logout Discord via Supabase
│   ├── api_service.dart       # Semua panggilan ke backend REST API
│   └── push_service.dart      # Setup Firebase Messaging
└── screens/
    ├── login_screen.dart      # Tombol "Login dengan Discord"
    ├── home_shell.dart        # Bottom navigation (4 tab)
    ├── dashboard_screen.dart  # Statistik server + aktivitas terbaru
    ├── moderation_screen.dart # Riwayat audit log + aksi cepat (warn/kick/ban/mute)
    ├── events_screen.dart     # List event + buat event baru
    └── settings_screen.dart   # Info akun + logout
```

## 🔜 Yang Belum Dibuat (Next Steps)
- **Pencarian member**: saat ini quick action moderasi minta input User ID manual.
  Idealnya ada endpoint `GET /api/members?search=nama` di backend + halaman
  pencarian member di app biar admin gak perlu hafal ID.
- **Detail RSVP per event**: layar events belum menampilkan siapa saja yang RSVP.
- **Notifikasi in-app**: saat ini push notif cuma muncul sebagai OS notification;
  belum ada halaman "riwayat notifikasi" di dalam app.
- **Ticket inbox**: fitur ticket system belum dibangun sama sekali (baik backend
  maupun mobile) — ini kandidat kuat untuk tahap berikutnya.
