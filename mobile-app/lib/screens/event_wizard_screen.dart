import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class EventWizardScreen extends StatefulWidget {
  final CommunityEvent? existingEvent;
  const EventWizardScreen({super.key, this.existingEvent});

  @override
  State<EventWizardScreen> createState() => _EventWizardScreenState();
}

class _EventWizardScreenState extends State<EventWizardScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  
  DateTime _startTime = DateTime.now().add(const Duration(hours: 1));
  bool _isRecurring = false;
  bool _syncToDiscord = true;
  
  XFile? _coverImage;
  String? _existingCoverUrl;
  
  bool _isLoading = false;
  String? _error;

  final Color _blurple = const Color(0xFF5865F2);

  @override
  void initState() {
    super.initState();
    if (widget.existingEvent != null) {
      final ev = widget.existingEvent!;
      _titleController.text = ev.title;
      _descController.text = ev.description ?? '';
      _startTime = ev.startTime;
      _isRecurring = ev.isRecurring;
      _existingCoverUrl = ev.coverUrl;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _coverImage = image);
    }
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      setState(() => _error = 'Judul event wajib diisi');
      return;
    }

    if (widget.existingEvent != null) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.edit_calendar_rounded, color: Color(0xFF5865F2), size: 28),
              SizedBox(width: 8),
              Text('Simpan Perubahan?', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text('Apakah Anda yakin ingin menyimpan perubahan pada event ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal', style: TextStyle(color: Colors.black54)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5865F2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Simpan'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String? coverUrl = _existingCoverUrl;

      if (_coverImage != null) {
        final bytes = await _coverImage!.readAsBytes();
        final ext = _coverImage!.name.split('.').last;
        final filename = '${DateTime.now().millisecondsSinceEpoch}.$ext';
        
        await Supabase.instance.client.storage
            .from('event_covers')
            .uploadBinary(filename, bytes);
            
        coverUrl = Supabase.instance.client.storage
            .from('event_covers')
            .getPublicUrl(filename);
      }

      if (widget.existingEvent != null) {
        await ApiService.updateEvent(
          widget.existingEvent!.id,
          title: _titleController.text.trim(),
          description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          coverUrl: coverUrl,
          startTime: _startTime,
          isRecurring: _isRecurring,
        );
      } else {
        await ApiService.createEvent(
          title: _titleController.text.trim(),
          description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          coverUrl: coverUrl,
          startTime: _startTime,
          isRecurring: _isRecurring,
          syncToDiscord: _syncToDiscord,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EEEE, d MMM yyyy HH:mm', 'id_ID');
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          widget.existingEvent != null ? 'Edit Event' : 'Buat Event Baru',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Poster Section
                  const Text('Poster Event', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: _coverImage != null
                          ? ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.file(File(_coverImage!.path), fit: BoxFit.cover))
                          : _existingCoverUrl != null
                              ? ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.network(_existingCoverUrl!, fit: BoxFit.cover))
                              : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: _blurple.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.add_photo_alternate_rounded, size: 40, color: _blurple),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text('Tap untuk pilih gambar', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Detail Section
                  const Text('Detail Event', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'Judul Event *',
                      labelStyle: const TextStyle(color: Colors.black54),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: Icon(Icons.title, color: _blurple),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Deskripsi',
                      alignLabelWithHint: true,
                      labelStyle: const TextStyle(color: Colors.black54),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Waktu Section
                  const Text('Jadwal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      title: const Text('Waktu Mulai', style: TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(df.format(_startTime), style: const TextStyle(color: Colors.black54)),
                      trailing: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _blurple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.calendar_month_rounded, color: _blurple, size: 24),
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context, 
                          initialDate: _startTime, 
                          firstDate: DateTime.now(), 
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(primary: _blurple),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (date != null && mounted) {
                          final time = await showTimePicker(
                            context: context, 
                            initialTime: TimeOfDay.fromDateTime(_startTime),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(primary: _blurple),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (time != null) {
                            setState(() => _startTime = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      title: const Text('Event Rutin (Berulang)', style: TextStyle(fontWeight: FontWeight.w500)),
                      activeColor: _blurple,
                      value: _isRecurring,
                      onChanged: (v) => setState(() => _isRecurring = v),
                    ),
                  ),
                  
                  if (widget.existingEvent == null) ...[
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        title: const Text('Buat Event di Discord juga', style: TextStyle(fontWeight: FontWeight.w500)),
                        activeColor: _blurple,
                        value: _syncToDiscord,
                        onChanged: (v) => setState(() => _syncToDiscord = v),
                      ),
                    ),
                  ],

                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
            
            // Bottom Save Button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), offset: const Offset(0, -4), blurRadius: 16),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text(
                        widget.existingEvent != null ? 'Simpan Perubahan' : 'Buat Event Baru', 
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
