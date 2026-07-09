import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';

class ModActionBottomSheet extends StatefulWidget {
  final VoidCallback onActionSuccess;

  const ModActionBottomSheet({super.key, required this.onActionSuccess});

  @override
  State<ModActionBottomSheet> createState() => _ModActionBottomSheetState();
}

class _ModActionBottomSheetState extends State<ModActionBottomSheet> {
  final _searchController = TextEditingController();
  final _reasonController = TextEditingController();
  
  bool _isSearching = false;
  String _error = '';
  List<dynamic> _searchResults = [];
  Timer? _debounce;

  Map<String, dynamic>? _selectedUser;
  String _selectedAction = 'warn'; // warn, mute, kick, ban

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _reasonController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      if (query.length >= 2) {
        _performSearch(query);
      } else {
        setState(() {
          _searchResults = [];
          _error = '';
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isSearching = true;
      _error = '';
    });
    try {
      final results = await ApiService.searchMembers(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error: $e';
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _submitAction() async {
    if (_selectedUser == null) return;
    final userId = _selectedUser!['id'];
    final userTag = _selectedUser!['tag'];
    final reason = _reasonController.text.trim();

    try {
      setState(() => _isSearching = true); // reuse loading state for submission
      
      switch (_selectedAction) {
        case 'warn':
          await ApiService.warnUser(userId, userTag, reason);
          break;
        case 'mute':
          // Default to 1 day for simplicity, could add a dropdown later
          await ApiService.muteUser(userId, 86400000, reason: reason); 
          break;
        case 'kick':
          await ApiService.kickUser(userId, reason: reason);
          break;
        case 'ban':
          await ApiService.banUser(userId, reason: reason);
          break;
      }
      
      if (mounted) {
        Navigator.pop(context);
        widget.onActionSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Aksi $_selectedAction berhasil dilakukan pada $userTag')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isSearching = false;
        });
      }
    }
  }

  Widget _buildActionChip(String action, String label, Color color) {
    final isSelected = _selectedAction == action;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: color.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(color: isSelected ? color : Colors.grey.shade300),
      onSelected: (selected) {
        if (selected) setState(() => _selectedAction = action);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Add safe area at bottom for keyboard
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          const Text(
            'Ambil Tindakan Baru',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1D2E)),
          ),
          const SizedBox(height: 16),
          
          if (_selectedUser == null) ...[
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari username atau nickname...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                ) : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error, style: const TextStyle(color: Colors.red)),
              ),
            
            // Search Results
            if (_searchResults.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 12),
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.separated(
                  itemCount: _searchResults.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user['avatarUrl'] != null ? NetworkImage(user['avatarUrl']) : null,
                        child: user['avatarUrl'] == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text(user['displayName'] ?? user['username'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(user['tag']),
                      onTap: () {
                        setState(() {
                          _selectedUser = user;
                          _searchController.clear();
                          _searchResults = [];
                        });
                      },
                    );
                  },
                ),
              ),
          ] else ...[
            // User Selected View
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: _selectedUser!['avatarUrl'] != null ? NetworkImage(_selectedUser!['avatarUrl']) : null,
                    child: _selectedUser!['avatarUrl'] == null ? const Icon(Icons.person) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_selectedUser!['displayName'] ?? _selectedUser!['username'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(_selectedUser!['tag'], style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _selectedUser = null),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            const Text('Pilih Aksi:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildActionChip('warn', 'Warn', Colors.orange),
                _buildActionChip('mute', 'Mute (24 Jam)', Colors.blueGrey),
                _buildActionChip('kick', 'Kick', Colors.red),
                _buildActionChip('ban', 'Ban', const Color(0xFFF62440)),
              ],
            ),
            
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                hintText: 'Alasan (opsional)...',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 2,
            ),
            
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF5865F2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSearching ? null : _submitAction,
                child: _isSearching 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Eksekusi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
