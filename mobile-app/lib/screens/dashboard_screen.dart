import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/user_provider.dart';
import '../services/socket_service.dart';
import '../models/models.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

BoxDecoration _antigravityBoxDecoration(BuildContext context) {
  return BoxDecoration(
    color: Theme.of(context).cardColor,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
    boxShadow: [
      BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 8)),
    ],
  );
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<DashboardStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<UserProvider>().user;
      if (user != null) {
        SocketService().init(user.guildId);
        SocketService().addStatsListener(_refresh);
      }
    });
  }

  @override
  void dispose() {
    SocketService().removeStatsListener(_refresh);
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _statsFuture = _load();
    });
    await _statsFuture;
  }

  Future<DashboardStats> _load() async {
    final json = await ApiService.getDashboardStats();
    return DashboardStats.fromJson(json);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<DashboardStats>(
          future: _statsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorState(message: '${snapshot.error}', onRetry: _refresh);
            }
            final stats = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 12),
                Text('Overview', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF1D1D1F), fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _StatCard(icon: Icons.people, label: 'Member', value: '${stats.memberCount}')),
                    const SizedBox(width: 16),
                    Expanded(child: _StatCard(icon: Icons.circle, label: 'Online', value: '${stats.onlineCount}')),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: _antigravityBoxDecoration(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('STATISTIK SERVER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF86868B), letterSpacing: 1.2)),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _MiniStat(icon: Icons.chat_bubble_outline, value: '${stats.textChannelCount}', label: 'Teks'),
                          _MiniStat(icon: Icons.mic_none, value: '${stats.voiceChannelCount}', label: 'Voice'),
                          _MiniStat(icon: Icons.shield_outlined, value: '${stats.roleCount}', label: 'Role'),
                          _MiniStat(icon: Icons.diamond_outlined, value: '${stats.boostCount}', label: 'Boost'),
                        ],
                      ),
                      const Divider(height: 32, color: Colors.black12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _MiniStat(
                            icon: Icons.network_ping,
                            value: stats.botPing > 0 ? '${stats.botPing} ms' : '-- ms',
                            label: 'Ping Bot',
                          ),
                          _MiniStat(
                            icon: Icons.event,
                            value: '${stats.upcomingEventsCount}',
                            label: 'Event',
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Padding(
                  padding: EdgeInsets.only(left: 8, bottom: 12),
                  child: Text('AKTIVITAS MODERASI TERBARU', style: TextStyle(color: Color(0xFF86868B), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
                if (stats.recentModActions.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: _antigravityBoxDecoration(context),
                    child: const Center(child: Text('Belum ada aktivitas', style: TextStyle(color: Color(0xFF86868B)))),
                  )
                else
                  Container(
                    decoration: _antigravityBoxDecoration(context),
                    child: Column(
                      children: stats.recentModActions.asMap().entries.map((e) {
                        final i = e.key;
                        final a = e.value;
                        return Column(
                          children: [
                            if (i > 0) Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15), indent: 20, endIndent: 20),
                            _ModActionTile(action: a),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _antigravityBoxDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF86868B), size: 24),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF1D1D1F), letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Color(0xFF86868B), fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ModActionTile extends StatelessWidget {
  final ModAction action;
  const _ModActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: CircleAvatar(backgroundColor: const Color(0xFFF5F5F7), child: Text(action.emoji)),
      title: Text('${action.targetTag ?? action.targetId} — ${action.actionType}', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF1D1D1F), fontWeight: FontWeight.w500)),
      subtitle: Text('oleh ${action.moderatorTag}${action.reason != null ? " · ${action.reason}" : ""}', style: const TextStyle(color: Color(0xFF86868B), fontSize: 13)),
      trailing: Text(DateFormat('HH:mm').format(action.createdAt), style: const TextStyle(color: Color(0xFF86868B), fontSize: 12)),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _MiniStat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF86868B), size: 24),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF1D1D1F))),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF86868B), fontWeight: FontWeight.w500)),
      ],
    );
  }
}
