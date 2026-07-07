import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/push_service.dart';
import '../services/user_provider.dart';
import '../models/models.dart';
import '../utils/localization.dart';
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
  late PageController _pageController;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _index);

    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      final offline = results.contains(ConnectivityResult.none);
      if (offline != _isOffline && mounted) {
        setState(() => _isOffline = offline);
      }
    });
    // Ambil profil + kapabilitas user sekali saat masuk, lalu daftarkan push notif.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProvider = context.read<UserProvider>();
      await userProvider.load();
      PushService.initAndRegister().catchError((_) {});
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        if (userProvider.loading) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (userProvider.error != null) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline,
                        color: Colors.redAccent, size: 40),
                    const SizedBox(height: 12),
                    Text('Gagal memuat profil: ${userProvider.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 16),
                    OutlinedButton(
                        onPressed: userProvider.load,
                        child: const Text('Coba Lagi')),
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
          _TabItem(context.l10n.navDashboard, Icons.dashboard_outlined,
              Icons.dashboard, const DashboardScreen()),
          if (canModerate)
            _TabItem(context.l10n.navModeration, Icons.shield_outlined,
                Icons.shield, const ModerationScreen()),
          if (canManageEvents)
            _TabItem(context.l10n.navEvents, Icons.event_outlined, Icons.event,
                const EventsScreen()),
          _TabItem(context.l10n.navSettings, Icons.settings_outlined,
              Icons.settings, const SettingsScreen()),
        ];

        final safeIndex = _index.clamp(0, tabs.length - 1);

        return Scaffold(
          body: Column(
            children: [
              if (_isOffline)
                Container(
                  width: double.infinity,
                  color: Colors.redAccent,
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: const SafeArea(
                    bottom: false,
                    child: Text(
                      'Tidak ada koneksi internet',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: tabs.map((t) => t.screen).toList(),
                ),
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: safeIndex,
            onDestinationSelected: (i) {
              setState(() => _index = i);
              _pageController.jumpToPage(i);
            },
            destinations: tabs
                .map((t) => NavigationDestination(
                    icon: Icon(t.icon),
                    selectedIcon: Icon(t.selectedIcon),
                    label: t.label))
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
