import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/preferences_provider.dart';

class AppLocalizations {
  final String locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    final prefs = context.watch<PreferencesProvider>();
    return AppLocalizations(prefs.language);
  }

  // --- General ---
  String get ok => locale == 'id' ? 'Oke' : 'OK';
  String get cancel => locale == 'id' ? 'Batal' : 'Cancel';
  String get save => locale == 'id' ? 'Simpan' : 'Save';
  String get close => locale == 'id' ? 'Tutup' : 'Close';

  // --- Bottom Navigation ---
  String get navDashboard => locale == 'id' ? 'Dashboard' : 'Dashboard';
  String get navModeration => locale == 'id' ? 'Moderasi' : 'Moderation';
  String get navEvents => locale == 'id' ? 'Event' : 'Events';
  String get navSettings => locale == 'id' ? 'Pengaturan' : 'Settings';

  // --- Settings Screen ---
  String get settingsTitle => locale == 'id' ? 'Pengaturan' : 'Settings';
  String get profileSection => locale == 'id' ? 'PROFIL' : 'PROFILE';
  String get editProfile => locale == 'id' ? 'Edit Profil' : 'Edit Profile';
  String get editProfileSub => locale == 'id'
      ? 'Ubah bio dan foto profil'
      : 'Change bio and profile picture';
  String get connectedAccounts =>
      locale == 'id' ? 'Akun Terhubung' : 'Connected Accounts';

  String get preferencesSection =>
      locale == 'id' ? 'PREFERENSI' : 'PREFERENCES';
  String get notifications => locale == 'id' ? 'Notifikasi' : 'Notifications';
  String get notificationsSub => locale == 'id'
      ? 'Push notification aktif otomatis'
      : 'Push notifications active automatically';
  String get language => locale == 'id' ? 'Bahasa' : 'Language';
  String get languageEn => 'English';
  String get languageId => 'Indonesia';
  String get theme => locale == 'id' ? 'Tema' : 'Theme';
  String get themeLight => locale == 'id' ? 'Terang' : 'Light';
  String get themeDark => locale == 'id' ? 'Gelap' : 'Dark';
  String get themeSystem => locale == 'id' ? 'Sistem' : 'System';

  String get supportSection => locale == 'id' ? 'DUKUNGAN' : 'SUPPORT';
  String get helpCenter => locale == 'id' ? 'Pusat Bantuan' : 'Help Center';
  String get aboutApp => locale == 'id' ? 'Tentang Aplikasi' : 'About App';
  String get aboutAppSub => locale == 'id' ? 'Versi' : 'Version';
  String get logout => locale == 'id' ? 'Keluar dari Akun' : 'Log Out';

  // --- Dashboard Screen ---
  String get welcome => locale == 'id' ? 'Selamat datang' : 'Welcome';
  String get serverStats =>
      locale == 'id' ? 'Statistik Server' : 'Server Statistics';
  String get totalMembers => locale == 'id' ? 'Total Member' : 'Total Members';
  String get activeMembers24h =>
      locale == 'id' ? 'Member Aktif (24j)' : 'Active Members (24h)';
  String get activeEvents => locale == 'id' ? 'Event Aktif' : 'Active Events';
  String get activeMutes => locale == 'id' ? 'Mute Aktif' : 'Active Mutes';

  // --- Moderation Screen ---
  String get moderationHistory =>
      locale == 'id' ? 'Riwayat Moderasi' : 'Moderation History';
  String get quickAction => locale == 'id' ? 'Aksi Cepat' : 'Quick Action';
  String get noModHistory => locale == 'id'
      ? 'Belum ada riwayat moderasi'
      : 'No moderation history yet';
  String get by => locale == 'id' ? 'oleh' : 'by';
  String get userIdRequired =>
      locale == 'id' ? 'User ID wajib diisi' : 'User ID is required';
  String get noReason =>
      locale == 'id' ? 'Tidak ada alasan' : 'No reason provided';
  String get userId =>
      locale == 'id' ? 'User ID (Discord)' : 'User ID (Discord)';

  // --- Events Screen ---
  String get eventList => locale == 'id' ? 'Daftar Event' : 'Event List';
  String get createEvent => locale == 'id' ? 'Buat Event' : 'Create Event';
}

extension AppLocalizationsExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
