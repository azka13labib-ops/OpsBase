import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/user_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Keluar?'),
        content: const Text('Kamu perlu login ulang lewat Discord untuk masuk kembali.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Keluar')),
        ],
      ),
    );
    if (confirm == true) {
      context.read<UserProvider>().clear();
      await AuthService.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = AuthService.currentUser;
    final username = authUser?.userMetadata?['full_name'] ?? authUser?.userMetadata?['name'] ?? 'Admin';
    final roleNames = context.watch<UserProvider>().user?.roleNames ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                const CircleAvatar(radius: 28, backgroundColor: Color(0xFF5865F2), child: Icon(Icons.person, color: Colors.white)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(username, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(authUser?.email ?? '', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                      if (roleNames.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: roleNames.map((r) => Chip(
                                label: Text(r, style: const TextStyle(fontSize: 11)),
                                backgroundColor: const Color(0xFF5865F2).withOpacity(0.2),
                                labelStyle: const TextStyle(color: Color(0xFF5865F2)),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              )).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.notifications_outlined, color: Colors.black54),
            title: const Text('Notifikasi', style: TextStyle(color: Colors.black87)),
            subtitle: const Text('Push notification aktif otomatis', style: TextStyle(color: Colors.black38)),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Keluar', style: TextStyle(color: Colors.redAccent)),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
