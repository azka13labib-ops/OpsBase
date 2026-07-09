import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/user_provider.dart';
import '../services/socket_service.dart';
import '../utils/localization.dart';
import '../models/models.dart';

// Brand colors matching the app theme
const _kPrimary = Color(0xFF5865F2);
const _kPrimaryDark = Color(0xFF3B44C1);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
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
    super.build(context);
    final username = context.watch<UserProvider>().user?.username ?? 'User';
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5FB),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: _kPrimary,
        child: FutureBuilder<DashboardStats>(
          future: _statsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                  child: CircularProgressIndicator(color: _kPrimary));
            }
            if (snapshot.hasError) {
              return _ErrorState(
                  message: '${snapshot.error}', onRetry: _refresh);
            }
            final stats = snapshot.data!;
            return CustomScrollView(
              slivers: [
                // --- Gradient Header ---
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_kPrimaryDark, _kPrimary, Color(0xFF7B87F7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius:
                          BorderRadius.vertical(bottom: Radius.circular(32)),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.l10n.welcome,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    username,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.dashboard_rounded,
                                  color: Colors.white, size: 26),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      context.l10n.serverStats,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1D2E),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),

                // --- 2x2 Stat Cards (row 1) ---
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.4,
                    ),
                    delegate: SliverChildListDelegate([
                      RepaintBoundary(child: _StatCard(
                        icon: Icons.people_alt_rounded,
                        value: '${stats.memberCount}',
                        label: context.l10n.totalMembers,
                        color: _kPrimary,
                        bgColor: const Color(0xFFEEF0FD),
                      )),
                      RepaintBoundary(child: _StatCard(
                        icon: Icons.circle,
                        value: '${stats.onlineCount}',
                        label: 'Online',
                        color: const Color(0xFF23A55A),
                        bgColor: const Color(0xFFEAF8F0),
                      )),
                      RepaintBoundary(child: _StatCard(
                        icon: Icons.chat_bubble_rounded,
                        value: '${stats.textChannelCount}',
                        label: 'Text Channels',
                        color: const Color(0xFFF0A32A),
                        bgColor: const Color(0xFFFDF5E6),
                      )),
                      RepaintBoundary(child: _StatCard(
                        icon: Icons.mic_rounded,
                        value: '${stats.voiceChannelCount}',
                        label: 'Voice Channels',
                        color: const Color(0xFF5C6AF7),
                        bgColor: const Color(0xFFEEF0FD),
                      )),
                    ]),
                  ),
                ),

                // --- 4 wide stat strips (row 2) ---
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.4,
                    ),
                    delegate: SliverChildListDelegate([
                      RepaintBoundary(child: _StatCard(
                        icon: Icons.shield_rounded,
                        value: '${stats.roleCount}',
                        label: 'Roles',
                        color: const Color(0xFF9B59B6),
                        bgColor: const Color(0xFFF5EEF8),
                      )),
                      RepaintBoundary(child: _StatCard(
                        icon: null,
                        imageAsset: 'assets/images/boost_icon.png',
                        value: '${stats.boostCount}',
                        label: 'Boosts',
                        color: const Color(0xFFFF73FA),
                        bgColor: const Color(0xFFFDF0FD),
                      )),
                      RepaintBoundary(child: _StatCard(
                        icon: Icons.speed_rounded,
                        value:
                            stats.botPing > 0 ? '${stats.botPing} ms' : '-- ms',
                        label: 'Bot Ping',
                        color: const Color(0xFF1ABC9C),
                        bgColor: const Color(0xFFE8F8F5),
                      )),
                      RepaintBoundary(child: _StatCard(
                        icon: Icons.event_rounded,
                        value: '${stats.upcomingEventsCount}',
                        label: 'Events',
                        color: const Color(0xFFF62440),
                        bgColor: const Color(0xFFFDEAED),
                      )),
                    ]),
                  ),
                ),

                // --- Recent Mod Actions ---
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(
                            color: _kPrimary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AKTIVITAS MODERASI TERBARU',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                  sliver: SliverToBoxAdapter(
                    child: stats.recentModActions.isEmpty
                        ? Container(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.shield_outlined,
                                    size: 40, color: Colors.grey.shade300),
                                const SizedBox(height: 8),
                                Text('Belum ada aktivitas',
                                    style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 14)),
                              ],
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Column(
                              children: stats.recentModActions
                                  .asMap()
                                  .entries
                                  .map((e) {
                                final i = e.key;
                                final a = e.value;
                                return Column(
                                  children: [
                                    if (i > 0)
                                      Divider(
                                          height: 1,
                                          color: Colors.grey
                                              .withValues(alpha: 0.1),
                                          indent: 20,
                                          endIndent: 20),
                                    RepaintBoundary(child: _ModActionTile(action: a)),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData? icon;
  final String? imageAsset;
  final String label;
  final String value;
  final Color color;
  final Color bgColor;

  const _StatCard({
    this.icon,
    this.imageAsset,
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: EdgeInsets.all(imageAsset != null ? 3 : 7),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: imageAsset != null
                ? Image.asset(imageAsset!,
                    width: 26, height: 26, fit: BoxFit.contain)
                : Icon(icon, color: color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1D2E),
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
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
    IconData iconData;
    Color iconColor;
    Color bgColor;
    switch (action.actionType.toLowerCase()) {
      case 'warn':
        iconData = Icons.warning_amber_rounded;
        iconColor = Colors.orange;
        bgColor = Colors.orange.shade50;
        break;
      case 'kick':
        iconData = Icons.person_remove_rounded;
        iconColor = Colors.red;
        bgColor = Colors.red.shade50;
        break;
      case 'ban':
        iconData = Icons.gavel_rounded;
        iconColor = const Color(0xFFF62440);
        bgColor = const Color(0xFFF62440).withValues(alpha: 0.08);
        break;
      case 'mute':
        iconData = Icons.volume_off_rounded;
        iconColor = Colors.blueGrey;
        bgColor = Colors.blueGrey.shade50;
        break;
      default:
        iconData = Icons.info_outline_rounded;
        iconColor = _kPrimary;
        bgColor = const Color(0xFFEEF0FD);
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: bgColor,
        child: Icon(iconData, color: iconColor, size: 20),
      ),
      title: Text(
        '${action.targetTag ?? action.targetId} — ${action.actionType.toUpperCase()}',
        style: const TextStyle(
          color: Color(0xFF1A1D2E),
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        'oleh ${action.moderatorTag}${action.reason != null ? " · ${action.reason}" : ""}',
        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
      ),
      trailing: Text(
        DateFormat('HH:mm').format(action.createdAt),
        style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
      ),
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.error_outline, color: Colors.red, size: 36),
            ),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
