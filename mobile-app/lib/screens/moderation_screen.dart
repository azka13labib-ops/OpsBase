import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

import '../services/user_provider.dart';
import '../services/socket_service.dart';
import '../models/models.dart';
import 'mod_action_bottom_sheet.dart';

final _dateFormat = DateFormat('d MMM HH:mm', 'id_ID');

class ModerationScreen extends StatefulWidget {
  const ModerationScreen({super.key});

  @override
  State<ModerationScreen> createState() => _ModerationScreenState();
}

class _ModerationScreenState extends State<ModerationScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  
  late Future<List<ModAction>> _historyFuture;
  String _filterAction = 'all';
  String _searchQuery = '';
  
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _historyFuture = _load();

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

  Future<List<ModAction>> _load() async {
    final raw = await ApiService.getModHistory();
    return raw.map((e) => ModAction.fromJson(e)).toList();
  }

  Future<void> _refresh() async {
    setState(() {
      _historyFuture = _load();
    });
    await _historyFuture;
  }

  void _openQuickAction() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ModActionBottomSheet(onActionSuccess: _refresh),
    );
  }

  Widget _buildFilterChip(String action, String label) {
    final isSelected = _filterAction == action;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF5865F2).withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF5865F2) : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(color: isSelected ? const Color(0xFF5865F2) : Colors.grey.shade300),
      onSelected: (selected) {
        if (selected) setState(() => _filterAction = action);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'mod_fab',
        onPressed: _openQuickAction,
        icon: const Icon(Icons.shield),
        label: const Text('Ambil Tindakan'),
        backgroundColor: const Color(0xFF5865F2),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search & Filter Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Cari nama di riwayat...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) {
                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                  _debounce = Timer(const Duration(milliseconds: 300), () {
                    setState(() => _searchQuery = val);
                  });
                },
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildFilterChip('all', 'Semua'),
                  const SizedBox(width: 8),
                  _buildFilterChip('warn', 'Warn'),
                  const SizedBox(width: 8),
                  _buildFilterChip('mute', 'Mute'),
                  const SizedBox(width: 8),
                  _buildFilterChip('kick', 'Kick'),
                  const SizedBox(width: 8),
                  _buildFilterChip('ban', 'Ban'),
                  const SizedBox(width: 8),
                  _buildFilterChip('message_delete', 'Hapus Pesan'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            
            // List View
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: FutureBuilder<List<ModAction>>(
                  future: _historyFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                          child: Text('${snapshot.error}',
                              style: const TextStyle(color: Colors.redAccent)));
                    }
                    
                    final history = snapshot.data!;
                    
                    // Filter Logic
                    var filteredHistory = history;
                    if (_filterAction != 'all') {
                      filteredHistory = filteredHistory
                          .where((a) => a.actionType.toLowerCase() == _filterAction)
                          .toList();
                    }
                    if (_searchQuery.isNotEmpty) {
                      final q = _searchQuery.toLowerCase();
                      filteredHistory = filteredHistory.where((a) => 
                        (a.targetTag?.toLowerCase().contains(q) ?? false) || 
                        (a.targetId.contains(q))
                      ).toList();
                    }

                    if (filteredHistory.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            const Text('Tidak ada riwayat yang cocok',
                                style: TextStyle(
                                    color: Colors.black54, fontSize: 16)),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 80), // padding for FAB
                      itemCount: filteredHistory.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: Colors.black12, height: 1),
                      itemBuilder: (context, i) {
                        final a = filteredHistory[i];
                        IconData iconData;
                        Color iconColor;
                        Color bgColor;
                        switch (a.actionType.toLowerCase()) {
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
                            bgColor = const Color(0xFFF62440).withValues(alpha: 0.1);
                            break;
                          case 'mute':
                            iconData = Icons.volume_off_rounded;
                            iconColor = Colors.blueGrey;
                            bgColor = Colors.blueGrey.shade50;
                            break;
                          case 'message_delete':
                            iconData = Icons.delete_outline_rounded;
                            iconColor = Colors.purple;
                            bgColor = Colors.purple.shade50;
                            break;
                          default:
                            iconData = Icons.info_outline_rounded;
                            iconColor = Colors.grey;
                            bgColor = Colors.grey.shade50;
                        }
                        return RepaintBoundary(
                          child: ListTile(
                            leading: CircleAvatar(
                                backgroundColor: bgColor,
                                child: Icon(iconData, color: iconColor, size: 20)),
                            title: Text(a.targetTag ?? a.targetId,
                                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              '${a.actionType.toUpperCase().replaceAll('_', ' ')} oleh ${a.moderatorTag}${a.reason != null ? "\n${a.reason}" : ""}',
                              style: const TextStyle(color: Colors.black54),
                            ),
                            isThreeLine: a.reason != null,
                            trailing: Text(
                                _dateFormat.format(a.createdAt),
                                style: const TextStyle(
                                    color: Colors.black38, fontSize: 11)),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
