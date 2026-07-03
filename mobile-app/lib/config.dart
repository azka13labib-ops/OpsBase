/// Isi nilai-nilai ini sesuai project kamu.
/// Untuk production, sebaiknya pindahkan ke --dart-define atau file .env
/// (pakai package flutter_dotenv) supaya tidak ke-commit ke git.
class AppConfig {
  // Sama dengan SUPABASE_URL & SUPABASE_ANON_KEY di backend/.env
  static const supabaseUrl = 'https://rwyoojokjbdmdoqfiowd.supabase.co';
  static const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ3eW9vam9ramJkbWRvcWZpb3dkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMwNjgyOTEsImV4cCI6MjA5ODY0NDI5MX0.3n5v8ihHecMPm3FaZ8lHbqycnmFx6pa4ZaDuyxk7d-U';

  // URL backend Express kita (yang punya bot token & eksekusi aksi Discord)
  // Saat development lokal pakai IP komputer kamu (bukan localhost) kalau
  // testing dari HP fisik, atau 10.0.2.2 kalau pakai Android Emulator.
  static const backendApiUrl = 'http://172.31.90.201:3000';
  // contoh dev: 'http://10.0.2.2:3000'

  // Redirect URL untuk OAuth Discord — daftarkan juga di Supabase Auth settings
  // dan di app (deep link / custom scheme)
  static const oauthRedirectUrl = 'com.komunitas.suite://login-callback';
}
