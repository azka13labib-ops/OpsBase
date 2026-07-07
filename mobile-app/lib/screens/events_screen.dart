import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../utils/localization.dart';
import '../services/socket_service.dart';
import '../services/user_provider.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import 'event_wizard_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late Future<List<CommunityEvent>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = _load();

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

  Future<List<CommunityEvent>> _load() async {
    final raw = await ApiService.getEvents();
    return raw.map((e) => CommunityEvent.fromJson(e)).toList();
  }

  Future<void> _refresh() async {
    setState(() {
      _eventsFuture = _load();
    });
    await _eventsFuture;
  }

  void _openEventWizard({CommunityEvent? existingEvent}) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => EventWizardScreen(existingEvent: existingEvent)),
    ).then((modified) {
      if (modified == true) _refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'event_fab',
        onPressed: _openEventWizard,
        backgroundColor: const Color(0xFF5865F2),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.createEvent,
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: const Color(0xFF5865F2),
          child: FutureBuilder<List<CommunityEvent>>(
            future: _eventsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF5865F2)));
              }
              if (snapshot.hasError) {
                return Center(
                    child: Text('${snapshot.error}',
                        style: const TextStyle(color: Colors.redAccent)));
              }
              final events = snapshot.data!;
              if (events.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5865F2).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.event_available,
                            size: 80, color: Color(0xFF5865F2)),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Belum ada event mendatang',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Buat event pertamamu untuk komunitas!',
                        style: TextStyle(color: Colors.black54, fontSize: 15),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _openEventWizard,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5865F2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: const Text('Buat Event Pertama',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              }
              return CustomScrollView(
                slivers: [
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'Upcoming Events',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _EventCard(
                          event: events[i],
                          onChanged: _refresh,
                          onEdit: () =>
                              _openEventWizard(existingEvent: events[i]),
                        ),
                        childCount: events.length,
                      ),
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

class _EventCard extends StatelessWidget {
  final CommunityEvent event;
  final VoidCallback onChanged;
  final VoidCallback onEdit;
  const _EventCard(
      {required this.event, required this.onChanged, required this.onEdit});

  Future<void> _delete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.redAccent, size: 28),
            SizedBox(width: 8),
            Text('Hapus Event', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
            'Apakah Anda yakin ingin menghapus event "${event.title}"? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService.deleteEvent(event.id);
      onChanged();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Event berhasil dihapus'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('EEEE, d MMM yyyy · HH:mm', 'id_ID').format(event.startTime);
    const discordBlurple = Color(0xFF5865F2);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Poster / Cover Image Header
            if (event.coverUrl != null)
              Image.network(
                event.coverUrl!,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildPlaceholderGradient(),
              )
            else
              _buildPlaceholderGradient(),

            // Content Body
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Options
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      if (event.isRecurring)
                        const Padding(
                          padding: EdgeInsets.only(left: 8, top: 4),
                          child: Icon(Icons.repeat,
                              size: 20, color: discordBlurple),
                        ),
                      const SizedBox(width: 8),
                      // Options Menu
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.more_horiz,
                              color: Colors.black54, size: 24),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          onSelected: (v) {
                            if (v == 'edit') onEdit();
                            if (v == 'delete') _delete(context);
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                                value: 'edit', child: Text('Edit Event')),
                            const PopupMenuItem(
                                value: 'delete',
                                child: Text('Hapus Event',
                                    style: TextStyle(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Time & Location Info
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 18, color: Colors.black54),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                dateStr,
                                style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        if (event.location != null &&
                            event.location!.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(height: 1),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  size: 18, color: Colors.black54),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  event.location!,
                                  style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (event.channelId != null) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(height: 1),
                          ),
                          const Row(
                            children: [
                              Icon(Icons.volume_up_rounded,
                                  size: 18, color: discordBlurple),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Voice Channel',
                                  style: TextStyle(
                                      color: discordBlurple,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Description
                  if (event.description != null &&
                      event.description!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      event.description!,
                      style: const TextStyle(
                          color: Colors.black87, fontSize: 15, height: 1.6),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderGradient() {
    return Container(
      height: 140,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5865F2), Color(0xFF7E89F3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(Icons.event,
                size: 120, color: Colors.white.withValues(alpha: 0.1)),
          ),
          const Center(
            child:
                Icon(Icons.celebration_rounded, size: 48, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
