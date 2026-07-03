import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/push_service.dart';
import '../services/user_provider.dart';
import '../models/models.dart';
import 'dashboard_screen.dart';
import 'moderation_screen.dart';
import 'events_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Ambil profil + kapabilitas user sekali saat masuk, lalu daftarkan push notif.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProvider = context.read<UserProvider>();
      await userProvider.load();
      PushService.initAndRegister().catchError((_) {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        if (userProvider.loading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (userProvider.error != null) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline, color: Colors.redAccent, size: 40),
                    const SizedBox(height: 12),
                    Text('Gagal memuat profil: ${userProvider.error}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 16),
                    OutlinedButton(onPressed: userProvider.load, child: const Text('Coba Lagi')),
                  ],
                ),
              ),
            ),
          );
        }

        // Susun daftar tab secara dinamis berdasarkan kapabilitas user.
        // Dashboard & Pengaturan selalu ada; Moderasi/Event cuma muncul kalau berhak.
        final canModerate = userProvider.can(Capability.moderateWarn) ||
            userProvider.can(Capability.moderateKick) ||
            userProvider.can(Capability.moderateBan) ||
            userProvider.can(Capability.moderateMute);
        final canManageEvents = userProvider.can(Capability.eventsCreate);

        final tabs = <_TabItem>[
          _TabItem('Dashboard', Icons.dashboard_outlined, Icons.dashboard, const DashboardScreen()),
          if (canModerate) _TabItem('Moderasi', Icons.shield_outlined, Icons.shield, const ModerationScreen()),
          if (canManageEvents) _TabItem('Event', Icons.event_outlined, Icons.event, const EventsScreen()),
          _TabItem('Pengaturan', Icons.settings_outlined, Icons.settings, const SettingsScreen()),
        ];

        final safeIndex = _index.clamp(0, tabs.length - 1);

        return Scaffold(
          body: IndexedStack(index: safeIndex, children: tabs.map((t) => t.screen).toList()),
          bottomNavigationBar: NavigationBar(
            selectedIndex: safeIndex,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: tabs
                .map((t) => NavigationDestination(icon: Icon(t.icon), selectedIcon: Icon(t.selectedIcon), label: t.label))
                .toList(),
          ),
        );
      },
    );
  }
}

class _TabItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;
  _TabItem(this.label, this.icon, this.selectedIcon, this.screen);
}
