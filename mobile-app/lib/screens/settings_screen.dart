import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/user_provider.dart';
import '../services/preferences_provider.dart';
import '../utils/localization.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.logout),
        content: const Text(
            'Kamu perlu login ulang lewat Discord untuk masuk kembali.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.logout)),
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
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8)),
      ],
    );
  }

  Widget _buildDivider() {
    return Divider(
        height: 1, color: Colors.grey.shade200, indent: 20, endIndent: 20);
  }

  Widget _buildListTile(BuildContext context, IconData icon, String title,
      {String? subtitle, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(icon,
          color: Theme.of(context).textTheme.bodyLarge?.color ??
              const Color(0xFF1D1D1F)),
      title: Text(title,
          style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color ??
                  const Color(0xFF1D1D1F),
              fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: const TextStyle(color: Color(0xFF86868B), fontSize: 13))
          : null,
      trailing:
          const Icon(Icons.chevron_right, color: Color(0xFF86868B), size: 20),
      onTap: onTap ??
          () {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fitur ini akan segera hadir!')));
          },
    );
  }

  void _showLanguagePicker(BuildContext context, PreferencesProvider prefs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.language,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildOption(
                  context, prefs.language == 'id', context.l10n.languageId, () {
                prefs.setLanguage('id');
                Navigator.pop(context);
              }),
              const SizedBox(height: 12),
              _buildOption(
                  context, prefs.language == 'en', context.l10n.languageEn, () {
                prefs.setLanguage('en');
                Navigator.pop(context);
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemePicker(BuildContext context, PreferencesProvider prefs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.theme,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildOption(context, !prefs.isDarkMode, context.l10n.themeLight,
                  () {
                prefs.setDarkMode(false);
                Navigator.pop(context);
              }),
              const SizedBox(height: 12),
              _buildOption(context, prefs.isDarkMode, context.l10n.themeDark,
                  () {
                prefs.setDarkMode(true);
                Navigator.pop(context);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(
      BuildContext context, bool isSelected, String name, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF5865F2).withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF5865F2)
                : Colors.grey.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? const Color(0xFF5865F2)
                      : Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF5865F2)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final prefs = context.watch<PreferencesProvider>();
    final authUser = AuthService.currentUser;
    final username = authUser?.userMetadata?['full_name'] ??
        authUser?.userMetadata?['name'] ??
        'Admin';
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
                    backgroundImage:
                        avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? const Icon(Icons.person,
                            color: Color(0xFF86868B), size: 32)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(username,
                            style: TextStyle(
                                color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color ??
                                    const Color(0xFF1D1D1F),
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                        Text(authUser?.email ?? '',
                            style: const TextStyle(
                                color: Color(0xFF86868B), fontSize: 13)),
                        if (roleNames.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: roleNames
                                .map((r) => Chip(
                                      label: Text(r,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600)),
                                      backgroundColor: const Color(0xFFF5F5F7),
                                      labelStyle: const TextStyle(
                                          color: Color(0xFF1D1D1F)),
                                      side: BorderSide(
                                          color: Colors.grey.shade300),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      visualDensity: VisualDensity.compact,
                                    ))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 12),
              child: Text(context.l10n.profileSection,
                  style: const TextStyle(
                      color: Color(0xFF86868B),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2)),
            ),
            Container(
              decoration: _boxDecoration(),
              child: Column(
                children: [
                  _buildListTile(
                      context, Icons.person_outline, context.l10n.editProfile,
                      subtitle: context.l10n.editProfileSub, onTap: () async {
                    final changed = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const EditProfileScreen()));
                    if (changed == true) setState(() {});
                  }),
                  _buildDivider(),
                  _buildListTile(
                      context, Icons.link, context.l10n.connectedAccounts,
                      subtitle: 'Discord'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 12),
              child: Text(context.l10n.preferencesSection,
                  style: const TextStyle(
                      color: Color(0xFF86868B),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2)),
            ),
            Container(
              decoration: _boxDecoration(),
              child: Column(
                children: [
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    leading: Icon(Icons.notifications_outlined,
                        color: Theme.of(context).textTheme.bodyLarge?.color ??
                            const Color(0xFF1D1D1F)),
                    title: Text(context.l10n.notifications,
                        style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyLarge?.color ??
                                    const Color(0xFF1D1D1F),
                            fontWeight: FontWeight.w500)),
                    subtitle: Text(context.l10n.notificationsSub,
                        style: const TextStyle(
                            color: Color(0xFF86868B), fontSize: 13)),
                    trailing: const Icon(Icons.chevron_right,
                        color: Color(0xFF86868B), size: 20),
                  ),
                  _buildDivider(),
                  _buildListTile(context, Icons.language, context.l10n.language,
                      subtitle: prefs.language == 'id'
                          ? context.l10n.languageId
                          : context.l10n.languageEn,
                      onTap: () => _showLanguagePicker(context, prefs)),
                  _buildDivider(),
                  _buildListTile(
                      context, Icons.dark_mode_outlined, context.l10n.theme,
                      subtitle: prefs.isDarkMode
                          ? context.l10n.themeDark
                          : context.l10n.themeLight,
                      onTap: () => _showThemePicker(context, prefs)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 12),
              child: Text(context.l10n.supportSection,
                  style: const TextStyle(
                      color: Color(0xFF86868B),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2)),
            ),
            Container(
              decoration: _boxDecoration(),
              child: Column(
                children: [
                  _buildListTile(
                      context, Icons.help_outline, context.l10n.helpCenter),
                  _buildDivider(),
                  _buildListTile(
                      context, Icons.info_outline, context.l10n.aboutApp,
                      subtitle: '${context.l10n.aboutAppSub} 1.0.0', onTap: () {
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
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: Text(context.l10n.logout,
                    style: const TextStyle(
                        color: Colors.redAccent, fontWeight: FontWeight.w500)),
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
