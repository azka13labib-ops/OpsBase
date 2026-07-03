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
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
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
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(child: _StatCard(icon: Icons.people, label: 'Member', value: '${stats.memberCount}')),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(icon: Icons.circle, iconColor: Colors.green, label: 'Online', value: '${stats.onlineCount}')),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Statistik Server', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _MiniStat(icon: Icons.chat_bubble_outline, value: '${stats.textChannelCount}', label: 'Teks'),
                          _MiniStat(icon: Icons.mic_none, value: '${stats.voiceChannelCount}', label: 'Channel'),
                          _MiniStat(icon: Icons.shield_outlined, value: '${stats.roleCount}', label: 'Role'),
                          _MiniStat(icon: Icons.diamond_outlined, iconColor: Colors.pinkAccent, value: '${stats.boostCount}', label: 'Boost'),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _MiniStat(
                            icon: Icons.network_ping,
                            iconColor: stats.botPing > 0 && stats.botPing < 100 ? Colors.green : Colors.orange,
                            value: stats.botPing > 0 ? '${stats.botPing} ms' : '-- ms',
                            label: 'Ping Bot',
                          ),
                          _MiniStat(
                            icon: Icons.event,
                            iconColor: Colors.blueAccent,
                            value: '${stats.upcomingEventsCount}',
                            label: 'Event',
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Aktivitas Moderasi Terbaru', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (stats.recentModActions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('Belum ada aktivitas', style: TextStyle(color: Colors.black38))),
                  )
                else
                  ...stats.recentModActions.map((a) => _ModActionTile(action: a)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String value;
  final String? subtitle;
  final bool wide;

  const _StatCard({required this.icon, this.iconColor, required this.label, required this.value, this.subtitle, this.wide = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor ?? Colors.black54, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: const TextStyle(color: Colors.black38, fontSize: 12)),
          ],
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
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(backgroundColor: const Color(0xFFF2F3F5), child: Text(action.emoji)),
      title: Text('${action.targetTag ?? action.targetId} — ${action.actionType}', style: const TextStyle(color: Colors.black87)),
      subtitle: Text('oleh ${action.moderatorTag}${action.reason != null ? " · ${action.reason}" : ""}', style: const TextStyle(color: Colors.black54)),
      trailing: Text(DateFormat('HH:mm').format(action.createdAt), style: const TextStyle(color: Colors.black38, fontSize: 12)),
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
  final Color? iconColor;

  const _MiniStat({required this.icon, required this.value, required this.label, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor ?? Colors.black54, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }
}
