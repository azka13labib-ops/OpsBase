import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/user_provider.dart';
import '../services/socket_service.dart';
import '../models/models.dart';

class ModerationScreen extends StatefulWidget {
  const ModerationScreen({super.key});

  @override
  State<ModerationScreen> createState() => _ModerationScreenState();
}

class _ModerationScreenState extends State<ModerationScreen> {
  late Future<List<ModAction>> _historyFuture;

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
    setState(() => _historyFuture = _load());
    await _historyFuture;
  }

  void _openQuickAction() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _QuickActionSheet(),
    ).then((_) => _refresh());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Moderasi')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openQuickAction,
        icon: const Icon(Icons.bolt),
        label: const Text('Aksi Cepat'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<ModAction>>(
          future: _historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
            }
            final history = snapshot.data!;
            if (history.isEmpty) {
              return const Center(child: Text('Belum ada riwayat moderasi', style: TextStyle(color: Colors.black38)));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              separatorBuilder: (_, __) => const Divider(color: Colors.black12, height: 1),
              itemBuilder: (context, i) {
                final a = history[i];
                return ListTile(
                  leading: CircleAvatar(backgroundColor: const Color(0xFFF2F3F5), child: Text(a.emoji)),
                  title: Text('${a.targetTag ?? a.targetId}', style: const TextStyle(color: Colors.black87)),
                  subtitle: Text(
                    '${a.actionType.toUpperCase()} oleh ${a.moderatorTag}${a.reason != null ? "\n${a.reason}" : ""}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  isThreeLine: a.reason != null,
                  trailing: Text(DateFormat('d MMM HH:mm', 'id_ID').format(a.createdAt), style: const TextStyle(color: Colors.black38, fontSize: 11)),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Bottom sheet untuk warn/kick/ban/mute cepat berdasarkan User ID.
/// Catatan: untuk versi lebih lanjut, ganti input User ID manual ini dengan
/// pencarian member (butuh endpoint tambahan GET /api/members?search=).
class _QuickActionSheet extends StatefulWidget {
  const _QuickActionSheet();

  @override
  State<_QuickActionSheet> createState() => _QuickActionSheetState();
}

class _QuickActionSheetState extends State<_QuickActionSheet> {
  final _userIdController = TextEditingController();
  final _reasonController = TextEditingController();
  String _action = 'warn';
  bool _loading = false;
  String? _error;

  List<String> _availableActions(BuildContext context) {
    final user = context.read<UserProvider>();
    final actions = <String>[];
    if (user.can(Capability.moderateWarn)) actions.add('warn');
    if (user.can(Capability.moderateMute)) actions.add('mute');
    if (user.can(Capability.moderateKick)) actions.add('kick');
    if (user.can(Capability.moderateBan)) actions.add('ban');
    return actions;
  }

  @override
  void initState() {
    super.initState();
    // Set default action ke aksi pertama yang memang boleh dia lakukan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final available = _availableActions(context);
      if (available.isNotEmpty && !available.contains(_action)) {
        setState(() => _action = available.first);
      }
    });
  }

  Future<void> _submit() async {
    if (_userIdController.text.trim().isEmpty) {
      setState(() => _error = 'User ID wajib diisi');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userId = _userIdController.text.trim();
      final reason = _reasonController.text.trim();
      switch (_action) {
        case 'warn':
          await ApiService.warnUser(userId, userId, reason.isEmpty ? 'Tidak ada alasan' : reason);
          break;
        case 'kick':
          await ApiService.kickUser(userId, reason: reason.isEmpty ? null : reason);
          break;
        case 'ban':
          await ApiService.banUser(userId, reason: reason.isEmpty ? null : reason);
          break;
        case 'mute':
          await ApiService.muteUser(userId, 3600000, reason: reason.isEmpty ? null : reason); // default 1 jam
          break;
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Aksi Moderasi Cepat', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: _availableActions(context).map((a) {
              return ChoiceChip(
                label: Text(a.toUpperCase()),
                selected: _action == a,
                onSelected: (_) => setState(() => _action = a),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _userIdController,
            decoration: const InputDecoration(labelText: 'User ID (Discord)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(labelText: 'Alasan', border: OutlineInputBorder()),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading ? const CircularProgressIndicator() : Text('Jalankan ${_action.toUpperCase()}'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
