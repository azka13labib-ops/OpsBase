import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/user_provider.dart';
import '../services/preferences_provider.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Keluar?'),
        content: const Text('Kamu perlu login ulang lewat Discord untuk masuk kembali.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Keluar')),
        ],
      ),
    );
    if (confirm == true) {
      if (context.mounted) {
        context.read<UserProvider>().clear();
      }
      await AuthService.logout();
    }
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 8)),
      ],
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey.shade200, indent: 20, endIndent: 20);
  }

  Widget _buildListTile(BuildContext context, IconData icon, String title, {String? subtitle, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(icon, color: Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF1D1D1F)),
      title: Text(title, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF1D1D1F), fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Color(0xFF86868B), fontSize: 13)) : null,
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF86868B), size: 20),
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur ini akan segera hadir!')));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesProvider>();
    final authUser = AuthService.currentUser;
    final username = authUser?.userMetadata?['full_name'] ?? authUser?.userMetadata?['name'] ?? 'Admin';
    final avatarUrl = authUser?.userMetadata?['avatar_url'];
    final roleNames = context.watch<UserProvider>().user?.roleNames ?? [];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: _boxDecoration(),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: const Color(0xFFE5E5EA),
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null ? const Icon(Icons.person, color: Color(0xFF86868B), size: 32) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(username, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF1D1D1F), fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(authUser?.email ?? '', style: const TextStyle(color: Color(0xFF86868B), fontSize: 13)),
                      if (roleNames.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: roleNames.map((r) => Chip(
                                label: Text(r, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                backgroundColor: const Color(0xFFF5F5F7),
                                labelStyle: const TextStyle(color: Color(0xFF1D1D1F)),
                                side: BorderSide(color: Colors.grey.shade300),
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                visualDensity: VisualDensity.compact,
                              )).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 12),
            child: Text('AKUN', style: TextStyle(color: Color(0xFF86868B), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ),
          Container(
            decoration: _boxDecoration(),
            child: Column(
              children: [
                _buildListTile(context, Icons.person_outline, 'Edit Profil', subtitle: 'Ubah bio dan foto profil', onTap: () async {
                  final changed = await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                  if (changed == true) setState(() {});
                }),
                _buildDivider(),
                _buildListTile(context, Icons.link, 'Akun Terhubung', subtitle: 'Discord'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 12),
            child: Text('PREFERENSI', style: TextStyle(color: Color(0xFF86868B), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ),
          Container(
            decoration: _boxDecoration(),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: Icon(Icons.notifications_outlined, color: Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF1D1D1F)),
                  title: Text('Notifikasi', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF1D1D1F), fontWeight: FontWeight.w500)),
                  subtitle: const Text('Push notification aktif otomatis', style: TextStyle(color: Color(0xFF86868B), fontSize: 13)),
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFF86868B), size: 20),
                ),
                _buildDivider(),
                _buildListTile(context, Icons.language, 'Bahasa', subtitle: prefs.language == 'id' ? 'Indonesia' : 'English', onTap: () {
                  showModalBottomSheet(context: context, builder: (_) => SafeArea(child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(title: const Text('Indonesia'), trailing: prefs.language == 'id' ? const Icon(Icons.check) : null, onTap: () { prefs.setLanguage('id'); Navigator.pop(context); }),
                      ListTile(title: const Text('English'), trailing: prefs.language == 'en' ? const Icon(Icons.check) : null, onTap: () { prefs.setLanguage('en'); Navigator.pop(context); }),
                    ],
                  )));
                }),
                _buildDivider(),
                _buildListTile(context, Icons.dark_mode_outlined, 'Tema', subtitle: prefs.isDarkMode ? 'Gelap' : 'Terang', onTap: () {
                  showModalBottomSheet(context: context, builder: (_) => SafeArea(child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(title: const Text('Terang'), trailing: !prefs.isDarkMode ? const Icon(Icons.check) : null, onTap: () { prefs.setDarkMode(false); Navigator.pop(context); }),
                      ListTile(title: const Text('Gelap'), trailing: prefs.isDarkMode ? const Icon(Icons.check) : null, onTap: () { prefs.setDarkMode(true); Navigator.pop(context); }),
                    ],
                  )));
                }),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 12),
            child: Text('DUKUNGAN', style: TextStyle(color: Color(0xFF86868B), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ),
          Container(
            decoration: _boxDecoration(),
            child: Column(
              children: [
                _buildListTile(context, Icons.help_outline, 'Pusat Bantuan'),
                _buildDivider(),
                _buildListTile(context, Icons.info_outline, 'Tentang Aplikasi', subtitle: 'Versi 1.0.0', onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Community Suite',
                    applicationVersion: '1.0.0',
                    applicationLegalese: '© 2026 Community Suite',
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            decoration: _boxDecoration(),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Keluar dari Akun', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500)),
              onTap: () => _logout(context),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
      ),
    );
  }
}
