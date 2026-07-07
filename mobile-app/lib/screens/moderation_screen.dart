import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../utils/localization.dart';
import '../services/user_provider.dart';
import '../services/socket_service.dart';
import '../models/models.dart';

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
      builder: (_) => const _QuickActionSheet(),
    ).then((_) => _refresh());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'mod_fab',
        onPressed: _openQuickAction,
        icon: const Icon(Icons.bolt),
        label: Text(context.l10n.quickAction),
      ),
      body: SafeArea(
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
              if (history.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_outlined,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(context.l10n.noModHistory,
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 16)),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: history.length,
                separatorBuilder: (_, __) =>
                    const Divider(color: Colors.black12, height: 1),
                itemBuilder: (context, i) {
                  final a = history[i];
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
                    default:
                      iconData = Icons.info_outline_rounded;
                      iconColor = Colors.grey;
                      bgColor = Colors.grey.shade50;
                  }
                  return ListTile(
                    leading: CircleAvatar(
                        backgroundColor: bgColor,
                        child: Icon(iconData, color: iconColor, size: 20)),
                    title: Text(a.targetTag ?? a.targetId,
                        style: const TextStyle(color: Colors.black87)),
                    subtitle: Text(
                      '${a.actionType.toUpperCase()} ${context.l10n.by} ${a.moderatorTag}${a.reason != null ? "\n${a.reason}" : ""}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    isThreeLine: a.reason != null,
                    trailing: Text(
                        DateFormat('d MMM HH:mm', 'id_ID').format(a.createdAt),
                        style: const TextStyle(
                            color: Colors.black38, fontSize: 11)),
                  );
                },
              );
            },
          ),
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
      setState(() => _error = context.l10n.userIdRequired);
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
          await ApiService.warnUser(
              userId, userId, reason.isEmpty ? context.l10n.noReason : reason);
          break;
        case 'kick':
          await ApiService.kickUser(userId,
              reason: reason.isEmpty ? null : reason);
          break;
        case 'ban':
          await ApiService.banUser(userId,
              reason: reason.isEmpty ? null : reason);
          break;
        case 'mute':
          await ApiService.muteUser(userId, 3600000,
              reason: reason.isEmpty ? null : reason); // default 1 jam
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
    Color currentActionColor;
    switch (_action) {
      case 'warn':
        currentActionColor = Colors.orange;
        break;
      case 'kick':
        currentActionColor = Colors.red;
        break;
      case 'ban':
        currentActionColor = const Color(0xFFF62440);
        break;
      case 'mute':
        currentActionColor = Colors.blueGrey;
        break;
      default:
        currentActionColor = const Color(0xFF5865F2);
    }

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Text(context.l10n.quickAction,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _availableActions(context).map((a) {
                final isSelected = _action == a;
                Color actionColor;
                switch (a) {
                  case 'warn':
                    actionColor = Colors.orange;
                    break;
                  case 'kick':
                    actionColor = Colors.red;
                    break;
                  case 'ban':
                    actionColor = const Color(0xFFF62440);
                    break;
                  case 'mute':
                    actionColor = Colors.blueGrey;
                    break;
                  default:
                    actionColor = const Color(0xFF5865F2);
                }

                return InkWell(
                  onTap: () => setState(() => _action = a),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? actionColor.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? actionColor
                            : Colors.grey.withValues(alpha: 0.2),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      a.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? actionColor : Colors.black54,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _userIdController,
              decoration: InputDecoration(
                labelText: context.l10n.userId,
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: currentActionColor, width: 2)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: 'Alasan',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: currentActionColor, width: 2)),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_error!,
                            style: const TextStyle(color: Colors.red))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: currentActionColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text('Jalankan ${_action.toUpperCase()}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
